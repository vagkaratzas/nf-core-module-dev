# Plan: Convert claude-agents repo into nf-core-module-dev Claude Code plugin

## Context

The current `claude-agents` repo holds four agent `.md` files and a separate `agent-memory/` directory (with `MEMORY.md` + `patterns.md` per agent). This structure works locally but has two problems: (1) memory files exist in two places (`agent-memory/` in repo AND `~/.claude/agent-memory/`), with no automatic sync; (2) the repo isn't installable as a Claude Code plugin, so other developers can't use it.

The goal is to restructure it as a proper Claude Code plugin — modelled on `superpowers` — so it can be installed via `claude install github:vagkaratzas/nf-core-module-dev`, and eventually submitted to the official marketplace.

Key decisions already made:
- Plugin name: `nf-core-module-dev`
- `nf-module-manager` becomes a **skill** (main session orchestrates; user sees everything)
- Memory content gets **embedded** in each agent file as reference sections (no separate memory files)
- Runtime discoveries still go to `~/.claude/agent-memory/<name>/`; stable patterns get PRed back to the agent file
- `memory: user` frontmatter field is dropped (was never a real Claude Code field)

---

## Target structure

```
nf-core-module-dev/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── nf-module-dev.md
│   ├── nf-test-expert.md
│   └── nf-secretary.md
├── skills/
│   ├── nf-module-manager/
│   │   └── SKILL.md
│   └── using-nf-core-module-dev/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
└── CLAUDE.md
```

---

## Critical files

- [ ] `agents/nf-module-dev.md` — rewrite (drop `memory: user`, merge MEMORY.md into reference sections)
- [ ] `agents/nf-secretary.md` — rewrite (drop `memory: user`, merge MEMORY.md + patterns.md)
- [ ] `agents/nf-test-expert.md` — rewrite (drop `memory: user`, merge MEMORY.md + patterns.md)
- [ ] `agents/nf-module-manager.md` — DELETE (replaced by skill)
- [ ] `agent-memory/` — DELETE entire directory
- [ ] `.claude-plugin/plugin.json` — CREATE
- [ ] `hooks/hooks.json` — CREATE
- [ ] `skills/using-nf-core-module-dev/SKILL.md` — CREATE
- [ ] `skills/nf-module-manager/SKILL.md` — CREATE (extracted from old agent, converted to skill)
- [ ] `CLAUDE.md` — UPDATE

Source memory files to absorb:
- [ ] `agent-memory/nf-module-dev/MEMORY.md`
- [ ] `agent-memory/nf-secretary/MEMORY.md` + `patterns.md`
- [ ] `agent-memory/nf-test-expert/MEMORY.md` + `patterns.md`
- [ ] `agent-memory/nf-module-manager/MEMORY.md`

---

## Implementation tasks

### Task 1 — [x] Add `.claude-plugin/plugin.json`

Create `.claude-plugin/plugin.json`:
```json
{
  "name": "nf-core-module-dev",
  "description": "Agents and skills for creating, testing, and documenting nf-core Nextflow modules",
  "version": "1.0.0",
  "author": { "name": "Vangelis Karatzas", "email": "vagkaratzas1990@gmail.com" },
  "homepage": "https://github.com/vagkaratzas/nf-core-module-dev",
  "repository": "https://github.com/vagkaratzas/nf-core-module-dev",
  "license": "MIT"
}
```

### Task 2 — [x] Add `hooks/hooks.json`

Create `hooks/hooks.json` to inject the bootstrap skill at session start.
Study how superpowers does this at:
`/home/vangelis/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/hooks/`
Mirror the exact pattern used there (path resolution, hook type, matcher).

### Task 3 — [x] Create `skills/using-nf-core-module-dev/SKILL.md`

Bootstrap skill content:

