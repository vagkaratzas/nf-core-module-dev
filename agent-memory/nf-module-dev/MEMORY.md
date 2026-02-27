# nf-module-dev Agent Memory

## Style patterns (confirmed across modules, Feb 2026)

- `def` is required for ALL local variables in both `script` and `stub` blocks
- `stub` block: always redeclare `def args`, `def prefix`, and any derived vars
- `stub` block: `echo "$args"` after `touch` commands when args are declared
- Optional file path inputs use `path optional_file` in input channel; conditional use: `def flag = optional_file ? "-x ${optional_file}" : ''`
- Optional outputs use `, optional: true, emit: name` syntax
- `topic: 'versions'` should be added to the versions output line: `path "versions.yml", emit: versions, topic: 'versions'`
  - NOTE: As of Feb 2026, NO modules in the repo yet use `topic: 'versions'` — it is a requested convention not yet widely adopted

## Resource label conventions

- `process_single`: single-threaded tools, lightweight (e.g. clipkit, wittyer)
- `process_low`: fast multi-cpu tools
- `process_medium`: standard bioinformatics tools
- `process_high`: memory/cpu intensive (e.g. eggnogmapper, yahs)
- Multiple labels allowed: `label 'process_medium'` + `label 'process_long'` for long-running medium-cpu tools


## clipkit-specific notes

- `-l/--log` flag (no arg) creates `<output>.clipkit.log` — separate from stdout redirect
- `-c/--complementary` flag (no arg) creates `<output>.clipkit.complement`
- `-a/--auxiliary_file` takes a file path — for `cst` mode only
- `-of/--output_file_format` specifies format (fasta, phylip, etc.) — not the file extension per se
- stdout from clipkit is captured as `> ${prefix}.log` in the module
- Output file naming: `${prefix}.${out_extension}` where `out_extension` defaults to "clipkit"

## Common patterns for optional file inputs

```nextflow
// Input
path optional_file

// Script
def optional_arg = optional_file ? "--flag ${optional_file}" : ''

// Usage in command
$optional_arg \\
```
