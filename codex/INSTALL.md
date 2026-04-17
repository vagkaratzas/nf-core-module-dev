# Installing nf-core-module-dev for Codex

Expose the three nf-core specialist agents (`nf-module-dev`, `nf-test-expert`, `nf-secretary`) as Codex skills via native skill discovery.

> **Codex ≠ Claude Code.** The `nf-module-manager` orchestration skill and the `using-nf-core-module-dev` session bootstrap are **not** shipped on Codex — both depend on Claude Code's subagent dispatch primitive, which Codex does not have. On Codex you invoke the three specialist skills directly, one at a time, in whatever order the task needs.

## Prerequisites

- Git
- Codex CLI installed

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vagkaratzas/nf-core-module-dev.git ~/.codex/nf-core-module-dev
   ```

2. **Run the install script:**
   ```bash
   cd ~/.codex/nf-core-module-dev
   ./codex/install.sh
   ```

   The script writes a clean `~/.codex/skills/<skill>/SKILL.md` for each specialist agent — frontmatter is normalised to `name` + `description` only (Codex skips files with unknown frontmatter fields such as `tools`, `model`, `color`):
   ```
   ~/.codex/skills/nf-module-dev/SKILL.md
   ~/.codex/skills/nf-test-expert/SKILL.md
   ~/.codex/skills/nf-secretary/SKILL.md
   ```

3. **Restart Codex** to discover the skills.

## Verify

```bash
ls ~/.codex/skills/nf-module-dev/
# should show: SKILL.md
```

## Usage on Codex

Invoke a skill explicitly for the task in front of you:

- **Create or update `main.nf` / `environment.yml`** → `nf-module-dev`
- **Write or fix nf-tests / snapshots** → `nf-test-expert`
- **Write or lint `meta.yml`** → `nf-secretary`

For a full module build, invoke them in order: `nf-module-dev` first, then `nf-test-expert` and `nf-secretary`.

## Updating

```bash
cd ~/.codex/nf-core-module-dev && git pull && ./codex/install.sh
```

Unlike symlinks, the installed files are copies — re-running `install.sh` is required after a `git pull` to pick up changes.

## Uninstalling

```bash
~/.codex/nf-core-module-dev/codex/uninstall.sh
```
