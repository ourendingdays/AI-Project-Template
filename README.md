# Project Template for AI Projects

A starter structure for AI / ML / Data-Science projects. Two patterns are supported: a **single-service** layout for one focused product, and a **multi-service monorepo** for projects that may grow into several backend services behind a unified frontend.

This repo is a GitHub template. Click **"Use this template"** to create a new repo from it, then run one of the bootstrap scripts.

---

## How to use this template

1. Click **"Use this template"** → **"Create a new repository"** at the top of this page.
2. Clone your new repo locally.
3. Go into the Project. Pick a pattern and run the matching bootstrap script:

   ```bash
   cd AI-Project-Template
   
   # Single-service: one focused product, one Python package.
   chmod +x bootstrap_single.sh
   bash bootstrap_single.sh

   # Multi-service: monorepo of independent backend services.
   chmod +x bootstrap_multi.sh
   bash bootstrap_multi.sh
   ```

   Each script is idempotent — it lays down folders, stub files, `.gitignore`, `.env.example`, and a runnable Flask + gunicorn skeleton.

4. **Rename the placeholder** (`your_pkg` for single-service, `service_a` for multi-service) to your real package or service name. Use a valid Python identifier — lowercase, no hyphens.
5. Set up the venv and verify it runs:

   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt

   # Dev server (single-service):
   flask --app your_pkg.api.main run --host 0.0.0.0 --port 8000
   # OR more prodction-ready
   gunicorn --bind 127.0.0.1:8000 your_pkg.api.main:app

   # Dev server (multi-service):
   flask --app service_a.api.main run --host 0.0.0.0 --port 8000
   # OR more production-ready
   gunicorn --bind 127.0.0.1:8000 service_a.api.main:app
   ```

   Then in an other terminal:

   ```bash
   curl http://localhost:8000/health
   ```

   You should get `{"status": "ok"}`.


6. Replace this README with one for your actual project.

---

## What's inside

The full layout, conventions, and rationale (why services are siblings, why `models/` is split from `ml_models/`, where databases fit, etc.) are documented in [`docs/`](docs/):

- [`docs/single-service-project-structure.md`](docs/single-service-project-structure.md)
- [`docs/multi-service-project-structure.md`](docs/multi-service-project-structure.md)
- `*-toml.md` variants of each, for projects that prefer a minimal `pyproject.toml`.

Defaults baked into the bootstraps: Flask + gunicorn, `requirements.txt` (no `pyproject.toml`), flat layout (no `src/` folder), one venv per area.

---

## License

MIT — see [`LICENSE`](LICENSE).
