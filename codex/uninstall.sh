#!/usr/bin/env bash
# Remove nf-core-module-dev skills from the Codex skills directory.

set -euo pipefail

CODEX_SKILLS_DIR="${HOME}/.codex/skills"
AGENTS=(nf-module-dev nf-test-expert nf-secretary)

for agent in "${AGENTS[@]}"; do
    target="${CODEX_SKILLS_DIR}/${agent}"
    if [[ -d "${target}" || -L "${target}" ]]; then
        rm -rf "${target}"
        echo "Removed ${target}"
    else
        echo "Nothing to remove at ${target}"
    fi
done
