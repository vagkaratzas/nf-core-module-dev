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
