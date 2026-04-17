#!/usr/bin/env bash
# Install nf-core-module-dev specialist agents as Codex skills.
# Writes ~/.codex/skills/<agent>/SKILL.md with normalised frontmatter
# (name + description only — strips Claude-Code-specific fields that
# cause strict skill loaders to skip the file).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_SKILLS_DIR="${HOME}/.codex/skills"
AGENTS=(nf-module-dev nf-test-expert nf-secretary)

echo "Installing nf-core-module-dev skills from: ${REPO_DIR}"
echo "Target:                                    ${CODEX_SKILLS_DIR}"
echo

mkdir -p "${CODEX_SKILLS_DIR}"

for agent in "${AGENTS[@]}"; do
    src="${REPO_DIR}/agents/${agent}.md"
    dest_dir="${CODEX_SKILLS_DIR}/${agent}"
    dest="${dest_dir}/SKILL.md"
    tmp_dest="${dest}.tmp"

    if [[ ! -f "${src}" ]]; then
        echo "  ✗ missing source: ${src}" >&2
        exit 1
    fi

    mkdir -p "${dest_dir}"

    # If a previous install left a symlink behind, shell redirection would
    # follow it and overwrite the source agent file instead of creating the
    # normalised skill copy that Codex expects.
    if [[ -L "${dest}" ]]; then
        rm -f "${dest}"
    fi

    # Strip Claude-Code-specific frontmatter fields (tools, model, color).
    # Keep only name + description; preserve the full body unchanged.
    awk '
        /^---$/ {
            count++
            if (count == 2) { in_fm = 0 }
            print; next
        }
        in_fm && /^(name|description):/ { print; next }
        in_fm { next }
        { print }
        count == 1 { in_fm = 1 }
    ' "${src}" > "${tmp_dest}"

    mv "${tmp_dest}" "${dest}"

    echo "  ✓ ${agent}"
done

echo
echo "Done. Restart Codex to pick up the new skills."
echo "Note: re-run this script after 'git pull' to update installed skills."