```markdown
---
name: using-nf-core-module-dev
description: Loaded at session start — establishes when to use nf-core module dev agents and skills
---

<SUBAGENT-STOP>
If dispatched as a subagent, skip this skill.
</SUBAGENT-STOP>

# nf-core Module Development Plugin

This plugin provides agents and a skill for creating complete nf-core Nextflow modules.

## When to reach for this plugin

| Task | What to use |
|------|-------------|
| Build a full module end-to-end (main.nf + tests + meta.yml) | `nf-module-manager` skill |
| Create or update main.nf / environment.yml only | `nf-module-dev` agent |
| Write or fix nf-tests / snapshots | `nf-test-expert` agent |
| Create or fix meta.yml | `nf-secretary` agent |

## Key rule
For end-to-end module work, ALWAYS invoke the `nf-module-manager` skill — never invoke the three agents manually in sequence yourself.
```

### Task 4 — [x] Create `skills/nf-module-manager/SKILL.md`

Extract workflow from `agents/nf-module-manager.md` and convert to a skill. Key changes from the old agent:

- Remove frontmatter fields that don't apply to skills (`model`, `color`, `memory`)
- Keep: `name`, `description` (verbatim trigger examples from old agent)
- The workflow is identical EXCEPT Step 3 is split into two phases:

```
### Step 3 — Parallel: write tests + write meta.yml
Spawn nf-test-expert AND nf-secretary simultaneously using the Agent tool — for WRITING only:
- nf-test-expert: write test file → run with --update-snapshot → confirm clean pass → report done
- nf-secretary: write meta.yml → report done (no lint yet)

Wait for BOTH to complete before proceeding.

### Step 3b — Lint (after snapshot exists)
Once nf-test-expert confirms the snapshot is generated, instruct nf-secretary to run lint.
Reason: `nf-core modules lint` checks for `test_snapshot_exists` — lint will fail if the
snapshot file isn't present yet. This is a sequencing dependency, not a meta.yml error.
```

