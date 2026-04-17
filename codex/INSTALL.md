# Installing nf-core-module-dev for Codex

Codex support is installer-only. This repository does not publish Codex marketplace metadata or a repo-root `.codex-plugin/plugin.json`.

Use the local installer to generate the Codex manifest and install a normalized plugin copy into Codex's local plugin cache.

## Prerequisites

- Linux or macOS (the installer is a bash script; Windows users need WSL or Git Bash)
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

   The script installs to `~/.codex/plugins/cache/local/nf-core-module-dev/<version>/`, generates `.codex-plugin/plugin.json` at install time, and normalizes frontmatter for Codex:
   - agents: `model` set to `inherit`; `tools` and `color` stripped
   - skills: only `name` and `description` kept in frontmatter

3. **Restart Codex** (full quit and relaunch — not just a model reload).

## What you get

| Component | Available on Codex |
|-----------|-------------------|
| `nf-module-dev` agent | yes |
| `nf-test-expert` agent | yes |
| `nf-secretary` agent | yes |
| `nf-module-manager` skill | yes |
| `using-nf-core-module-dev` bootstrap | yes |

## Updating The Install

```bash
cd ~/.codex/nf-core-module-dev && git pull && ./codex/install.sh
```

The install script overwrites the installed copy. Re-run it after `git pull`.

## Uninstalling

```bash
~/.codex/nf-core-module-dev/codex/uninstall.sh
```
