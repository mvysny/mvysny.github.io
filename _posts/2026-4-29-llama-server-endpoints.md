---
title: "A tour of llama.cpp's llama-server HTTP endpoints"
date: 2026-04-29
tags: [llama.cpp, llm, http, openai]
---

`llama-server` is the HTTP front-end that ships with [llama.cpp](https://github.com/ggml-org/llama.cpp). One binary gives you a native API, an OpenAI-compatible API, an Ollama-compatible shim, plus a built-in web UI — all backed by the same GGUF model and the same KV cache slots.

For this post I poked at a local instance running build `b8681-Debian` with `unsloth/Qwen3.6-35B-A3B-GGUF` loaded (4 slots, `n_ctx=65536`, vision enabled). Every example below is a real request/response from that server.

## Server introspection

### `GET /health`

Trivial liveness probe. Returns `200 OK` once the model is loaded.

```bash
$ curl -s http://localhost:8080/health
{"status":"ok"}
```

### `GET /props`

Everything the server is willing to tell you about itself: default sampler params, model alias, model path, modalities, the chat template, build info, sleep state. Useful for clients that want to auto-detect chat-template capabilities or enabled features.

```bash
$ curl -s http://localhost:8080/props | jq '{model_alias, total_slots, modalities, build_info, eos_token,
                                              n_ctx: .default_generation_settings.n_ctx}'
{
  "model_alias": "unsloth/Qwen3.6-35B-A3B-GGUF",
  "total_slots": 4,
  "modalities": { "vision": true, "audio": false },
  "build_info": "b8681-Debian",
  "eos_token": "<|im_end|>",
  "n_ctx": 65536
}
```

The full payload also includes `chat_template_caps` (does the template support tools? parallel tool calls? typed content?), which is what well-behaved clients should branch on instead of hard-coding model names.

### `GET /slots`

Each parallel decoding slot the server owns. Handy for capacity planning and for watching what's currently being processed.

```bash
$ curl -s http://localhost:8080/slots | jq '.[] | {id, n_ctx, is_processing, speculative}'
{ "id": 0, "n_ctx": 65536, "is_processing": false, "speculative": false }
{ "id": 1, "n_ctx": 65536, "is_processing": false, "speculative": false }
{ "id": 2, "n_ctx": 65536, "is_processing": false, "speculative": false }
{ "id": 3, "n_ctx": 65536, "is_processing": false, "speculative": false }
```

Slots that are mid-generation also expose the active sampler params and a `next_token` block with `n_remain` and `n_decoded`.

### `GET /metrics`

Prometheus-format metrics — but only when the server was launched with `--metrics`. Otherwise:

```bash
$ curl -s -w '%{http_code}\n' http://localhost:8080/metrics
501
```

### `GET /lora-adapters` / `POST /lora-adapters`

List loaded LoRA adapters and (with POST) change their per-request scale. Empty array on a vanilla server:

```bash
$ curl -s http://localhost:8080/lora-adapters
[]
```

## Native generation API

The native endpoints predate the OpenAI shim. They expose more knobs (DRY, XTC, `top_n_sigma`, mirostat, slot pinning via `id_slot`, custom grammar, …) and return llama.cpp-shaped JSON.

### `POST /completion`

The workhorse. Give it a `prompt` (string or token array), get back generated text plus rich timing/sampler metadata.

```bash
$ curl -s -X POST http://localhost:8080/completion \
    -H 'Content-Type: application/json' \
    -d '{"prompt":"The capital of France is","n_predict":8,"temperature":0,"stream":false}'
```

```json
{
  "index": 0,
  "content": " Paris.\nThe capital of France is",
  "id_slot": 2,
  "stop": true,
  "model": "unsloth/Qwen3.6-35B-A3B-GGUF",
  "tokens_predicted": 8,
  "tokens_evaluated": 5,
  "stop_type": "limit",
  "tokens_cached": 12,
  "timings": {
    "prompt_n": 5,    "prompt_ms": 118.6,  "prompt_per_second": 42.2,
    "predicted_n": 8, "predicted_ms": 319.8, "predicted_per_second": 25.0
  }
}
```

Setting `"stream": true` switches the response to Server-Sent Events with one chunk per token (`data: {...}\n\n`), terminated by a final chunk that has `"stop": true`.

### `POST /tokenize` and `POST /detokenize`

Round-trip text ↔ token IDs against the loaded model's tokenizer.

```bash
$ curl -s -X POST http://localhost:8080/tokenize \
    -H 'Content-Type: application/json' \
    -d '{"content":"Hello, world!"}'
{"tokens":[9419,11,1814,0]}

$ curl -s -X POST http://localhost:8080/detokenize \
    -H 'Content-Type: application/json' \
    -d '{"tokens":[9419,11,1814,0]}'
{"content":"Hello, world!"}
```

`/tokenize` also accepts `"add_special": true` to prepend BOS, and `"with_pieces": true` to get string pieces alongside the IDs.

### `POST /apply-template`

Renders a chat-style messages array through the model's Jinja chat template, without running inference. Great for building proxies that need the exact prompt the model would otherwise see.

```bash
$ curl -s -X POST http://localhost:8080/apply-template \
    -H 'Content-Type: application/json' \
    -d '{"messages":[{"role":"user","content":"Hi"}]}'
{"prompt":"<|im_start|>user\nHi<|im_end|>\n<|im_start|>assistant\n<think>\n"}
```

Note how Qwen3.6 opens a `<think>` block automatically — this server has reasoning support baked into the template.

### `POST /infill`

Fill-in-the-middle for code models. Pass `input_prefix` and `input_suffix`; the server stitches them with the model's FIM tokens before decoding.

```bash
$ curl -s -X POST http://localhost:8080/infill \
    -H 'Content-Type: application/json' \
    -d '{"input_prefix":"def add(a,b):\n    return ",
         "input_suffix":"\n",
         "prompt":"",
         "n_predict":8,
         "temperature":0}'
{"index":0,"content":"a+b","stop":true,"tokens_predicted":3, ...}
```

## OpenAI-compatible API

Drop-in for anything that already speaks the OpenAI REST shape — point your `OPENAI_BASE_URL` at the server and most SDKs Just Work.

### `GET /v1/models`

```bash
$ curl -s http://localhost:8080/v1/models | jq '.data[0] | {id, owned_by, meta}'
{
  "id": "unsloth/Qwen3.6-35B-A3B-GGUF",
  "owned_by": "llamacpp",
  "meta": {
    "vocab_type": 2, "n_vocab": 248320,
    "n_ctx_train": 262144, "n_embd": 2048,
    "n_params": 34660610688, "size": 22123538944
  }
}
```

### `POST /v1/chat/completions`

```bash
$ curl -s -X POST http://localhost:8080/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{"messages":[{"role":"user","content":"Reply with exactly the word: pong"}],
         "max_tokens":4,"temperature":0}'
```

```json
{
  "object": "chat.completion",
  "model": "unsloth/Qwen3.6-35B-A3B-GGUF",
  "choices": [{
    "index": 0,
    "finish_reason": "length",
    "message": {
      "role": "assistant",
      "content": "",
      "reasoning_content": "Here's a thinking"
    }
  }],
  "usage": { "prompt_tokens": 17, "completion_tokens": 4, "total_tokens": 21 },
  "system_fingerprint": "b8681-Debian"
}
```

Two things to notice that aren't strictly OpenAI:
- `reasoning_content` is split out from `content` because the chat template emits a `<think>` block. Set `"reasoning_format": "none"` to keep everything in `content`.
- `system_fingerprint` is the llama.cpp build tag — useful for reproducibility logs.

The endpoint also accepts the OpenAI tool-calling shape (`tools`, `tool_choice`, `tool_calls` in responses), JSON-mode (`response_format: { "type": "json_object" }`), and llama.cpp's grammar extensions (`grammar`, `json_schema`).

### `POST /v1/completions`

Legacy text completion. Same generation engine, different response wrapper.

```bash
$ curl -s -X POST http://localhost:8080/v1/completions \
    -H 'Content-Type: application/json' \
    -d '{"prompt":"2+2=","max_tokens":4,"temperature":0}'
{
  "object": "text_completion",
  "choices": [{ "text": "5\n\n<think>\n", "index": 0, "finish_reason": "length" }],
  "usage": { "prompt_tokens": 4, "completion_tokens": 4, "total_tokens": 8 }
}
```

### `POST /v1/embeddings` and `POST /rerank`

Both exist, but they're gated behind launch flags — and this server didn't get them:

```bash
$ curl -s -X POST http://localhost:8080/v1/embeddings \
    -H 'Content-Type: application/json' -d '{"input":"hello"}'
{"error":{"code":501,
          "message":"This server does not support embeddings. Start it with `--embeddings`",
          "type":"not_supported_error"}}

$ curl -s -X POST http://localhost:8080/reranking \
    -H 'Content-Type: application/json' -d '{"query":"q","documents":["a","b"]}'
{"error":{"code":501,
          "message":"This server does not support reranking. Start it with `--reranking`",
          "type":"not_supported_error"}}
```

Pooling-based models (BGE, E5, etc.) only run as embedders, so embeddings and chat completion are mutually exclusive on a single process. Run a second `llama-server` if you need both.

## Ollama-compatible shim

Just enough surface for clients that hard-code Ollama's API.

### `GET /api/tags`

```bash
$ curl -s http://localhost:8080/api/tags | jq '.models[0] | {name, capabilities, details}'
{
  "name": "unsloth/Qwen3.6-35B-A3B-GGUF",
  "capabilities": ["completion", "multimodal"],
  "details": { "format": "gguf", "family": "", "families": [""] }
}
```

There's also `/api/show` (model details) on builds that include it; this server returned 404, so YMMV by version.

## The web UI

Hitting `GET /` with a browser serves a static **SimpleChat** page — a tiny vanilla-JS client that drives `/v1/chat/completions` and `/v1/completions`. It's perfect for sanity-checking that the model loaded and the chat template renders correctly, without pulling in any external UI.

## Cheat sheet

| Endpoint                         | Method | Purpose                              | Needs flag         |
| -------------------------------- | ------ | ------------------------------------ | ------------------ |
| `/health`                        | GET    | Liveness probe                       | —                  |
| `/props`                         | GET    | Server config + chat template        | —                  |
| `/slots`                         | GET    | Per-slot decode state                | (default on)       |
| `/metrics`                       | GET    | Prometheus metrics                   | `--metrics`        |
| `/lora-adapters`                 | GET/POST | List / re-scale LoRA adapters      | `--lora …`         |
| `/completion`                    | POST   | Native completion (full sampler set) | —                  |
| `/tokenize`, `/detokenize`       | POST   | Tokenizer round-trip                 | —                  |
| `/apply-template`                | POST   | Render chat template, no inference   | —                  |
| `/infill`                        | POST   | Fill-in-the-middle for code          | model-dependent    |
| `/v1/models`                     | GET    | OpenAI model list                    | —                  |
| `/v1/chat/completions`           | POST   | OpenAI chat (tools, JSON mode, grammar) | —               |
| `/v1/completions`                | POST   | OpenAI legacy text completion        | —                  |
| `/v1/embeddings`, `/embedding`   | POST   | Embeddings                           | `--embeddings`     |
| `/rerank`, `/v1/rerank`          | POST   | Reranking                            | `--reranking`      |
| `/api/tags`, `/api/show`         | GET    | Ollama-compatible model listing      | —                  |
| `/`                              | GET    | Built-in SimpleChat web UI           | —                  |

## Closing thoughts

The thing that keeps surprising me about `llama-server` is how much of a complete product it is for a "reference" server. You get OpenAI compatibility for free, an Ollama shim for free, deep introspection (`/props`, `/slots`, timings on every response), and a UI for free — all backed by the same KV cache and parallel decoding slots, in a single static binary. For local development and small-scale serving it's hard to beat, and when you outgrow it, the OpenAI endpoint means most of your client code ports straight to a hosted API without changes.
