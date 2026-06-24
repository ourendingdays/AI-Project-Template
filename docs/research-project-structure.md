# Project Structure — Research Project

This is the reference document for a Python project organized as a **library or research codebase** rather than a deployed application. No backend, no frontend, no HTTP server — just Python code organized by capability, runnable as scripts or importable as modules.

---

## Overview: Research Project

This pattern is for projects where the deliverable is **the code itself**: a Python library, a research/experiment codebase, a model-training pipeline, a CLI tool. Things you `import`, run as scripts, or pull into a notebook — not things you deploy as a long-running service behind nginx.

> Throughout this document, `app` is used as the package name. Replace it with your project's real name (e.g., `assistant`, `ragkit`, `wordcraft`). It must be a valid Python identifier — lowercase, no hyphens.

### Why this pattern

The reasoning is: *"I'm building a focused Python project — a model, a pipeline, a tool — that doesn't need to be served over HTTP. I want code organized by capability, easy to navigate, easy to import."*

This is the shape used by countless ML/AI research codebases (Hugging Face's `transformers/examples`, OpenAI's evals, fast.ai's nbdev projects), library projects (LangChain modules, instructor, etc.), and most "I'm building a thing I'll run locally or import elsewhere" projects.

For a focused Python project, this pattern gives you:

- **One namespace** — every import starts with `from app.<something>`.
- **Capability-based organization** — folders named for what they *do* (`rag/`, `inference/`, `processing/`), not for what *role* they play in a service architecture (`api/`, `services/`, etc.).
- **No deployment bloat** — no `backend/`, no `frontend/`, no nginx assumptions.
- **Easy to grow into a library** — already structured to be `pip install`-able if needed.

> **Choosing between this and the service patterns:**
> - If you'll deploy this as an HTTP API → use single-service or multi-service patterns.
> - If users will `pip install` it, or you'll run it as scripts/notebooks → use this pattern.
> - If you start here and later decide to add an API on top → wrap the code in a thin `api/` module that imports from `app.<whatever>`. Don't restructure everything.

---

## Directory Tree

```
your-project/
├── README.md
├── .gitignore
├── .env.example                 # template for env vars; never commit .env itself
├── docker-compose.yml           # for local dev only — not production deployment
├── Dockerfile                   # for local dev / reproducibility
├── requirements.txt             # all Python dependencies
│
├── app/                         # main package — rename to your project name
│   ├── __init__.py
│   ├── core/                    # LLM abstractions, base classes, model factory
│   │   ├── __init__.py
│   │   ├── base_llm.py
│   │   ├── model_factory.py
│   │   └── clients/             # provider-specific clients
│   │       ├── __init__.py
│   │       ├── anthropic.py
│   │       └── openai.py
│   ├── prompts/                 # prompt templates and chains
│   │   ├── __init__.py
│   │   ├── templates.py
│   │   └── chain.py
│   ├── rag/                     # retrieval-augmented generation
│   │   ├── __init__.py
│   │   ├── embedder.py
│   │   ├── retriever.py
│   │   ├── vector_store.py
│   │   └── indexer.py
│   ├── processing/              # data preparation
│   │   ├── __init__.py
│   │   ├── chunking.py
│   │   ├── tokenizer.py
│   │   └── preprocessor.py
│   ├── inference/               # model execution
│   │   ├── __init__.py
│   │   ├── engine.py
│   │   └── response_parser.py
│   ├── training/                # train/fine-tune scripts (only if applicable)
│   │   ├── __init__.py
│   │   └── train.py
│   ├── evaluation/              # eval scripts and metrics
│   │   ├── __init__.py
│   │   ├── metrics.py
│   │   └── benchmarks.py
│   └── config/                  # app-level Pydantic settings
│       ├── __init__.py
│       └── settings.py
│
├── experiments/                 # YAML configs for experiment runs
│   └── exp_001.yaml
│
├── notebooks/                   # exploration only — not source of truth
│   └── 01-explore-embeddings.ipynb
│
├── data/                        # gitignored except README + .gitkeep files
│   ├── raw/                     # immutable original data
│   ├── interim/                 # intermediate processing artifacts
│   ├── processed/               # final data fed into models
│   ├── cache/                   # cached computations
│   ├── embeddings/              # generated vector embeddings
│   └── vectordb/                # vector database files
│
├── models/                      # trained model artifacts (gitignored)
│   └── README.md
│
├── tests/
│   ├── __init__.py
│   ├── unit/                    # function-level tests
│   │   ├── test_chunking.py
│   │   └── test_prompts.py
│   └── integration/             # end-to-end tests, real API calls
│       ├── test_rag_pipeline.py
│       └── test_inference.py
│
├── scripts/                     # CLI entry points for common tasks
│   ├── setup_env.sh
│   ├── build_embeddings.py
│   └── run_eval.py
│
└── docs/
    ├── project-structure.md     # this file
    └── architecture.md
```

---

## Why this shape

This section covers the major structural decisions. Differences from the service-oriented patterns are flagged explicitly.

### Why `experiments/` is separate from `app/config/`

Same distinction as in the service patterns:

- **`experiments/<name>.yaml`** — describes a *training/evaluation run*. Hyperparameters, dataset version, model size. Checked in, versioned, reproducible.
- **`app/config/settings.py`** — describes the *running app*. API keys, log levels, paths. Loaded from environment variables (via `.env`), never committed.

The screenshot version had a single `config/` folder mixing both. Don't do that.

### Why `notebooks/` is at the root, not inside `app/`

Different from the service patterns. Here's why:

- In the **service pattern**, notebooks live inside `ml/<service>/notebooks/` because notebooks are part of the *training/research subsystem*, separate from the running service. The split makes it obvious.
- In the **library pattern**, there's no separate service to contrast notebooks with — the whole project is research/exploration. Notebooks deserve top-level visibility because they're part of how you actually work with the project day-to-day.

Same rule applies: **notebooks are exploration only.** When code stabilizes, move it into `app/<something>/`. The notebook becomes a record, not the source of truth.

### Why `models/` and `data/` are top-level, not inside `app/`

Same reason as in the service patterns:

- **`data/`** = inputs (datasets, raw text, embeddings)
- **`models/`** = outputs (trained weights, checkpoints)

Both are gitignored. Commit the *code* that produces them, not the artifacts themselves. When you outgrow local files, `data/` points at a data warehouse / DVC remote and `models/` points at a model registry (W&B, MLflow, Hugging Face Hub).

### Why `tests/` has `unit/` and `integration/`

The screenshot version splits these, and it's a good idea:

- **`tests/unit/`** — tests individual functions in isolation. Fast. No network. No real model calls.
- **`tests/integration/`** — tests the system end-to-end. Slow. May call real APIs. May require setup.

You run `pytest tests/unit/` constantly during development. You run `pytest tests/integration/` in CI or before merging. The split lets you do that.


### Why `Dockerfile`

For **reproducibility**, not deployment. They let you (or someone else) run your library / experiments in an identical environment regardless of OS. Use it like:

```bash
docker compose run --rm app python -m app.training.train --config experiments/exp_001.yaml
```

…not like a production service.

---

## Dependency Management

Single `requirements.txt`. No `pyproject.toml`, no `requirements-dev.txt` split.

```
flask  # ONLY if you eventually add a thin API layer — usually omit
anthropic>=0.40
openai>=1.0
pydantic>=2.0
pydantic-settings>=2.0
torch>=2.4
transformers>=4.40
datasets>=2.20
faiss-cpu  # or another vector store
# Testing / lint — add as needed
pytest>=8.0
ruff>=0.6
```

If reproducibility starts mattering (the "worked last month, now broken" problem):

```bash
pip freeze > requirements.lock
```

…or use `pip-tools`.

---

## Workflow & How Imports Work

Flat layout, no `src/`, no installed package. Same rule as the service patterns:

> **Always run Python commands from the project root.**

### Why this rule exists

Your code does:

```python
# Inside app/rag/retriever.py
from app.core.base_llm import BaseLLM
from app.processing.chunking import chunk_text
```

Python adds the current working directory to its module search path. With `app/` directly under the project root, running from the root means Python finds `app/` and imports work. Running from anywhere else → `ModuleNotFoundError`.

There's no `pyproject.toml` and no `pip install -e .` — same trade-off as the service patterns.

### Setting up the project

```bash
git clone <your-repo>
cd your-project

python -m venv .venv
source .venv/bin/activate            # macOS/Linux
# .venv\Scripts\activate              # Windows

pip install -r requirements.txt
```

### Daily development workflow

Always from the project root:

```bash
# Run a script
python -m app.training.train --config experiments/exp_001.yaml

# Run a CLI helper
python scripts/build_embeddings.py

# Run a notebook
jupyter lab notebooks/

# Run tests
pytest tests/unit/                   # fast
pytest tests/integration/            # slow
pytest tests/                        # all

# Lint and format
ruff check .
ruff format .
```

### What NOT to do

```bash
# ❌ Fails — Python can't find `app` from this cwd
cd app
python -m app.rag.retriever

# ❌ Fails — different cwd issue
cd ~/Desktop
python -m app.something

# ✅ Works
cd your-project
python -m app.rag.retriever
```

### IDE setup

Set your IDE's source root to the **project root** (not `app/`). Imports like `from app.rag...` should resolve cleanly.

- **VS Code**: open the project folder as the workspace root. No special config needed.
- **PyCharm**: project root is auto-detected as a source root for flat layouts.

---

## Documentation

- **`README.md`** (root) — what the project is, quick start.
- **`docs/`** — architecture, design notes, decision records.
- **`docs/adr/`** (optional) — Architecture Decision Records as the project grows.

---

## What to do now vs. later

**Now (day 1):**
- `app/` with at least `__init__.py` and one subpackage (say, `core/`)
- `experiments/`, `notebooks/`, `data/`, `models/` placeholders
- `.gitignore`, `README.md`, `.env.example`, `requirements.txt`
- `tests/unit/` with one starter test

**Add when needed:**
- More `app/<capability>/` folders as new capabilities emerge.
- `tests/integration/` when you have end-to-end paths worth testing.
- `Dockerfile` / `docker-compose.yml` for reproducibility.
- `scripts/<thing>.py` for automation that's annoying to type out.

---

## When to graduate to a different pattern

This pattern works until your project needs to be served as an HTTP API to other systems. Signs it's time to move (or add) a service layer:

- **You're writing the same orchestration code into every script.** Wrap it in a service.
- **You want non-Python clients to call your code.** They need HTTP, not Python imports.
- **You want to deploy this as a service users hit through a browser or app.** Move to the service pattern.

When that happens, you have two options:

1. **Wrap with a thin API layer** — add `app/api/` with Flask/FastAPI routes that call into your existing capabilities. The library structure stays intact; the API is just one more entry point.
2. **Restructure into a service pattern** — move `app/` into `backend/<service>/`, split `models/` and `data/` per service, etc. More work, but cleaner if you're going all-in on the service shape.

For most projects, option 1 is plenty. Option 2 is only worth it if you're building multiple services.

---

## References

- [Cookiecutter Data Science](https://cookiecutter-data-science.drivendata.org/)
- [Hugging Face transformers examples](https://github.com/huggingface/transformers/tree/main/examples)
- [Hydra (config management)](https://hydra.cc/)
- [DVC (data + model versioning)](https://dvc.org/)
- [Made With ML](https://madewithml.com/)
