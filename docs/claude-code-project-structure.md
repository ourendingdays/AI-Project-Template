# Project Structure — Claude Code

This is the reference document for a Claude Code's project structure for files and folders.
Includes :

    - *.md files
    - .claude/* : 
        - rules
        - commands
        - skills
        - agents
        - hooks  

---

## Overview: Claude Code 

This pattern is for Claude Code projects. It summarizes the main Claude Code's functionalities into a clear structure.

> Throughout this document, `..` is used as the placeholder for the tree overview

## Directory Tree

```
your-project/
├── CLAUDE.md                       # main Claude file 
├── CLAUDE.local.md                 # additional personal commands to Claude
├── .mcp.json                       # template for MCP integration configs 
│
├── .claude/                        # main package — rename to your project name
│   ├── settings.json
│   └── settings.json  
│   ├── rules/                      # modular .md/* files by topic
│   │   ├── code-style.md           # style
│   │   ├── testing.md              # testing
│   ├───└── api-conventions.md      # API design
│   ├── commands/                   # Custom slash commands (/project:name) for repeatable workflows
│   │   ├── review.md               
│   │   └──fix-issue.md
│   ├── skils/                     # auto triggered based on the task context
│   │   └── NAME/
│   │   │  └── SKILL.md
│   ├── agents/                     # Specializd sub-agents with roles
│   │   ├── code-reviewer.md
│   │   └── security-auditor.md
│   ├── hooks/                      # Event-driven scripts (pre/post tool use)
│   │   └── validate-bash.sh
```

---

## What each component does

This section covers the major structural decisions. Differences from the service-oriented patterns are flagged explicitly.

---

## Setting up the project

COMMAND SHEET?


```bash
git clone <your-repo>
cd your-project

python -m venv .venv
source .venv/bin/activate            # macOS/Linux
# .venv\Scripts\activate              # Windows

pip install -r requirements.txt
```

---

## Documentation

- **`README.md`** (root) — what the project is, quick start.
- **`docs/`** — architecture, design notes, decision records.
- **`docs/adr/`** (optional) — Architecture Decision Records as the project grows.

---

## What to do now vs. later

**Now (day 1):**
- Rewrite CLAUDE.md tailored for you
- Add coding rules

**Add when needed:**
- New `subagents` as zou see Claude doing repetitive things over and over again
- `Hooks/` to prevent Claude from reading or changing sensible files

---

## References

- [Anthropic Academy](https://www.anthropic.com/learn)
- [Anthropic courses transformers examples](https://anthropic.skilljar.com)
