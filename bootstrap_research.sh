#!/usr/bin/env bash
# bootstrap_research.sh — Create the library/research project skeleton.
# Run from the repo root. Idempotent: safe to re-run.

set -euo pipefail

# Choose your package name. This is what `from <name>.something import ...` will look like.
# Replace 'app' with your real project name (lowercase, no hyphens) before running,
# or run as-is and rename later with `grep -rl 'app' . | xargs sed -i 's/app/<newname>/g'`.
PKG=app

# --- Top-level files ---

cat > .gitignore <<'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/

# Virtual environments
.venv/
venv/
env/

# Environment files (NEVER commit secrets)
.env
.env.local
.env.*.local
!.env.example

# Editor/IDE
.vscode/
.idea/
*.swp
.DS_Store

# Data and model artifacts (large, generated, or sensitive)
data/raw/*
data/interim/*
data/processed/*
data/cache/*
data/embeddings/*
data/vectordb/*
!data/**/.gitkeep
!data/README.md

models/*
!models/.gitkeep
!models/README.md

# Notebooks
.ipynb_checkpoints/

# Logs
*.log
EOF

cat > .env.example <<'EOF'
# Copy this file to .env and fill in real values. NEVER commit .env.

# --- External APIs ---
ANTHROPIC_API_KEY=
OPENAI_API_KEY=

# --- App config ---
LOG_LEVEL=INFO
EOF

cat > requirements.txt <<'EOF'
# Python dependencies for the project.
datasets>=2.20
matplotlib>=3.11.0
numpy>=1.26
pandas>=3.0.3
pydantic>=2.0
pydantic-settings>=2.0
scikit-learn>=1.9.0
torch>=2.4
transformers>=4.40

# AI Agents (uncomment as needed)
# anthropic>=0.40
# openai>=1.0

# Vector stores (pick one when adding RAG)
# faiss-cpu
# chromadb
# qdrant-client

# Testing / lint
pytest>=8.0
ruff>=0.6
EOF

cat > Dockerfile <<'EOF'
# For reproducibility, not production deployment.
FROM python:3.12-slim
WORKDIR /workspace
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["bash"]
EOF

cat > docker-compose.yml <<'EOF'
# For local development — runs the project in a reproducible container.
services:
  app:
    build: .
    volumes:
      - .:/workspace
    env_file:
      - .env
    # Override the CMD to run specific scripts:
    #   docker compose run --rm app python -m app.training.train
EOF

# --- Main package ---
mkdir -p $PKG/{core,prompts,rag,processing,inference,training,evaluation,config}
mkdir -p $PKG/core/clients

# __init__.py files
touch $PKG/__init__.py
for sub in core prompts rag processing inference training evaluation config; do
  touch $PKG/$sub/__init__.py
done
touch $PKG/core/clients/__init__.py

# A minimal core/base_model.py
cat > $PKG/core/base_model.py <<'EOF'
"""Common interface for all LLM clients."""
from abc import ABC, abstractmethod


class BaseLLM(ABC):
    """Abstract base class. All concrete clients inherit from this."""

    @abstractmethod
    def complete(self, prompt: str, **kwargs) -> str:
        """Send a prompt, return the completion text."""
        ...
EOF

# A minimal config/settings.py
cat > $PKG/config/settings.py <<'EOF'
"""App configuration loaded from environment variables."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")

    anthropic_api_key: str = ""
    openai_api_key: str = ""
    log_level: str = "INFO"


settings = Settings()
EOF

# Stub clients
cat > $PKG/core/clients/anthropic.py <<'EOF'
"""Anthropic client wrapper. Stub — fill in when needed."""
from app.core.base_model import BaseLLM


class AnthropicClient(BaseLLM):
    def complete(self, prompt: str, **kwargs) -> str:
        raise NotImplementedError("Wire up the Anthropic SDK here.")
EOF

# Stub prompt template
cat > $PKG/prompts/templates.py <<'EOF'
"""Prompt templates. Fill in as the project grows."""

SYSTEM_PROMPT = "You are a helpful assistant."
EOF

# --- experiments/ ---
mkdir -p experiments
cat > experiments/exp_001.yaml <<'EOF'
# Example experiment config. Replace with real hyperparameters.
name: exp_001
model: claude-sonnet-4-6
temperature: 0.7
max_tokens: 1024
EOF

# --- notebooks/ ---
mkdir -p notebooks
touch notebooks/.gitkeep
cat > notebooks/README.md <<'EOF'
# Notebooks

Exploration only — not source of truth.

When code stabilizes here, move it into a proper module under `app/<capability>/`. The notebook becomes a record of how you got there.
EOF

# --- data/ ---
mkdir -p data/{raw,interim,processed,cache,embeddings,vectordb}
for sub in raw interim processed cache embeddings vectordb; do
  touch data/$sub/.gitkeep
done

cat > data/README.md <<'EOF'
# Data

**All contents are gitignored** — only the structure and this README are tracked.

- `raw/` — immutable original data, never edited
- `interim/` — intermediate processing artifacts
- `processed/` — final data fed into models
- `cache/` — cached computations
- `embeddings/` — generated vector embeddings
- `vectordb/` — vector database files
EOF

# --- models/ ---
mkdir -p models
touch models/.gitkeep
cat > models/README.md <<'EOF'
# Models

Trained model artifacts (weights, checkpoints, fine-tuned models). **Gitignored.**

When local files outgrow useful, point this at a model registry (W&B, MLflow, Hugging Face Hub) or a versioned cloud bucket.
EOF

# --- tests/ ---
mkdir -p tests/{unit,integration}
touch tests/__init__.py
touch tests/unit/__init__.py
touch tests/integration/__init__.py

cat > tests/unit/test_settings.py <<'EOF'
"""Sanity check that settings load without errors."""
from app.config.settings import Settings


def test_settings_load() -> None:
    s = Settings()
    assert s.log_level == "INFO"
EOF

# --- scripts/ ---
mkdir -p scripts
cat > scripts/setup_env.sh <<'EOF'
#!/usr/bin/env bash
# Sets up a fresh venv with all dependencies. Run once per machine.
set -euo pipefail
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
echo "✅ Environment ready. Activate with: source .venv/bin/activate"
EOF
chmod +x scripts/setup_env.sh

cat > scripts/build_embeddings.py <<'EOF'
"""Stub: build embeddings from data/processed/ and save to data/embeddings/.

Run with: python scripts/build_embeddings.py
"""

def main() -> None:
    raise NotImplementedError("Wire up embedding generation here.")


if __name__ == "__main__":
    main()
EOF

# --- docs/ ---
mkdir -p docs
[ ! -f docs/architecture.md ] && cat > docs/architecture.md <<'EOF'
# Architecture

High-level notes for this project. Fill in:

- What the project does
- Major components and their responsibilities
- External dependencies (APIs, databases, vector stores)
- Data flow
EOF

echo "✅ Library/research project skeleton created."
echo ""
echo "Package name: '$PKG'"
echo ""
echo "Next steps:"
echo "  1. Rename '$PKG' to your real package name if desired:"
echo "       mv $PKG <newname>"
echo "       grep -rl '$PKG' . | xargs sed -i 's/$PKG/<newname>/g'"
echo "  2. python -m venv .venv && source .venv/bin/activate"
echo "  3. pip install -r requirements.txt"
echo "  4. Run a test:"
echo "       pytest tests/unit/"
echo "  5. Run a script:"
echo "       python -m $PKG.config.settings"
echo "  6. Review docs/project-structure.md for the full pattern."
