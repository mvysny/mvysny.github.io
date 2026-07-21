---
layout: post
title: Local RAG with llama.cpp on Nvidia and LlamaIndex
---

I [already wrote up](../lemonade-llamaindex-local-rag/)
how I run RAG over my own documents on an AMD Ryzen AI box using
Lemonade. This post is the same setup for an Nvidia laptop. Lemonade doesn't
work with Nvidia's proprietary drivers, so on this machine I drive three
`llama-server` processes directly instead. LlamaIndex still lives in a
libvirt VM and talks to them over `virbr0`.

The machine is a laptop with an **Nvidia GeForce RTX 4060 Laptop GPU** on
Ubuntu 26.04 with the proprietary Nvidia driver. The whole stack runs
through **Vulkan**, not CUDA — Ubuntu 26.04 ships llama.cpp and a
`libggml0-backend-vulkan` package in the archive, but there's no CUDA
ggml backend in apt. Vulkan on the proprietary Nvidia driver is rock
solid and fast enough that the CUDA route isn't worth the out-of-tree
package dance.

## The setup

Two machines, one physical:

- **Host**: Ubuntu 26.04 on the RTX 4060 laptop. Runs **three
  `llama-server` processes**, one per model, each on its own port:
  - `:8000` — `unsloth/Qwen3.5-4B-GGUF:Q4_K_M`, the chat LLM, 32k context.
  - `:8001` — `nomic-ai/nomic-embed-text-v1.5-GGUF:Q4_K_M`, the embedder,
    8192 context.
  - `:8002` — `gpustack/bge-reranker-v2-m3-GGUF:Q4_K_M`, the
    cross-encoder reranker, 2048 context.
  All three are plain OpenAI-compatible HTTP endpoints bound to
  `192.168.122.1` (the libvirt default bridge) so the VM can reach them.
- **VM**: a libvirt guest on `192.168.122.0/24` running the **LlamaIndex**
  Python script. Each of the three servers is configured as an independent
  OpenAI endpoint in LlamaIndex: `http://192.168.122.1:8000/v1` for chat,
  `:8001/v1` for embeddings, `:8002/v1` for rerank.

## What each piece does

**llama.cpp** is the inference engine. One process per model is the
path of least resistance here: each server pins its own GPU memory,
batching is tuned per-workload, and a crash or restart of one doesn't
disturb the others. The three servers together use most of the 8 GB on
the 4060 Mobile — Q4_K_M quantization keeps each model small enough that
they coexist.

**Vulkan** is the GPU backend. `libggml0-backend-vulkan` is the
plug-in shared library ggml loads to talk to the GPU through the Vulkan
API; the proprietary Nvidia driver ships its own Vulkan ICD, so the path
is userspace-llama.cpp → Vulkan loader → Nvidia ICD → GPU. No CUDA
toolkit, no DKMS drama beyond installing the driver itself, and no
recompiling llama.cpp — the apt package already has Vulkan support wired
in. On a 4060 Mobile this is within a few percent of CUDA for single-stream
inference at these model sizes.

**LlamaIndex** is the orchestration library. It reads the folder of
documents, chunks them, embeds the chunks, stores them in an in-memory
vector index, and runs the retrieval → rerank → answer pipeline:

1. Split docs into 1024-token chunks with ~10% overlap (102 tokens).
2. Embed each chunk using the `:8001` embedding endpoint.
3. For each query: retrieve the top 20 chunks by cosine similarity.
4. Rerank those 20 with the cross-encoder on `:8002` down to the top 10.
5. Stuff the top 10 into the LLM on `:8000` and ask for an answer.

The **cross-encoder reranker** is what makes this actually good. A bi-encoder
embedder gives you recall; a cross-encoder that sees `(query, doc)` together
gives you precision. Going `20 → 10` with BGE v2-m3 is cheap on Vulkan and
makes answers dramatically less hallucinatory.

## Installing llama.cpp and the Vulkan backend

From the Ubuntu archive:

```bash
sudo apt install llama.cpp libggml0-backend-vulkan vulkan-tools
```

`vulkan-tools` is optional but handy — `vulkaninfo --summary` should list
the Nvidia GPU as a Vulkan device. If it doesn't, the rest won't work; fix
the driver situation first (`ubuntu-drivers autoinstall` or the Nvidia
`.run` installer, depending on how you run your machine).

