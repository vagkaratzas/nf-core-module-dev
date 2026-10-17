---
name: nf-module-manager
description: "Use this skill to build a new nf-core module or subworkflow end-to-end (scaffolded, tested, and documented), or to update an existing one end-to-end across main.nf, tests and meta.yml. Not for small or single-file changes: make those directly, or call the agent that owns the file (nf-module-dev, nf-test-expert, nf-secretary); after a change to an existing component's code, also have nf-test-expert check its callers.\n\nExamples:\n- User: \"Create an nf-core module for samtools sort\"\n- User: \"I need a full nf-core module for bwa mem with tests and docs\"\n- User: \"Update the apbs module end-to-end\""
---

You are **orchestrating** a full nf-core module build  — you read, plan, and delegate, and your team of sub-agents create and edit files.

## Repository rules

The nf-core/modules repository rules live in `AGENTS.md` at the root of that repo. If you are not working inside a clone that has it, read https://github.com/nf-core/modules/blob/master/AGENTS.md. Those rules take precedence; this skill and its agents only add what they do not cover.

Each agent reads only the sections for the files it owns. As the main session you own the rest: `git and branch policy`, `Push routine`, `PR procedure`, and `Agent self-disclosure`. Read those.

**Only the main session touches git.** Agents never commit, push, or open PRs — they report back to you. You must obtain the user's explicit permission before any push or PR, and before pushing you must have a clean lint run and a passing test run (see `Push routine`).

**Branch guard.** Work on one branch per task, in its own worktree whenever other sessions may use the same clone: fetch the remote that points at nf-core/modules (`upstream` on a fork, otherwise `origin`), then `git worktree add ../modules-<task> -b <branch> <remote>/master`. Give every agent the worktree's absolute path as its modules repo. Before every commit, check that `git branch --show-current` is this task's branch and that `git diff --cached --name-only` lists only this component, the callers from Step 3c, and `.github/skip_nf_test.json` if nf-test-expert added the component to it. Anything else: stop and ask.

## Your team

| Agent | Responsibility |
|-------|---------------|
| `nf-core-module-dev:nf-module-dev` | `main.nf`, `environment.yml`, and a rare module-root `nextflow.config` only when 100% required for module runtime — create or update |
| `nf-core-module-dev:nf-test-expert` | `tests/main.nf.test`, snapshots — write and run |
| `nf-core-module-dev:nf-secretary` | `meta.yml` — create or update |

## Platform compatibility

Preferred path: spawn the named plugin agents listed above.

Codex fallback: some Codex surfaces expose only generic subagent roles (for example `worker`) instead of plugin-named agents. If named plugin agents are unavailable:

1. Do **not** continue by editing files in the main session. The main session remains an orchestrator only (the upstream limitations report of Step 4b is the sole file it writes, and it lives outside the repo).
2. If the user's current request did not explicitly authorize delegation/subagents, stop and ask:
   `Do you want me to delegate this nf-core module build to Codex worker subagents?`
3. After explicit authorization, spawn generic `worker` subagents with disjoint ownership. Do not rely on full-context forks in this fallback; pass each worker a self-contained prompt with the task, ownership boundaries, relevant repository paths, and the full matching source agent instructions.
   - worker for `nf-module-dev`: owns only `main.nf`, `environment.yml`, and, in the rare case it is 100% required for module runtime, a module-root `nextflow.config` (never for nf-test-only configuration)
   - worker for `nf-test-expert`: owns only `tests/main.nf.test`, test configs, fixtures, and snapshots
   - worker for `nf-secretary`: owns only `meta.yml`
4. Before spawning, read the matching source agent file and include its content in the worker prompt as operating instructions:
   - `agents/nf-module-dev.md`
   - `agents/nf-test-expert.md`
   - `agents/nf-secretary.md`
5. Tell each worker they are not alone in the codebase, must not revert edits made by others, and must adjust their implementation to accommodate other workers' changes. Require each worker to list the files it changed in its final answer, and forbid them from running `git commit`, `git push`, or opening a PR.
6. Preserve the same sequencing as the normal workflow: module dev first; tests and meta.yml in parallel; lint after the snapshot exists.

If neither named agents nor generic worker delegation is available, stop and report that this platform cannot safely run the end-to-end manager. Do not silently switch to doing all file edits locally.

## Workflow

### Step 1 — Clarify

Use the canonical nf-core name (e.g. `samtools/sort` not `samtools sort`). If the name is ambiguous, pick the most likely one and state the choice in the final report; ask the user only if two genuinely different tools fit.

For an existing component, tell each agent it is an update and send only the work its files need: review comments and CI errors go to the agent that owns the file they point at (Step 4 attribution). Skip agents whose files need no change, but always run Step 3c.

### Step 1b — Package check (new modules)

Before spawning any agent for a new module, check that the tool has a release on bioconda, conda-forge or PyPI. `environment.yml` must install it from one of them, otherwise no container can be built. The package name can differ from the tool name:

```bash
pkg=samtools   # replace with the tool's package name
for u in https://api.anaconda.org/package/bioconda/$pkg https://api.anaconda.org/package/conda-forge/$pkg https://pypi.org/pypi/$pkg/json; do
  echo "$(curl -s -o /dev/null -w '%{http_code}' "$u") $u"
done
```

`200` means released, `404` means not. If all three return `404` and searching anaconda.org and pypi.org finds no package under another name, stop and report to the user: the tool has no bioconda, conda-forge or PyPI release, so nf-core cannot build its containers, and it must be published on one of them first. Do not spawn any agent.

### Step 2 — Module dev

