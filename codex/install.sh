#!/usr/bin/env bash
# Install nf-core-module-dev as a full Codex plugin.
# Copies the plugin structure to ~/.codex/.tmp/plugins/plugins/nf-core-module-dev/
# and normalises frontmatter so Codex loads all agents and skills correctly:
#   - agents: keep name + description, set model: inherit (strip tools, color)
#   - skills: keep name + description only (strip tools, model, color)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="${HOME}/.codex/.tmp/plugins/plugins/nf-core-module-dev"

echo "Installing nf-core-module-dev plugin"
echo "  from: ${REPO_DIR}"
echo "  to:   ${PLUGIN_DIR}"
echo

# Normalise skill SKILL.md: keep name + description, strip all other FM fields
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

# Normalise agent .md: keep name + description, set model: inherit, strip tools/color
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

# ── .codex-plugin manifest ───────────────────────────────────────────────────
mkdir -p "${PLUGIN_DIR}/.codex-plugin"
cp "${REPO_DIR}/.codex-plugin/plugin.json" "${PLUGIN_DIR}/.codex-plugin/plugin.json"
echo "  ✓ .codex-plugin/plugin.json"

# ── agents ───────────────────────────────────────────────────────────────────
mkdir -p "${PLUGIN_DIR}/agents"
for src in "${REPO_DIR}/agents"/*.md; do
    agent_name="$(basename "${src}")"
    dest="${PLUGIN_DIR}/agents/${agent_name}"
    normalize_agent "${src}" | safe_write "${dest}"
    echo "  ✓ agents/${agent_name}"
done

# ── skills ───────────────────────────────────────────────────────────────────
for skill_dir in "${REPO_DIR}/skills"/*/; do
    skill_name="$(basename "${skill_dir}")"
    dest_dir="${PLUGIN_DIR}/skills/${skill_name}"
    mkdir -p "${dest_dir}"

    # Normalise SKILL.md; copy any other files as-is
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

echo
echo "Done. Restart Codex to pick up the plugin."
echo "Note: re-run this script after 'git pull' to update the installed plugin."