## Running the three servers

Each server downloads its GGUF from HuggingFace on first run via the `-hf`
flag and caches it under `~/.cache/llama.cpp`. No separate `pull` step.

```bash
# LLM on port 8000
llama-server -hf unsloth/Qwen3.5-4B-GGUF:Q4_K_M \
  -ngl 99 -c 32768 --jinja \
  --host 192.168.122.1 --port 8000 &

# Embedder on port 8001
llama-server -hf nomic-ai/nomic-embed-text-v1.5-GGUF:Q4_K_M \
  -ngl 99 --embeddings \
  -c 8192 -b 4096 -ub 4096 \
  --host 192.168.122.1 --port 8001 &

# Reranker on port 8002
llama-server -hf gpustack/bge-reranker-v2-m3-GGUF:Q4_K_M \
  -ngl 99 --reranking \
  -c 2048 -b 2048 -ub 2048 \
  --host 192.168.122.1 --port 8002 &
```

A few of the flags are worth calling out:

- `-ngl 99` offloads "up to 99 layers" to the GPU — i.e., all of them for
  models of this size. Drop it and the server falls back to CPU inference,
  which for a 4 B model is unusably slow compared to the GPU path.
- `--jinja` enables the Jinja chat template embedded in the GGUF, which is
  what makes Qwen3.5's actual chat format (including `<think>` tags) work
  through the `/v1/chat/completions` endpoint. Without it the server uses
  a generic default template and you get worse answers for no good reason.
- `-b 4096 -ub 4096` on the embedder is a large physical/ubatch size so
  the GPU stays saturated while indexing a corpus. The default (512) makes
  initial indexing a few times slower for no benefit — embedding is
  perfectly batch-parallel.
- `-b 2048 -ub 2048` on the reranker matters even more: a single
  `(query, doc)` pair for BGE-reranker-v2-m3 can tokenize to more than 512
  tokens, at which point the server refuses the request with
  `input (N tokens) is too large to process. increase the physical batch
  size`. Setting the ubatch to the full context avoids this.
- `--host 192.168.122.1` binds to the libvirt bridge so the VM can reach
  the servers. Default is `127.0.0.1`, which is useless for this layout.

I run these straight from a terminal and leave them in the background with
`&`. If you want them to survive a reboot, wrap them in a systemd user unit
or a tmux session — nothing about the servers themselves cares.

Sanity-check that all three are up:

```bash
for p in 8000 8001 8002; do
  echo "-- :$p --"
  curl -s http://192.168.122.1:$p/v1/models | jq '.data[].id'
done
```

## LlamaIndex in the VM

In the guest:

```bash
sudo apt install python3-venv
python3 -m venv ~/venv-rag
source ~/venv-rag/bin/activate
pip install 'llama-index-core>=0.12' \
            llama-index-llms-openai-like \
            llama-index-embeddings-openai-like \
            llama-index-readers-file \
            httpx \
            rich
```

`llama-index-readers-file` is what teaches `SimpleDirectoryReader` to
extract text from PDFs, DOCX, and other binary formats. Without it, the
reader silently falls back to reading raw bytes as "text" — you'll embed
`%PDF-1.7\n%...\nstream\nxYMo...`, index will build fine, and every query
will come back with the LLM politely explaining that the context contains
only binary data. It pulls in `pypdf` transitively; swap to `pymupdf` if
you need higher-quality extraction and the AGPL license is acceptable.

`python3-venv` is the Debian/Ubuntu package that provides Python's built-in
`venv` module — it's split out of the base `python3` install on these
distros. `python3 -m venv ~/venv-rag` then creates an isolated Python
environment under `~/venv-rag/` with its own `python` binary and `site-packages`
directory. `source ~/venv-rag/bin/activate` puts that environment's `bin/`
on `PATH`, so the subsequent `pip install` writes the LlamaIndex packages
into the venv instead of system-wide. This matters because modern Ubuntu
refuses system-wide `pip install` (PEP 668), and because you don't want
LlamaIndex's dependency tree tangled with whatever else the guest has
installed.

Save the following as `rag.py`. It loads `./notes/`, embeds and indexes it,
asks a question, and prints the answer:

```python
import logging
import os
import sys
import httpx

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(message)s")
logging.getLogger("httpx").setLevel(logging.INFO)
from llama_index.core import (
    Settings,
    SimpleDirectoryReader,
    StorageContext,
    VectorStoreIndex,
    load_index_from_storage,
)
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.postprocessor.types import BaseNodePostprocessor
from llama_index.core.schema import NodeWithScore
from llama_index.llms.openai_like import OpenAILike
from llama_index.embeddings.openai_like import OpenAILikeEmbedding
from rich.console import Console
from rich.markdown import Markdown

HOST = "http://192.168.122.1"
LLM_URL     = f"{HOST}:8000/v1"
EMBED_URL   = f"{HOST}:8001/v1"
RERANK_URL  = f"{HOST}:8002/v1"
API_KEY = "sk-anything"   # llama-server ignores this but the SDK requires a value
STORE_DIR = "./index_store"

_http = httpx.Client(timeout=600.0)

Settings.llm = OpenAILike(
    model="qwen3.5-4b",
    api_base=LLM_URL,
    api_key=API_KEY,
    context_window=32_768,
    is_chat_model=True,
    max_tokens=2048,
    timeout=600.0,
    max_retries=0,
    http_client=_http,
)

Settings.embed_model = OpenAILikeEmbedding(
    model_name="nomic-embed-text-v1.5",
    api_base=EMBED_URL,
    api_key=API_KEY,
    embed_batch_size=32,
)

# 10% of 1024 = 102
Settings.node_parser = SentenceSplitter(chunk_size=1024, chunk_overlap=102)


class LlamaCppRerank(BaseNodePostprocessor):
    """Call llama-server's /v1/rerank (bge-reranker-v2-m3 in cross-encoder mode)."""
    model: str = "bge-reranker-v2-m3"
    top_n: int = 10

    def _postprocess_nodes(self, nodes, query_bundle=None):
        if not nodes or query_bundle is None:
            return nodes
        r = _http.post(
            f"{RERANK_URL}/rerank",
            json={
                "model": self.model,
                "query": query_bundle.query_str,
                "documents": [n.get_content() for n in nodes],
            },
            timeout=120,
        )
        r.raise_for_status()
        results = r.json()["results"]
        ranked = sorted(results, key=lambda x: -x["relevance_score"])[: self.top_n]
        return [NodeWithScore(node=nodes[r["index"]].node,
                              score=r["relevance_score"]) for r in ranked]


def main(folder: str, question: str) -> None:
    if os.path.isdir(STORE_DIR):
        print(f"loading cached index from {STORE_DIR}")
        index = load_index_from_storage(StorageContext.from_defaults(persist_dir=STORE_DIR))
    else:
        docs = SimpleDirectoryReader(folder, recursive=True).load_data()
        print(f"loaded {len(docs)} documents, indexing...")
        index = VectorStoreIndex.from_documents(docs, show_progress=True)
        index.storage_context.persist(STORE_DIR)
        print(f"index persisted to {STORE_DIR}")

    query_engine = index.as_query_engine(
        similarity_top_k=20,
        node_postprocessors=[LlamaCppRerank(top_n=10)],
        response_mode="compact",
    )
    answer = query_engine.query(question)
    console = Console()
    console.print("\n--- answer ---\n")
    console.print(Markdown(str(answer)))


if __name__ == "__main__":
    folder = sys.argv[1] if len(sys.argv) > 1 else "./notes"
    question = sys.argv[2] if len(sys.argv) > 2 else "Summarize these notes."
    main(folder, question)
```

This is noticeably shorter than the Lemonade version. llama-server returns
proper HTTP error codes, so the "unwrap HTTP-200-with-error-body" hook
that Lemonade needed is gone, and so is the `max_tokens=1024` FastFlowLM
UTF-8 workaround. `model="qwen3.5-4b"` is just a label — llama-server
only has one model loaded and doesn't validate the field, so anything
works there.

A few non-obvious choices in the setup are worth calling out:

- `response_mode="compact"` packs as many reranked chunks as will fit into a
  single LLM prompt. The default (`refine`) makes one LLM call per chunk,
  iteratively rewriting the answer — with 10 chunks that's 10 serial calls
  for no real quality gain when everything already fits in a 32 k context.
