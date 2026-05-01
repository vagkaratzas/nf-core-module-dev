# Release Notes

## v1.2.0dev — unreleased

- `nf-module-dev`: research step now requires cross-checking official docs **and** the command's `--help` output, with explicit instruction to write down every mandatory + optional input file, every flag, and every possible output (no silent omissions)
- `nf-module-dev`: prefer a single input tuple (`tuple val(meta), path(reads), path(reference), ...`) over multiple separate channels — split only when inputs have genuinely different cardinalities
- `nf-module-dev`: emitted version string MUST be bare numeric (`1.0.0`) — no `v` prefix, no tool name, no commit hash; strip with `sed`/`awk` inside the `eval`
- `nf-module-dev`: added meta-map naming rules (`meta`, `meta2`, `meta3`); only `meta.id` and `meta.single_end` are accepted standard keys; pass extras via `ext.args`
- `nf-module-dev`: added `args` / `args2` / `args3` numbering rule for piped tools, by pipe position
- `nf-module-dev`: explicit rule to never modify the `when:` block — conditional execution belongs in `process.ext.when` in pipeline config
- `nf-module-dev`: prefer compressed output formats (`*.fastq.gz` over `*.fastq`, `*.bam` over `*.sam`) and use UNIX pipes to avoid intermediate writes
- `nf-module-dev`: scripts longer than ~20 lines must move to `templates/<module>.<ext>` rather than inline
- `nf-module-dev`: stub block for gzipped outputs must use `echo "" | gzip > "${prefix}.txt.gz"` — `touch foo.txt.gz` produces an empty file that breaks downstream parsers
- `nf-module-dev`: forced redirection `2>|` instead of `2>` (nf-core enables noclobber)
- `nf-module-dev`: hardcoded `val('1.2.3')` fallback documented for tools with no `--version` flag, with required explanatory comment
- `nf-module-dev`: consolidated all version-emission rules into a single `## Reference: versions output` section to remove duplication between rules and example

## v1.1.0 — [2026/04/17]

- `nf-test-expert`: clarified that `--profile` must use the `+` prefix (e.g. `+singularity`) to append the container profile on top of the base `test` profile, not replace it
- `nf-test-expert`: agent now explicitly asks the user for `NXF_SINGULARITY_CACHEDIR` when using Singularity — no longer risks guessing a wrong default path
- `nf-test-expert`: prefer the smallest meaningful test file; sars-cov-2 data from the `modules` branch of nf-core/test-datasets is now the explicitly recommended first choice
- `nf-test-expert`: all three assertion priority options now explicitly wrap in `snapshot(...).match()`; option 3 (file existence) now also includes the versions `findAll` assertion alongside `.exists()`
- `nf-test-expert`: added explicit rule that `process.out.findAll { key, val -> key.startsWith("versions") }` is the only correct way to assert versions when `snapshot(sanitizeOutput(process.out)).match()` is not working
- `nf-module-dev`: added explicit container directive rules — look up the matching tag at `quay.io/repository/biocontainers/<package>?tab=tags` when the package is on Bioconda; in any other case leave placeholders and ask the user — never generate Wave containers
- `nf-module-manager`: hardened the no-file-editing rule — the orchestrator is now explicitly forbidden from editing any file regardless of how trivial the change; all edits must be delegated to the appropriate agent
- **Codex support**: Codex can now be installed via `codex/install.sh` (Linux/macOS; Windows requires WSL or Git Bash), which generates `.codex-plugin/plugin.json` at install time and installs a normalized local plugin copy.

## v1.0.0 — [2026/04/15] — Initial release

First public release of the nf-core-module-dev Claude Code plugin.

- `nf-module-dev` agent: creates and updates `main.nf` and `environment.yml`
- `nf-test-expert` agent: writes nf-tests and generates snapshots
- `nf-secretary` agent: creates and lints `meta.yml`
- `nf-module-manager` skill: end-to-end orchestration of all three agents
- Session-start bootstrap via `using-nf-core-module-dev` skill
