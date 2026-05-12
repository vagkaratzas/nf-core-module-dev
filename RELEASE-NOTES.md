# Release Notes

## v1.3.0dev — [unreleased]

### Codex packaging

- added a source-controlled `.codex-plugin/plugin.json` so Codex installs no longer depend on generating the plugin manifest at install time
- kept `.claude-plugin/marketplace.json` as the shared marketplace catalog for both Claude Code and Codex; it now includes Codex-compatible `interface`, `policy`, `category`, and Git URL source metadata
- added `codex/hooks.json` as an explicit no-op Codex lifecycle config so Codex installs do not accidentally load the Claude-only session hook
- updated `codex/install.sh` to copy the committed Codex manifest and no-op hook while still normalizing agent and skill frontmatter for local development installs
- updated install docs to prefer `codex plugin marketplace add vagkaratzas/nf-core-module-dev` plus `/plugins`, with `codex/install.sh` documented as a local development helper
- added `.codex-plugin/plugin.json` to the version bump configuration so Claude and Codex manifests stay in sync
- added a Codex fallback path to `nf-module-manager`: when named plugin agents are unavailable, it must ask for explicit generic-worker delegation, pass each worker a self-contained prompt with the matching source agent instructions, and avoid editing files in the main session

## v1.2.0 — [2026/05/01]

Aligned with the nf-core tools v4.0.2 ruleset.

### `nf-module-dev`

- research step now requires cross-checking official docs **and** the command's `--help` output, with explicit instruction to write down every mandatory + optional input file, every flag, and every possible output (no silent omissions)
- prefer a single input tuple (`tuple val(meta), path(reads), path(reference), ...`) over multiple separate channels — split only when inputs have genuinely different cardinalities
- emitted version string MUST be bare numeric (`1.0.0`) — no `v` prefix, no tool name, no commit hash; strip with `sed`/`awk` inside the `eval`
- added meta-map naming rules (`meta`, `meta2`, `meta3`); only `meta.id` and `meta.single_end` are accepted standard keys; pass extras via `ext.args`
- added `args` / `args2` / `args3` numbering rule for piped tools, by pipe position
- explicit rule to never modify the `when:` block — conditional execution belongs in `process.ext.when` in pipeline config
- prefer compressed output formats (`*.fastq.gz` over `*.fastq`, `*.bam` over `*.sam`) and use UNIX pipes to avoid intermediate writes
- scripts longer than ~20 lines must move to `templates/<module>.<ext>` rather than inline
- stub block for gzipped outputs must use `echo "" | gzip > "${prefix}.txt.gz"` — `touch foo.txt.gz` produces an empty file that breaks downstream parsers
- forced redirection `2>|` instead of `2>` (nf-core enables noclobber)
- hardcoded `val('1.2.3')` fallback documented for tools with no `--version` flag, with required explanatory comment
- consolidated all version-emission rules into a single `## Reference: versions output` section to remove duplication between rules and example

### `nf-test-expert`

- added priority-3 assertion option `path(...).readLines().contains("<expected line>")` between line-count and bare file-existence — keeps a content-level guarantee when full snapshots are unstable
- added singularity-pull failure fallback — when image pull fails, the agent now hands the user the exact `singularity pull ... && mv ...` command (with Nextflow cache-name conventions) instead of silently retrying or working around it
- documented the `params.modules_testdata_base_path` convention for referencing shared test data; `${projectDir}` is now reserved for temporary module-local fixtures
- added empty-output rule — real (non-stub) tests must not snapshot the empty-file MD5 `d41d8cd98f00b204e9800998ecf8427e`; fix the test data or disregard that channel output completely
- explicit "stub test is mandatory" rule — every module needs at least one `options "-stub"` test as the minimum CI safety net
- documented `.github/skip_nf_test.json` (alphabetical) for legitimately unsupported profiles
- clarified that upstream-dependency tags (`mmseqs`, `mmseqs/createdb` etc. for setup-block runs) are mandatory because they cause upstream changes to re-trigger this module's CI

### `nf-secretary`

- workflow now runs `nextflow lint <main.nf>` (strict Nextflow grammar check) before `nf-core modules lint` to catch syntax issues early
- EDAM lookup procedure added — agent must check the built-in table, then grep existing repo `meta.yml` files, then search the EDAM ontology directly, before settling for `ontologies: []`
- EDAM coverage rule made explicit — every file entry, input AND output, gets ontologies populated; no skipping after the first one
- reconciled prior guidance about `--fix`-inserted `ontologies: []` — the agent now treats each as a TODO and runs the lookup procedure before leaving it empty
- added `tools` block requirements — every invoked tool listed individually, with `args_id` matching the `$args` / `$args2` / `$args3` numbering from `main.nf`
- keywords rule strengthened — must cover research domain / data type / function and MUST NOT be solely the (sub)tool name; multi-tool modules add the `multi-tool` keyword plus each component
- input-block rules expanded — tuple inputs split into separate entries, every meta map (`meta`, `meta2`, …) documented individually, each input marked Mandatory or Optional in its description, file `pattern` is Java glob syntax
- documented the `type:` whitelist (`map`, `file`, `directory`, `string`, `boolean`, `integer`, `float`, `list`) — anything else fails schema validation

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
