# Installing nf-core-module-dev for Codex

Codex uses the repository's shared marketplace catalog at `.claude-plugin/marketplace.json` and the Codex plugin manifest at `.codex-plugin/plugin.json`.

## Marketplace Installation

1. **Add the marketplace:**
   ```bash
   codex plugin marketplace add vagkaratzas/nf-core-module-dev
   ```

2. **Open the plugin browser:**
   ```bash
   codex
   ```

   Then run:
   ```text
   /plugins
   ```

3. **Install the plugin:**
   - Select the `vagkaratzas` marketplace.
   - Open `nf-core-module-dev`.
   - Select `Install plugin`.

4. **Restart Codex** so bundled skills and plugin metadata are loaded in a fresh session.

## Local Development Installation

For testing an unpublished working tree, use the local helper:

```bash
git clone https://github.com/vagkaratzas/nf-core-module-dev.git ~/.codex/nf-core-module-dev
cd ~/.codex/nf-core-module-dev
./codex/install.sh
```

The helper installs a normalized copy into `~/.codex/plugins/cache/local/nf-core-module-dev/<version>/`:
- `.codex-plugin/plugin.json` is copied from the source-controlled Codex manifest
- `codex/hooks.json` disables accidental loading of the Claude-only session hook
- agents: `model` is set to `inherit`; `tools` and `color` are stripped
- skills: only `name` and `description` are kept in frontmatter

Restart Codex after running the helper. Re-run it after `git pull` to refresh the installed local copy.

## What You Get

| Component | Available on Codex |
|-----------|-------------------|
| `nf-module-dev` agent | yes, when the Codex surface supports plugin agents |
| `nf-test-expert` agent | yes, when the Codex surface supports plugin agents |
| `nf-secretary` agent | yes, when the Codex surface supports plugin agents |
| `nf-module-manager` skill | yes |
| `using-nf-core-module-dev` bootstrap | yes |

## Updating

For marketplace installs, update the marketplace from Codex:

```bash
codex plugin marketplace upgrade vagkaratzas
```

For local helper installs:

```bash
cd ~/.codex/nf-core-module-dev
git pull
./codex/install.sh
```

## Uninstalling Local Helper Installs

```bash
~/.codex/nf-core-module-dev/codex/uninstall.sh
```

For marketplace installs, uninstall from the Codex `/plugins` browser.

## Known Limitations

Codex subagent and plugin-agent support has changed across recent releases. If Codex does not expose the three specialist agents directly, use the bundled `nf-module-manager` skill as the entry point and review outputs carefully.

Currently, Codex subagents may not reliably stop to ask the user for input when an agent instruction requires confirmation. This is especially relevant for profile selection, Singularity cache paths, and container placeholder resolution.

**Recommendation**: prefer Claude Code for the most reliable end-to-end module workflow. Use the Codex plugin when Claude Code is unavailable or when you are prepared to review and correct agent outputs manually.
