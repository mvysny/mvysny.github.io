---
layout: post
title: Enlarging AMD iGPU GTT on Linux to Run Big LLMs
---

AMD integrated GPUs (APUs) share the system RAM with the CPU — there's no separate
VRAM chip. In the BIOS you can carve out a fixed chunk of RAM as "VRAM" for the iGPU,
but that setting is usually capped: on my **Ryzen AI 9 HX 370 (Radeon 890M)** the BIOS
tops out at 48 GB. On a machine with 96 or 128 GB of RAM that's frustrating — you'd love
to hand more of it to the GPU and run a 70B model.

Good news: on Linux the BIOS number is not the ceiling. The `amdgpu` driver can additionally
map regular system RAM into the GPU's address space as **GTT** memory, and that pool is
tunable independently of the BIOS, well past 48 GB. This is exactly what lets these little
APUs run surprisingly large LLMs.

# What is GTT?

GTT stands for **Graphics Translation Table**. Two pools of GPU-visible memory exist on an APU:

- **VRAM** — the fixed carve-out reserved by the BIOS during POST, before the kernel even loads.
  It's contiguous, pinned, and the GPU addresses it directly. You can only change its size in BIOS.
- **GTT** — regular kernel-managed system RAM pages, made GPU-accessible on demand by mapping them
  through the GART (Graphics Address Remapping Table). Sized by a kernel parameter, not the BIOS.

The crucial point on an APU: **both pools live in the same physical DRAM**, on the same memory
controller, with the same bandwidth. There is no separate GPU bus and no PCIe hop. "VRAM" and "GTT"
are just two labels for two ways the driver hands you the same DDR4/LPDDR5x.

GTT is not new and not tied to the "AI" branding. It's a generic part of `amdgpu` that predates the
Ryzen AI series — my ancient **Ryzen 7 PRO 4750U** (Renoir, Vega, GFX9) uses the exact same mechanism.

# How it helps running LLMs

llama.cpp's **Vulkan backend** (via RADV) treats VRAM + GTT as one combined pool of usable device
memory. Unlike Windows, there's no hard cap: you can load a model far bigger than the BIOS VRAM
number and it simply spills into GTT.

That means a laptop with a 2 GB VRAM carve-out can happily run an 24 GB model on the GPU, and a
Strix-Halo-class box reaches 100+ GB usable. On my 4750U with a modest 2 GB VRAM setting, the driver
already exposes ~14.3 GB of GTT *by default* — roughly 16 GB of GPU-visible memory for free.

> **Caveat — Vulkan, not ROCm.** This trick works for the Vulkan backend. ROCm/HIP is much more
> restrictive: on gfx1150 `hipMalloc` can only allocate inside dedicated VRAM, not GTT, and AMD
> doesn't officially support the 890M under ROCm anyway. So on these iGPUs, use the Vulkan backend.
> It needs only functional Vulkan drivers — no ROCm stack — and it's dramatically faster than CPU.

If your `llama-server` logs `no usable GPU found`, you're probably missing the Vulkan backend package
(the Debian/Ubuntu llama.cpp package ships backends separately):

```bash
sudo apt install libggml0-backend-vulkan mesa-vulkan-drivers vulkan-tools
vulkaninfo --summary   # confirm an AMD Radeon / RADV entry
```

# Enlarging the GTT pool

Two things trip people up before anything else works:

**1. VRAM cannot be changed from Linux — only in BIOS.** The `ttm` parameters below affect *only* GTT,
never VRAM. If `dmesg` keeps reporting your BIOS VRAM number, that's expected; leave it alone (set it
*small* — see below).

**2. Use the `ttm.` prefix, not `amdttm.`** This is the big one. `amdttm.*` is for AMD Instinct
(datacenter) hardware; on consumer Ryzen APUs it is **silently ignored**. Consumer chips use the plain
`ttm.` prefix. I burned an evening on this: I set `amdttm.pages_limit=...`, rebooted, and nothing
changed — the driver just kept showing the auto default.

The value is a **page count**, and GTT pages are 4 KiB. So:

```
pages = GB × 1024 × 1024 / 4  = GB × 262144
```

For example, 28 GB → `28 × 262144 = 7340032` pages. Leave ~20% of RAM as headroom for the OS.

## Applying it via /etc/kernel/cmdline (systemd-boot + Secure Boot)

