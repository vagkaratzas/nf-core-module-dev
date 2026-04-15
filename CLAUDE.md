# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is the **nf-core-module-dev** Claude Code plugin — a set of agents and skills for creating, testing, and documenting nf-core Nextflow modules. It is modelled on the superpowers plugin structure and installable via:

```bash
claude plugin marketplace add vagkaratzas/nf-core-module-dev
claude plugin install nf-core-module-dev@vagkaratzas
```

## Structure

```
nf-core-module-dev/
├── .claude-plugin/plugin.json   ← plugin manifest (name, version, author)
├── agents/
│   ├── nf-module-dev.md         ← creates/updates main.nf + environment.yml
│   ├── nf-test-expert.md        ← writes and runs nf-tests + snapshots
│   └── nf-secretary.md          ← writes and lints meta.yml
├── skills/
│   ├── nf-module-manager/
│   │   └── SKILL.md             ← end-to-end orchestration workflow
│   └── using-nf-core-module-dev/
│       └── SKILL.md             ← session-start bootstrap
└── hooks/
    └── hooks.json               ← injects bootstrap skill at session start
```

## Agent and skill responsibilities

| Component | Owns | Never touches |
|-----------|------|---------------|
| `nf-module-dev` agent | `main.nf`, `environment.yml` | tests, meta.yml |
| `nf-test-expert` agent | `tests/main.nf.test`, snapshots | main.nf, meta.yml |
| `nf-secretary` agent | `meta.yml` | main.nf, tests |
| `nf-module-manager` skill | Orchestration only — never writes files | everything |

## Agent file structure

Each agent `.md` file has three zones:
1. **Frontmatter** — `name`, `description`, `model`, `color` (no `memory` field — not a real Claude Code field)
2. **Workflow** — step-by-step process
3. **Reference sections** — stable domain knowledge embedded directly (style patterns, conventions, lookup tables)
4. **Runtime memory** — instructions to write session findings to `~/.claude/agent-memory/<name>/`

The reference sections replace the old `agent-memory/` directory. When a runtime-discovered pattern stabilises, it gets PRed back into the agent file.

## Adding or updating knowledge

- Edit the relevant `## Reference: ...` section in the agent file directly
- For nf-secretary: EDAM ontology terms, lint rules, YAML conventions
- For nf-test-expert: assertion patterns, known non-deterministic outputs, pitfalls
- For nf-module-dev: main.nf style rules, resource label conventions

## Path placeholders

Agent files use `<modules_repo>` and `<singularity_cache>` as placeholders for paths that vary per user. Agents ask the user for these values if not already known.

## Plugin manifest

`.claude-plugin/plugin.json` follows the Claude Code plugin schema. Version should be bumped on any meaningful change before pushing.

## Hook

`hooks/session-start` reads `skills/using-nf-core-module-dev/SKILL.md` and injects it into the session context via `hookSpecificOutput.additionalContext`. `hooks/run-hook.cmd` is a cross-platform wrapper (Unix + Windows).
