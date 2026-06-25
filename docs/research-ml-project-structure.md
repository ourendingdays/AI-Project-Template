# Project Structure — Research Project

This is the reference document for a Python project organized as a **research codebase** for Machine Learning. No backend, no frontend, no HTTP server — just Python code for Data science : analyse data, run notebook, etc.

---

## Overview: Research Project

This pattern is for projects where the deliverable is **the solution itself**: na ML research/experiment codebase, a model-training pipeline. Things you `import`, run as scripts, or pull into a notebook — not things you deploy as a long-running service behind nginx.

> Throughout this document, `app` is used as the package name. Replace it with your project's real name (e.g., `assistant`, `ragkit`, `wordcraft`). It must be a valid Python identifier — lowercase, no hyphens.

### Why this pattern

The reasoning is: *"I'm experimenting and building a model fr kaggle competiotion or a system to understand how it works."*

This is the shape used by countless ML Students, including me when I was young  and most "I'm building a thing I'll run locally to see the results" projects.

For a focused Python project, this pattern gives you:

- **One namespace** — every import starts with `from app.<something>`.
- **Capability-based organization** — folders named for what they *do* (`data/`, `training/`, `processing/`), not for what *role* they play in a service architecture (`api/`, `services/`, etc.).
- **No deployment bloat** — no `backend/`, no `frontend/`, no nginx assumptions.

---

## Directory Tree

```
your-project/
├── README.md
├── .gitignore
├── .env.example                 # template for env vars; never commit .env itself
├── requirements.txt             # all Python dependencies
│
├── src/                         # main package — rename to your project name
│   ├── __init__.py
│   ├── processing/              # data preparation
│   │   ├── __init__.py
│   │   ├── data_analyser.py
│   │   └── preprocessor.py
│   ├── training/                # train/fine-tune scripts (only if applicable)
│   │   ├── __init__.py
│   │   └── train.py
│   ├── evaluation/              # eval scripts and metrics
│   │   ├── __init__.py
│   │   └──  metrics.py
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
```

---

## Why this shape

This section covers the major structural decisions. 

### Why `notebooks/` is at the root, not inside `src/`

Different from the service patterns. Here's why:

- In the **service pattern**, notebooks live inside `ml/<service>/notebooks/` because notebooks are part of the *training/research subsystem*, separate from the running service. The split makes it obvious.
- In the **library pattern**, there's no separate service to contrast notebooks with — the whole project is research/exploration. Notebooks deserve top-level visibility because they're part of how you actually work with the project day-to-day.

Same rule applies: **notebooks are exploration only.** When code stabilizes, move it into `src/<something>/`. The notebook becomes a record, not the source of truth.

### Why `models/` and `data/` are top-level, not inside `src/`

Same reason as in the service patterns:

- **`data/`** = inputs (datasets, raw text, embeddings)
- **`models/`** = outputs (trained weights, checkpoints)

Both are gitignored. Commit the *code* that produces them, not the artifacts themselves. When you outgrow local files, `data/` points at a data warehouse / DVC remote and `models/` points at a model registry (W&B, MLflow, Hugging Face Hub).

---

## Dependency Management

`requirements.txt`

```
datasets>=2.20
matplotlib>=3.11.0
pandas>=3.0.3
scikit-learn>=1.9.0
torch>=2.4
transformers>=4.40
```

If reproducibility starts mattering (the "worked last month, now broken" problem):

```bash
pip freeze > requirements.lock
```

---

## Workflow & How Imports Work

> **Always run Python commands from the project root.**

Python adds the current working directory to its module search path. With `src/` directly under the project root, running from the root means Python finds `src/` and imports work. Running from anywhere else → `ModuleNotFoundError`.

### Setting up the project

```bash
git clone <your-repo>
cd your-project

python -m venv .venv
source .venv/bin/activate            # macOS/Linux
# .venv\Scripts\activate             # Windows

pip install -r requirements.txt
```