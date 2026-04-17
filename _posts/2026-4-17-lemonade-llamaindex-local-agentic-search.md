---
layout: post
title: Local Agentic Search with Lemonade and LlamaIndex
---

I want agentic search over my own documents, without anything leaving the
machine. This is how I wired it up on an AMD Ryzen AI 9 HX 370 laptop (Framework 13,
Ubuntu 26.04): Lemonade on the metal driving the NPU and the iGPU, and
LlamaIndex inside a libvirt VM talking to it over the default `virbr0` bridge.

## The setup

Two machines, one physical:

- **Host**: Ubuntu 26.04 on the Ryzen AI 9 HX 370. Runs **Lemonade** (installed
  via snap), which serves an OpenAI-compatible HTTP API on
  `192.168.122.1:8000`. Lemonade hosts three models, each pinned to the right
  backend:
  - `qwen3.5-4b-FLM` — the chat LLM, running on the XDNA NPU via **FastFlowLM**,
    64k context.
  - `nomic-embed-text-v1-GGUF` — the embedder, running on the iGPU via Vulkan
    llama.cpp, 8192 token context.
  - `bge-reranker-v2-m3-GGUF` — the cross-encoder reranker, Vulkan, 2048
    context.
- **VM**: a libvirt guest on `192.168.122.0/24` running the **LlamaIndex**
  Python script. It sees Lemonade as a remote OpenAI endpoint at
  `http://192.168.122.1:8000/v1` and has no idea (or need to know) that the
  other side is a stitched-together mess of NPU and GPU runtimes.

## What each piece does

**Lemonade** is AMD's local LLM server. It loads models, routes them to the
right accelerator (NPU through FastFlowLM, GPU through Vulkan llama.cpp),
and exposes an OpenAI-compatible REST API: `/v1/chat/completions`,
`/v1/embeddings`, `/v1/rerank`. From the client side it looks like any other
OpenAI-ish endpoint.

**FastFlowLM** is the runtime that actually executes transformer inference
on AMD's XDNA NPU. It's what makes `qwen3.5-4b-FLM` fast and cold on the NPU
instead of hot and slow on the CPU. Lemonade shells out to it.

**Vulkan llama.cpp** is how the embedder and reranker get onto the iGPU.
Vulkan is the only GPU backend that works reliably on Ryzen AI iGPUs without
ROCm drama; llama.cpp compiled with `-DGGML_VULKAN=1` is fast enough that
neither the embedder nor the reranker becomes a bottleneck.

**LlamaIndex** is the orchestration library. It reads the folder of
documents, chunks them, embeds the chunks, stores them in an in-memory
vector index, and runs the retrieval → rerank → answer pipeline:

1. Split docs into 1024-token chunks with ~10% overlap (102 tokens).
2. Embed each chunk using Lemonade's embedding endpoint.
3. For each query: retrieve the top 20 chunks by cosine similarity.
4. Rerank those 20 with the cross-encoder down to the top 10.
5. Stuff the top 10 into the LLM's context and ask for an answer.

The **cross-encoder reranker** is what makes this actually good. A bi-encoder
embedder gives you recall; a cross-encoder that sees `(query, doc)` together
gives you precision. Going `20 → 10` with BGE v2-m3 is cheap on Vulkan and
makes answers dramatically less hallucinatory.

## Installing and configuring Lemonade

Install from snap:

```bash
sudo snap install lemonade-server
```

By default Lemonade binds to `127.0.0.1:8000`. That's useless for the VM —
we need it on `192.168.122.1` so the guest can reach it.

### Snap config doesn't work, use systemd

The obvious move is `snap set lemonade-server host=192.168.122.1`. On my box
this had no effect — the daemon kept binding to localhost regardless of what
`snap get lemonade-server` reported. I didn't dig into why; the clean
workaround is a systemd drop-in.

Find the service name:

```bash
systemctl list-units --type=service | grep lemonade
```

For me it was `snap.lemonade-server.daemon.service`. Edit it:

```bash
sudo systemctl edit snap.lemonade-server.daemon.service
```

Add:

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/snap run lemonade-server.daemon --host 192.168.122.1 --port 8000
LimitMEMLOCK=infinity
```

The empty `ExecStart=` is mandatory — systemd requires clearing the original
before you can set a new one.
`LimitMEMLOCK=infinity` is important so that the NPU has access to all available RAM.

Reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart snap.lemonade-server.daemon.service
ss -tlnp | grep 8000   # verify it's listening on .122.1
```

### Pull the models and pin the backends

```bash
# LLM on NPU via FastFlowLM
lemonade-server pull qwen3.5-4b-FLM --backend flm --context 65536

# Embedder on Vulkan — generous batch sizes so indexing is fast
lemonade-server pull nomic-embed-text-v1-GGUF \
    --backend vulkan \
    --context 8192 \
    --llamacpp-args "--ubatch-size 4096 --batch-size 4096"

# Reranker on Vulkan, cross-encoder mode
lemonade-server pull bge-reranker-v2-m3-GGUF \
    --backend vulkan \
    --context 2048 \
    --mode cross-encoder \
    --llamacpp-args "--ubatch-size 2048 --batch-size 2048"
```