If you set up Secure Boot the way I describe in
[ubuntu-systemd-boot-mok-shim](https://codeberg.org/mvysny/ubuntu-systemd-boot-mok-shim/), your kernel
command line lives in `/etc/kernel/cmdline` and is *baked into each signed UKI*. There is no
boot-time editing (that's the whole point of Secure Boot). So editing the file alone changes nothing —
you must rebuild and re-sign the UKIs.

Edit `/etc/kernel/cmdline` (it's a single line containing the *complete* command line, including
`root=`) and append the parameter. For 28 GB of GTT on a 32 GB machine:

```
... root=UUID=... ro quiet splash ttm.pages_limit=7340032 ttm.page_pool_size=7340032
```

Then rebuild the UKIs and reboot:

```bash
sudo ./rebuild-ukis
sudo reboot
```

## Verify it took effect

```bash
# runtime page counts:
cat /sys/module/ttm/parameters/pages_limit /sys/module/ttm/parameters/page_pool_size
# convert page count → GB:
awk 'BEGIN{print 7340032 / 262144}'   # → 28

# GPU-visible memory as seen by the driver:
cat /sys/class/drm/card0/device/mem_info_vram_total \
    /sys/class/drm/card0/device/mem_info_gtt_total
dmesg | grep -i amdgpu
```

If you fat-fingered the parameter name, `dmesg | grep -i "unknown parameter"` will show
`ttm: unknown parameter '...' ignored`. If the sysfs path doesn't exist at all, the module isn't
loaded or the name is wrong for your kernel — cross-check with `modinfo ttm`.

The real proof is loading a model bigger than your VRAM carve-out and watching GTT climb:

```bash
./llama-cli -hf unsloth/Qwen3-8B-GGUF:Q4_K_M -ngl 99
# in another terminal:
watch -n1 'cat /sys/class/drm/card0/device/mem_info_vram_used \
                /sys/class/drm/card0/device/mem_info_gtt_used'
```

## Set the BIOS VRAM small

Counter-intuitively, for a pure LLM box you want the BIOS VRAM set **small** (512 MB – 1 GB), then let
the large GTT pool do the work. Vulkan combines the two anyway, and a small carve-out frees more RAM
for GTT. (If you also game on the machine, keep a *moderate* 4–8 GB carve-out — some OpenGL titles read
the reported dedicated-VRAM number and balk at "512 MB", and games get a protected block that way.)

# Concrete results

The models here use Qwen3's dense/MoE naming. An `8B` is a plain **dense** model; `A3B` is not a size —
it's MoE shorthand for "3B active parameters", used on the 30B- and 35B-class mixture-of-experts models
(e.g. `Qwen3.6-35B-A3B`: 35B total, 3B active per token). There's no such thing as an "8B-A3B".

- **Ryzen 7 PRO 4750U** (8-core Renoir, Vega, ~32 GB RAM), GTT set to 28 GB via `ttm.pages_limit`:
  a **Qwen3.6-35B-A3B** MoE (~22 GB at Q4_K_M) — which *cannot* fit in this laptop's VRAM carve-out at
  all — runs entirely on the Vulkan backend at **~10 tokens/s**. On a 6-year-old business laptop.
- **Ryzen AI 9 HX 370** (Radeon 890M, LPDDR5x): the same **Qwen3.6-35B-A3B** MoE runs at **19.18 t/s**
  with an 8 GB VRAM + 70 GB GTT split, and at **21.33 t/s** with a 48 GB fixed VRAM carve-out that holds
  the whole model — see the performance section below.

Good all-round starter model that comfortably exceeds a 2 GB VRAM ceiling without stressing a 16 GB
budget, runs on the old CPU at around 5.4 TPS:

```bash
./llama-server -hf unsloth/Qwen3-8B-GGUF:Q4_K_M -ngl 99   # ~5 GB
```

# The performance hit: is GTT slower than VRAM?

Physically? No. On an APU it's the same DRAM at the same bandwidth, and token generation is
**memory-bandwidth-bound** — performance tracks your RAM frequency, not the VRAM/GTT label. My first
instinct was "no meaningful difference".

Measured? There *is* a small hit, and it's a real access-path cost, not noise. On the HX 370 with the
Qwen3.6-35B-A3B MoE:

| Layout                    | Speed      |
|---------------------------|------------|
| 48 GB VRAM (whole model)  | 21.33 t/s  |
| 8 GB VRAM + 70 GB GTT     | 19.18 t/s  |

That's a consistent **~11%**. The cause: VRAM is a contiguous carve-out the GPU addresses directly,
while every GTT access goes through the GART address-remapping layer (and the IOMMU, if enabled),
carrying translation cost and worse TLB behavior. That shaves a few percent off *effective* bandwidth.

**Why MoE amplifies it.** Qwen3.6-35B-A3B is ~22 GB at Q4. With 48 GB VRAM the whole thing is in the
direct-access pool. With 8 GB VRAM + GTT, ~14 GB spills to GTT — and because MoE changes its active
expert set every token, generation effectively streams weights from *across the whole model*, so most
per-token reads take the slower GTT path. A dense model that fits in the carve-out wouldn't show this.

Two things worth knowing:

- **11% is the well-behaved case.** The horror stories of "GTT is 35% slower than CPU" are about
  *discrete* GPUs, where GTT means genuine PCIe round-trips. On a UMA APU there's no PCIe hop, so you
  get off lightly.
- **`iommu=pt` helps a bit.** Adding `iommu=pt` (passthrough) to the kernel cmdline lets the device
  bypass IOMMU translation for its own memory and cuts some of the GTT overhead. On the HX 370 with the
  8 GB VRAM + 70 GB GTT split it nudged the Qwen3.6-35B-A3B MoE from 19.18 t/s up to roughly **20 t/s** —
  a small but real gain. It's hardware-dependent, so A/B benchmark it with `llama-bench` on your box.

  **Drawback of `iommu=pt`:** it weakens DMA protection. `pt` doesn't disable the IOMMU (that's
  `iommu=off`); instead it identity-maps host memory for DMA, so devices can read/write *all* of
  physical RAM directly instead of only the buffers the IOMMU would otherwise remap for them. That
  removes a layer of isolation against buggy or malicious peripherals doing arbitrary DMA — the classic
  risk being an untrusted Thunderbolt/USB4 or PCIe device (an "evil maid" DMA attack). It also loosens
  the memory isolation you'd want if you do VFIO device passthrough to VMs. On a locked-down laptop
  with no external PCIe/Thunderbolt exposure the practical risk is low, which is why `iommu=pt` is a
  common performance default — but on a machine where untrusted devices can be plugged in, that's a
  real security trade-off, not a free win. (There's no correctness or stability downside for the GPU
  itself.)

**The tradeoff:** a big fixed VRAM carve-out is ~11% faster but locks that RAM away from the OS; a
small VRAM + big GTT split shares RAM flexibly at a small speed cost. If your model fits in the max
carve-out, VRAM wins. If it exceeds the carve-out (the whole reason you're reading this), you're on GTT
regardless — and 19 t/s on a laptop iGPU for a 35B model is a fine deal.

# Troubleshooting: `vk::DeviceLostError` during prompt processing

If the model loads fine but `llama-server` crashes mid-prompt with:

```
radv/amdgpu: The CS has been cancelled because the context is lost.
terminate called after throwing an instance of 'vk::DeviceLostError'
  what():  vk::Queue::submit: ErrorDeviceLost
```

...it's **not** a memory problem. It's a known issue on slower AMD iGPUs (e.g. Renoir gfx90c under
RADV): llama.cpp batches many nodes into one `vkQueueSubmit`, and on a slow GPU the accumulated work in
a single submission exceeds `amdgpu.lockup_timeout` (default 2000 ms). The kernel resets the compute
ring and it surfaces as device-lost — typically right as batches get large (`n_tokens=4096`).

Two fixes, in order of preference:

1. **Shrink the batch** (most targeted):
   ```bash
   ./llama-server -m model.gguf -ngl 99 -ub 256 -b 256   # try 128 if still crashing
   ```
2. **Raise the lockup timeout** — since we're already editing `/etc/kernel/cmdline`, just add it there
   rather than fiddling with `/etc/modprobe.d`:
   ```
   ... ttm.pages_limit=7340032 amdgpu.lockup_timeout=10000
   ```
   Rebuild UKIs, reboot, and verify with `cat /sys/module/amdgpu/parameters/lockup_timeout`.

Try `-ub`/`-b` first — it's the documented root cause, and it usually lets you keep the bigger model.

# CPU baseline, for comparison

To measure how much the iGPU actually buys you:

```bash
./llama-bench -m model.gguf -ngl 99          # GPU (Vulkan)
./llama-bench -m model.gguf -ngl 0           # CPU only
./llama-server -m model.gguf --device none   # truer CPU baseline: skips Vulkan init entirely
```

For a fair CPU run, pin threads to *physical* cores (`-t 8` on the 8-core/16-thread 4750U) — the
llama.cpp CPU backend peaks around physical-core count.

# Summary

- The BIOS VRAM cap is not the ceiling. On Linux, `amdgpu` exposes system RAM as GTT, and the Vulkan
  backend treats VRAM + GTT as one pool.
- On consumer Ryzen use `ttm.pages_limit` / `ttm.page_pool_size` (**not** `amdttm.`), with
  `pages = GB × 262144`.
- With Secure Boot + systemd-boot UKIs, put it in `/etc/kernel/cmdline` and run `sudo ./rebuild-ukis`.
- The GTT-vs-VRAM performance hit is real but small (~11% on an MoE, less on dense models) because on
  an APU it's the same DRAM — you're only paying GART/IOMMU translation overhead, not a PCIe hop.