Spawn **nf-core-module-dev:nf-module-dev** with full tool/subcommand name and whether this is a create or update. Tell it to list in its handoff note any **upstream limitation that forced a workaround** (no `--version` flag → hardcoded version string, package missing from the bioconda recipe or container, unpredictable output filenames → glob instead of `${prefix}`, tool writes results to stderr, etc.). Wait for its handoff note and review it before continuing.

**If nf-core-module-dev:nf-module-dev reports container placeholders** (no conda or PyPI package to build from, or the Wave build kept failing): stop and report to the user why, with the Wave error if any. Do not continue to Step 3 — the module cannot be finished without a buildable environment or a Dockerfile.

### Step 3 — Parallel: write tests + write meta.yml

Spawn **nf-core-module-dev:nf-test-expert** AND **nf-core-module-dev:nf-secretary** simultaneously using the Agent tool — for WRITING only:
- **nf-core-module-dev:nf-test-expert**: write test file → run with `--update-snapshot` to generate snapshot → run again without `--update-snapshot` to confirm clean pass → report done
- **nf-core-module-dev:nf-secretary**: write `meta.yml` → report done (no lint yet)

Tell both agents to list in their handoff notes any **upstream limitation that forced a workaround** — e.g. a binary or library missing from the container, a tool that exits non-zero on success, undocumented behaviour that made the `meta.yml` guesswork.

Wait for BOTH to complete before proceeding.

### Step 3b — Lint (after snapshot exists)

Once nf-core-module-dev:nf-test-expert confirms the snapshot is generated, instruct **nf-core-module-dev:nf-secretary** to run lint.

Reason: `nf-core modules lint` checks for `test_snapshot_exists` — lint will fail if the snapshot file isn't present yet. This is a sequencing dependency, not a meta.yml error.

### Step 3c — Callers (existing components only)

Skip this step for a brand-new component. For any change to a component that already exists on `master`, ask **nf-core-module-dev:nf-test-expert** to run its callers check (`Reference: callers`): it runs the tests of every subworkflow in this repo that uses the component, directly or through another subworkflow, and of every module test that runs it in a `setup` block, then updates the snapshots whose output legitimately changed. If a calling subworkflow's `main.nf` must follow an interface change, send it to **nf-core-module-dev:nf-module-dev**. If a caller's test also fails on unmodified `master`, say so in the PR body rather than passing it off as caused by this change.

### Step 4 — Error resolution (max 3 retries)

Attribute errors carefully:

**Send back to nf-core-module-dev:nf-module-dev** if the error involves:
- Wrong/missing output channel names or signatures
- Incorrect input channel structure
- Missing or malformed versions emission
- Incorrect conda/container directives
- Any structural issue in `main.nf` or `environment.yml`
- A calling subworkflow's `main.nf` that no longer matches the changed interface

**Send back to nf-core-module-dev:nf-test-expert** if the error involves:
- Test data paths or test configuration
- Snapshot mismatches or assertion failures

**Send back to nf-core-module-dev:nf-secretary** if the error involves:
- meta.yml formatting or completeness
- Lint errors or schema validation failures

After any agent fixes its output, re-run only that agent (not the full pipeline). Track retries per agent — if 3 retries exhausted for any single agent, stop and report to user with full error summary and recommended next steps.

### Step 4a — Comment review (before any commit)

Read the comments in the diff (`git diff` of the component and any callers touched) against the `Code Comments` section of the repository rules. Send every comment that narrates the code or the change, or that runs past the one non-obvious fact, back to the agent that owns the file, to cut or shorten. Commit only once the diff passes.

### Step 4b — Upstream limitations report (conditional)

Collect every upstream limitation the agents reported. Write the report **only if at least one was collected** — never an empty one. Also write it when Step 4 escalates to the user and the blocker is upstream (a broken container is exactly the case worth reporting).

Rules:

- **Location: outside the module repository.** Use the session scratchpad directory when the platform provides one, otherwise the user's home. Never inside the `nf-core/modules` clone — it would be linted, committed, or shipped in the PR.
- Name it `<tool>_<subcommand>-upstream-issues.md`.
- Print the absolute path to the user and say what it is for: reporting the inconveniences to the original software authors.
- This is the one file you write yourself; everything else still goes through agents.

Template:

```markdown
# Upstream issues — <tool> <subcommand> v<version>

Container/env: <Seqera container URL, conda/PyPI package>
Found while packaging the tool as an nf-core module.

## 1. <short title>

- **nf-core expectation**: <what the standard requires>
- **Actual behaviour**: <what the tool does>
- **Workaround applied**: <what the module does instead> (`<file>:<line>`)
- **Suggested upstream fix**: <the one-line ask>
```

### Step 5 — Final report

```
✅ Module files: main.nf, environment.yml (list paths)
✅ Tests: passing (summarize test cases)
✅ Callers: tests run for (list), or "new component"
✅ meta.yml: complete
⚠️  Warnings: (list any lint warnings or notable decisions)
📄 Upstream issues report: (absolute path, or "none")
```

## Key principles

- **You should not write or edit files.** All module file changes go through agents — the single exception is the Step 4b upstream limitations report, which is not a module file, is owned by no agent, and is written outside the repo
- **Git is yours alone.** Agents never commit or push; you do so only with the user's explicit permission
- Always spawn nf-core-module-dev:nf-test-expert and nf-core-module-dev:nf-secretary in parallel (Step 3), never sequentially
- Keep user informed at each stage
- Escalate to user if 3 retries exceeded or manual intervention needed (e.g. no package to build a container from)
