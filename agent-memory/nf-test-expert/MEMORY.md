# nf-test Expert Memory

## Key Paths
- Modules repo: `/home/vangelis/Desktop/Projects/modules`
- Pipeline repo: `/home/vangelis/Desktop/Projects/proteinfamilies`
- Singularity cache: `/home/vangelis/Desktop/Tools/singularity`
- nf-test config: `/home/vangelis/Desktop/Projects/modules/tests/config/nf-test.config`

## CRITICAL: Singularity cache
Always set before ANY nf-test run:
```bash
export NXF_SINGULARITY_CACHEDIR="/home/vangelis/Desktop/Tools/singularity"
```
Never skip — omitting this pulls images to a default location and wastes disk space.

## @vagkaratzas Style
- Structure: `nextflow_process { name, script, process, tags, [setup], tests }`
- Tags: always `"modules"`, `"modules_nfcore"`, tool-family, tool/subcommand — **and one tag per `tool/subcommand` for every module used in any `setup` block**. E.g. if setup runs `MMSEQS_CREATEDB`, add `tag "mmseqs"` and `tag "mmseqs/createdb"` at the top of the `nextflow_process` block alongside the primary module's tags. Missing setup-module tags is a common oversight.
- Test naming: `"<dataset> - <input_type(s)> - <output_type>"`, stub suffix: `" - stub"`
- Assertions: `assert process.success` then `assertAll({ assert snapshot(process.out).match() })`
- Stub tests: always `options "-stub"` + `snapshot(process.out).match()` (always stable)

## Assertion Priority
1. `snapshot(process.out).match()` — always try first
2. Per-channel with line count for unstable channel: `snapshot(process.out.stable, path(process.out.unstable[0][1]).readLines().size(), process.out.versions_X).match()`
3. File existence only — last resort
Stubs always use priority 1 regardless of real test strategy.

## Topic-Based Versions
Modules using `topic: versions` emit named channels (`versions_pygenprop`, `versions_python`, etc.)
`snapshot(process.out).match()` captures all automatically — do NOT use `path(process.out.versions[0]).yaml`.
Examples: `pygenprop/build`, `pygenprop/info`, `yahs`, `busco`, `gemmi/cif2json`

## Chained Module Tests
```
setup { run("MODULE") { script "path/to/main.nf"; process { ... } } }
```
Reference outputs with `MODULENAME.out.channel_name`. Chains can be multi-level.
Example: `pygenprop/info` chains ARIA2 → PYGENPROP_BUILD → PYGENPROP_INFO

## Known Non-Deterministic Outputs (priority 2)
- APBS: `test.log` contains build timestamp → snapshot line count only; `pot.dx` is stable (md5)
- EGGNOGMAPPER mmseqs mode: `.seed_orthologs` contains absolute temp paths (UUID dirs) + non-deterministic hit ordering; `.emapper.hits` ordering varies. Use line count for both. Annotations `readLines()[3..6]` IS stable.

## MMseqs2 DB Staging Pattern (EGGNOGMAPPER + MMSEQS_CREATEDB)
MMSEQS_CREATEDB outputs a DIRECTORY (`path("${prefix}/")`). When passed as `path(db)` input to another module, Nextflow stages it as a symlink to the directory. The emapper module required a fix to handle this: when `db.isDirectory()`, use `${db}/${db.name}` as the db path (not just `${db}`). See `eggnogmapper/main.nf` fix: `def db_path = (db instanceof Path && db.isDirectory()) ? "${db}/${db.name}" : "$db"`.

## GString Escaping in nf-test when blocks
In nf-test `when { process { """ ... """ } }` triple-quoted strings, `${var}` is evaluated as Groovy GString. To pass `${var}` as Nextflow DSL code (evaluated at runtime, not nf-test parse time), use `\${var}` (escape the dollar). Example: `MMSEQS_CREATEDB.out.db.map { _meta, db -> [ 'mmseqs', db ] }` — works because no interpolation needed. But `"${db}/${db.name}"` inside the triple-quoted string would fail (db not in nf-test scope).

## Test Data
- InterProScan: `proteomics/interproscan/human_skin_metagenome_ips_result.tsv`
- Genome properties flatfile: download via ARIA2 from `https://raw.githubusercontent.com/ebi-pf-team/genome-properties/refs/heads/master/flatfiles/genomeProperties.txt`
- Base URL: `https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/`

## Running a Single Test
Use `--tag "<test_name>"` to run only one specific test — do NOT run all tests when only one is being added/changed:
```bash
nf-test test /path/to/main.nf.test --profile +singularity --verbose --tag "sarscov2 - proteome - no_search"
```

## Detailed Notes
See: `patterns.md`