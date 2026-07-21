---
layout: post
title: Local AI agents with smolagents and llama.cpp
---

I've been using llama.cpp on this box for
[RAG](../local-rag-llamacpp-nvidia-llamaindex/); this post is the same
engine pointed at a different problem — running an actual *agent* that
plans, writes Python, and uses tools, entirely against a local model.
The whole thing runs in a rootless Docker container talking to
`llama-server` over `--network host`, which turns out to collapse a
surprising amount of the safety story that the smolagents docs spend
real effort on.

## The stack

- **`llama-server`** on the host, serving `unsloth/Qwen3.6-35B-A3B-GGUF`
  on port 8080 with the OpenAI-compatible `/v1/chat/completions` API.
  Qwen3.6-35B-A3B is a 35 B mixture-of-experts model with only ~3 B
  active parameters per token, so it runs at ~21 tok/s on a single
  consumer GPU at Q4_K_M while behaving like a much bigger model on
  reasoning-heavy work.
- **smolagents** — Hugging Face's small agent framework. We use
  `CodeAgent`, which has the model write Python in fenced code blocks
  and runs it. This is a step beyond the more common
  *tool-calling* style: instead of asking the model to emit a
  `{"name": "...", "args": ...}` JSON for one call at a time, the model
  writes a short program that may chain several tools, do arithmetic,
  parse an intermediate result, and decide what to call next — all in a
  single completion.
- **A rootless Docker container** for smolagents. The container is the
  sandbox — see the next section.
- **Web search** as the one tool the agent gets — smolagents'
  `WebSearchTool`, which scrapes DuckDuckGo Lite with nothing but
  `requests` and the stdlib HTML parser. No API key, no account, no
  extra dependency.

The classic smolagents demo question:

> *How many seconds would it take for a leopard at full speed to run
> through Pont des Arts?*

The model has to (a) recall or look up a leopard's top speed,
(b) recall or look up the length of Pont des Arts, (c) divide one by
the other with unit conversions. `CodeAgent` lets it do (c) in actual
Python instead of by guessing arithmetic in tokens.

## Why "Docker is the sandbox" matters

The smolagents docs spend a lot of time on `E2BExecutor` and
`DockerExecutor` because the default `LocalPythonExecutor` runs the
model's generated Python *in the agent's own process*. If you run the
agent on your laptop, that Python has access to your home directory,
your SSH keys, and your network. Smolagents mitigates this with an
import allowlist and an AST walker, but the docs are honest: it's
defense-in-depth, not a sandbox.

In our setup the agent process **already** runs inside a container —
no host mounts, no Docker socket, no `--privileged`, no ports forwarded
inward. The worst the agent can do is wreck its own ephemeral
container, which `docker run --rm` puts back on next invocation.
`LocalPythonExecutor` is fine here; you don't need
`E2BExecutor` (which costs money and adds a network round-trip
per code block) or `DockerExecutor` (which would mean
docker-in-docker, with its own pile of caveats). The container *is* the
sandbox.

There are two ways to break that, both of which you should not do:

- Mounting `/var/run/docker.sock` into the container (the agent can now
  start sibling containers as root on the host).
- Running with `--privileged` (the agent owns the host kernel).

As long as you don't do either, the threat model is "agent corrupts
its own container," which is fine.

For belt-and-braces, we also run the Python interpreter inside the
container as a non-root user. That way even *inside* the container the
agent can't, say, `apt install` a backdoor and have it persist for a
sibling process running concurrently.

## Running `llama-server`

I'm assuming llama.cpp is already installed (`apt install llama.cpp` on
recent Ubuntu, or build from source). The model downloads from
HuggingFace on first run and caches under `~/.cache/llama.cpp`.

```bash
llama-server \
  -hf unsloth/Qwen3.6-35B-A3B-GGUF \
  --hf-file Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
  -ngl 99 -c 65536 --jinja
```

A few of the flags are worth calling out:

- `-ngl 99` offloads up to 99 layers to the GPU — i.e., all of them for
  this model. Drop it and the server falls back to CPU and you'll wait
  minutes for what should take seconds.
- `-c 65536` sets the context window to 64 k. Native context is 256 k,
  but each agent step accumulates the full conversation including
  generated code and tool output, and 64 k is a comfortable working
  size that fits in VRAM.
