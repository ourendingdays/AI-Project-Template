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


habits that make Claude Code more reliable in practice:


1---- Don’t turn CLAUDE. md into a giant instruction dump

Use it for stable things: project context, architecture notes, conventions, important commands.

If something is really a repeatable procedure, checklist, or playbook, it usually belongs somewhere else.


2---- Use Plan Mode before bigger changes

For multi-file edits, refactors, or anything slightly messy, it is usually safer to let Claude inspect and plan first before touching code.


3---- Turn repeated prompts into skills

If you keep typing the same “review this,” “debug this,” or “prepare this for deploy” instructions, that is usually a sign the workflow should become reusable instead of rewritten every time.


4---- Use hooks for things that should happen every time

Formatting, validation, guardrails, notifications - anything deterministic is better handled by the system than by hoping the model remembers.


The more useful shift, to me, is moving the right things out of the prompt and into the environment.

That’s where repeated prompting starts turning into structure.

---

## References

- [Anthropic Academy](https://www.anthropic.com/learn)
- [Anthropic courses transformers examples](https://anthropic.skilljar.com)
