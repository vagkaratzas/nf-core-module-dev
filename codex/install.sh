#!/usr/bin/env bash
# Install nf-core-module-dev as a Codex plugin (local marketplace fallback).
# Installs to ~/.codex/plugins/cache/local/nf-core-module-dev/<version>/
# and normalises frontmatter so Codex loads all agents and skills correctly:
#   - agents: keep name + description, set model: inherit (strip tools, color)
#   - skills: keep name + description only (strip tools, model, color)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_JSON="${REPO_DIR}/.codex-plugin/plugin.json"
VERSION="$(grep '"version"' "${PLUGIN_JSON}" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
PLUGIN_DIR="${HOME}/.codex/plugins/cache/local/nf-core-module-dev/${VERSION}"
CONFIG_FILE="${HOME}/.codex/config.toml"

echo "Installing nf-core-module-dev plugin (v${VERSION})"
echo "  from: ${REPO_DIR}"
echo "  to:   ${PLUGIN_DIR}"
echo

# ── normalisation helpers ─────────────────────────────────────────────────────

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

# ── plugin files ──────────────────────────────────────────────────────────────

mkdir -p "${PLUGIN_DIR}/.codex-plugin"
cp "${PLUGIN_JSON}" "${PLUGIN_DIR}/.codex-plugin/plugin.json"
echo "  ✓ .codex-plugin/plugin.json"

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

# ── config.toml registration ──────────────────────────────────────────────────

if ! grep -q '\[plugins\."nf-core-module-dev@local"\]' "${CONFIG_FILE}" 2>/dev/null; then
    printf '\n[plugins."nf-core-module-dev@local"]\nenabled = true\n' >> "${CONFIG_FILE}"
    echo "  ✓ registered in ${CONFIG_FILE}"
else
    echo "  ✓ config.toml entry already present"
fi

echo
echo "Done. Restart Codex to pick up the plugin."
echo "Note: re-run this script after 'git pull' to update the installed plugin."
