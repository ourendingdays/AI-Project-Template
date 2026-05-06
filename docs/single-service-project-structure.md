# Project Structure (Single-Service)

Reference document for the layout of this project. Covers the directory tree, the rationale behind each part, how dependencies are managed, and the day-to-day development workflow.

---

## Overview: Single-Service Application

This project is structured as a **single-service application**: one backend, one ML pipeline, one frontend, all serving a single coherent product. The entire backend lives inside one Python package (`your_pkg/`), and the ML side has one set of training/evaluation/data folders.

> Throughout this document, `your_pkg` is used as a stand-in for your real package name. Replace it with whatever you actually call your project (e.g., `assistant`, `bookbot`, `tutor`). Package names must be valid Python identifiers — lowercase, no hyphens, underscores OK.

### Why this pattern

The reasoning is: *"I'm building one thing. I want a clean place for its API code, a clean place for its training code, and a clean place for its UI — and minimal nesting."*

This is the simplest shape that still scales beyond a toy script. It's what most solo apps, small SaaS products, and single-purpose ML services look like in production. Examples: a chatbot product, a document-summarization API, a recommendation engine — anything where the answer to "what does this project do?" is one sentence.

For a solo project building one focused product, this pattern gives you:

- **One namespace** to think about — everything is `your_pkg.something`.
- **Less nesting** than a multi-service monorepo (no `backend/<service>/api/...`, just `backend/your_pkg/api/...`).
- **Clear graduation path**: if you later realize you're actually building multiple loosely-related things, you can split into a multi-service monorepo. That refactor is a few hours of work — not a disaster.

> **Choosing between this and the multi-service version:** if you suspect you'll build several loosely-related things in the same repo (e.g., one product talking to several different specialized backends), prefer the multi-service pattern. If you're building one focused product, this version is simpler.

---

## Directory Tree

