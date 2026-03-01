# nf-core meta.yml Patterns

## General Structure

- No `# yaml-language-server` header line in published/reference modules (the auto-generated stubs include it, but real modules don't)
- `name`: use underscore for subcommands (e.g. `pygenprop_info`, not `pygenprop/info`)
- `description`: use `|` block scalar for multi-line; single line OK for short descriptions
- `keywords`: list of lowercase strings, no trailing punctuation
- `licence`: list form `["Apache-2.0"]` OR block form `- "MPL-2.0"` — both seen; block form preferred
- `identifier`: always `""` (empty string), never omit
- No `doi` field in pygenprop — omit if no DOI exists for the tool

## Input Block

- List of lists: each channel is `- - element1:\n      ...\n    element2:\n      ...`
- Tuple elements are nested under the channel as siblings at the same indent level
- `meta` map entry: `type: map`, description with `Groovy Map containing sample information\ne.g. \`[ id:'sample1' ]\``
- File entries: always include `pattern` and `ontologies`
- `ontologies: []` is valid for entries without a known EDAM term

## Output Block

- NOT a list — it's a mapping keyed by emit name (unlike input which is a list)
- Each emit name maps to a list of tuples; tuple channels use list-of-lists (`- -`) notation
- Scalar (non-tuple) channels like `path("versions.yml")` use a single-level list (`- versions.yml:`)
- `val` (non-tuple) input channels like `val out_format` use a bare mapping entry (no outer `-`): `- out_format:\n    type: string`
- Always document ALL emit channels including version channels
- `ontologies: []` is added automatically by `--fix` for file entries without EDAM terms; keep them
- `versions.yml` gets `ontologies:\n  - edam: http://edamontology.org/format_3750` (YAML format) — added by --fix

### CRITICAL: Output block list vs mapping

The `output:` block MUST be a YAML mapping (object), NOT a list. Using list syntax (`- clipkit:`, `- log:`) triggers schema error "Incorrect type. Expected 'object(Meta yaml)'". Correct form:

```yaml
output:
  clipkit:          # NOT "- clipkit:"
  - - meta:
        type: map
        ...
    - ${prefix}.${out_extension}:
        type: file
        ...
  log:
  - - meta:
        type: map
        ...
    - ${prefix}.log:
        type: file
        ...
  versions:
  - versions.yml:
      type: file
      ...
```

## Topic-Based Versions (new pattern as of ~2025)

When `main.nf` uses `topic: versions`:
- Each version channel appears BOTH under `output:` (as `versions_<tool>:`) AND under `topics: versions:`
- For multiple tools, `topics.versions` gets multiple list entries (one per tool tuple)
- The eval expression in meta.yml must exactly match the eval string in main.nf
- For hardcoded versions: `echo 1.1:` as the eval key
- For python: `python -V | sed "s/Python //g":` as the eval key

### CRITICAL: Eval key quoting in YAML

Eval keys containing `\$` (escaped dollar), single-quotes, or pipe chars must be UNQUOTED in YAML.
Double-quoting these keys causes the YAML parser to crash with a traceback (not a lint error message).

CORRECT (unquoted):
```yaml
      - apbs --version 2>&1 | sed '6!d;s|^.*Version APBS ||; s| .*\$||':
          type: eval
```

WRONG (crashes YAML parser):
```yaml
      - "apbs --version 2>&1 | sed '6!d;s|^.*Version APBS ||; s| .*\$||'":
          type: eval
```

Same rule applies to `${task.process}` and tool name keys — they work fine unquoted.

Example structure for two-tool topic versions:
```yaml
output:
  versions_toolA:
    - - ${task.process}:
          type: string
          description: The name of the process
      - toolA:
          type: string
          description: The name of the tool
      - echo 1.1:
          type: eval
          description: The expression to obtain the version of the tool
  versions_python:
    - - ${task.process}:
          ...
      - python:
          ...
      - python -V | sed "s/Python //g":
          type: eval
          ...

topics:
  versions:
    - - ${task.process}:
          type: string
          description: The name of the process
      - toolA:
          type: string
          description: The name of the tool
      - echo 1.1:
          type: eval
          description: The expression to obtain the version of the tool
    - - ${task.process}:
          type: string
          description: The name of the process
      - python:
          type: string
          description: The name of the tool
      - python -V | sed "s/Python //g":
          type: eval
          description: The expression to obtain the version of the tool
```

## Output key names: prefix vs glob patterns

The linter's `correct_meta_outputs` check parses `main.nf`'s script block to infer the actual
output filename pattern. When `main.nf` uses `tee ${prefix}.log`, the linter expects the output
key to be `${prefix}.log`, NOT `*.log`. Using the wrong key causes a `correct_meta_outputs` error.

- If main.nf `output:` block has `path("*.log")` but the script uses `tee ${prefix}.log`, the
  correct meta.yml key is `${prefix}.log` (what the script actually produces)
- `nf-core modules lint --fix` can auto-correct these keys but leaves empty `{}` bodies —
  always fill them with `type`, `description`, `pattern`, `ontologies`

## Common Lint Warnings (not errors)

- `container_links`: HTTP 404 when linter tries to resolve Seqera Wave container URL — transient/registry issue, not a meta.yml problem
- `main_nf_container: Container versions do not match` — follows from the 404 above; also not a meta.yml issue

## EDAM Ontology Terms

- SQLite format: `http://edamontology.org/format_3621`
- TSV: `http://edamontology.org/format_3475`
- Textual format: `http://edamontology.org/format_2330`
- JSON: `http://edamontology.org/format_3464`
- VCF: `http://edamontology.org/format_3989`
- mmCIF: `http://edamontology.org/format_1477`
- PDB: `http://edamontology.org/format_1476`
- FASTA: `http://edamontology.org/format_1929`
- OpenDX: no specific EDAM term — use `ontologies: []`

Always keep (don't remove!) the comment at the end of the edam ontology with the specific format name!

## doi Field Rules

- The schema does NOT allow `doi: ""` (empty string) — this causes a meta_yml_valid error
- If a tool has no DOI, simply OMIT the `doi` field entirely (do not set it to `""` or `null`)
- This was confirmed by the APBS module lint failure and by pygenprop/build which has no doi field

## Optional Outputs

- Optional outputs (annotated with `optional: true` in main.nf) are documented identically to
  regular outputs in meta.yml — just mention "Optional" in the description text
- No special schema field exists for optional outputs; describe the optionality in the description

## Tool URLs

- pygenprop: homepage/dev = `https://github.com/Micromeda/pygenprop`, docs = `https://pygenprop.readthedocs.io/en/latest/`, licence = Apache-2.0, no DOI
- gemmi: homepage = `https://gemmi.readthedocs.io/`, dev = `https://github.com/project-gemmi/gemmi`, doi = `10.5281/zenodo.3697983`, licence = MPL-2.0
- pharmcat: homepage/docs = `https://pharmcat.clinpgx.org/`, dev = `https://github.com/PharmGKB/PharmCAT`, doi = `10.1002/cpt.928`, licence = MPL-2.0
- apbs: homepage/docs = `https://apbs.readthedocs.io/en/latest/`, dev = `https://github.com/Electrostatics/apbs`, licence = BSD-3-Clause, no DOI
  - Input tuple: `val(meta), path(in), path(pqr)` — pqr can be a list of files
  - Outputs: `dx` (optional, enabled by `write pot dx` in .in file), `mc` (io.mc), `log`, versions_apbs
  - `.in` file accepts `.inp` extension for legacy compatibility