- `timeout=600.0, max_retries=0` on the LLM. OpenAI's SDK defaults to a
  60-second HTTP timeout and 2 automatic retries. A single chat completion
  over ~10 k tokens of reranked context can exceed 60 s — you'll see
  `openai._base_client Retrying request to /chat/completions in 0.38 seconds`
  and the server quietly processing the same request twice (or the retry
  queuing behind the in-flight one, doubling latency). Raise the timeout,
  disable retries, let it finish.
- Enabling `httpx` INFO logging is the cheapest way to see what's actually
  happening: one log line per HTTP call, so you can watch
  embeddings → rerank → chat flow across the three ports. For a deeper
  trace (event tree, per-step timings), add `LlamaDebugHandler` to
  `Settings.callback_manager`.

Run it:

```bash
python rag.py ./notes "What did I decide about encrypted boot on ArchLinux?"
```

A thin wrapper so you don't have to remember to activate the venv and pass
the folder every time — save as `ask.sh` next to `rag.py`, `chmod +x`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
source bin/activate
python rag.py ./notes "$@"
```

Then `./ask.sh "What did I decide about encrypted boot on ArchLinux?"`.
`readlink -f` resolves symlinks, so you can drop a symlink to `ask.sh`
on your `$PATH` and still have relative paths (`bin/activate`, `./notes`)
resolve against the venv directory.

First run embeds everything and persists the index to `./index_store/` —
expect a few minutes for a few thousand chunks, GPU will be pegged.
Subsequent runs reload from disk in a fraction of a second and go straight
to the retrieve → rerank → answer loop. The 4060 Mobile runs Qwen3.5 4B at
Q4_K_M at around 62 tokens/second, fast enough to feel interactive. When the source folder changes, `rm -rf ./index_store/` to
force a rebuild — this script doesn't detect edits. Same if you swap the
embedding model: the old vectors live in a different space and silently
produce garbage retrievals, so always clear the store on embedder changes.

## A failure mode: `<think>` runaway on opinion queries

Some queries silently return `Empty Response`. Mine started with "What is
the opinion on Spring?" — consistent empty answer every run, against a
corpus that clearly has plenty to say about Spring. Rephrasing to "How is
Spring mentioned?" against the same index returned a fine answer
immediately. Question-shape-dependent failures like this always mean
there's something worth seeing on the wire.

First, rule out the infrastructure by hitting the LLM directly with no
LlamaIndex in the loop:

```python
from openai import OpenAI
c = OpenAI(base_url="http://192.168.122.1:8000/v1", api_key="x")
r = c.chat.completions.create(
    model="qwen3.5-4b",
    messages=[{"role": "user", "content": "What is the opinion on Spring?"}],
    max_tokens=4096,
)
print(r.choices[0].finish_reason, repr(r.choices[0].message.content))
```

`finish_reason=stop`, full paragraph of answer, every run. So the server,
model, and template are all fine in isolation — whatever is going wrong
is in the RAG path.

Next, log the actual `/chat/completions` traffic during a failing RAG
call. `httpx` event hooks on the client we already pass to `OpenAILike`
are the minimal-invasive way:

```python
import json

def _log_request(request):
    if "/chat/completions" not in str(request.url):
        return
    with open("rag_trace.jsonl", "a") as f:
        f.write(json.dumps({"t": "req", "body": request.content.decode()}) + "\n")

def _log_response(response):
    if "/chat/completions" not in str(response.request.url):
        return
    response.read()
    with open("rag_trace.jsonl", "a") as f:
        f.write(json.dumps({"t": "resp", "body": response.text}) + "\n")