- `--jinja` enables the chat template embedded in the GGUF. For
  `CodeAgent` this matters because Qwen3.6 is a *thinking* model: it
  emits `<think>...</think>` blocks before the answer. With `--jinja`,
  the server parses those out into a separate `reasoning_content`
  field, so the `content` we read in code is just the final answer
  (and the fenced Python block we want). Without `--jinja` the server
  uses a generic template, the `<think>` block ends up inline in
  `content`, and smolagents' code-block parser can get confused.

`--jinja` also enables proper OpenAI-format tool calls (Qwen3.6's
underlying tool-call format is XML-flavoured, and `--jinja` is what
translates between that and the JSON shape on the wire). We don't need
this for `CodeAgent` specifically, but it's the right default if you
later swap to `ToolCallingAgent`.

Sanity-check it's up:

```bash
curl -s http://localhost:8080/v1/models | jq '.data[].id'
```

You should see `unsloth/Qwen3.6-35B-A3B-GGUF`.

## The Dockerfile (rootless)

```dockerfile
FROM python:3.12-slim

RUN pip install --no-cache-dir "smolagents[toolkit,openai]"

RUN useradd -m -u 1000 agent
WORKDIR /home/agent
COPY --chown=agent:agent agent.py .
USER agent

CMD ["python", "-u", "agent.py"]
```

What each piece is doing:

- `smolagents[toolkit,openai]` — `[toolkit]` is the standard set of
  built-in tools (search, web visit, Python REPL helpers); `[openai]`
  pulls in the `openai` Python client, which is what `OpenAIServerModel`
  uses under the hood to talk to llama-server's OpenAI-compatible API.
  Notably no `ddgs` here: `WebSearchTool` (the recommended search tool
  in current smolagents) only needs `requests`, which `[toolkit]`
  already pulls in. If you'd rather use `DuckDuckGoSearchTool` — a
  thinner wrapper that calls the upstream `ddgs` library and gives you
  built-in rate limiting and a `max_results` knob — add `ddgs` here
  (older guides call it `duckduckgo-search`; it was renamed).
- `useradd -m -u 1000 agent` creates a regular user with home directory
  and explicit UID. We do this *after* `pip install` so the install
  goes into the system site-packages as root, then we drop privileges
  for everything that follows.
- `COPY --chown=agent:agent` makes sure the script lands owned by the
  unprivileged user, not root.
- `USER agent` is the rootless switch. Everything from here — including
  the `CMD`, including the Python that smolagents will execute on the
  model's behalf — runs as UID 1000, with no `sudo`, no write access to
  `/usr` or `/etc`, and no ability to do anything privileged inside the
  container even if the model decides to.
- `python -u` keeps stdout unbuffered so the conversation streams as it
  happens instead of arriving in a wall at the end.

## The agent: `agent.py`

This is the whole script. It does three things: configures
`OpenAIServerModel` to point at our llama-server, wraps it in a small
subclass that prints every request and response, and runs the leopard
question through a `CodeAgent` armed with `WebSearchTool`.

```python
from smolagents import CodeAgent, OpenAIServerModel, WebSearchTool


class LoggingModel(OpenAIServerModel):
    """Print every request and response so we can see what
    smolagents and the model actually say to each other."""

    def generate(self, messages, **kwargs):
        print("\n" + "=" * 78)
        print("REQUEST  ->  llama-server")
        print("=" * 78)
        for m in messages:
            role = getattr(m, "role", None) or m.get("role", "?")
            content = getattr(m, "content", None) or m.get("content", "")
            if isinstance(content, list):
                content = "\n".join(
                    c.get("text", "") if isinstance(c, dict) else str(c)
                    for c in content
                )
            print(f"\n[{role}]\n{content}")

        reply = super().generate(messages, **kwargs)

        print("\n" + "-" * 78)
        print("RESPONSE <-  llama-server")
        print("-" * 78)
        if getattr(reply, "raw", None):
            raw = (
                reply.raw.model_dump()
                if hasattr(reply.raw, "model_dump")
                else reply.raw
            )
            reasoning = (
                raw.get("choices", [{}])[0]
                .get("message", {})
                .get("reasoning_content")
            )
            if reasoning:
                print(f"\n[<think>]\n{reasoning}\n[</think>]")
        print(f"\n[assistant]\n{reply.content}")
        return reply


model = LoggingModel(
    model_id="unsloth/Qwen3.6-35B-A3B-GGUF",
    api_base="http://localhost:8080/v1",
    api_key="not-needed",            # llama-server ignores it but the SDK requires a value
    flatten_messages_as_text=False,
)

agent = CodeAgent(
    tools=[WebSearchTool()],
    model=model,
    verbosity_level=2,                # smolagents' own step/tool/observation log
)

agent.run(
    "How many seconds would it take for a leopard at full speed "
    "to run through Pont des Arts?"
)
```