```
your-project/
├── README.md
├── .gitignore
├── .env.example                 # template for env vars; never commit .env itself
├── docker-compose.yml           # orchestrates services (incl. database); add when needed
│
├── backend/
│   ├── .venv/                   # one venv for the backend (gitignored)
│   ├── Dockerfile
│   ├── requirements.txt         # runtime deps (fastapi, anthropic, sqlalchemy, ...)
│   ├── requirements-dev.txt     # dev deps (pytest, ruff, mypy, ...)
│   ├── alembic.ini              # alembic config (only if using a database)
│   ├── migrations/              # database migrations (only if using a database)
│   │   ├── env.py
│   │   └── versions/
│   │       └── 001_initial.py
│   ├── your_pkg/                # the importable package (flat layout, no src/)
│   │   ├── __init__.py
│   │   ├── api/                 # FastAPI routes / HTTP layer
│   │   ├── core/                # config, logging, settings (pydantic-settings)
│   │   ├── db/                  # database engine, session, base class
│   │   ├── models/              # SQLAlchemy ORM models (database tables)
│   │   ├── repositories/        # optional: data access layer (queries)
│   │   ├── services/            # business logic — orchestrates models + APIs
│   │   ├── ml_models/           # ML model wrappers (loading, inference)
│   │   ├── clients/             # external API clients (Anthropic, etc.)
│   │   ├── schemas/             # Pydantic request/response models (API I/O)
│   │   └── utils/
│   └── tests/
│
├── ml/                          # everything training/experiment-related
│   ├── .venv/                   # separate venv from backend (heavy training deps)
│   ├── requirements.txt         # heavy training deps (torch, transformers, datasets, ...)
│   ├── configs/                 # experiment YAMLs (one per run/experiment)
│   ├── data/                    # data loading + preprocessing code
│   ├── training/                # train scripts, trainers
│   ├── evaluation/              # eval scripts, metrics
│   ├── notebooks/               # exploration only — not source of truth
│   └── pipelines/               # end-to-end orchestration (e.g., DVC, Prefect)
│
├── frontend/                    # populate when stack is chosen
│   └── README.md                # placeholder noting "TBD"
│
├── data/                        # ML data, gitignored except README + .gitkeep files
│   ├── raw/                     # immutable original data — never edit
│   ├── interim/                 # intermediate processing artifacts
│   ├── processed/               # final data fed into training
│   └── external/                # third-party data
│
├── models/                      # trained ML model artifacts (gitignored)
│   └── README.md
│
├── scripts/                     # one-off CLI scripts (download data, seed db, etc.)
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

### Why one package (`your_pkg/`) instead of multiple service folders

For a single-product application, putting everything inside one Python package means:

- **Shared code is trivial.** Anything in `your_pkg/utils/` or `your_pkg/clients/` is importable from any other module in the project — no separate "shared library" needed.
- **One import root.** Every import in the project starts with `from your_pkg.<something>`. That's a strong, consistent convention.
- **Less nesting.** `backend/your_pkg/api/routes.py` is one level shallower than the multi-service equivalent.
- **No cross-service question.** You never have to ask "should this go in service A or B?" because there's only one place.

The trade-off: if you later realize you're really building two unrelated things, you'll need to refactor into a multi-service layout. For a focused single product, that day rarely comes.

### Why `models/` is separate from `data/`

They look similar (both are "blob-like artifacts"), but they're fundamentally different:

- **`data/`** = **inputs** to your ML pipeline. Datasets, feature files, raw text dumps. Things you feed into training.
- **`models/`** = **outputs** of your ML pipeline. Trained weights. Things training produces.

Why this matters in practice:

- **Different versioning needs.** Datasets change rarely and are huge. Model checkpoints change often (every training run produces new ones) and are also huge but in different ways.
- **Different access patterns.** Data is read by training jobs. Models are read by the serving API.
- **Different governance.** Data may have privacy/legal constraints (PII, licensing). Models have IP/security concerns (weight leaks, model theft).
- **Different "next steps".** When you outgrow local files, `data/` typically points at a data warehouse or DVC remote; `models/` typically points at a model registry (MLflow, W&B, Hugging Face Hub, S3 with versioning).

Putting them in one folder muddles all of this. Two folders cost you nothing and keep the distinction clear.

> **Note:** the top-level `data/` and `models/` folders are for *ML* data and *ML* model artifacts — the static files used by training and the trained weights it produces. They are *not* the same thing as the application's runtime database. See the Database section below for that.

### Why `notebooks/` lives inside `ml/`, not at the repo root

A `notebooks/` folder at the root signals "notebooks are first-class citizens of this project." That's a trap.

Notebooks are **excellent for exploration** — trying a new library, plotting a dataset, sanity-checking a model. They're **terrible as the source of truth** for production code:

- They hide execution state (you can run cells out of order and get different results).
- They're a nightmare in code review (the JSON file changes when you scroll, click, or just re-run).
- They can't be unit-tested easily.
- They mix code, output, and prose in ways that don't survive into production.

The healthy pattern is: **prototype in a notebook → once it works, move the real code into `ml/training/`, `ml/evaluation/`, or `backend/your_pkg/ml_models/`**. The notebook becomes a record of how you got there, not the place where the logic lives.

Putting notebooks inside `ml/` instead of at the root signals exactly this: they belong to the experimentation phase, not the running application. Hugging Face, fast.ai, and most serious ML repos follow this convention.

### Why requirements files are split between `backend/` and `ml/`

Same reason as the `backend/`-vs-`ml/` split, applied to dependencies:

- `backend/requirements.txt` lists what the **API at runtime** needs — small, focused, ships in the production Docker image.
- `ml/requirements.txt` lists what **training** needs — huge, includes development tools like Weights & Biases, only used on the training machine.

If you put everything in one `requirements.txt`:

- Your serving image installs `wandb`, `tensorboard`, `jupyterlab`, full PyTorch with CUDA, etc. — none of which it uses.
- Build time goes from 30 seconds to 10 minutes.
- Image size goes from ~200 MB to several gigabytes.
- Every training-tool security advisory affects your production API.

Two files = two clean environments. The serving image is lean; the training environment has everything it needs.

(`frontend/` will get its own dependency manifest when you add it — `package.json` for npm/pnpm. Same principle: frontend deps don't belong in Python files.)

### Why split `your_pkg/` into `api/`, `core/`, `db/`, `models/`, `services/`, etc.

Separation of concerns inside the package:

- **`api/`** — HTTP layer only. Defines routes, parses requests, formats responses. Contains no business logic.
- **`core/`** — app-wide infrastructure: config loading, logging setup, settings.
- **`db/`** — database connection plumbing: SQLAlchemy engine, session factory, declarative base. The "how do I talk to the database" code, not the "what's in the database" code.
- **`models/`** — SQLAlchemy ORM models. One class per database table. This is what `models/` means in nearly every Python web framework (Django, FastAPI tutorials, Flask), so the name aligns with ecosystem conventions.
- **`repositories/`** *(optional)* — a data access layer that wraps queries. `user_repo.get_by_email(email)` instead of writing raw SQLAlchemy queries inside services. Add this when query logic starts duplicating across services; skip it for small apps.
- **`services/`** — business logic. Orchestrates ORM models, ML models, and external clients to fulfill requests.
- **`ml_models/`** — ML model wrappers (loading weights, running inference). Named `ml_models/` rather than `models/` to keep ML out of the way of database models, and to avoid colliding with the popular `models` PyPI package.
- **`clients/`** — external API integrations (Anthropic, OpenAI, etc.).
- **`schemas/`** — Pydantic models for **API request/response validation**. Despite the similar-looking name, these are different from `models/` — see below.
- **`utils/`** — small generic helpers.

The dependency direction goes one way: **`api/` → `services/` → (`models/` + `ml_models/` + `clients/` + `repositories/`)**. An HTTP route never queries the database directly; it calls a `service`, which uses a repository or ORM model. This means you can swap out the HTTP framework, change DB engines, change API providers, or upgrade an ML model without touching unrelated layers.

This is straight from FastAPI's [full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template) and [Netflix Dispatch](https://github.com/Netflix/dispatch).

### Why `schemas/` (Pydantic) and `models/` (SQLAlchemy) are separate

They sound similar and often have classes with the same names (`User`, `Conversation`), but they describe two different worlds:

- **`models/`** describes **what's stored in the database**. SQLAlchemy classes mapped to tables.
- **`schemas/`** describes **what crosses the API boundary**. Pydantic classes that validate incoming requests and shape outgoing responses.

These will diverge as the app grows. A `User` ORM model has `password_hash`, `created_at`, internal flags, etc. A `UserResponse` Pydantic schema only includes the safe fields you want to send back to clients. A `UserCreate` schema accepts a plaintext password the model never stores. Conflating them either leaks DB internals to your API or pollutes your DB with API-only concerns.

Keep them separate from day one. It's more files but radically cleaner code.

### Why configs are split (not a top-level `configs/`)

There are two genuinely different kinds of configuration:

- **Experiment configs** (learning rate, model size, dataset version) → `ml/configs/`. These describe a *training run* and should be checked in, versioned, and reproducible.
- **App configs** (API keys, ports, log levels, database URL) → `backend/your_pkg/core/` as Pydantic settings, loaded from environment variables (via `.env` locally, real env vars in production). These describe the *running service* and should never be checked in.

A top-level `configs/` mixes secrets with experiment hyperparameters and creates confusion about which file controls what.

### Why `frontend/` is a sibling of `backend/`, not nested

Standard full-stack layout. The frontend and backend speak to each other over HTTP — they're peers, not parent-child. Each can be developed, tested, built, and deployed independently. Matches Vercel's examples, the FastAPI full-stack template, and most Next.js + Python combos in production.

---

## Database

If your project needs persistence (user accounts, saved conversations, application state), "the database" is actually three separate things, each living in a different place:

### 1. Connection code and ORM models — inside `your_pkg/`

The Python code that talks to the database is just application code. It lives inside the package:

- `your_pkg/db/` — engine, session factory, declarative base. Plumbing.
- `your_pkg/models/` — SQLAlchemy ORM classes, one per table.
- `your_pkg/repositories/` — *optional* data access layer (skip for small apps).

### 2. Migrations — at `backend/migrations/`, outside the package

Migrations are versioned scripts that evolve the schema over time. They sit beside `your_pkg/`, not inside it:

```
backend/
├── alembic.ini
├── migrations/
│   ├── env.py
│   └── versions/
│       ├── 001_initial.py
│       └── 002_add_user_email.py
└── your_pkg/
```

Why outside `your_pkg/`? Migrations aren't *imported* by the app — they're a separate artifact run by a CLI (`alembic upgrade head`) at deploy time. Putting them inside the package conflates "code my app runs" with "scripts deployment runs."

[Alembic](https://alembic.sqlalchemy.org/) is the standard SQLAlchemy migration tool and generates this structure automatically (`alembic init migrations`).

### 3. The database server — in `docker-compose.yml`

The actual running Postgres (or MySQL, etc.) is infrastructure, not files in the repo. It lives in your compose file:

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    depends_on:
      - db
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}

volumes:
  postgres_data:
```

