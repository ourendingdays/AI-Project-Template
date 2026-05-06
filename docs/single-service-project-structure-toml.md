# Project Structure — Single-Service (with minimal `pyproject.toml`)

This is the **`pyproject.toml` variant** of the single-service layout. It uses `pyproject.toml` only as a build descriptor — `requirements.txt` still manages dependencies. The benefit: you can run Python commands from anywhere (no `cd backend/` rule), and you can use the `src/` layout safely.

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
│   ├── pyproject.toml           # ← minimal: only declares the package for `pip install -e .`
│   ├── requirements.txt         # ← still manages all deps
│   ├── requirements-dev.txt
│   ├── alembic.ini              # only if using a database
│   ├── migrations/              # only if using a database
│   ├── src/                     # ← src layout, enabled by pyproject.toml
│   │   └── your_pkg/
│   │       ├── __init__.py
│   │       ├── api/
│   │       ├── core/
│   │       ├── db/
│   │       ├── models/          # SQLAlchemy ORM models
│   │       ├── repositories/    # optional
│   │       ├── services/
│   │       ├── ml_models/
│   │       ├── clients/
│   │       ├── schemas/         # Pydantic
│   │       └── utils/
│   └── tests/
│
├── ml/                          # same as the no-toml version
├── frontend/
├── data/
├── models/
├── scripts/
└── docs/
```

The only structural changes vs. the no-toml version:

- A `pyproject.toml` file in `backend/`.
- The package now lives at `backend/src/your_pkg/` instead of `backend/your_pkg/`.

Everything else (`ml/`, `data/`, top-level `models/`, `frontend/`, `docs/`, the `db/`/`models/`/`schemas/` split inside the package) is identical.

---

## The `pyproject.toml` file

```toml
# backend/pyproject.toml
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "your-pkg"
version = "0.1.0"

[tool.setuptools.packages.find]
where = ["src"]
```

That's the entire file. Ten lines. It does **one job**: tells Python that `backend/src/your_pkg/` is an installable package. It does **not** manage dependencies — `requirements.txt` still does that.

Write it once. Never edit it again.

---

## Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pip install -e .                  # ← extra step vs. no-toml version
```

The `pip install -e .` runs once. It registers `your_pkg` in the venv's `site-packages/` as a link back to `backend/src/your_pkg/`. After this, `your_pkg` is importable from anywhere as long as the venv is active.

---

## Workflow

The `cd backend/` rule from the no-toml version **no longer applies**. You can run Python commands from anywhere:

```bash
# All of these work, as long as the venv is active:
cd ~/anywhere
python -m your_pkg.api.main
uvicorn your_pkg.api.main:app --reload
pytest backend/tests/

# This still works too:
cd backend
python -m your_pkg.api.main
```

This is the main practical benefit: tests run cleanly from the repo root, IDEs need less configuration, Docker `WORKDIR` becomes flexible.

---

## Why use this variant

- **Run from anywhere** — no `cd backend/` rule to remember.
- **`src/` layout safety** — Python won't accidentally import your local package when you mean a third-party one.
- **Smoother CI/Docker** — commands work regardless of working directory.
- **One small file** — ten lines, written once, never touched again.

The cost: one `pip install -e .` step in setup, and one extra config file in the tree.

---

## When to skip this variant

Stick with the no-`pyproject.toml` version if:

- You always work from `backend/` anyway and don't mind the rule.
- You want zero non-`requirements.txt` Python config in the repo.
- The project is throwaway or experimental.

---

## What stays the same

Everything else in the single-service doc applies:

- `models/` (SQLAlchemy) vs. `ml_models/` (ML wrappers) vs. `schemas/` (Pydantic) — same separation.
- Database setup, migrations location (`backend/migrations/`), Alembic, and the `docker-compose.yml` story for the DB server — same.
- `data/`, top-level `models/`, `notebooks/` inside `ml/` — same.
- Two requirements files (one for `backend/`, one for `ml/`) — same.
- One venv per area — same.