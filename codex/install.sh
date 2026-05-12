#!/usr/bin/env bash
# Install nf-core-module-dev as a local Codex plugin.
# Installs to ~/.codex/plugins/cache/local/nf-core-module-dev/<version>/
# and normalises frontmatter so Codex loads all agents and skills correctly:
#   - agents: keep name + description, set model: inherit (strip tools, color)
#   - skills: keep name + description only (strip tools, model, color)
# The Codex plugin manifest is copied from .codex-plugin/plugin.json.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${REPO_DIR}/.codex-plugin/plugin.json"
VERSION="$(grep '"version"' "${VERSION_FILE}" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
PLUGIN_DIR="${HOME}/.codex/plugins/cache/local/nf-core-module-dev/${VERSION}"
CONFIG_FILE="${HOME}/.codex/config.toml"

if [[ -z "${VERSION}" ]]; then
    echo "Could not determine plugin version from ${VERSION_FILE}" >&2
    exit 1
fi

echo "Installing nf-core-module-dev plugin (v${VERSION})"
echo "  from: ${REPO_DIR}"
echo "  to:   ${PLUGIN_DIR}"
echo

normalize_skill() {
    local src="$1"
    awk '
        /^---$/ { count++; if (count == 2) in_fm = 0; print; next }
        in_fm && /^(name|description):/ { print; next }
        in_fm { next }
        { print }
        count == 1 { in_fm = 1 }
    ' "${src}"
}

normalize_agent() {
    local src="$1"
    awk '
        /^---$/ { count++; if (count == 2) in_fm = 0; print; next }
        in_fm && /^(name|description):/ { print; next }
        in_fm && /^model:/ { print "model: inherit"; next }
        in_fm { next }
        { print }
        count == 1 { in_fm = 1 }
    ' "${src}"
}

safe_write() {
    local dest="$1"
    local tmp="${dest}.tmp"
    cat > "${tmp}"
    mv "${tmp}" "${dest}"
}

# Remove stale version directories before installing
PLUGIN_BASE="${HOME}/.codex/plugins/cache/local/nf-core-module-dev"
if [[ -d "${PLUGIN_BASE}" ]]; then
    find "${PLUGIN_BASE}" -maxdepth 1 -mindepth 1 -type d ! -name "${VERSION}" -exec rm -rf {} +
fi

mkdir -p "${PLUGIN_DIR}/.codex-plugin"
cp "${REPO_DIR}/.codex-plugin/plugin.json" "${PLUGIN_DIR}/.codex-plugin/plugin.json"

echo "  ✓ .codex-plugin/plugin.json"

mkdir -p "${PLUGIN_DIR}/codex"
cp "${REPO_DIR}/codex/hooks.json" "${PLUGIN_DIR}/codex/hooks.json"

echo "  ✓ codex/hooks.json"

mkdir -p "${PLUGIN_DIR}/agents"
for src in "${REPO_DIR}/agents"/*.md; do
    agent_name="$(basename "${src}")"
    normalize_agent "${src}" | safe_write "${PLUGIN_DIR}/agents/${agent_name}"
    echo "  ✓ agents/${agent_name}"
done

for skill_dir in "${REPO_DIR}/skills"/*/; do
    skill_name="$(basename "${skill_dir}")"
    dest_dir="${PLUGIN_DIR}/skills/${skill_name}"
    mkdir -p "${dest_dir}"
    for f in "${skill_dir}"*; do
        fname="$(basename "${f}")"
        if [[ "${fname}" == "SKILL.md" ]]; then
            normalize_skill "${f}" | safe_write "${dest_dir}/SKILL.md"
        else
            cp -r "${f}" "${dest_dir}/${fname}"
        fi
    done
    echo "  ✓ skills/${skill_name}/"
done

mkdir -p "$(dirname "${CONFIG_FILE}")"
if ! grep -q '\[plugins\."nf-core-module-dev@local"\]' "${CONFIG_FILE}" 2>/dev/null; then
    printf '\n[plugins."nf-core-module-dev@local"]\nenabled = true\n' >> "${CONFIG_FILE}"
    echo "  ✓ registered in ${CONFIG_FILE}"
else
    echo "  ✓ config.toml entry already present"
fi

echo
echo "Done. Restart Codex to pick up the plugin."
echo "Note: re-run this script after 'git pull' to update the installed plugin."
