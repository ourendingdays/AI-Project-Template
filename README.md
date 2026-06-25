# Project Template for AI Projects

A starter structure for an application-, as well as research-like AI / ML / Data-Science projects. Simply run the script and enjoy meticulously thought of project file,- folder architecture that encompasses most of the daily stuff you need.

For AI applications, 2  patterns are supported: 
   - a **single-service** layout for one focused product :  <i>bootstrap_single</i> covered [here](docs/single-service-project-structure.md)
   - and a **multi-service monorepo** for projects that may grow into several backend services behind a unified frontend : <i>bootstrap_multi</i>, covered [here](docs/multi-service-project-structure.md))

For ML Research project, 1 pattern is available:
   - Longer version, suitable for a long research : <i>bootstrap_research</i>, covered [here](docs/research-project-structure.md)
   - Shorter version, usual Data Science code Project structure : <i>bootstrap_research_short</i>, covered [here](docs/research-project-structure-short.md)

Claude code project Structure, that lets you fast on your feet with the most basic and needed skills, agents and rules
   - <i>bootstrap_claude</i>, described [here](docs/claude-code-project-structure.md)

   
This repo is a <i>GitHub template</i>. If you do not want to download or pull the repo, you can then click **"Use this template"** to create a new repo from it, then run one of the bootstrap scripts.

Of course, not everything is presented withing the scripts, many things are missing and some stuff uses packages not common for some developers. Feel freee to add, change, rename and further develop the repo.

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

   # ML-research: focus on data-driven research and problem solving.
   chmod +x bootstrap_multi.sh
   bash bootstrap_multi.sh
   ```

   Each script is idempotent — it lays down folders, stub files, `.gitignore`, `.env.example`, and a runnable Flask + gunicorn skeleton.

4. **Rename the placeholder** (`your_pkg` for single-service, `service_a` for multi-service) to your real package or service name. Use a valid Python identifier — lowercase, no hyphens.
5. Set up the venv and verify it runs (for service architectures):

   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt

   # Dev server (single-service):
   flask --app your_pkg.api.main run --host 0.0.0.0 --port 8000
   # OR more production-ready
   gunicorn --bind 127.0.0.1:8000 your_pkg.api.main:app

   # Dev server (multi-service):
   flask --app service_a.api.main run --host 0.0.0.0 --port 8000
   # OR more production-ready
   gunicorn --bind 127.0.0.1:8000 service_a.api.main:app
   ```

   Then in an other terminal verify response:

   ```bash
   # Multi architecture
   curl http://localhost:8000/service_a/health

   # Single architecture
   curl http://localhost:8000/your_pkg/health
   ```

   You should get `{"status": "ok"}`.


6. Replace this README with one for your actual project.

---

## What's inside

The full layout, conventions, and rationale (why services are siblings, why `models/` is split from `ml_models/`, where databases fit, etc.) are documented in [`docs/`](docs/):

- [`docs/single-service-project-structure.md`](docs/single-service-project-structure.md)
- [`docs/multi-service-project-structure.md`](docs/multi-service-project-structure.md)
- [`docs/research-project-structure.md`](docs/research-project-structure.md)
- [`docs/research-project-structure-short.md`](docs/research-project-structure-short.md)
- [`docs/claude-code-project-structure.md`](docs/claude-code-project-structure.md)

Defaults baked into the bootstraps: Flask + gunicorn, `requirements.txt`, etc.

---

## License

MIT — see [`LICENSE`](LICENSE).
