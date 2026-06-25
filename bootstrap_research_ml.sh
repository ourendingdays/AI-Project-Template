#!/usr/bin/env bash
# bootstrap_research_ml.sh — Create the ml-research project skeleton.
# Run from the repo root. Idempotent: safe to re-run.

set -euo pipefail

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
EOF

# --- Main package ---
mkdir -p src/{processing,training,evaluation}

# __init__.py files
touch src/__init__.py
for sub in processing training evaluation; do
  touch src/$sub/__init__.py
done

# A minimal core/base_model.py
cat > src/processing/data_analyser.py <<'EOF'
"""Analyse Data"""
from abc import ABC, abstractmethod


class Analyser(ABC):
    """Abstract base class. All concrete clients inherit from this."""

    @abstractmethod
    def complete(self, prompt: str, **kwargs) -> str:
        """Send a prompt, return the completion text."""
        ...
EOF

cat > src/processing/processor.py <<'EOF'
"""Processor class"""
from abc import ABC, abstractmethod


class Processor(ABC):
    """Abstract base class. All concrete processors inherit from this."""

    @abstractmethod
    def train(self, data: str, **kwargs) -> None:
        """Train the model on the given data."""
        pass
EOF


# Trainer
cat > src/training/train.py <<'EOF'
"""Trainer class"""
from abc import ABC, abstractmethod

class Trainer(ABC):
    """Abstract base class. All concrete trainers inherit from this."""

    @abstractmethod
    def train(self, data: str, **kwargs) -> None:
        """Train the model on the given data."""
        pass
EOF

# Evaluate template
cat > src/evaluation/metrics.py <<'EOF'
"""Evaluation metrics"""
from abc import ABC, abstractmethod

class Evaluator(ABC):
    """Abstract base class. All concrete evaluators inherit from this."""

    @abstractmethod
    def evaluate(self, predictions: list[str], references: list[str], **kwargs) -> dict:
        """Evaluate predictions against references and return metrics."""
        pass
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
mkdir -p data/{raw,train,test}
for sub in raw train test ; do
  touch data/$sub/.gitkeep
done

cat > data/README.md <<'EOF'
# Data

**All contents are gitignored** — only the structure and this README are tracked.

- `raw/` — immutable original data, never edited
- `train/` — intermediate processing artifacts
- `test/` — final data fed into models
EOF

# --- models/ ---
mkdir -p models
touch models/.gitkeep
cat > models/README.md <<'EOF'
# Models

Trained model artifacts (weights, checkpoints, fine-tuned models). **Gitignored.**

When local files outgrow useful, point this at a model registry (W&B, MLflow, Hugging Face Hub) or a versioned cloud bucket.
EOF


echo "✅ ML-research project skeleton created."
echo ""
echo "Next steps:"
echo "  python -m venv venv && source venv/bin/activate"
