# nf-core-module-dev

A Claude Code plugin that gives your coding agent specialised skills for creating, testing, and documenting [nf-core](https://nf-co.re) Nextflow modules.

## How it works

When you ask Claude to build an nf-core module, it doesn't just start writing code. The `nf-module-manager` skill orchestrates a structured pipeline:

1. It delegates `main.nf` and `environment.yml` to **nf-module-dev**, which researches the tool, scaffolds the module, and populates it following current nf-core conventions.
2. It then launches **nf-test-expert** and **nf-secretary** in parallel — one writes and runs the nf-tests, the other writes the `meta.yml`.
3. Once the snapshot exists, the meta.yml is linted. Errors are routed back to the right agent automatically (up to 3 retries per agent).
4. You get a final report: module files, test results, lint status, and any warnings.

Each agent is a specialist:

| Agent | Responsibility |
|-------|---------------|
| `nf-module-dev` | `main.nf`, `environment.yml` |
| `nf-test-expert` | nf-tests, snapshots |
| `nf-secretary` | `meta.yml`, linting |

Because the `nf-module-manager` runs as a **skill** in your main session (not a hidden sub-agent), you can watch every step as it happens.

## Installation

### Claude Code

```bash
claude plugin marketplace add vagkaratzas/nf-core-module-dev
claude plugin install nf-core-module-dev@vagkaratzas
```

Then start a new session. The plugin bootstraps automatically — you get the full experience: the three specialists plus the `nf-module-manager` orchestrator.

### Codex

Codex support now lives in `.codex-plugin/plugin.json` and points at the shared repo-root `agents/`, and `skills/` directories, so plugin stores can target the repository root directly.

For local installs or environments that cannot consume the repo directly, the legacy fallback is still available:

```bash
git clone https://github.com/vagkaratzas/nf-core-module-dev.git ~/.codex/nf-core-module-dev
cd ~/.codex/nf-core-module-dev
./codex/install.sh
```

Restart Codex (full quit). The full plugin is available: all three specialist agents plus `nf-module-manager` skill. Re-run `install.sh` after `git pull` to update when using the fallback flow. See [`codex/INSTALL.md`](codex/INSTALL.md) for details and uninstall instructions.

## Usage

For a complete end-to-end module build, just describe what you want:

> "Create an nf-core module for `bwa-mem2 mem`"

Claude will invoke the `nf-module-manager` skill and orchestrate the full pipeline.

For targeted work, agents can be invoked directly:

> "Write an nf-test for the `clipkit` module"  
> "Fix the meta.yml lint errors in `samtools/sort`"  
> "Update `eggnogmapper` to the latest bioconda version"

## What's inside

### Skills
- **nf-module-manager** — end-to-end module orchestration with parallel agents and automatic error attribution
- **using-nf-core-module-dev** — session-start bootstrap that tells Claude when to reach for each agent

### Agents
- **nf-module-dev** — researches tools, scaffolds modules, populates `main.nf` and `environment.yml` following current nf-core style. Stops and waits for you if a bioconda/container environment can't be auto-detected.
- **nf-test-expert** — writes nf-tests calibrated to current community style, generates and verifies snapshots, supports singularity/docker/conda profiles
- **nf-secretary** — writes and lints `meta.yml`, handles topic-based versions, EDAM ontologies, and all known schema edge cases

## Requirements

- [Claude Code](https://claude.ai/code)
- A local clone of [nf-core/modules](https://github.com/nf-core/modules)
- `nf-core` CLI installed and on your PATH
- `nf-test` installed and on your PATH
- Singularity, Docker, or conda for running tests

## Contributing

Agents carry their domain knowledge as embedded reference sections — no separate memory files. To contribute a fix or new pattern:

1. Fork the repository
2. Edit the relevant `## Reference: ...` section in the agent `.md` file
3. Submit a PR

## Releasing

Version numbers are kept in sync across `plugin.json` and `marketplace.json` using the included bump script:

```bash
# Check versions are in sync
scripts/bump-version.sh --check

# Bump to a new version
scripts/bump-version.sh 1.1.0

## License

MIT
