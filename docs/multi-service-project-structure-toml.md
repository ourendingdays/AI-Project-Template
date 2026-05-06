# Project Structure — Multi-Service (with minimal `pyproject.toml`)

This is the **`pyproject.toml` variant** of the multi-service monorepo layout. Each service gets its own minimal `pyproject.toml` so it's installable as a package. `requirements.txt` still manages dependencies. The benefit: services are importable from anywhere, no `cd backend/` rule, and the `src/` layout works safely per service.

---

## Directory Tree

```
your-project/
├── README.md
├── .gitignore
├── .env.example
├── docker-compose.yml
│
├── backend/
│   ├── .venv/
│   ├── Dockerfile
│   ├── requirements.txt         # ← still manages all deps for all services
│   ├── requirements-dev.txt
│   ├── service_a/
│   │   ├── pyproject.toml       # ← per-service: declares this service as a package
│   │   ├── src/
│   │   │   └── service_a/
│   │   │       ├── __init__.py
│   │   │       ├── api/
│   │   │       ├── core/
│   │   │       ├── db/
│   │   │       ├── models/
│   │   │       ├── repositories/
│   │   │       ├── services/
│   │   │       ├── ml_models/
│   │   │       ├── clients/
│   │   │       ├── schemas/
│   │   │       └── utils/
│   │   ├── alembic.ini          # only if this service uses a database
│   │   └── migrations/          # only if this service uses a database
│   ├── service_b/               # same shape as service_a
│   │   └── ...
│   └── tests/
│       └── service_a/
│
├── ml/                          # same as the no-toml version
├── frontend/
├── data/
├── models/
├── scripts/
└── docs/
```

The structural changes vs. the no-toml version:

- A `pyproject.toml` file in **each service folder** (`service_a/pyproject.toml`, `service_b/pyproject.toml`).
- Each service uses a `src/` layout: `backend/service_a/src/service_a/...`.

Everything else (top-level layout, `ml/`, `data/`, the `db/`/`models/`/`schemas/` split inside each service, etc.) is identical.

---

## The `pyproject.toml` file (one per service)

```toml
# backend/service_a/pyproject.toml
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "service-a"
version = "0.1.0"

[tool.setuptools.packages.find]
where = ["src"]
```

Ten lines. One job: declares this service as an installable package. Does **not** manage dependencies — `backend/requirements.txt` still does that, combined for all services.

Each service gets a near-identical copy. The only thing you change between them is `name` and the folder under `src/`.

---

## Setup

One venv at the `backend/` level (same as the no-toml multi-service version), with each service installed in editable mode:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate

pip install -r requirements-dev.txt

# Install each service as an editable package:
pip install -e ./service_a
pip install -e ./service_b
```

Each `pip install -e ./service_x` registers that service's package in the venv. After this, `import service_a`, `import service_b`, etc. all work from anywhere.

---

## Workflow

The `cd backend/` rule **no longer applies**. Run Python from anywhere:

```bash
# All of these work, venv-active:
cd ~/anywhere
python -m service_a.api.main
uvicorn service_a.api.main:app --reload --port 8000
uvicorn service_b.api.main:app --reload --port 8001
pytest backend/tests/

# Database migrations (per service):
cd backend/service_a
alembic upgrade head
```

---

## Why use this variant

Same benefits as the single-service variant, plus one specific to the multi-service shape:

- **Run from anywhere** — no `cd backend/` rule.
- **Per-service dependency isolation when needed**: if you ever decide to pin a service to a different library version, this layout makes it trivial — each service's `pyproject.toml` can later declare its own dependencies and you'd promote it from "package descriptor" to "real package definition." The no-toml version requires a bigger refactor to get there.
- **Each service is a real, installable Python package**, which makes per-service Docker images cleaner if you ever split them.

The cost: a `pyproject.toml` per service (still ten lines each, written once) and one `pip install -e ./<service>` per service in setup.

---

## When to skip this variant

Stick with the no-`pyproject.toml` version if:

- You're fine with the `cd backend/` rule.
- You don't anticipate splitting services into independent images or repos soon.
- You want zero non-`requirements.txt` Python config in the repo.

---

## What stays the same

Everything else in the multi-service doc applies:

- Services as siblings under `backend/`, no wrapper package — same.
- `models/` (SQLAlchemy) vs. `ml_models/` (ML wrappers) vs. `schemas/` (Pydantic) per service — same.
- Each service owns its own database; migrations live inside the service folder — same.
- One combined `backend/requirements.txt` for all services until conflicts force a split — same.
- One venv at `backend/` level shared across all services — same.
- `ml/` structure with services as siblings, `data/<service>/`, `models/<service>/` — same.