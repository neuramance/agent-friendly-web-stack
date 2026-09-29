#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${REPO_DIR}/install.sh"
SKILL="agent-friendly-web-stack"
RAW_URL="https://raw.githubusercontent.com/neuramance/agent-friendly-web-stack/main/SKILL.md"

assert_installed() {
  local base="$1"
  local expected="${2:-${REPO_DIR}/SKILL.md}"
  cmp "${expected}" "${base}/.agents/skills/${SKILL}/SKILL.md"
  test -L "${base}/.claude/skills/${SKILL}"
  cmp "${expected}" "${base}/.claude/skills/${SKILL}/SKILL.md"
}

fake_curl() {
  local bin="$1"
  local body="$2"
  local status="$3"
  mkdir -p "${bin}"
  cat <<EOF > "${bin}/curl"
#!/usr/bin/env bash
printf '%s\n' "\$@" > "${bin}/curl.args"
while ((\$# > 0)); do
  if [[ "\$1" == "-o" ]]; then
    printf '%s' "${body}" > "\$2"
  fi
  shift
done
exit ${status}
EOF
  chmod +x "${bin}/curl"
}

test_target_reports_full_paths() {
  local tmp="$1"
  local out
  out="$("${INSTALLER}" --target "${tmp}/project")"
  assert_installed "${tmp}/project"
  printf '%s\n' "${out}" | grep -Fq "${tmp}/project/.agents/skills/${SKILL}/SKILL.md"
  printf '%s\n' "${out}" | grep -Fq "${tmp}/project/.claude/skills/${SKILL}"
}

test_positional_relative_target() {
  local tmp="$1"
  (cd "${tmp}" && "${INSTALLER}" subproject >/dev/null)
  assert_installed "${tmp}/subproject"
}

test_global_by_default() {
  local tmp="$1"
  "${INSTALLER}" >/dev/null
  assert_installed "${HOME}"
}

test_local() {
  local tmp="$1"
  (cd "${tmp}" && "${INSTALLER}" --local >/dev/null)
  assert_installed "${tmp}"
}

test_reinstall_replaces_stale_install() {
  local tmp="$1"
  mkdir -p "${tmp}/.agents/skills/${SKILL}" "${tmp}/.claude/skills/${SKILL}"
  printf 'stale\n' > "${tmp}/.agents/skills/${SKILL}/SKILL.md"
  printf 'stale\n' > "${tmp}/.claude/skills/${SKILL}/SKILL.md"
  "${INSTALLER}" --target "${tmp}" >/dev/null
  assert_installed "${tmp}"
}

test_piped_install_fetches_skill() {
  local tmp="$1"
  fake_curl "${tmp}/bin" "remote skill" 0
  printf 'remote skill' > "${tmp}/expected"
  PATH="${tmp}/bin:${PATH}" bash -s -- --target "${tmp}/project" < "${INSTALLER}" >/dev/null
  assert_installed "${tmp}/project" "${tmp}/expected"
  grep -Fxq "${RAW_URL}" "${tmp}/bin/curl.args"
  grep -Fxq -- "--max-time" "${tmp}/bin/curl.args"
}

test_failed_download_keeps_existing_skill() {
  local tmp="$1"
  "${INSTALLER}" --target "${tmp}/project" >/dev/null
  fake_curl "${tmp}/bin" "partial" 28
  local code=0
  PATH="${tmp}/bin:${PATH}" bash -s -- --target "${tmp}/project" < "${INSTALLER}" >/dev/null 2>&1 || code=$?
  test "${code}" -eq 28
  assert_installed "${tmp}/project"
  test "$(ls -A "${tmp}/project/.agents/skills/${SKILL}")" = "SKILL.md"
}

test_target_without_directory() {
  local tmp="$1"
  local code=0
  local err
  err="$("${INSTALLER}" --target 2>&1 >/dev/null)" || code=$?
  test "${code}" -eq 2
  printf '%s\n' "${err}" | grep -Fq -- "--target"
}

test_unknown_option() {
  local tmp="$1"
  local code=0
  local err
  err="$("${INSTALLER}" --bogus 2>&1 >/dev/null)" || code=$?
  test "${code}" -eq 2
  printf '%s\n' "${err}" | grep -Fq -- "--bogus"
  test ! -e "${HOME}/.agents"
}

test_help() {
  local tmp="$1"
  local out
  out="$("${INSTALLER}" --help)"
  printf '%s\n' "${out}" | grep -Fq "Usage: install.sh"
  test ! -e "${HOME}/.agents"
}

run_all() {
  local tests=(
    test_target_reports_full_paths
    test_positional_relative_target
    test_global_by_default
    test_local
    test_reinstall_replaces_stale_install
    test_piped_install_fetches_skill
    test_failed_download_keeps_existing_skill
    test_target_without_directory
    test_unknown_option
    test_help
  )

  local pass=0
  local fail=0
  local t
  for t in "${tests[@]}"; do
    local res=0
    set +e
    (
      set -e
      tmp="$(cd "$(mktemp -d)" && pwd)"
      trap 'rm -rf "${tmp}"' EXIT
      export HOME="${tmp}/home"
      mkdir -p "${HOME}"
      "${t}" "${tmp}"
    )
    res=$?
    set -e
    if ((res == 0)); then
      ((pass++))
      printf '  ✓ %s\n' "${t}"
    else
      ((fail++))
      printf '  ✗ %s\n' "${t}" >&2
    fi
  done

  printf '\nResult: %d passed, %d failed\n' "${pass}" "${fail}"
  if ((fail > 0)); then
    exit 1
  fi
}

run_all
