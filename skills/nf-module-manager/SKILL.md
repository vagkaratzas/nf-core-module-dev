---
name: nf-module-manager
description: "Use this skill when the user wants a complete nf-core module built end-to-end: scaffolded, tested, and documented. Also use when the user wants to update an existing module completely (code + tests + docs).\n\nExamples:\n- User: \"Create an nf-core module for samtools sort\"\n- User: \"I need a full nf-core module for bwa mem with tests and docs\"\n- User: \"Set up the nf-core module structure for trimmomatic trimpe\"\n- User: \"Update the apbs module end-to-end\""
---

You are orchestrating a full nf-core module build. Delegate ALL file writing to the three agents below — never write module files yourself.

## Your team

| Agent | Responsibility |
|-------|---------------|
| `nf-core-module-dev:nf-module-dev` | `main.nf`, `environment.yml` — create or update |
| `nf-core-module-dev:nf-test-expert` | `tests/main.nf.test`, snapshots — write and run |
| `nf-core-module-dev:nf-secretary` | `meta.yml` — create or update |

## Workflow

### Step 1 — Clarify

If tool/subcommand is ambiguous, confirm with user before proceeding (e.g. `samtools/sort` not `samtools sort`).

### Step 2 — Module dev

Spawn **nf-core-module-dev:nf-module-dev** with full tool/subcommand name and whether this is a create or update. Wait for its handoff note and review it before continuing.

**If nf-core-module-dev:nf-module-dev reports unfilled placeholders** (no bioconda env found, container not set): stop immediately, inform the user of exactly which fields need filling and in which files, and wait for user confirmation before proceeding to Step 2b.

### Step 2b — Resume module dev after placeholder fill (conditional)

Only runs if Step 2 was paused for placeholder filling. Once the user confirms the fields are filled, re-spawn **nf-core-module-dev:nf-module-dev** to continue the module creation from where it stopped — populating `main.nf`, and creating `nextflow.config` if needed (steps 5–6 of its Mode A workflow). Wait for its handoff note before proceeding.

### Step 3 — Parallel: write tests + write meta.yml

Spawn **nf-core-module-dev:nf-test-expert** AND **nf-core-module-dev:nf-secretary** simultaneously using the Agent tool — for WRITING only:
- **nf-core-module-dev:nf-test-expert**: write test file → run with `--update-snapshot` to generate snapshot → run again without `--update-snapshot` to confirm clean pass → report done
- **nf-core-module-dev:nf-secretary**: write `meta.yml` → report done (no lint yet)

Wait for BOTH to complete before proceeding.

### Step 3b — Lint (after snapshot exists)

Once nf-core-module-dev:nf-test-expert confirms the snapshot is generated, instruct **nf-core-module-dev:nf-secretary** to run lint.

Reason: `nf-core modules lint` checks for `test_snapshot_exists` — lint will fail if the snapshot file isn't present yet. This is a sequencing dependency, not a meta.yml error.

### Step 4 — Error resolution (max 3 retries)

Attribute errors carefully:

**Send back to nf-core-module-dev:nf-module-dev** if the error involves:
- Wrong/missing output channel names or signatures
- Incorrect input channel structure
- Missing or malformed versions emission
- Incorrect conda/container directives
- Any structural issue in `main.nf` or `environment.yml`

**Send back to nf-core-module-dev:nf-test-expert** if the error involves:
- Test data paths or test configuration
- Snapshot mismatches or assertion failures

**Send back to nf-core-module-dev:nf-secretary** if the error involves:
- meta.yml formatting or completeness
- Lint errors or schema validation failures

After any agent fixes its output, re-run only that agent (not the full pipeline). Track retries per agent — if 3 retries exhausted for any single agent, stop and report to user with full error summary and recommended next steps.

### Step 5 — Final report

```
✅ Module files: main.nf, environment.yml (list paths)
✅ Tests: passing (summarize test cases)
✅ meta.yml: complete
⚠️  Warnings: (list any lint warnings or notable decisions)
```

## Key principles

- Never write module files yourself — always delegate
- Always spawn nf-core-module-dev:nf-test-expert and nf-core-module-dev:nf-secretary in parallel (Step 3), never sequentially
- Keep user informed at each stage
- Escalate to user if 3 retries exceeded or manual intervention needed (e.g. container placeholder)
