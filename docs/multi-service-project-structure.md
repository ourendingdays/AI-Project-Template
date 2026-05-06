# Project Structure

Reference document for the layout of this project. Covers the directory tree, the rationale behind each part, how dependencies are managed, and the day-to-day development workflow.

---

## Overview: Monorepo with Multiple Services

This project follows a **monorepo with multiple services** pattern. The backend is split into independent service folders that sit as siblings under `backend/`. The same applies to the ML side under `ml/`.

> Throughout this document, `service_a` is used as a stand-in for a real service name. Replace it with whatever you actually call your service (e.g., `assistant`, `vision`, `agent`). Service names must be valid Python identifiers — lowercase, no hyphens, underscores OK.

### Why this pattern

The reasoning is: *"I don't know what I'll build next, but a unified frontend talking to multiple backend services is likely."* That's exactly the scenario this pattern is designed for.

This shape scales from "one service" up to "many services" without redesign. It's the structure used by Vercel's infrastructure, Supabase, and most modern AI startups (one frontend, many backend services — chat, embeddings, vision, agents — each independently growable).

For a solo project that's still figuring out what it wants to be, this pattern gives you:

- A clear place to put the next service when an idea comes up — just `mkdir backend/<new_service>/`.
- Clean code separation between unrelated concerns from day one.
- Optionality: any service can later be split into its own deployment, image, or even repo with minimal refactoring.
- Without forcing premature complexity (per-service venvs, per-service Dockerfiles, etc.) until you actually need it.

---

## Directory Tree

```
your-project/
├── README.md
├── .gitignore
├── .env.example                 # template for env vars; never commit .env itself
├── docker-compose.yml           # orchestrates services; add when 2+ services exist
│
├── backend/
│   ├── .venv/                   # one venv shared by all backend services (gitignored)
│   ├── Dockerfile
│   ├── requirements.txt         # combined runtime deps for all services
│   ├── requirements-dev.txt     # dev deps (pytest, ruff, mypy, ...)
│   ├── service_a/               # one service — replace name with your own
│   │   ├── __init__.py
│   │   ├── api/                 # FastAPI routes / HTTP layer
│   │   ├── core/                # config, logging, settings
│   │   ├── services/            # business logic
│   │   ├── ml_models/           # ML model wrappers (loading, inference)
│   │   ├── clients/             # external API clients (Anthropic, etc.)
│   │   ├── schemas/             # Pydantic request/response models
│   │   └── utils/
│   ├── service_b/               # another service follows the same shape
│   │   └── ...
│   └── tests/
│       └── service_a/
│
├── ml/                          # everything training/experiment-related
│   ├── .venv/                   # separate venv from backend (heavy training deps)
│   ├── requirements.txt         # combined training deps for all services
│   └── service_a/
│       ├── configs/             # experiment YAMLs
│       ├── data/                # data loading + preprocessing code
│       ├── training/            # train scripts, trainers
│       ├── evaluation/          # eval scripts, metrics
│       └── notebooks/           # exploration only — not source of truth
│
├── frontend/                    # populate when stack is chosen
│   └── README.md                # placeholder noting "TBD"
│
├── data/                        # gitignored except README + .gitkeep files
│   └── service_a/
│       ├── raw/                 # immutable original data — never edit
│       ├── interim/             # intermediate processing artifacts
│       ├── processed/           # final data fed into training
│       └── external/            # third-party data
│
├── models/                      # trained model artifacts (gitignored)
│   └── service_a/
│
├── scripts/                     # one-off CLI scripts (download data, migrate, etc.)
│
└── docs/
    ├── project-structure.md     # this file
    └── architecture.md          # overall architecture notes
```

---

## Why this shape

This section explains the major structural decisions. The short version: each top-level folder represents a **different lifecycle**, a **different runtime**, or a **different role**. Mixing them together causes pain that compounds over time.

### Why `backend/`, `ml/`, and `frontend/` are separated

These three live different lives:

| | `backend/` | `ml/` | `frontend/` |
|---|---|---|---|
| Language | Python | Python | JavaScript/TypeScript |
| Runtime | always running (server) | runs occasionally (training jobs) | runs in the user's browser |
| Hardware | small CPU box | beefy GPU box | the user's device |
| Deploy frequency | every change | once per experiment | every UI change |
| Dependencies | fastapi, anthropic SDK | torch, transformers, datasets | react, next.js |

If you mash them together:

- Your serving Docker image pulls in **gigabytes** of training-only dependencies (PyTorch alone is ~2GB) that the API never uses. Slower builds, slower deploys, bigger attack surface, more security patches.
- A frontend developer touching a button has to wait for Python tests to pass in CI.
- A change to a training script triggers redeploy of the production API.
- Versioning becomes confusing — does "v1.2.0" mean the model, the API, or the UI?

