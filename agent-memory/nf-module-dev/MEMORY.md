# nf-module-dev Agent Memory

## Style patterns (confirmed across modules, Feb 2026)

- Variables used in `output:` block globs (e.g. `prefix`, `out_extension`) MUST be process-scoped (bare assignment, no `def`) — the linter enforces this
- Variables only used inside the script heredoc (e.g. `args`, `comp_flag`) should use `def`
- `stub` block: redeclare `prefix` and derived output vars as bare (no `def`); use `def` for `args` and flag intermediates
- `stub` block: `echo "$args"` after `touch` commands when args are declared
- Optional file path inputs use `path optional_file` in input channel; conditional use: `def flag = optional_file ? "-x ${optional_file}" : ''`
- Optional outputs use `, optional: true, emit: name` syntax
- **Versions output (new standard, Mar 2026)**: Use eval tuple — NO `cat <<-END_VERSIONS` heredoc. Pattern:
  ```nextflow
  tuple val("${task.process}"), val('toolname'), eval("tool --version 2>&1 | sed 's/tool //'"), topic: versions, emit: versions_toolname
  ```
  Note: `topic: versions` — NO quotes around `versions` (unlike the string `'versions'` in old path-based approach).
- **meta.yml sync**: After adding `path auxiliary_file` (or any new path input), `nf-core modules lint --fix` will add `auxiliary_file: {}` (empty). Must manually fill in `type`, `description`, `pattern`, `ontologies: []` — the schema rejects empty `{}` entries.

## Resource label conventions

- `process_single`: single-threaded tools, lightweight (e.g. clipkit, wittyer)
- `process_low`: fast multi-cpu tools
- `process_medium`: standard bioinformatics tools
- `process_high`: memory/cpu intensive (e.g. eggnogmapper, yahs)
- Multiple labels allowed: `label 'process_medium'` + `label 'process_long'` for long-running medium-cpu tools


## clipkit-specific notes

- `-l/--log` is a boolean `store_true` flag — creates `<output_file>.log` (e.g. `${prefix}.${out_extension}.log`)
- `-c/--complementary` is a boolean `store_true` flag — creates `<output_file>.complement`
- Do NOT use stdout redirect for the log; `-l` writes the file automatically
- `-a/--auxiliary_file` takes a file path — for `cst` mode only
- `-of/--output_file_format` specifies format (fasta, phylip, etc.) — not the file extension per se
- Output file naming: `${prefix}.${out_extension}` where `out_extension` defaults to "clipkit"
- `complementary` (`-c`) is NOT a channel input — users pass it via `ext.args` from external config
- `auxiliary_file` is a `path` input (optional); controls `-a` flag via `def aux_flag = auxiliary_file ? "-a ${auxiliary_file}" : ''`

## Common patterns for optional file inputs

```nextflow
// Input
path optional_file

// Script
def optional_arg = optional_file ? "--flag ${optional_file}" : ''

// Usage in command
$optional_arg \\
```
