#!/usr/bin/env bash
set -euo pipefail

RAW_BASE="https://raw.githubusercontent.com/neuramance/agent-friendly-web-stack/main"

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

mode="global"
target_dir=""
install_bin=1

while (($# > 0)); do
  case "$1" in
    --global)
      mode="global"
      shift
      ;;
    --local)
      mode="local"
      shift
      ;;
    --target)
      target_dir="$2"
      shift 2
      ;;
    --no-bin)
      install_bin=0
      shift
      ;;
    --help|-h)
      cat <<'EOF'
install.sh - Install agent-friendly-web-stack skill

Usage:
  ./install.sh [--global|--local] [--target <dir>] [--no-bin]

Options:
  --global       Install to ~/.agents/skills and ~/.claude/skills (default)
  --local        Install to ./.agents/skills and ./.claude/skills
  --target <dir> Install into a specific directory
  --no-bin       Do not install the afws CLI binary
EOF
      exit 0
      ;;
    *)
      target_dir="$1"
      shift
      ;;
  esac
done

dest_agents=""
dest_claude=""

if [[ -n "${target_dir}" ]]; then
  dest_agents="${target_dir}/.agents/skills/agent-friendly-web-stack"
  dest_claude="${target_dir}/.claude/skills/agent-friendly-web-stack"
elif [[ "${mode}" == "global" ]]; then
  dest_agents="${HOME}/.agents/skills/agent-friendly-web-stack"
  dest_claude="${HOME}/.claude/skills/agent-friendly-web-stack"
else
  dest_agents="$(pwd)/.agents/skills/agent-friendly-web-stack"
  dest_claude="$(pwd)/.claude/skills/agent-friendly-web-stack"
fi

mkdir -p "${dest_agents}"
mkdir -p "$(dirname "${dest_claude}")"

if [[ -n "${SCRIPT_DIR}" && -f "${SCRIPT_DIR}/SKILL.md" ]]; then
  cp "${SCRIPT_DIR}/SKILL.md" "${dest_agents}/SKILL.md"
else
  curl -fsSL "${RAW_BASE}/SKILL.md" -o "${dest_agents}/SKILL.md"
fi

rm -rf "${dest_claude}"
ln -s "${dest_agents}" "${dest_claude}"

bin_installed=0
bin_dest=""
if ((install_bin)); then
  for cand in "${HOME}/.local/bin" "/usr/local/bin"; do
    if [[ -d "${cand}" && -w "${cand}" ]]; then
      bin_dest="${cand}/afws"
      if [[ -n "${SCRIPT_DIR}" && -f "${SCRIPT_DIR}/bin/afws" ]]; then
        cp "${SCRIPT_DIR}/bin/afws" "${bin_dest}"
      else
        curl -fsSL "${RAW_BASE}/bin/afws" -o "${bin_dest}"
      fi
      chmod +x "${bin_dest}"
      bin_installed=1
      break
    fi
  done
fi

printf '\n'
printf '╭──────────────────────────────────────────────────╮\n'
printf '│ ● ● ●  afws · skill install                      │\n'
printf '├──────────────────────────────────────────────────┤\n'
printf '│                                                  │\n'
printf '│  ✓ skill     %s/SKILL.md\n' "${dest_agents}"
printf '│  ✓ claude    %s (symlink)\n' "${dest_claude}"
if ((bin_installed)); then
  printf '│  ✓ cli       %s\n' "${bin_dest}"
fi
printf '│                                                  │\n'
printf '│  Installed successfully. Agents ready.           │\n'
printf '│                                                  │\n'
printf '╰──────────────────────────────────────────────────╯\n'
printf '\n'
