# AGENTS.md

This file is loaded by Codex and other AGENTS.md-aware CLIs when working inside this repository.

## What this repo is

The **nf-core-module-dev** plugin — agents and skills for creating, testing, and documenting nf-core Nextflow modules. It targets both Claude Code (primary) and Codex.

## Structure

```
agents/          ← three specialist agents (source of truth for both platforms)
skills/          ← nf-module-manager orchestrator + session bootstrap
codex/           ← local Codex install helper + Codex-specific no-op hooks
.claude-plugin/  ← Claude Code plugin manifest
.codex-plugin/   ← Codex plugin manifest
```

## Agent responsibilities

| Agent | Owns | Never touches |
|-------|------|---------------|
| `nf-module-dev` | `main.nf`, `environment.yml` | tests, meta.yml |
| `nf-test-expert` | `tests/main.nf.test`, snapshots | main.nf, meta.yml |
| `nf-secretary` | `meta.yml` | main.nf, tests |

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

## Adding knowledge

Edit the relevant `## Reference: ...` section in the agent `.md` file directly. No separate memory files — reference knowledge lives in the agent.
