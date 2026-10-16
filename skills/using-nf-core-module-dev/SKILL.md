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
| Any module or subworkflow change: new module, update, review or CI fix | `nf-module-manager` skill |
| Create or update main.nf / environment.yml only | `nf-module-dev` agent |
| Write or fix nf-tests / snapshots | `nf-test-expert` agent |
| Create or fix meta.yml | `nf-secretary` agent |

## Key rule

For any change to an nf-core module or subworkflow — a new module, a small update, a version bump, a review fix or a CI fix — ALWAYS invoke the `nf-module-manager` skill. Never do the work directly with shell commands, and never invoke the three agents manually in sequence yourself. Requests phrased as an issue or PR ("resolve nf-core/modules issue #N", "address the review comments on PR #N") count.