The connection string lives in `.env` locally (and real environment variables in production), read by your `core/config.py` Pydantic settings.

### Database contents are NOT the `data/` folder

A common confusion worth heading off:

- **`data/` folder** = static files used by ML training (CSVs, JSONL, raw scrapes). Versioned alongside the code that processes them.
- **Database contents** = live application state (users, sessions, conversations). Lives inside the running Postgres container, backed up separately, never committed to Git.

If you need to ship sample DB data with the repo (for tests, local dev), put it in `backend/tests/fixtures/` or in a `scripts/seed_db.py` script. Don't put it in the top-level `data/` folder — that's for ML.

### Required dependencies (when adding a database)

Add to `backend/requirements.txt`:

```
sqlalchemy>=2.0
alembic>=1.13
psycopg2-binary>=2.9       # or asyncpg for async; or pymysql for MySQL
```

---

## Dependency Management

This project uses `requirements.txt` files. No `pyproject.toml`. No package install step.

### Layout

| File | Purpose |
|---|---|
| `backend/requirements.txt` | Runtime deps for the serving API (incl. database drivers) |
| `backend/requirements-dev.txt` | Dev tools (pytest, ruff, mypy). Includes runtime via `-r requirements.txt` |
| `ml/requirements.txt` | Training deps (torch, transformers, datasets, etc.) |

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