A few things worth understanding about this script:

- `WebSearchTool` is the search tool the smolagents README points at
  in its quickstart. Despite the generic name it defaults to
  DuckDuckGo: it scrapes the lightweight HTML at
  `lite.duckduckgo.com/lite/` with a hand-rolled `HTMLParser` and no
  third-party client, which is why our Dockerfile didn't need `ddgs`.
  Pass `engine="bing"` to switch to Bing's RSS endpoint instead. The
  separate `DuckDuckGoSearchTool` is a thinner wrapper around the
  upstream `ddgs` Python client (formerly `duckduckgo-search`); it
  exposes `max_results` and a `rate_limit` knob, but adds a
  dependency. Either is a drop-in replacement for the other in the
  `tools=[...]` list.
- We're combining **two** levels of logging on purpose.
  `verbosity_level=2` is smolagents' own log: it prints each step
  number, the code block the model wrote, the result of executing it,
  and the next observation. It's the *agent's* view of the world.
  `LoggingModel` prints what's actually going on the wire to llama —
  the full system prompt, the running message history, the raw
  completion, and the `<think>` block. Reading both side by side is
  how you build an intuition for what an agent framework actually
  *is*: a pile of carefully constructed system prompts plus a loop.
- `OpenAIServerModel.generate()` is the method smolagents calls per
  step. In older releases (before ~1.10) the method was `__call__`; if
  you're on an older pin, override `__call__` instead. `pip show
  smolagents` will tell you which you have.
- `flatten_messages_as_text=False` is the default for
  `OpenAIServerModel` but worth being explicit — it preserves the
  list-of-`{role, content}` structure that the chat completions API
  expects, instead of collapsing the whole conversation into one
  string.
- `api_key="not-needed"`. llama-server accepts any value (or none) but
  the OpenAI SDK refuses to send a request without *some* key set, so
  you have to pass a non-empty string.
- `reply.raw` is the raw OpenAI response object; we reach into it to
  pull out `reasoning_content`, which is where llama-server (with
  `--jinja`) puts everything between `<think>` and `</think>`.
  `reply.content` is just the post-think answer — that's what
  `CodeAgent` parses to find the Python code block, so it's also what
  you want printed as "the assistant's actual response."

## Networking: `--network host` on Linux

```bash
docker build -t smol-leopard .
docker run --rm --network host smol-leopard
```

`--network host` is the no-friction option on Linux: the container
shares the host network namespace, so `localhost:8080` inside the
container *is* `localhost:8080` on the host, and `llama-server` is
reachable with no port forwarding and no DNS gymnastics. It's also the
safest option for our setup, because the container has no listening
ports of its own — all traffic is outbound to llama and to
DuckDuckGo.

This is Linux-only. On Mac and Windows, `docker run --network host` is
either ignored or differently behaved depending on the Docker Desktop
version. There you'd swap to:

```bash
docker run --rm --add-host=host.docker.internal:host-gateway smol-leopard
```

…and change the `api_base` in `agent.py` to
`http://host.docker.internal:8080/v1`. Mentioning it for completeness;
this post assumes Ubuntu.

## What you actually see when you run it

Roughly, in order:

1. **smolagents' system prompt**, printed by `LoggingModel`. It's
   enormous — several kilobytes — and explains to the model that it is
   a code agent, what tools it has (each rendered as a Python function
   signature), how to write its answer as a `<code>...</code>` block
   ending in `final_answer(...)`, and what observations look like.
   Reading this once is the single most clarifying thing you can do for
   understanding why agent frameworks behave the way they do. One
   detail worth noting: rule 9 of the prompt is a hard whitelist of
   stdlib modules the model is allowed to import — `collections,
   datetime, itertools, math, queue, random, re, stat, statistics,
   time, unicodedata`. `LocalPythonExecutor` enforces it before
   running the code, so an `import os` in the model's output fails
   fast.