Separating them means each piece can be built, tested, deployed, and versioned independently. This is the pattern in nearly every production MLOps reference architecture (Hugging Face's `transformers/examples`, Cookiecutter Data Science, Made With ML).

### Why services are siblings under `backend/` (not nested under one package)

Two unrelated capabilities should not share a codebase namespace. Putting them as siblings (`backend/service_a/`, `backend/service_b/`) means:

- Each service's code is self-contained and understandable in isolation.
- Adding a new service is just `mkdir backend/<new>/` — no central package to modify.
- If a service later outgrows the monorepo and needs its own deployment, image, or repo, you move one folder. No untangling required.
- Code review and ownership stay clean: a PR touching one service's files doesn't accidentally affect another.

The alternative (everything under one wrapper package with subpackages) is better when services are **tightly coupled** and share lots of code. For loosely-related services that just happen to live in the same repo, sibling folders are cleaner.

### Why `models/` is separate from `data/`

They look similar (both are "blob-like artifacts"), but they're fundamentally different:

- **`data/`** = **inputs** to your ML pipeline. Datasets, feature files, raw text dumps. Things you feed into training.
- **`models/`** = **outputs** of your ML pipeline. Trained weights. Things training produces.

Why this matters in practice:

- **Different versioning needs.** Datasets change rarely and are huge. Model checkpoints change often (every training run produces new ones) and are also huge but in different ways.
- **Different access patterns.** Data is read by training jobs. Models are read by the serving API.
- **Different governance.** Data may have privacy/legal constraints (PII, licensing). Models have IP/security concerns (weight leaks, model theft).
- **Different "next steps".** When you outgrow local files, `data/` typically points at a data warehouse or DVC remote; `models/` typically points at a model registry (MLflow, W&B, Hugging Face Hub, S3 with versioning).

Putting them in one folder muddles all of this. Two folders cost you nothing and keep the distinction clear. Both are further split by service so each service's data and models are isolated.

### Why `notebooks/` lives inside `ml/<service>/`, not at the repo root

A `notebooks/` folder at the root signals "notebooks are first-class citizens of this project." That's a trap.

Notebooks are **excellent for exploration** — trying a new library, plotting a dataset, sanity-checking a model. They're **terrible as the source of truth** for production code:

- They hide execution state (you can run cells out of order and get different results).
- They're a nightmare in code review (the JSON file changes when you scroll, click, or just re-run).
- They can't be unit-tested easily.
- They mix code, output, and prose in ways that don't survive into production.

The healthy pattern is: **prototype in a notebook → once it works, move the real code into `ml/<service>/training/`, `ml/<service>/evaluation/`, or `backend/<service>/ml_models/`**. The notebook becomes a record of how you got there, not the place where the logic lives.

Putting notebooks inside the relevant service folder under `ml/` signals exactly this: they belong to the experimentation phase of a specific service, not the running application. Hugging Face, fast.ai, and most serious ML repos follow this convention.

### Why requirements files are split between `backend/` and `ml/` (but combined within each)

Same reason as the `backend/`-vs-`ml/` split, applied to dependencies:

- `backend/requirements.txt` lists what the **APIs at runtime** need — small, focused, ships in the production Docker image. Combined for all backend services.
- `ml/requirements.txt` lists what **training** needs — huge, includes development tools like Weights & Biases, only used on the training machine. Combined for all ML pipelines.

If you put everything in one project-wide `requirements.txt`:

- Your serving image installs `wandb`, `tensorboard`, `jupyterlab`, full PyTorch with CUDA, etc. — none of which it uses.
- Build time goes from 30 seconds to 10 minutes.
- Image size goes from ~200 MB to several gigabytes.
- Every training-tool security advisory affects your production API.

**Why combined within `backend/` rather than per-service**: for a solo project, you'll naturally keep common libraries (FastAPI, Pydantic, Anthropic SDK) at the same version across services. One combined file means one venv, one `pip install`, one place to upgrade. The cost is that *if* two services ever need genuinely conflicting versions of the same library, you're stuck — but that's vanishingly rare in solo work, and the structure can be split per-service later if it ever happens.

(`frontend/` will get its own dependency manifest when you add it — `package.json` for npm/pnpm. Same principle: frontend deps don't belong in Python files.)

### Why split each service into `api/`, `core/`, `services/`, `clients/`, etc.

Separation of concerns inside each service:

- **`api/`** — HTTP layer only. Defines routes, parses requests, formats responses. Contains no business logic.
- **`core/`** — service-wide infrastructure: config loading, logging setup, settings.
- **`services/`** — business logic. Orchestrates models and external clients to fulfill requests. (The naming is a bit recursive — `service_a/services/` means "business logic units within service_a." If the doubling feels confusing, rename this folder to `logic/` or `domain/`.)
- **`ml_models/`** — ML model wrappers (loading weights, running inference). Named `ml_models/` rather than `models/` to avoid confusion with database models if you ever add an ORM, and to avoid colliding with the popular `models` PyPI package.
- **`clients/`** — external API integrations (Anthropic, OpenAI, etc.).
- **`schemas/`** — Pydantic models for request/response validation.
- **`utils/`** — small generic helpers.

The dependency direction goes one way: **`api/` → `services/` → `ml_models/` + `clients/`**. An HTTP route never calls the Anthropic API directly; it calls a `service`, which calls a `client`. This means you can swap out the HTTP framework, change API providers, or upgrade a model without touching unrelated layers.

This is straight from FastAPI's [full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template) and [Netflix Dispatch](https://github.com/Netflix/dispatch).

### Why configs are split (not a top-level `configs/`)

There are two genuinely different kinds of configuration:

- **Experiment configs** (learning rate, model size, dataset version) → `ml/<service>/configs/`. These describe a *training run* and should be checked in, versioned, and reproducible.
- **App configs** (API keys, ports, log levels) → `backend/<service>/core/` as Pydantic settings, loaded from environment variables (via `.env` locally, real env vars in production). These describe the *running service* and should never be checked in.

A top-level `configs/` mixes secrets with experiment hyperparameters and creates confusion about which file controls what.

### Why `frontend/` is a sibling of `backend/`, not nested

Standard full-stack layout. The frontend and backend speak to each other over HTTP — they're peers, not parent-child. Each can be developed, tested, built, and deployed independently. A unified frontend can talk to multiple backend services — that's the whole point of the monorepo-with-services pattern.

---

## Dependency Management

This project uses `requirements.txt` files. No `pyproject.toml`. No package install step.

### Layout

| File | Purpose |
|---|---|
| `backend/requirements.txt` | Runtime deps for all backend services |
| `backend/requirements-dev.txt` | Dev tools (pytest, ruff, mypy). Includes runtime via `-r requirements.txt` |
| `ml/requirements.txt` | Training deps (torch, transformers, datasets, etc.) for all ML pipelines |

### Example `requirements-dev.txt`

```
-r requirements.txt
pytest>=8.0
ruff>=0.6
mypy>=1.10
```

The `-r requirements.txt` line pulls in runtime deps so a single `pip install -r requirements-dev.txt` gives a complete dev environment.

### Reproducibility note

`requirements.txt` doesn't pin transitive dependencies by default. If reproducibility breaks ("worked last month, now broken"), generate a lockfile with:

```bash
pip freeze > requirements.lock
```

Or use `pip-tools` (`pip-compile requirements.in → requirements.txt`) for a more structured workflow.

### When to split requirements per service

Stick with combined files until you hit a real conflict. Signs it's time to split:

- Two services genuinely need different major versions of the same library and one can't be upgraded.
- One service has heavy GPU dependencies (e.g., CUDA-enabled PyTorch for inference) that another service doesn't need.
- You want one service's Docker image to be much smaller than another's.

Until then: one `backend/requirements.txt` is simpler and works.

---

## Workflow & How Imports Work

This project uses a **flat layout** (services sit directly under `backend/`, no `src/` folder, no wrapper package) and does **not** install anything as a Python package. This means there's a rule to remember:

> **Always run Python commands from inside `backend/` (or `ml/`).**

### Why this rule exists

When you run a Python command, Python automatically adds the **current working directory** to its module search path. Your code does:

```python
# Inside backend/service_a/api/routes.py
from service_a.services.chat import answer_question
from service_a.clients.anthropic import AnthropicClient
```

For this to work, Python needs to find a folder named `service_a` somewhere it searches. With the flat layout, services sit directly under `backend/`, so:

- Run from `backend/` → cwd is `backend/` → Python sees `service_a/` → imports work ✅
- Run from anywhere else → cwd doesn't contain those folders → `ModuleNotFoundError` ❌

There's no `pyproject.toml` and no `pip install -e .` — that's the whole reason this rule exists. The trade-off is: **no extra config file, but you must `cd backend/` first.**

The good news: **`cd backend/` once works for all services.** You don't need to `cd backend/<service>/` to run a service — Python finds it from `backend/` because it's a folder there.

### Setting up the project

One-time setup:

```bash
# 1. Clone or create the repo
cd your-project

# 2. Create a virtual environment for the backend (one venv for all services)
cd backend
python -m venv .venv

# 3. Activate it
source .venv/bin/activate              # macOS/Linux
# .venv\Scripts\activate                # Windows

# 4. Install backend dependencies
pip install -r requirements-dev.txt

# 5. Set up the ML environment separately (different deps, different machine in production)
cd ../ml
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Daily development workflow

**Backend work** (any service):

```bash
cd backend
source .venv/bin/activate

# Run a service
python -m service_a.api.main
# or with uvicorn:
uvicorn service_a.api.main:app --reload --port 8000

# Run a second service in another terminal (same venv)
uvicorn service_b.api.main:app --reload --port 8001

# Run all tests
pytest tests/

# Run only tests for one service
pytest tests/service_a/

# Lint / format / typecheck
ruff check .
ruff format .
mypy service_a/
```

**ML work**:

```bash
cd ml
source .venv/bin/activate

python -m service_a.training.train --config service_a/configs/exp_001.yaml
```

### What NOT to do

```bash
# ❌ This will fail with ModuleNotFoundError
cd your-project
python backend/service_a/api/main.py

# ❌ This will also fail
cd your-project/backend/service_a
python api/main.py

# ✅ This works
cd your-project/backend
python -m service_a.api.main
```

The pattern is always: `cd backend/`, then run `python -m <service>.something`.

### IDE setup

If your editor (VS Code, PyCharm) shows red squiggles under imports like `from service_a.services.chat import ...`, it's because the editor doesn't know where to look. Fix it by setting the editor's source root to `backend/`:

- **VS Code**: open `backend/` as the workspace root, or add to `.vscode/settings.json`:
  ```json
  {
    "python.analysis.extraPaths": ["backend"]
  }
  ```
- **PyCharm**: right-click `backend/` → "Mark Directory as" → "Sources Root".

### Docker note

When you add Docker later, set `WORKDIR /app/backend` so the container respects the same convention:

```dockerfile
WORKDIR /app/backend
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ .
# Run a specific service:
CMD ["uvicorn", "service_a.api.main:app", "--host", "0.0.0.0"]
```

For multiple services, you can either:
- Build one image and run different `CMD`s per container (simplest), or
- Build per-service images later when services diverge enough to justify it.

---

## Tool Configuration

Each tool gets its own config file:

- `backend/pytest.ini` — pytest configuration
- `backend/ruff.toml` — ruff linter/formatter config
- `backend/mypy.ini` — mypy type checker config

---

## Documentation

- **`README.md`** (root) — what the project is, quick start. First thing on GitHub.
- **`docs/`** — everything else: architecture, design notes, decision records.
- **`docs/adr/`** (optional, add later) — Architecture Decision Records, one short markdown file per significant decision (e.g., `0001-use-fastapi.md`, `0002-monorepo-with-services.md`). Standard template: [Michael Nygard's ADR format](https://github.com/joelparkerhenderson/architecture-decision-record).

---

## What to do now vs. later

**Now (day 1):**
- `backend/<your_first_service>/` with stub `api/main.py`
- `ml/<your_first_service>/` skeleton
- `data/<your_first_service>/` empty dirs with `.gitkeep`
- `.gitignore`, `README.md`, `.env.example`
- `backend/requirements.txt`, `backend/requirements-dev.txt`, `ml/requirements.txt`

**Add when needed:**
- A second service — just `mkdir backend/<new_service>/` and mirror the structure.
- `frontend/` — when stack is chosen.
- `docker-compose.yml` — when there are 2+ runnable things to compose.
- `models/<service>/` artifacts — when training produces them.
- Per-service `requirements.txt` — only when one venv genuinely can't satisfy all services.
- `docs/adr/` — when decisions worth recording accumulate.

Premature structure is almost as bad as no structure. The goal is a tree that *can* grow into the full thing without rewrites — not one fully built on day one.

---

## When to graduate to a stricter setup

The current setup (one venv per area, combined requirements, no `pyproject.toml`) is right for a solo project that's still finding its shape. Watch for these signals that it's time to evolve:

- **Per-service venvs**: when services need conflicting library versions, or when one service has heavy deps another doesn't.
- **Per-service Dockerfiles**: when image sizes diverge significantly or services need different base images (e.g., one needs CUDA, the other doesn't).
- **`pyproject.toml` per service**: when you want to publish a service as a library, or when you want strict dependency isolation enforced by tooling.
- **Splitting into separate repos**: when a service has its own team, its own release cycle, and its own deployment story that has nothing to do with the others.

Each of these is a *future* decision. The current structure makes all of them straightforward to adopt later — that's the whole point.

---

## References

- [Python Packaging User Guide — src vs flat layout](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/)
- [FastAPI full-stack template](https://github.com/fastapi/full-stack-fastapi-template)
- [Cookiecutter Data Science](https://cookiecutter-data-science.drivendata.org/)
- [Hugging Face transformers examples](https://github.com/huggingface/transformers/tree/main/examples)
- [Netflix Dispatch](https://github.com/Netflix/dispatch)
- [Hydra (config management)](https://hydra.cc/)
- [DVC (data + model versioning)](https://dvc.org/)
- [Architecture Decision Records](https://github.com/joelparkerhenderson/architecture-decision-record)