# nf-secretary Agent Memory

See detailed notes in `patterns.md`.

## Quick Reference

- Modules path: `/home/vangelis/Desktop/Projects/modules/modules/nf-core/`
- Lint: `/home/vangelis/miniconda3/bin/nf-core modules lint <tool/subcommand>` (nf-core 3.5.2)
- Schema: `https://raw.githubusercontent.com/nf-core/modules/master/modules/meta-schema.json`

## Critical Rules (prevent lint errors)

- `doi: ""` → NOT valid — omit field entirely if no DOI
- `identifier: ""` → valid, always include
- Optional outputs → document normally, add "Optional." to description
- Eval keys with `\$` or single-quotes → UNQUOTED in YAML (double-quoting crashes parser)
- Output key must match script output, not glob (e.g. `${prefix}.log` not `*.log`)
- `nf-core modules lint --fix` may leave empty `{}` bodies — always fill them
- `test_snapshot_exists` failure → test infrastructure issue, not meta.yml

## Confirmed working modules (reference)

- `pygenprop/build`, `pygenprop/info`, `pharmcat/matcher`, `gemmi/cif2json`, `apbs`, `clipkit`, `caalm`
- Details in: `patterns.md`