2. **The user message** — your literal prompt.
3. **The model's `<think>` block** — Qwen3.6 reasoning about leopard
   speed and bridge length, deciding whether to search or guess, and
   sketching the calculation. This is *not* the answer; it's the
   model's scratchpad, separated out by `--jinja`.
4. **The model's content** — a `<code>...</code>` block calling
   `web_search("leopard top speed")` (or similar) and printing the
   result.
5. **smolagents executes that code locally**, captures stdout, and the
   loop goes around: the next request to llama includes the previous
   assistant turn *plus* a new user-role observation containing the
   tool output.
6. After one or two more rounds — usually search for the bridge length,
   then a final calculation — the model writes
   `final_answer(<seconds>)` and `CodeAgent` returns.

### A concrete run

One actual execution against Qwen3.6-35B-A3B at Q4_K_M:

- **3 steps, 46 seconds wall time.** No retries, no malformed code.
- **Step 1** — 10.4 s, 2.2 k input / 186 output tokens. The model issues
  *both* `web_search` calls in a single code block — bridge length and
  leopard speed in parallel, in one round trip. This is the
  `CodeAgent` win in miniature: a `ToolCallingAgent` would have
  serialised the two searches into two separate model turns.
- **Step 2** — 27.4 s, 6.7 k input / 614 output tokens. Input grew 3×
  because the previous step's full search observation (raw markdown of
  every result) is now stuffed back into the conversation. This is the
  context-bloat tax on agent loops, in microcosm: every additional
  step multiplies what the model has to re-read.
- **Step 3** — `final_answer(...)`. Done.

The model picked **58 km/h** as the leopard's top speed by reading the
seven sources `web_search` returned, noticing 58 km/h showed up in
four of them, and committing to it explicitly in its `<think>` block
before doing the arithmetic. That kind of "chew on noisy tool output
and decide" is exactly what `CodeAgent` is good at — and the kind of
thing that's painful to do as a chain of `ToolCallingAgent` JSON
calls.

The answer itself is **"about 9.6 seconds"** — a leopard at 58 km/h
crossing a 155 m bridge — but the interesting part, again, is watching
it get there.

### A trimmed wire transcript

The above in slow motion. Each step has three pieces — the model's
hidden `<think>`, the model's visible `content` (a `<code>` block),
and the observation smolagents feeds back after running the code.

**Step 1, `<think>` (`reasoning_content`, hidden from `CodeAgent`'s
parser thanks to `--jinja`):**

> The user wants to know how long it would take a leopard at full
> speed to run through the Pont des Arts. To calculate this, I need
> two pieces of information:
>
> 1. The length of the Pont des Arts.
> 2. The top speed of a leopard.
>
> I will start by searching for the length of the Pont des Arts and
> the speed of a leopard.

**Step 1, `content` (the executable code):**

```
Thought: I need to find the length of the Pont des Arts and the top speed of a leopard to calculate the time. I will use web search to find these two facts.
<code>
pont_des_arts_length = web_search(query="Pont des Arts length meters")
leopard_speed = web_search(query="leopard top speed km/h")
print(f"Pont des Arts length: {pont_des_arts_length}")
print(f"Leopard speed: {leopard_speed}")
</code>
```

This is the moment the `CodeAgent`-vs-`ToolCallingAgent` distinction
gets concrete. A `ToolCallingAgent` would have the model emit
something like:

```json
{"tool_calls": [
  {"function": {"name": "web_search", "arguments": {"query": "Pont des Arts length meters"}}},
  {"function": {"name": "web_search", "arguments": {"query": "leopard top speed km/h"}}}
]}
```

…and the framework dispatches them. `CodeAgent` instead has the model
emit *Python that calls them as functions*, which is strictly more
expressive: you can post-process, branch, loop, do arithmetic between
calls, or build the next query from the result of the previous one —
all in a single completion.

**Step 1, observation (stdout from running the above; trimmed):**

```
Pont des Arts length: ## Search Results

[Pont des Arts - Wikipedia](https://en.wikipedia.org/wiki/Pont_des_Arts)
The Pont des Arts ... is a pedestrian bridge in Paris which crosses the River Seine...

[Pont des Arts, Paris, France - LatLong](https://www.latlong.net/place/pont-des-arts-paris-france-32945.html)
... It has a length of 155 m (509 ft) and a width of 11 m (36 ft)...

[... 8 more hits ...]

Leopard speed: ## Search Results

[How Fast Can a Leopard Run?](https://africafreak.com/how-fast-can-a-leopard-run)
African leopards have a top speed of 56 - 60 km/h (35 - 37 mph)...

[How Fast Is A Leopard?](https://untamedanimals.com/how-fast-is-a-leopard/)
... Their top speed is 36 mph or 58 km/h ...

[... 5 more hits ...]
```

