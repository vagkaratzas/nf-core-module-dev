# Release Notes

## v1.1.0 — Unreleased

- `nf-test-expert`: clarified that `--profile` must use the `+` prefix (e.g. `+singularity`) to append the container profile on top of the base `test` profile, not replace it
- `nf-test-expert`: agent now explicitly asks the user for `NXF_SINGULARITY_CACHEDIR` when using Singularity — no longer risks guessing a wrong default path
- `nf-test-expert`: prefer the smallest meaningful test file; sars-cov-2 data from the `modules` branch of nf-core/test-datasets is now the explicitly recommended first choice
- `nf-module-dev`: added explicit container directive rules — look up the matching tag at `quay.io/repository/biocontainers/<package>?tab=tags` when the package is on Bioconda; in any other case leave placeholders and ask the user — never generate Wave containers
- `nf-module-manager`: hardened the no-file-editing rule — the orchestrator is now explicitly forbidden from editing any file regardless of how trivial the change; all edits must be delegated to the appropriate agent
- **Codex support**: Codex can now be installed via `codex/install.sh`, which generates `.codex-plugin/plugin.json` at install time and installs a normalized local plugin copy.

## v1.0.0 — [2026/04/15] — Initial release

First public release of the nf-core-module-dev Claude Code plugin.

- `nf-module-dev` agent: creates and updates `main.nf` and `environment.yml`
- `nf-test-expert` agent: writes nf-tests and generates snapshots
- `nf-secretary` agent: creates and lints `meta.yml`
- `nf-module-manager` skill: end-to-end orchestration of all three agents
- Session-start bootstrap via `using-nf-core-module-dev` skill
