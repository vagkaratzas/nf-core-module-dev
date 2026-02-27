# nf-module-manager Memory

## Key Paths
- Modules directory: `/home/vangelis/Desktop/Projects/modules/modules/nf-core/`
- nf-test config: `/home/vangelis/Desktop/Projects/modules/tests/config/nf-test.config`
- Test data base path param: `params.modules_testdata_base_path`

## Orchestration Rules
- NEVER write module files directly — always delegate
- nf-test-expert + nf-secretary always run in parallel after nf-module-dev completes
- Max 3 retries on nf-module-dev before escalating to user

## Style Reference Modules
- `gemmi/cif2json` — simple single-input/single-output
- `pharmcat/matcher` — multi-input, optional output, nextflow.config in tests/
- `pygenprop/build`, `pygenprop/info` — topic-based versions pattern, chained tests

## Common Retry Triggers
(populate as patterns emerge)