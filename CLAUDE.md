# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repo stores agent definitions and their persistent memory for nf-core Nextflow module development. Agents are Markdown files with YAML frontmatter that Claude Code loads as specialized subagents.

## Structure

```
agents/           — Agent definition files (*.md)
agent-memory/     — Persistent memory directories, one per agent
  nf-module-dev/  — MEMORY.md (style patterns, resource labels, tool-specific notes)
  nf-module-manager/ — MEMORY.md (orchestration rules, retry triggers)
  nf-secretary/   — MEMORY.md + patterns.md (meta.yml conventions, lint rules, EDAM ontologies)
  nf-test-expert/ — MEMORY.md + patterns.md (test style, assertion priorities, known pitfalls)
```

Agent memory under `agent-memory/` is separate from the user's personal memory at `~/.claude/agent-memory/` — those are symlinked or referenced by agents at runtime.

## Agent Responsibilities

| Agent | Files it owns | Does NOT touch |
|-------|--------------|----------------|
| `nf-module-dev` | `main.nf`, `environment.yml` | tests, meta.yml |
| `nf-test-expert` | `tests/main.nf.test`, snapshots | main.nf, meta.yml |
| `nf-secretary` | `meta.yml` | main.nf, tests |
| `nf-module-manager` | Orchestrator only — never writes files | everything |

## Agent Frontmatter Fields

Standard fields in agent `.md` files:
- `name`: agent identifier used in Claude Code's Agent tool `subagent_type`
- `description`: trigger condition shown in the Agent tool selector (multi-line strings use `"..."`)
- `model`: `sonnet` | `opus` | `haiku`
- `color`: display color in the UI
- `memory`: `user` — agents read user-level memory on startup

## Editing Agents

When editing an agent definition:
- The `description` field drives when Claude Code auto-selects the agent — keep it precise with concrete examples
- Startup calibration blocks (reading recent modules by @vagkaratzas) are intentional — do not remove them; they keep agents aligned with current community style
- Memory paths in agent files point to `~/.claude/agent-memory/<agent-name>/` — these are the live runtime memory locations, not this repo's `agent-memory/` directory

## Memory Files

`MEMORY.md` in each `agent-memory/` directory is an index (≤200 lines). Detail lives in `patterns.md`.

When updating memory:
- Keep `MEMORY.md` as a quick-reference index
- Put verbose patterns, examples, and edge cases in `patterns.md`
- Remove stale entries rather than appending contradictions

## Key External Paths (referenced by agents)

- Modules repo: `/home/vangelis/Desktop/Projects/modules`
- Module files: `modules/nf-core/<tool>/<subcommand>/`
- Singularity cache: `/home/vangelis/Desktop/Tools/singularity`
- nf-test config: `/home/vangelis/Desktop/Projects/modules/tests/config/nf-test.config`
- nf-core CLI: `/home/vangelis/miniconda3/bin/nf-core` (version 3.5.2)

## nf-test Commands

```bash
# Always set before running nf-test
export NXF_SINGULARITY_CACHEDIR="/home/vangelis/Desktop/Tools/singularity"

# Run all tests for a module
nf-test test /path/to/main.nf.test --profile +singularity --verbose

# Run a single test by name
nf-test test /path/to/main.nf.test --profile +singularity --verbose --tag "<test_name>"

# Run with snapshot update
nf-test test /path/to/main.nf.test --profile +singularity --verbose --update-snapshot
```

## nf-core Commands

```bash
# Scaffold a new module
cd /home/vangelis/Desktop/Projects/modules
nf-core modules create <tool/subcommand> --empty-template

# Lint a module
nf-core modules lint <tool/subcommand>

# Lint and auto-fix meta.yml
nf-core modules lint <tool/subcommand> --fix
```