The unabridged version is roughly 4 kB of markdown — that's the
chunk that re-enters the prompt at step 2 and triples the input-token
count.

**Step 2, `<think>` — the model reading noisy multi-source output and
picking a number:**

> From the search results:
>
> 1. **Pont des Arts length**: Multiple sources state the length is **155 meters**.
> 2. **Leopard top speed**:
>    * Source 1: "56 - 60 km/h"
>    * Source 2: "36 mph or 58 km/h"
>    * Source 3: "almost 37 miles per hour (58 km/h)"
>    * Source 4: "roughly 58 kilometers per hour"
>    * Source 5: "36 miles per hour"
>    * Source 6: "40 MPH"
>    * Source 7: "56 - 60 km/h"
>
> The most consistent value for a leopard's top speed seems to be
> around **58 km/h** (approx 36 mph). I will use 58 km/h for the
> calculation.

**Step 2, `content` — pure arithmetic, no tools:**

```
<code>
distance_meters = 155
speed_kmh = 58
speed_mps = speed_kmh * 1000 / 3600
time_seconds = distance_meters / speed_mps
print(f"Distance: {distance_meters} m")
print(f"Speed: {speed_kmh} km/h")
print(f"Time: {time_seconds} seconds")
</code>
```

**Step 2, observation:**

```
Distance: 155 m
Speed: 58 km/h
Time: 9.620689655172415 seconds
```

This is the other `CodeAgent` advantage worth seeing in the flesh:
the unit conversion and division get offloaded to a real Python
interpreter instead of being guessed in tokens. `155 / (58 * 1000 /
3600)` is something LLMs get wrong surprisingly often when asked to
compute it inline; a `ToolCallingAgent` with no code execution would
need to either expose a `calculate` tool or trust the model's mental
math.

**Step 3, `content` — done:**

```
<code>
final_answer("It would take approximately 9.62 seconds for a leopard at full speed (58 km/h) to run through the 155 meters of the Pont des Arts.")
</code>
```

`CodeAgent` recognises `final_answer(...)`, breaks the loop, and
returns the value to the caller.

## Why bother

Two reasons.

First, **pedagogy**. Reading the system prompt smolagents constructs,
and watching the model's reasoning, makes "agent" feel a lot less
magical. It's a chat completion in a loop, with a careful prompt and a
small Python sandbox. Once you've seen the wire traffic for a real run,
you can debug your own agent code without superstition — when the
model does something dumb, you can usually point at the exact line of
the system prompt that confused it.

Second, **latency, cost, and privacy**. A `CodeAgent` run can easily
make 5–10 model calls. Hitting a hosted frontier model that many times
per question gets expensive fast, especially if you're iterating on the
agent's prompts. Local Qwen3.6-35B-A3B is good enough at this class of
task that the iteration loop becomes free. And the leopard question is
a toy; the same framework run against your own documents, your own
code, or your own logs is something you'd rather not have leaving the
machine.

## Caveats

- **`CodeAgent` quality scales with the model.** Qwen3.6-35B-A3B is
  comfortably above the bar for this demo. Smaller models (anything
  under ~7 B active parameters in my experience) struggle to reliably
  produce well-formed code blocks ending in `final_answer(...)` and
  will burn steps on syntax errors.
- **Rootless inside the container is belt-and-braces, not the primary
  defence.** The primary defence is that the container has nothing
  worth attacking — no host mounts, no docker socket, no privileged
  flag, no inbound ports. `USER agent` is there so a single bad
  `apt`-installable trick can't compromise the container's own
  toolchain mid-run.
- **DuckDuckGo rate-limits.** If you run this in a tight loop you'll
  start seeing empty search results. For real work, swap to a paid
  search API (`GoogleSearchTool` with SerpAPI) or run an offline
  retrieval tool against your own documents.
- **`--jinja` is doing more work than it looks.** If you ever swap
  models, double-check that the new GGUF has a chat template that
  actually emits `<think>` correctly. A model trained for thinking
  with a broken template will dump its scratchpad into `content`, and
  `CodeAgent` will try to execute the scratchpad as Python.
