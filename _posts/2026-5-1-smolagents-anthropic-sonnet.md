---
layout: post
title: Pointing smolagents at Claude Sonnet
---

[Yesterday's post](../smolagents-local-llamacpp/) ran a smolagents
`CodeAgent` against a local Qwen3.6-35B-A3B served by `llama-server`
over its OpenAI-compatible API. This is the same setup with one piece
swapped out: the model. Instead of `OpenAIServerModel` pointed at
`localhost:8080`, we point at **Claude Sonnet 4.6** via smolagents'
built-in `LiteLLMModel`.

Everything else from yesterday — `CodeAgent`, `WebSearchTool`, the
rootless container, the leopard question, the
"`verbosity_level=2` plus a `LoggingModel` wrapper" debugging pattern —
carries over unchanged. If you haven't read that post, read it first;
this one only covers the diff.

## Why bother (when local works)

Two honest reasons.

- **You don't have a GPU.** A Sonnet 4.6 API key works from a laptop,
  a CI runner, or a $4/month VPS with no accelerator. The local stack
  needs roughly an RTX 4090 or better to make Qwen3.6-35B-A3B feel
  responsive.
- **You want the ceiling of a frontier model.** Sonnet is materially
  stronger at multi-step planning, code synthesis, and recovering from
  a tool result that came back surprising. For a leopard question this
  doesn't matter; for an agent that has to drive a real codebase
  through 8–15 steps, it matters a lot.

The tradeoffs going the other direction — privacy, cost, latency
floor, the ability to iterate without paying per token — are the
reasons yesterday's post exists. Pick per task.

## Getting an Anthropic API key

The whole flow is on the web console at
[platform.claude.com](https://platform.claude.com/) (formerly
`console.anthropic.com`, which still redirects):

1. Sign in with a Google or email account.
2. Add a payment method under **Settings → Billing** and put a small
   amount of credit on it. The API will refuse requests until you do
   — even with the free tier on web Claude, the API itself is
   pay-as-you-go.
3. Go to **Settings → API Keys** and click **Create Key**. Give it a
   name (per-project names help — you can revoke one without
   nuking the others).
4. Copy the key *now*. The console will not show it again.

By convention everything Anthropic-shaped looks for the
`ANTHROPIC_API_KEY` environment variable, including the official
Python SDK and LiteLLM. Don't bake the key into source. The pattern I
use:

```bash
# in ~/.config/anthropic/key (chmod 600), gitignored everywhere
export ANTHROPIC_API_KEY=sk-ant-api03-...

# pulled in by the shell rc
source ~/.config/anthropic/key
```

Then it's available to any program you launch from that shell, and
you'll see in a moment how to forward exactly that variable into the
container without copying its value into a Dockerfile.

A first sanity-check from outside any agent code:

```bash
curl -s https://api.anthropic.com/v1/models \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" | jq '.data[].id'
```

You should see `claude-sonnet-4-6`, `claude-opus-4-7`,
`claude-haiku-4-5-20251001`, and a handful of older snapshots. If you
see `authentication_error`, the key is wrong; if you see
`credit_balance_too_low`, billing is the missing step.

## What `LiteLLMModel` actually is

smolagents itself doesn't ship a dedicated `AnthropicModel` class.
The supported path for Anthropic (and Bedrock, Vertex, Mistral,
Cohere, Groq, and a long tail of other providers) is `LiteLLMModel`,
a thin wrapper around the [LiteLLM](https://docs.litellm.ai/) client
library. LiteLLM takes the OpenAI chat-completions request shape and
translates it to whatever the target provider expects — including
Anthropic's Messages API, which is *not* OpenAI-compatible (system
prompt is a top-level parameter, `max_tokens` is required, response
content is a list of typed blocks, stop sequences are spelled
differently). All of that translation happens inside LiteLLM; you
hand it OpenAI-shaped messages and it does the rest.

The model-id syntax is `provider/model-name`. For Anthropic that's
`anthropic/claude-sonnet-4-6`. The `anthropic/` prefix is what tells
LiteLLM which translation table and which environment variable
(`ANTHROPIC_API_KEY`) to use.

## The agent script

The only change from yesterday's `agent.py` is the model
construction. Everything else — the `LoggingModel` wrapper,
`CodeAgent`, `WebSearchTool`, the leopard prompt — is identical.

```python
from smolagents import CodeAgent, LiteLLMModel, WebSearchTool


class LoggingModel(LiteLLMModel):
    """Same wrapper as yesterday — parent class swapped from
    OpenAIServerModel to LiteLLMModel."""
    # body unchanged from yesterday's post


model = LoggingModel(
    model_id="anthropic/claude-sonnet-4-6",
    max_tokens=4096,
)

agent = CodeAgent(tools=[WebSearchTool()], model=model, verbosity_level=2)
agent.run(
    "How many seconds would it take for a leopard at full speed "
    "to run through Pont des Arts?"
)
```

A few things worth understanding:

- **No `api_base`, no `api_key`.** LiteLLM picks up
  `ANTHROPIC_API_KEY` from the environment and routes to
  `api.anthropic.com` automatically based on the `anthropic/` prefix.
  If you ever need to override the endpoint (e.g. to go through an
  internal proxy or hit Bedrock instead), pass `api_base=...` and a
  region/credential pair appropriate to that provider.
- **`max_tokens=4096` matters.** Anthropic's Messages API requires
  `max_tokens` on every request — OpenAI-style endpoints default it,
  Anthropic doesn't. LiteLLM passes it through. The `OpenAIServerModel`
  call in yesterday's post got away without setting it because
  llama-server defaults to "as much as fits"; here you have to be
  explicit.
- **`reply.raw` still works inside the `LoggingModel` wrapper.**
  LiteLLM normalises the response back into an OpenAI-shaped object,
  which is why the `reply.raw.model_dump()` and
  `choices[0].message.reasoning_content` accesses from yesterday
  keep working without changes. (Anthropic's native response shape
  is different — content blocks, top-level `usage.input_tokens`,
  etc. — but you only see the OpenAI-flavoured projection of it
  through LiteLLM.)
- **`flatten_messages_as_text` is gone from the call site.** The
  default for `LiteLLMModel` is what you want, and there's no
  knob to twiddle for Anthropic specifically.

## Updated Dockerfile

Two lines change from yesterday's: drop `[openai]`, add `[litellm]`.

```dockerfile
FROM python:3.12-slim

RUN pip install --no-cache-dir "smolagents[toolkit,litellm]"

RUN useradd -m -u 1000 agent
WORKDIR /home/agent
COPY --chown=agent:agent agent.py .
USER agent

CMD ["python", "-u", "agent.py"]
```

`smolagents[litellm]` pulls in the `litellm` client library, which is
what `LiteLLMModel` uses under the hood. It does pull in noticeably
more than the OpenAI extra did — LiteLLM bundles tokenizer data and
support code for many providers — so the image grows by a few
hundred megabytes. The rootless `USER agent` switch matters as much
here as it did yesterday: Sonnet writes Python more capably than
Qwen3.6 does, which means it's also more capable of writing Python
that does something surprising. The container is still the sandbox.

## Running it

```bash
docker build -t smol-leopard-anthropic .
docker run --rm -e ANTHROPIC_API_KEY smol-leopard-anthropic
```

Two things changed from yesterday's `docker run`:

- **No `--network host`.** The container has no reason to reach
  `localhost:8080` anymore — there's no llama-server. It only needs
  outbound HTTPS to `api.anthropic.com` and to DuckDuckGo Lite,
  which the default bridge network gives you for free. Dropping
  `--network host` is a small but real security improvement: the
  container no longer shares the host's network namespace.
- **`-e ANTHROPIC_API_KEY`** — with no value — forwards the variable
  from your shell into the container. Don't write `-e
  ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY`; that *also* works but puts
  the key into your shell history and the docker process list. The
  no-value form just inherits.

## What changes in the wire transcript

Two differences worth flagging if you compare the two
`LoggingModel` outputs side by side:

- **No `<think>` block by default.** Qwen3.6 emits a
  `<think>...</think>` scratchpad on every turn, which `--jinja`
  parses out into a separate `reasoning_content` field. Sonnet
  doesn't emit one unless you turn on extended thinking (LiteLLM
  exposes it as `thinking={"type": "enabled", "budget_tokens": ...}`
  passed through as a kwarg). Without it, you only see the final
  content the model decided to commit to.
- **One step instead of two-or-three.** Sonnet 4.6 routinely solves
  the leopard question in a single round trip: one `web_search`
  call for the bridge length and another for leopard speed in the
  same code block (same as Qwen), then arithmetic and
  `final_answer(...)` in the same block. Where Qwen typically split
  this across 3 steps with a 27 s second step, Sonnet folds it into
  1–2 steps and total wall time tends to land around 10–15 seconds.

The actual answer doesn't change: ~9.6 seconds for a leopard at
58 km/h to cross a 155 m bridge. What changes is the *path*.

## Caveats

- **You're sending data to Anthropic.** Yesterday's "the leopard
  question is a toy; the same framework against your own code is
  something you'd rather not have leaving the machine" still applies —
  in the other direction. If you point this agent at sensitive
  documents, those documents go to Anthropic's API (via LiteLLM,
  which is a pure client library and does not phone home, but does
  add itself to the call stack on every request). Read Anthropic's
  data usage policy before pointing it at anything that matters.
- **Cost is per-token, on every step.** A `CodeAgent` run on
  Sonnet that takes 5 model calls with growing context can run to
  tens of thousands of input tokens by the final step (the same
  observation-stuffing tax described in yesterday's post). At
  Sonnet 4.6 prices that's still cents per question, but iterating
  on prompts in a tight loop adds up — keep an eye on the dashboard
  at `platform.claude.com` while you're tuning.
- **LiteLLM's error messages are LiteLLM's, not Anthropic's.** When
  a request fails — bad model id, exceeded context, malformed tool
  schema — the exception you see has been through one round of
  translation. The original `error.type` is usually still in the
  message string, but you may have to peel a layer to find it. If
  that becomes a recurring annoyance, the alternative is to write a
  small `Model` subclass against the official `anthropic` SDK
  directly. It's about 30 lines and removes the indirection — worth
  it if you also want first-class access to Anthropic-specific
  features (prompt caching with `cache_control`, extended thinking,
  beta headers) without going through LiteLLM's translation table.
- **Model IDs drift.** `anthropic/claude-sonnet-4-6` resolves to the
  latest 4.6 snapshot today; pinning to a dated alias (e.g.
  `anthropic/claude-sonnet-4-6-20251015`) is the right move for
  anything you want reproducible. Hit `/v1/models` to see what's
  currently available before you pin.