_http = httpx.Client(
    timeout=600.0,
    event_hooks={"request": [_log_request], "response": [_log_response]},
)
```

The failing response: `finish_reason=length`, `content=""`,
`completion_tokens=8192` (the whole cap), and `reasoning_content`
containing ~34 000 characters of the model in a tight self-doubt loop:

```
Wait, "anti-pattern" is in the text. I will use "anti-pattern".
Wait, "evil" is in the text. I will use "evil".
Wait, "parasite" is in the text. I will use "parasite".
...
```

That's the whole bug. Qwen3.5 in thinking mode — which is what `--jinja`
enables via the chat template's `<think>` tags — takes the system
prompt's "answer using only the provided context, never directly
reference it" rule, combines it with strongly opinionated source
material, and enters a verification loop inside `<think>` that never
exits. Every completion token goes to reasoning; nothing after `</think>`
ever gets emitted. LlamaIndex sees `content=""` and prints
`Empty Response`.

Things that do *not* fix it:

- **Raising `max_tokens` further.** The model isn't converging — it
  loops. More budget buys a longer loop, not an answer.
- **Injecting `/no_think` into the query.** Qwen's thinking-suppression
  directive isn't reliably honored when it's embedded mid-message inside
  a QA prompt template; the template scans for it at message boundaries.

Things that do, with tradeoffs:

- **Drop `--jinja` on port 8000.** The model still emits `<think>` tags
  (trained behavior, independent of the input template) and llama-server
  still parses them into `reasoning_content`, but without the
  thinking-aware chat template the reasoning terminates in a bounded
  ~2 000 tokens instead of looping. Bump `max_tokens=4096` to leave room
  for the answer after that.
- **Swap to a non-thinking model** (e.g., `Qwen2.5-7B-Instruct`).
  Biggest change, usually unnecessary.

I kept `--jinja`. On queries that don't trigger the loop — which is
almost all of them — thinking mode produces noticeably better RAG
answers. "What is the opinion on X" is the failure shape; "What does the
author say about X" or "How does the author characterize X" work fine.
Rephrasing is cheaper than giving up answer quality on the 95 % case.

## An alternative: Qwen2.5-3B-Instruct for speed

If the `<think>` runaway is a dealbreaker — or you just want faster
answers — the whole thinking-model tradeoff goes away with a non-thinking
instruct model. `Qwen2.5-3B-Instruct` is a drop-in replacement for the
chat server on port 8000:

```bash
llama-server -hf Qwen/Qwen2.5-3B-Instruct-GGUF:Q4_K_M \
  -ngl 99 -c 32768 --jinja \
  --host 192.168.122.1 --port 8000 &
```

`--jinja` stays on — Qwen2.5 has a proper chat template embedded in the
GGUF and the server produces noticeably worse answers without it — but
this isn't a thinking model, so there's no runaway-loop failure mode
lurking behind the flag. `rag.py` needs no changes; the `model="qwen3.5-4b"`
field is just a label and llama-server ignores it.

On the 4060 Mobile this runs at **~91 tokens/second**, up from ~62 on
Qwen3.5 4B. VRAM is a non-issue at this size: ~1.9 GB weights plus
~1.2 GB KV at full 32 k context, so the LLM + embedder + reranker
together come in around 4.3 GB — comfortable headroom on an 8 GB card.

What you give up is answer shape. Qwen3.5 in thinking mode burns a few
thousand tokens inside `<think>` before emitting prose, and that
reasoning shows up in the output: answers are longer, more structured,
with more cross-referencing between chunks. Qwen2.5-3B-Instruct just
answers — it extracts what the context says and stops. For
retrieval-shaped queries ("what did I decide about X") that's usually
exactly what you want. For queries that ask the model to synthesize
across several chunks it can feel terse.

If the terseness starts to bite, a system prompt on `OpenAILike` is the
cheapest lever — no template surgery, no retrieval changes, just a nudge
on output length:

```python
Settings.llm = OpenAILike(
    ...,
    system_prompt=("Answer thoroughly. When the context supports it, "
                   "give 2–3 paragraphs with specifics from the notes, "
                   "not a one-line summary."),
)
```

Worth trying without it first, though. At 91 tok/s, asking a follow-up is
cheap, and a terse-but-correct answer is usually more useful than one
padded to look thorough.

## Why this split

Three processes instead of one is the correct shape once there's no
Lemonade-style supervisor: each server only has to think about one model,
so batching, context size, and GPU memory are tuned per-workload without
compromise. Restarting the reranker doesn't stall a chat in flight.
Swapping the embedder for a different model is a `kill` and a new
command line, not a config reload.

Putting LlamaIndex in a VM is paranoia, but useful paranoia. Any malicious
document that talks the LLM into doing something silly (or any bug in
LlamaIndex's document loaders) is contained to a throwaway guest with no
access to my home directory. The attack surface exposed to the LLM is
just the three HTTP ports on the bridge.