---

## Workflow & How Imports Work

This project uses a **flat layout** (`backend/your_pkg/`, no `src/` folder) and does **not** install the package. This means there's a rule to remember:

> **Always run Python commands from inside `backend/` (or `ml/`).**

### Why this rule exists

When you run a Python command, Python automatically adds the **current working directory** to its module search path. Your code does:

```python
# Inside backend/your_pkg/api/routes.py
from your_pkg.services.chat import answer_question
from your_pkg.clients.anthropic import AnthropicClient
from your_pkg.models.user import User
```

For this to work, Python needs to find a folder named `your_pkg` somewhere it searches. With a flat layout, `your_pkg` sits directly under `backend/`, so:

- Run from `backend/` → cwd is `backend/` → Python sees `your_pkg/` → import works ✅
- Run from anywhere else → cwd doesn't contain `your_pkg/` → `ModuleNotFoundError` ❌

There's no `pyproject.toml` and no `pip install -e .` — that's the whole reason this rule exists. The trade-off is: **no extra config file, but you must `cd backend/` first.**

### Setting up the project

One-time setup:

```bash
# 1. Clone or create the repo
cd your-project

# 2. Create a virtual environment for the backend
cd backend
python -m venv .venv

# 3. Activate it
source .venv/bin/activate              # macOS/Linux
# .venv\Scripts\activate                # Windows

# 4. Install backend dependencies
pip install -r requirements-dev.txt

# 5. (If using a database) Start the DB container and apply migrations
docker compose up -d db
alembic upgrade head

# 6. Set up the ML environment separately (different deps, different machine in production)
cd ../ml
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Daily development workflow

**Backend work:**

```bash
cd backend
source .venv/bin/activate

# Run the API
python -m your_pkg.api.main
# or with uvicorn:
uvicorn your_pkg.api.main:app --reload

# Database migrations (when schema changes)
alembic revision --autogenerate -m "add user table"
alembic upgrade head

# Run tests
pytest tests/

# Lint / format / typecheck
ruff check .
ruff format .
mypy your_pkg/
```

**ML work:**

```bash
cd ml
source .venv/bin/activate

python training/train.py --config configs/exp_001.yaml
```

### What NOT to do

```bash
# ❌ This will fail with ModuleNotFoundError
cd your-project
python backend/your_pkg/api/main.py

# ❌ This will also fail
cd your-project/backend/your_pkg
python api/main.py