- The memory update section is REMOVED (skills don't write memory)
- The "never write module files yourself" principle remains prominent

### Task 5 — [x] Rewrite `agents/nf-module-dev.md`

Keep the full existing workflow unchanged. Changes:
1. Drop `memory: user` from frontmatter
2. Remove the startup memory-read instruction (`Read MEMORY.md before starting`)
3. Replace with embedded reference sections after the workflow:

```markdown
## Reference: main.nf style patterns

- Variables used in `output:` block globs MUST be process-scoped (bare assignment, no `def`)
- Variables only used inside the script heredoc use `def`
- Stub block: redeclare output vars as bare (no `def`); use `def` for args/flag intermediates
- Stub block: `echo "$args"` after `touch` commands when args are declared
- Optional file inputs: `path optional_file` in input; `def flag = optional_file ? "-x ${optional_file}" : ''`
- Optional outputs: `, optional: true, emit: name` syntax
- Versions output (current standard): eval tuple — NO `cat <<-END_VERSIONS` heredoc:
  ```nextflow
  tuple val("${task.process}"), val('toolname'), eval("tool --version 2>&1 | sed 's/tool //'"), topic: versions, emit: versions_toolname
  ```
  Note: `topic: versions` — NO quotes around `versions`

## Reference: resource labels

| Label | Use for |
|-------|---------|
| `process_single` | Single-threaded, lightweight tools |
| `process_low` | Fast multi-CPU tools |
| `process_medium` | Standard bioinformatics tools |
| `process_high` | Memory/CPU intensive (e.g. eggnogmapper, yahs) |
| Multiple labels | `process_medium` + `process_long` for long-running medium-CPU tools |

## Reference: tool-specific notes

- clipkit: `-l/--log` is boolean store_true → creates `<output>.log`; `-c/--complementary` → `<output>.complement`; `-a` takes a file path (optional path input); output naming: `${prefix}.${out_extension}`
- Optional file input pattern: `path optional_file` in input channel; `def flag = optional_file ? "--flag ${optional_file}" : ''`
```

4. Keep the runtime memory section at the bottom, updated:
```markdown
## Runtime memory
Write new findings to `~/.claude/agent-memory/nf-module-dev/` during sessions.
When a pattern stabilises, open a PR to add it to this file's reference sections.
```

### Task 6 — [x] Rewrite `agents/nf-secretary.md`

Keep full workflow unchanged. Changes:
1. Drop `memory: user` from frontmatter
2. Remove startup memory-read instruction
3. Merge `agent-memory/nf-secretary/MEMORY.md` critical rules and `patterns.md` into embedded reference sections:

```markdown
## Reference: meta.yml conventions

### Structure
- No `# yaml-language-server` header line
- `name`: underscore for subcommands (e.g. `pygenprop_info`)
- `identifier`: always `""`, never omit
- `doi`: OMIT entirely if no DOI — do NOT set to `""`
- `licence`: block form preferred (`- "MIT"`)

### Input block
- List of lists: each channel is `- - element1: ...`
- `meta` map: `type: map`, description with `Groovy Map containing sample information\ne.g. \`[ id:'sample1' ]\``
- Always include `pattern` and `ontologies` for file entries; `ontologies: []` is valid

### Output block
MUST be a YAML mapping (object), NOT a list. Using list syntax (`- clipkit:`) triggers
schema error "Incorrect type. Expected 'object(Meta yaml)'". Correct:
  output:
    clipkit:        # NOT "- clipkit:"
    - - meta: ...
    versions:
    - versions.yml: ...

### Eval key quoting
Keys containing `\$`, single-quotes, or pipe chars MUST be UNQUOTED in YAML.
Double-quoting crashes the YAML parser.

CORRECT (unquoted):
  - apbs --version 2>&1 | sed '6!d;s|^.*Version APBS ||; s| .*\$||':
      type: eval

### Topic-based versions
When main.nf uses `topic: versions`:
- Each version channel appears under both `output:` (as `versions_<tool>:`) AND `topics: versions:`
- Eval expression in meta.yml must exactly match the eval string in main.nf

## Reference: EDAM ontology terms

- FASTA: `http://edamontology.org/format_1929`
- FASTQ: `http://edamontology.org/format_1930`
- TSV: `http://edamontology.org/format_3475`
- JSON: `http://edamontology.org/format_3464`
- VCF: `http://edamontology.org/format_3989`
- mmCIF: `http://edamontology.org/format_1477`
- PDB: `http://edamontology.org/format_1476`
- SQLite: `http://edamontology.org/format_3621`
- Alignment (generic): `http://edamontology.org/format_1921`
- FASTA alignment: `http://edamontology.org/format_1984`
- Phylogenetic tree: `http://edamontology.org/format_2006`
- Plain text / log: `http://edamontology.org/format_3671`
- YAML: `http://edamontology.org/format_3750`
- OpenDX / NumPy .npy: `ontologies: []`
Always keep the format name comment after the EDAM URL.

## Reference: confirmed tool metadata

- pygenprop: homepage `https://github.com/Micromeda/pygenprop`, licence Apache-2.0, no DOI
- gemmi: homepage `https://gemmi.readthedocs.io/`, doi `10.5281/zenodo.3697983`, licence MPL-2.0
- pharmcat: homepage `https://pharmcat.clinpgx.org/`, doi `10.1002/cpt.928`, licence MPL-2.0
- apbs: homepage `https://apbs.readthedocs.io/en/latest/`, licence BSD-3-Clause, no DOI
- clipkit: homepage `https://jlsteenwyk.com/ClipKIT/`, doi `10.1371/journal.pbio.3001007`, licence MIT, identifier `biotools:clipkit`
- caalm: homepage `https://github.com/lczong/CAALM`, licence MIT, no DOI, identifier `""`
```

4. Runtime memory section at bottom (same pattern as nf-module-dev).

### Task 7 — [x] Rewrite `agents/nf-test-expert.md`

Keep full workflow unchanged. Changes:
1. Drop `memory: user` from frontmatter
2. Remove startup memory-read instruction
3. Merge MEMORY.md + patterns.md into embedded reference sections:

```markdown
## Reference: @vagkaratzas test style

- Structure: `nextflow_process { name, script, process, tags, [setup], tests }`
- Tags: always `"modules"`, `"modules_nfcore"`, tool-family, tool/subcommand
  — add one tag per module used in any `setup` block (e.g. if setup runs MMSEQS_CREATEDB, add `tag "mmseqs"` and `tag "mmseqs/createdb"`)
- Test naming: `"<dataset> - <input_type(s)> - <output_type>"`, stub suffix: `" - stub"`
- Assertions: `assert process.success` then `assertAll({ assert snapshot(process.out).match() })`
- Stub tests: always `options "-stub"` + `snapshot(process.out).match()` (always stable)

## Reference: assertion priority

1. `snapshot(process.out).match()` — always try first
2. Per-channel with line count for unstable outputs
3. File existence only — last resort
Stubs always use priority 1.

## Reference: known pitfalls

- Cannot `run()` the same process being tested in a setup block — Nextflow throws "already defined"
- `${projectDir}` resolves to the nf-test root (where nf-test.config lives), NOT the test file directory
  → files at `modules/nf-core/tool/tests/file.txt` referenced as `${projectDir}/modules/nf-core/tool/tests/file.txt`
- GString escaping: in `when { process { """ ... """ } }` blocks, use `\${var}` to pass Nextflow DSL vars (not nf-test scope)
- Topic-based versions: modules using `topic: versions` emit named channels — `snapshot(process.out).match()` captures all automatically; do NOT use `path(process.out.versions[0]).yaml`

## Reference: known non-deterministic outputs

- APBS: `test.log` contains build timestamp → snapshot line count only; `pot.dx` is stable (md5)
- EGGNOGMAPPER mmseqs mode: `.seed_orthologs` has UUID temp paths + non-deterministic hit ordering; `.emapper.hits` ordering varies → use line count for both; annotations `readLines()[3..6]` IS stable

## Reference: test data locations

- Base URL: `https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/`
- InterProScan: `proteomics/interproscan/human_skin_metagenome_ips_result.tsv`
- Genome properties: download via ARIA2 from `https://raw.githubusercontent.com/ebi-pf-team/genome-properties/refs/heads/master/flatfiles/genomeProperties.txt`
```

4. Runtime memory section at bottom.

### Task 8 — [ ] Delete `agents/nf-module-manager.md` and `agent-memory/` directory

```bash
git rm agents/nf-module-manager.md
git rm -r agent-memory/
```

### Task 9 — [ ] Update `CLAUDE.md`

Rewrite to reflect:
- New repo name and purpose (installable Claude Code plugin)
- New structure (`.claude-plugin/`, `skills/`, `agents/`, `hooks/`)
- Install command: `claude install github:vagkaratzas/nf-core-module-dev`
- Agent/skill responsibility table
- How to update agent knowledge (edit reference sections, PR back)
- Runtime memory path: `~/.claude/agent-memory/<name>/`

### Task 10 — [x] Rename GitHub repo

In GitHub settings: rename `claude-agents` → `nf-core-module-dev`.
This is a manual step — cannot be done via CLI without GitHub auth.

---

## Verification

- [ ] **Structural check**: Confirm all files exist in correct locations; no leftover `agent-memory/` dir
- [ ] **Plugin manifest**: Validate `plugin.json` against superpowers schema manually
- [ ] **Hook test**: Start a new Claude Code session; confirm the bootstrap skill content appears in the session-start context
- [ ] **Skill trigger test**: Ask Claude Code "create an nf-core module for samtools sort" — confirm it invokes `nf-module-manager` skill, not the old agent
- [ ] **Agent trigger test**: Ask "write an nf-test for the clipkit module" — confirm `nf-test-expert` agent is dispatched directly
- [ ] **End-to-end test**: Run a full module creation through `nf-module-manager` skill; verify Step 3/3b sequencing (meta.yml written in parallel, lint runs only after snapshot exists)
