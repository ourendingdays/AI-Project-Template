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
│   ├── agents/                     # Specializd sub-agents with roles
│   │   └── code-reviewer.md
│   ├── commands/                   # Custom slash commands (/project:name) for repeatable workflows
│   │   ├── review.md               
│   │   └── audit-dependencies.md
│   ├── hooks/                      # Event-driven scripts (pre/post tool use)
│   │   └── validate-bash.sh
│   ├── rules/                      # modular .md/* files by topic
│   │   ├── code-style.md           # style
│   │   ├── testing.md              # testing
│   ├───└── api-conventions.md      # API design
│   ├── skils/                     # auto triggered based on the task context
│   │   └── code-review/
│   │   │  └── SKILL.md
```

---

## Documentation

More information on Claude Code can be found in this [cheat sheet](https://gist.github.com/ourendingdays/3e6856460d003fda7ec12b0a1fb3fbd6#file-claude-code-cheat-sheet-md)
---

## What to do now vs. later

- Rewrite CLAUDE.md tailored for you
- Add new `subagents` as you see Claude doing repetitive things over and over again
- `Hooks/` to prevent Claude from reading or changing sensible files
- Add Skills as you see fit

---

## References

- [Anthropic Academy](https://www.anthropic.com/learn)
- [Anthropic courses transformers examples](https://anthropic.skilljar.com)
