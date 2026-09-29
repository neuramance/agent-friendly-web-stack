#!/usr/bin/env bash
set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/neuramance/agent-friendly-web-stack/main/SKILL.md"
SKILL="agent-friendly-web-stack"

base="${HOME}"
while (($# > 0)); do
  case "$1" in
    --global)
      base="${HOME}"
      shift
      ;;
    --local)
      base="$(pwd)"
      shift
      ;;
    --target)
      if (($# < 2)); then
        printf 'Error: --target requires a directory\n' >&2
        exit 2
      fi
      base="$2"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage: install.sh [--global|--local|--target <dir>]

Install the agent-friendly-web-stack skill.

Options:
  --global        Install to ~/.agents/skills and ~/.claude/skills (default)
  --local         Install to ./.agents/skills and ./.claude/skills
  --target <dir>  Install to <dir>/.agents/skills and <dir>/.claude/skills
EOF
      exit 0
      ;;
    -*)
      printf 'Error: unknown option "%s"\n' "$1" >&2
      exit 2
      ;;
    *)
      base="$1"
      shift
      ;;
  esac
done

source_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

mkdir -p "${base}"
base="$(cd "${base}" && pwd)"
skill_dir="${base}/.agents/skills/${SKILL}"
claude_link="${base}/.claude/skills/${SKILL}"
mkdir -p "${skill_dir}" "$(dirname "${claude_link}")"

if [[ -n "${source_dir}" && -f "${source_dir}/SKILL.md" ]]; then
  cp "${source_dir}/SKILL.md" "${skill_dir}/SKILL.md"
else
  download="${skill_dir}/.SKILL.md.download"
  trap 'rm -f "${download}"' EXIT
  curl -fsSL --connect-timeout 10 --max-time 60 --retry 3 --retry-connrefused "${RAW_URL}" -o "${download}"
  mv "${download}" "${skill_dir}/SKILL.md"
fi

rm -rf "${claude_link}"
ln -s "../../.agents/skills/${SKILL}" "${claude_link}"

printf 'Installed %s skill:\n  %s/SKILL.md\n  %s -> ../../.agents/skills/%s\n' \
  "${SKILL}" "${skill_dir}" "${claude_link}" "${SKILL}"
