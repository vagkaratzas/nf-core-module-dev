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
├── hooks/
│   └── hooks.json               ← injects bootstrap skill at session start
└── codex/
    ├── INSTALL.md               ← Codex install guide
    ├── install.sh               ← writes normalized copies into ~/.codex/skills/<skill>/SKILL.md
    └── uninstall.sh
```

## Multi-platform support

- **Claude Code** is the primary target: full plugin with agents, skills, and hooks.
- **Codex** now has a repo-root manifest at `.codex-plugin/plugin.json` that points at the shared `agents/`, and `skills/` directories for store-based installation. The legacy `codex/install.sh` path remains as a fallback local install and still normalizes frontmatter for environments that need it.

Agents must remain self-contained — no cross-agent calls in their content — so they work standalone on Codex.

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

`.claude-plugin/plugin.json` follows the Claude Code plugin schema. Both `plugin.json` and `marketplace.json` must stay in sync — use the bump script:

```bash
# Check current versions are in sync
scripts/bump-version.sh --check

# Bump to a new version (updates both files atomically)
scripts/bump-version.sh 1.1.0
```

## Hook

`hooks/session-start` reads `skills/using-nf-core-module-dev/SKILL.md` and injects it into the session context via `hookSpecificOutput.additionalContext`. `hooks/run-hook.cmd` is a cross-platform wrapper (Unix + Windows), and `hooks/hooks.json` now invokes it via a repo-relative path so the shared hook config is not tied to Claude-specific environment variables.
