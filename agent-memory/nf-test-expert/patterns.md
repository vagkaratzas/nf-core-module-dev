# nf-test Patterns and Pitfalls

## Cannot `run()` the same process being tested in setup
Within a `nextflow_process` test block, `process "FOO"` is the primary declaration. You CANNOT use `run("FOO")` in any setup block — Nextflow throws `A process named 'FOO' is already defined`. Workarounds:
- Use a static test data file placed in `tests/` and reference it with `${projectDir}/path/to/file`
- Use a different upstream process that produces the required input format

## Static test data files in module tests/
`${projectDir}` in nf-test resolves to the nf-test root (where `nf-test.config` lives), NOT the test file's directory. In the nf-core modules repo, that is `/home/vangelis/Desktop/Projects/modules`. So a file placed at `modules/nf-core/eggnogmapper/tests/test.emapper.seed_orthologs` is referenced as:
```
file("${projectDir}/modules/nf-core/eggnogmapper/tests/test.emapper.seed_orthologs", checkIfExists: true)
```

## EGGNOGMAPPER no_search mode output behaviour
In `no_search` mode (`-m no_search --annotate_hits_table <file>`):
- Only `*.emapper.annotations` is produced as a new output file
- `*.emapper.seed_orthologs` is staged as an INPUT file — Nextflow excludes it from output collection even though it is physically present in the work dir
- `*.emapper.hits` is not produced at all
- Required fix: make both `orthologs` and `hits` outputs `optional: true` in `main.nf`
- Test assertions: only assert on `annotations` lines and `versions`

## Channel.of() for simple value channels in when blocks
To pass a static tuple as a channel input (no setup block needed):
```groovy
input[1] = Channel.of([ 'no_search', file("${projectDir}/path/to/file", checkIfExists: true) ])
```
This emits a single item `['no_search', <Path>]` matching `tuple val(search_mode), path(db)`.