# ✅ This works
cd your-project/backend
python -m your_pkg.api.main
```

The pattern is always: `cd backend/`, then run `python -m your_pkg.something`.

### IDE setup

If your editor (VS Code, PyCharm) shows red squiggles under `from your_pkg...` imports, it's because the editor doesn't know where `your_pkg` lives. Fix it by setting the editor's working directory or Python source root to `backend/`:

- **VS Code**: open `backend/` as the workspace root, or add to `.vscode/settings.json`:
  ```json
  {
    "python.analysis.extraPaths": ["backend"]
  }
  ```
- **PyCharm**: right-click `backend/` → "Mark Directory as" → "Sources Root".

### Docker note

When you add Docker later, set `WORKDIR /app/backend` in the Dockerfile so the container respects the same convention:

```dockerfile
WORKDIR /app/backend
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ .
CMD ["uvicorn", "your_pkg.api.main:app", "--host", "0.0.0.0"]
```

Your `docker-compose.yml` will orchestrate the backend container, the database container, and (eventually) the frontend.

---

## Tool Configuration

Each tool gets its own config file:

- `backend/pytest.ini` — pytest configuration
- `backend/ruff.toml` — ruff linter/formatter config
- `backend/mypy.ini` — mypy type checker config
- `backend/alembic.ini` — alembic configuration (only if using a database)

---

## Documentation

- **`README.md`** (root) — what the project is, quick start. First thing on GitHub.
- **`docs/`** — everything else: architecture, design notes, decision records.
- **`docs/adr/`** (optional, add later) — Architecture Decision Records, one short markdown file per significant decision (e.g., `0001-use-fastapi.md`, `0002-postgres-vs-sqlite.md`). Standard template: [Michael Nygard's ADR format](https://github.com/joelparkerhenderson/architecture-decision-record).

---

## What to do now vs. later

**Now (day 1):**
- `backend/your_pkg/` with stub `api/main.py`
- `ml/` skeleton
- `data/` empty dirs with `.gitkeep`
- `.gitignore`, `README.md`, `.env.example`
- `backend/requirements.txt`, `backend/requirements-dev.txt`, `ml/requirements.txt`

**Add when needed:**
- `your_pkg/db/`, `your_pkg/models/`, `migrations/` — when the app needs persistence.
- `your_pkg/repositories/` — when query logic starts duplicating across services.
- `frontend/` — when stack is chosen.
- `docker-compose.yml` — when there are 2+ runnable things to compose (e.g., backend + database).
- `models/` artifacts — when training produces them.
- `docs/adr/` — when decisions worth recording accumulate.

Premature structure is almost as bad as no structure. The goal is a tree that *can* grow into the full thing without rewrites — not one fully built on day one.

---

## When to graduate to a stricter (or different) setup

The current setup (one package, one venv per area, combined requirements, no `pyproject.toml`) is right for a focused single-product solo project. Watch for these signals that it's time to evolve:

- **Multi-service monorepo**: when you find yourself building a second, *unrelated* capability in the same repo and stuffing it awkwardly into `your_pkg/`. That's the sign to split into sibling service folders under `backend/`.
- **`pyproject.toml`**: when you want to publish the package as a library, want strict dependency isolation enforced by tooling, or want to be able to run from any working directory (so the `cd backend/` rule no longer applies).
- **Per-environment Dockerfiles**: when image sizes diverge significantly or you need different base images (e.g., one needs CUDA, the other doesn't).
- **Splitting into separate repos**: when a part of the project has its own team, its own release cycle, and its own deployment story that has nothing to do with the rest.

Each of these is a *future* decision. The current structure makes all of them straightforward to adopt later — that's the whole point.

---

## References

- [Python Packaging User Guide — src vs flat layout](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/)
- [FastAPI full-stack template](https://github.com/fastapi/full-stack-fastapi-template)
- [Cookiecutter Data Science](https://cookiecutter-data-science.drivendata.org/)
- [Hugging Face transformers examples](https://github.com/huggingface/transformers/tree/main/examples)
- [Netflix Dispatch](https://github.com/Netflix/dispatch)
- [Alembic — SQLAlchemy migrations](https://alembic.sqlalchemy.org/)
- [Hydra (config management)](https://hydra.cc/)
- [DVC (data + model versioning)](https://dvc.org/)
- [Architecture Decision Records](https://github.com/joelparkerhenderson/architecture-decision-record)