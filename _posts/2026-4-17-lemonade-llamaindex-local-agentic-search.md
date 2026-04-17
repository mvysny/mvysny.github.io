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
ExecStart=/snap/bin/lemonade-server serve --host 192.168.122.1 --port 8000
```

The empty `ExecStart=` is mandatory — systemd requires clearing the original
before you can set a new one. Reload and restart:

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
    --mode cross-encoder
```

The `--ubatch-size 4096 --batch-size 4096` on the embedder matters. The
default (512) makes the initial index of a decent-sized folder take many
minutes; 4096 keeps the iGPU saturated and cuts indexing roughly 4-5×.

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
            httpx
```

Save the following as `rag.py`. It loads `./notes/`, embeds and indexes it,
asks a question, and prints the answer:

```python
import sys
import httpx
from llama_index.core import Settings, SimpleDirectoryReader, VectorStoreIndex
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.postprocessor.types import BaseNodePostprocessor
from llama_index.core.schema import NodeWithScore
from llama_index.llms.openai_like import OpenAILike
from llama_index.embeddings.openai_like import OpenAILikeEmbedding

LEMONADE = "http://192.168.122.1:8000/v1"
API_KEY = "sk-lemonade"   # Lemonade ignores this but the SDK requires a value

Settings.llm = OpenAILike(
    model="qwen3.5-4b-FLM",
    api_base=LEMONADE,
    api_key=API_KEY,
    context_window=64_000,
    is_chat_model=True,
    max_tokens=2048,
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
    """Call Lemonade's /v1/rerank (bge-reranker-v2-m3 in cross-encoder mode)."""
    model: str = "bge-reranker-v2-m3-GGUF"
    top_n: int = 10

    def _postprocess_nodes(self, nodes, query_bundle=None):
        if not nodes or query_bundle is None:
            return nodes
        r = httpx.post(
            f"{LEMONADE}/rerank",
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
    docs = SimpleDirectoryReader(folder, recursive=True).load_data()
    print(f"loaded {len(docs)} documents, indexing...")
    index = VectorStoreIndex.from_documents(docs, show_progress=True)

    query_engine = index.as_query_engine(
        similarity_top_k=20,
        node_postprocessors=[LemonadeRerank(top_n=10)],
    )
    answer = query_engine.query(question)
    print("\n--- answer ---\n")
    print(answer)


if __name__ == "__main__":
    folder = sys.argv[1] if len(sys.argv) > 1 else "./notes"
    question = sys.argv[2] if len(sys.argv) > 2 else "Summarize these notes."
    main(folder, question)
```

Run it:

```bash
python rag.py ./notes "What did I decide about encrypted boot on ArchLinux?"
```

First run embeds everything — expect a few minutes for a few thousand chunks,
iGPU will be pegged. Subsequent questions just do the retrieve → rerank →
answer loop, which on the NPU runs at tens of tokens/second for the Qwen3.5
4B model, fast enough to feel interactive.

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