The `--ubatch-size 4096 --batch-size 4096` on the embedder matters. The
default (512) makes the initial index of a decent-sized folder take many
minutes; 4096 keeps the iGPU saturated and cuts indexing roughly 4-5×.

The matching flags on the reranker matter even more: a single (query, doc)
pair for BGE-reranker-v2-m3 tokenizes to a few hundred tokens and can
exceed the 512 default, at which point the backend refuses the request
with `input (N tokens) is too large to process. increase the physical
batch size`. Setting ubatch-size to the full context avoids this.

Sanity-check that all three are loaded:

```bash
curl -s http://192.168.122.1:8000/v1/models | jq '.data[].id'
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

LEMONADE = "http://192.168.122.1:8000/v1"
API_KEY = "sk-lemonade"   # Lemonade ignores this but the SDK requires a value
STORE_DIR = "./index_store"

Settings.llm = OpenAILike(
    model="qwen3.5-4b-FLM",
    api_base=LEMONADE,
    api_key=API_KEY,
    context_window=65_536,
    is_chat_model=True,
    max_tokens=2048,
    timeout=600.0,
    max_retries=0,
)

Settings.embed_model = OpenAILikeEmbedding(
    model_name="nomic-embed-text-v1-GGUF",
    api_base=LEMONADE,
    api_key=API_KEY,
    embed_batch_size=32,
)

# 10% of 1024 = 102
Settings.node_parser = SentenceSplitter(chunk_size=1024, chunk_overlap=102)


class LemonadeRerank(BaseNodePostprocessor):
    """Call Lemonade's /v1/reranking (bge-reranker-v2-m3 in cross-encoder mode)."""
    model: str = "bge-reranker-v2-m3-GGUF"
    top_n: int = 10

    def _postprocess_nodes(self, nodes, query_bundle=None):
        if not nodes or query_bundle is None:
            return nodes
        r = httpx.post(
            f"{LEMONADE}/reranking",
            json={
                "model": self.model,
                "query": query_bundle.query_str,
                "documents": [n.get_content() for n in nodes],
            },
            timeout=120,
        )
        r.raise_for_status()
        body = r.json()
        # Lemonade wraps some backend errors as 200 + {"error": ...} bodies,
        # so raise_for_status() isn't enough — check the shape explicitly.
        if "results" not in body:
            raise RuntimeError(f"rerank response missing 'results': {body}")
        results = body["results"]
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
        node_postprocessors=[LemonadeRerank(top_n=10)],
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

A few non-obvious choices in the setup are worth calling out:

- `response_mode="compact"` packs as many reranked chunks as will fit into a
  single LLM prompt. The default (`refine`) makes one LLM call per chunk,
  iteratively rewriting the answer — with 10 chunks that's 10 serial calls
  at tens of seconds each on the NPU, for no real quality gain when
  everything already fits in a 64k context.
- `timeout=600.0, max_retries=0` on the LLM. OpenAI's SDK defaults to a
  60-second HTTP timeout and 2 automatic retries. On the NPU, a single
  chat completion over ~10k tokens of reranked context can easily exceed
  60s — you'll see `openai._base_client Retrying request to
  /chat/completions in 0.38 seconds` and the server quietly processing the
  same request twice (or the retry queues behind the in-flight one,
  doubling latency). Raise the timeout, disable retries, let it finish.
- Enabling `httpx` INFO logging is the cheapest way to see what's actually
  happening: one log line per HTTP call to Lemonade, so you can watch
  embeddings → rerank → chat flow by. For a deeper trace (event tree,
  per-step timings), add `LlamaDebugHandler` to `Settings.callback_manager`.

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
expect a few minutes for a few thousand chunks, iGPU will be pegged.
Subsequent runs reload from disk in a fraction of a second and go straight
to the retrieve → rerank → answer loop, which on the NPU runs at tens of
tokens/second for the Qwen3.5 4B model, fast enough to feel interactive.
When the source folder changes, `rm -rf ./index_store/` to force a rebuild
— this script doesn't detect edits. Same if you swap the embedding model:
the old vectors live in a different space and silently produce garbage
retrievals, so always clear the store on embedder changes.

## Why this split

The NPU is the right place for the chat LLM: low power, designed for
transformer inference, stays quiet. The iGPU is the right place for
embeddings and reranking: those are bursty, compute-bound, batch-friendly,
and don't need to run continuously. CPU does nothing interesting here,
which is the whole point — it stays free for the rest of the desktop.

Putting LlamaIndex in a VM is paranoia, but useful paranoia. Any malicious
document that talks the LLM into doing something silly (or any bug in
LlamaIndex's document loaders) is contained to a throwaway guest with no
access to my home directory. The attack surface exposed to the LLM is
just the HTTP API on the bridge.
