# AGENTS.md

This file is the source of truth for coding agents working inside this repository. `CLAUDE.md` only points here.

## What this repo is

The **nf-core-module-dev** plugin — agents and skills for creating, testing, and documenting nf-core Nextflow modules. It targets Claude Code and Codex.

Claude Code installation:

```bash
claude plugin marketplace add vagkaratzas/nf-core-module-dev
claude plugin install nf-core-module-dev@vagkaratzas
```

## Structure

```
agents/          ← three specialist agents (source of truth for both platforms)
skills/          ← nf-module-manager orchestrator + session bootstrap
hooks/           ← Claude Code session-start hook
codex/           ← local Codex install helper + Codex-specific no-op hooks
.claude-plugin/  ← Claude Code plugin manifest + shared marketplace catalog
.codex-plugin/   ← Codex plugin manifest
```

Expanded layout:

```
nf-core-module-dev/
├── .claude-plugin/plugin.json   ← Claude Code plugin manifest
├── .claude-plugin/marketplace.json ← shared marketplace catalog used by Claude and Codex
├── .codex-plugin/plugin.json    ← Codex plugin manifest
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
│   └── hooks.json               ← injects bootstrap skill at session start for Claude
└── codex/
    ├── INSTALL.md               ← Codex install guide
    ├── hooks.json               ← no-op lifecycle config for Codex installs
    ├── install.sh               ← installs a normalized local copy for development
    └── uninstall.sh
```

## Agent responsibilities

| Agent | Owns | Never touches |
|-------|------|---------------|
| `nf-module-dev` | `main.nf`, `environment.yml` | tests, meta.yml |
| `nf-test-expert` | `tests/main.nf.test`, snapshots | main.nf, meta.yml |
| `nf-secretary` | `meta.yml` | main.nf, tests |
| `nf-module-manager` skill | orchestration only | all file writes |

## Agent file structure

Each agent `.md` file has three zones:

1. **Frontmatter** — `name`, `description`, `model`, `color` (and sometimes `tools`; no `memory` field because it is not a real Claude Code field)
2. **Workflow** — step-by-step process
3. **Reference sections** — stable domain knowledge embedded directly (style patterns, conventions, lookup tables)
4. **Runtime memory** — instructions to write session findings to `~/.claude/agent-memory/<name>/`

The reference sections replace the old `agent-memory/` directory. When a runtime-discovered pattern stabilizes, it gets PRed back into the agent file.

## Multi-platform support

- **Claude Code**: full plugin with agents, skills, and session hook through the Claude marketplace.
- **Codex**: uses the shared marketplace catalog in `.claude-plugin/marketplace.json` plus the source-controlled Codex manifest in `.codex-plugin/plugin.json`. `codex/install.sh` remains a local development helper that copies normalized agents and skills into Codex's local plugin cache.

Agents must remain self-contained so they work standalone on Codex.

## Cross-platform rules — do not break these

1. **Agents must be self-contained.** No cross-agent calls in the agent body — agents run standalone on Codex without an orchestrator.
2. **Keep Claude-Code-specific frontmatter in `agents/*.md`** (`tools`, `model`, `color`). The `codex/install.sh` local helper strips them at install time. Do NOT remove them from the source files.
3. **`nf-module-manager` dispatches agents by name** (`nf-core-module-dev:nf-module-dev` etc.). Both Claude Code and Codex interpret this format; do not replace it with platform-specific tool syntax.
4. **The shared marketplace catalog lives in `.claude-plugin/marketplace.json`.** Codex can read Claude-style marketplace catalogs, so do not duplicate it under `.agents/plugins/marketplace.json` unless there is a concrete Codex-only marketplace requirement.
5. **Codex's plugin manifest lives in `.codex-plugin/plugin.json`.** Only `plugin.json` belongs in `.codex-plugin/`; Codex-specific support files belong elsewhere.

## Installing for Codex

Codex users can add this repository as a marketplace:

```bash
codex plugin marketplace add vagkaratzas/nf-core-module-dev
```

Then install `nf-core-module-dev` from `/plugins`. For local development, run `./codex/install.sh` from a local clone, then restart Codex. Re-run the installer after `git pull`. See `codex/INSTALL.md` for full details.

## Adding or updating knowledge

- Edit the relevant `## Reference: ...` section in the agent file directly
- For `nf-secretary`: EDAM ontology terms, lint rules, YAML conventions
- For `nf-test-expert`: assertion patterns, known non-deterministic outputs, pitfalls
- For `nf-module-dev`: main.nf style rules, resource label conventions

No separate memory files — reference knowledge lives in the agent.

## Path placeholders

Agent files use `<modules_repo>` and `<singularity_cache>` as placeholders for paths that vary per user. Agents ask the user for these values if not already known.

## Plugin manifests

`.claude-plugin/plugin.json` follows the Claude Code plugin schema. `.codex-plugin/plugin.json` follows the Codex plugin schema. The shared marketplace catalog stays in `.claude-plugin/marketplace.json` because both Claude and Codex can read it.

All version fields must stay in sync — use the bump script:

```bash
# Check current versions are in sync
scripts/bump-version.sh --check

# Bump to a new version
scripts/bump-version.sh 1.1.0
```

## Hooks

`hooks/session-start` reads `skills/using-nf-core-module-dev/SKILL.md` and injects it into the session context via `hookSpecificOutput.additionalContext`. `hooks/run-hook.cmd` is a cross-platform wrapper (Unix + Windows), and `hooks/hooks.json` invokes it via a repo-relative path so the shared hook config is not tied to Claude-specific environment variables.

Codex installs use `codex/hooks.json` as an explicit no-op lifecycle config so Codex does not accidentally load the Claude-only `hooks/hooks.json`.
