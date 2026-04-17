#!/usr/bin/env bash
# Remove the nf-core-module-dev Codex plugin (local marketplace install).

set -euo pipefail

PLUGIN_BASE="${HOME}/.codex/plugins/cache/local/nf-core-module-dev"
CONFIG_FILE="${HOME}/.codex/config.toml"

if [[ -d "${PLUGIN_BASE}" ]]; then
    rm -rf "${PLUGIN_BASE}"
    echo "Removed ${PLUGIN_BASE}"
else
    echo "Nothing to remove at ${PLUGIN_BASE}"
fi

# Remove config.toml entry if present
if grep -q '\[plugins\."nf-core-module-dev@local"\]' "${CONFIG_FILE}" 2>/dev/null; then
    # Remove the section header and the next line (enabled = true)
    sed -i '/\[plugins\."nf-core-module-dev@local"\]/{N;d}' "${CONFIG_FILE}"
    echo "Removed config.toml entry"
fi
