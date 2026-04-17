# Installing nf-core-module-dev for Codex

Codex support now lives in the repository's `.codex-plugin/plugin.json`, which points at the shared repo-root `agents/`, `skills/`, and `hooks/` directories. If you are publishing this repository through a Codex-compatible plugin store, point the store at the repository root.

The steps below document the legacy local-install fallback. It still installs the full plugin — all three specialist agents plus the `nf-module-manager` orchestrator — into Codex's local plugin directory for environments that cannot consume the repo directly.

## Prerequisites

- Git
- Codex CLI installed

## Legacy Local Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vagkaratzas/nf-core-module-dev.git ~/.codex/nf-core-module-dev
   ```

2. **Run the install script:**
   ```bash
   cd ~/.codex/nf-core-module-dev
   ./codex/install.sh
   ```

   The script copies the plugin to `~/.codex/plugins/cache/local/nf-core-module-dev/<version>/` and normalises frontmatter for Codex:
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

## Updating The Legacy Install

```bash
cd ~/.codex/nf-core-module-dev && git pull && ./codex/install.sh
```

The install script overwrites the installed copy — re-running it is required after a `git pull`.

## Uninstalling

```bash
~/.codex/nf-core-module-dev/codex/uninstall.sh
```
