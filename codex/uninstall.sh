#!/usr/bin/env bash
# Remove the nf-core-module-dev Codex plugin.

set -euo pipefail

PLUGIN_DIR="${HOME}/.codex/.tmp/plugins/plugins/nf-core-module-dev"

if [[ -d "${PLUGIN_DIR}" || -L "${PLUGIN_DIR}" ]]; then
    rm -rf "${PLUGIN_DIR}"
    echo "Removed ${PLUGIN_DIR}"
else
    echo "Nothing to remove at ${PLUGIN_DIR}"
fi
