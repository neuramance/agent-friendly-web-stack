#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
AFWS="${REPO_DIR}/bin/afws"
INSTALLER="${REPO_DIR}/install.sh"

test_help() {
  local out
  out="$("${AFWS}" help)"
  printf '%s\n' "${out}" | grep -q "Agent-Friendly Web Stack CLI"

  local out_long
  out_long="$("${AFWS}" --help)"
  printf '%s\n' "${out_long}" | grep -q "Usage:"

  local out_short
  out_short="$("${AFWS}" -h)"
  printf '%s\n' "${out_short}" | grep -q "Usage:"
}

test_no_args() {
  local out
  local code=0
  out="$("${AFWS}" 2>&1)" || code=$?
  test "${code}" -eq 0
  printf '%s\n' "${out}" | grep -q "Agent-Friendly Web Stack CLI"
  printf '%s\n' "${out}" | grep -q "Usage:"
}

test_unknown_subcmd() {
  local code=0
  local out
  out="$("${AFWS}" unknown_cmd 2>&1)" || code=$?
  test "${code}" -eq 2
  printf '%s\n' "${out}" | grep -q 'Error: unknown command "unknown_cmd"'

  local empty_code=0
  local empty_out
  empty_out="$("${AFWS}" "" 2>&1)" || empty_code=$?
  test "${empty_code}" -eq 2
  printf '%s\n' "${empty_out}" | grep -q 'Error: unknown command ""'
}

test_subcommand_help() {
  local out_audit code_audit=0
  out_audit="$("${AFWS}" audit --help 2>&1)" || code_audit=$?
  test "${code_audit}" -eq 0
  printf '%s\n' "${out_audit}" | grep -q "Usage: afws audit"

  local out_scaffold code_scaffold=0
  out_scaffold="$("${AFWS}" scaffold --help 2>&1)" || code_scaffold=$?
  test "${code_scaffold}" -eq 0
  printf '%s\n' "${out_scaffold}" | grep -q "Usage: afws scaffold"

  local out_spec code_spec=0
  out_spec="$("${AFWS}" spec --help 2>&1)" || code_spec=$?
  test "${code_spec}" -eq 0
  printf '%s\n' "${out_spec}" | grep -q "Usage: afws spec"

  local out_install code_install=0
  out_install="$("${AFWS}" install --help 2>&1)" || code_install=$?
  test "${code_install}" -eq 0
  printf '%s\n' "${out_install}" | grep -q "Usage: afws install"

  local out_help_audit code_help_audit=0
  out_help_audit="$("${AFWS}" help audit 2>&1)" || code_help_audit=$?
  test "${code_help_audit}" -eq 0
  printf '%s\n' "${out_help_audit}" | grep -q "Usage: afws audit"
}

test_spec_stack() {
  local out
  out="$("${AFWS}" spec stack)"
  printf '%s\n' "${out}" | grep -q "Next.js"
  printf '%s\n' "${out}" | grep -q "App Router"
  printf '%s\n' "${out}" | grep -q "StyleX"
  printf '%s\n' "${out}" | grep -q "Supabase Cloud"
}

test_spec_invalid() {
  local code=0
  "${AFWS}" spec non_existent_section >/dev/null 2>&1 || code=$?
  test "${code}" -eq 2
}

test_audit_missing_dir() {
  local code=0
  "${AFWS}" audit "/path/that/does/not/exist/$(date +%s)" >/dev/null 2>&1 || code=$?
  test "${code}" -eq 2
}

test_audit_empty_dir() {
  local tmp
  tmp="$(mktemp -d)"
  local code=0
  "${AFWS}" audit "${tmp}" >/dev/null 2>&1 || code=$?
  rm -rf "${tmp}"
  test "${code}" -eq 2
}

create_conforming_app() {
  local target="$1"
  touch "${target}/bun.lock"
  touch "${target}/next.config.ts"
  touch "${target}/babel.config.js"
  touch "${target}/postcss.config.js"
  touch "${target}/proxy.ts"
  mkdir -p "${target}/app"
  mkdir -p "${target}/supabase/migrations"

  cat <<'EOF' > "${target}/package.json"
{
  "name": "conforming-app",
  "packageManager": "bun@1.3.14",
  "engines": {
    "node": ">=24"
  },
  "scripts": {
    "setup": "bunx playwright install && supabase start",
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "typecheck": "next typegen && tsc --noEmit",
    "lint": "eslint .",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "test": "vitest run",
    "test:db": "supabase test db",
    "test:smoke": "node server.test.js",
    "test:e2e": "playwright test",
    "db:start": "supabase start",
    "db:reset": "supabase db reset",
    "db:types": "supabase gen types typescript --local",
    "check": "bun run format:check && bun run lint && bun run typecheck && bun run test && bun run build && bun run test:db && bun run test:e2e"
  },
  "dependencies": {
    "@stylexjs/stylex": "^0.19.0",
    "@supabase/ssr": "^0.12.5",
    "@supabase/supabase-js": "^2.112.4",
    "next": "16.3.3",
    "react": "19.2.8",
    "react-dom": "19.2.8",
    "zod": "^4.5.1"
  },
  "devDependencies": {
    "@playwright/test": "^1.62.1",
    "@stylexjs/babel-plugin": "^0.19.0",
    "@stylexjs/eslint-plugin": "^0.19.0",
    "@stylexjs/postcss-plugin": "^0.19.0",
    "eslint": "^9",
    "prettier": "^3.9.6",
    "supabase": "^2.116.0",
    "typescript": "^5",
    "vitest": "^4.1.11"
  }
}
EOF
}

test_audit_conforming_project() {
  local tmp
  tmp="$(mktemp -d)"
  create_conforming_app "${tmp}"

  local code=0
  local out
  out="$("${AFWS}" audit "${tmp}" 2>&1)" || code=$?
  rm -rf "${tmp}"

  test "${code}" -eq 0
  printf '%s\n' "${out}" | grep -q "0 drift · conforming to stack spec"
}

test_audit_default_dir() {
  local tmp
  tmp="$(mktemp -d)"
  create_conforming_app "${tmp}"

  local code=0
  local out
  out="$(cd "${tmp}" && "${AFWS}" audit 2>&1)" || code=$?
  rm -rf "${tmp}"

  test "${code}" -eq 0
  printf '%s\n' "${out}" | grep -q "0 drift · conforming to stack spec"
}

test_audit_without_jq() {
  local tmp
  tmp="$(mktemp -d)"
  create_conforming_app "${tmp}"

  local fakebin
  fakebin="$(mktemp -d)"
  ln -s "$(which node)" "${fakebin}/node"
  if command -v bun >/dev/null 2>&1; then
    ln -s "$(which bun)" "${fakebin}/bun"
  fi
  ln -s "$(which bash)" "${fakebin}/bash"
  ln -s "$(which sed)" "${fakebin}/sed"
  ln -s "$(which grep)" "${fakebin}/grep"
  ln -s "$(which dirname)" "${fakebin}/dirname"
  ln -s "$(which basename)" "${fakebin}/basename"

  local code=0
  local out
  out="$(PATH="${fakebin}" "${AFWS}" audit "${tmp}" 2>&1)" || code=$?
  rm -rf "${tmp}" "${fakebin}"

  test "${code}" -eq 0
  printf '%s\n' "${out}" | grep -q "0 drift · conforming to stack spec"
}

test_audit_drifting_project() {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "${tmp}/app"
  mkdir -p "${tmp}/pages"
  mkdir -p "${tmp}/src"
  touch "${tmp}/next.config.ts"
  touch "${tmp}/proxy.ts"

  cat <<'EOF' > "${tmp}/package.json"
{
  "name": "drifting-app",
  "packageManager": "npm@10.0.0",
  "dependencies": {
    "next": "16.3.3",
    "tailwindcss": "^4.0.0"
  },
  "scripts": {
    "dev": "next dev"
  }
}
EOF

  local code=0
  local out
  out="$("${AFWS}" audit "${tmp}" 2>&1)" || code=$?
  rm -rf "${tmp}"

  test "${code}" -eq 1
  printf '%s\n' "${out}" | grep -q "pages/ router forbidden"
  printf '%s\n' "${out}" | grep -q "src/ indirection forbidden"
  printf '%s\n' "${out}" | grep -q "tailwindcss forbidden"
  printf '%s\n' "${out}" | grep -q "packageManager != bun@"
}

test_spec_aliases() {
  local out_scripts out_auth out_gate
  out_scripts="$("${AFWS}" spec scripts)"
  printf '%s\n' "${out_scripts}" | grep -q "Expose canonical scripts"
  out_auth="$("${AFWS}" spec auth)"
  printf '%s\n' "${out_auth}" | grep -q "Supabase"
  out_gate="$("${AFWS}" spec gate)"
  printf '%s\n' "${out_gate}" | grep -q "Before claiming completion"
}

test_scaffold_dry_run() {
  local out
  out="$("${AFWS}" scaffold my-test-app --dry-run)"
  printf '%s\n' "${out}" | grep -q "bunx create-next-app@latest"
  printf '%s\n' "${out}" | grep -q "@stylexjs/stylex"
}

test_scaffold_skip_install_and_audit() {
  local tmp
  tmp="$(mktemp -d)/scaffold-app"
  local code=0
  local out
  out="$("${AFWS}" scaffold "${tmp}" --skip-install 2>&1)" || code=$?
  test "${code}" -eq 0
  test -f "${tmp}/package.json"
  test -f "${tmp}/next.config.ts"
  test -f "${tmp}/babel.config.js"
  test -f "${tmp}/postcss.config.js"
  test -f "${tmp}/proxy.ts"
  test -f "${tmp}/vitest.config.ts"
  test -f "${tmp}/playwright.config.ts"
  test -f "${tmp}/supabase/config.toml"
  test -d "${tmp}/supabase/migrations"
  test -f "${tmp}/app/globals.css"
  printf '%s\n' "${out}" | grep -q "0 drift · conforming to stack spec"
  rm -rf "$(dirname "${tmp}")"
}

test_installer() {
  local tmp
  tmp="$(mktemp -d)"
  "${INSTALLER}" --target "${tmp}" --no-bin >/dev/null
  test -f "${tmp}/.agents/skills/agent-friendly-web-stack/SKILL.md"
  test -f "${tmp}/.claude/skills/agent-friendly-web-stack/SKILL.md"
  rm -rf "${tmp}"
}

test_installer_relative_target() {
  local tmp
  tmp="$(mktemp -d)"
  (
    cd "${tmp}"
    mkdir -p subproject
    "${INSTALLER}" --target subproject --no-bin >/dev/null
    test -f "subproject/.agents/skills/agent-friendly-web-stack/SKILL.md"
    test -f "subproject/.claude/skills/agent-friendly-web-stack/SKILL.md"
  )
  rm -rf "${tmp}"
}

test_afws_install_target() {
  local tmp
  tmp="$(mktemp -d)"
  "${AFWS}" install --target "${tmp}" >/dev/null
  test -f "${tmp}/.agents/skills/agent-friendly-web-stack/SKILL.md"
  test -f "${tmp}/.claude/skills/agent-friendly-web-stack/SKILL.md"
  rm -rf "${tmp}"
}

run_all() {
  local tests=(
    test_help
    test_no_args
    test_unknown_subcmd
    test_subcommand_help
    test_spec_stack
    test_spec_aliases
    test_spec_invalid
    test_audit_missing_dir
    test_audit_empty_dir
    test_audit_conforming_project
    test_audit_default_dir
    test_audit_without_jq
    test_audit_drifting_project
    test_scaffold_dry_run
    test_scaffold_skip_install_and_audit
    test_installer
    test_installer_relative_target
    test_afws_install_target
  )

  local pass=0
  local fail=0
  local t
  for t in "${tests[@]}"; do
    local res=0
    set +e
    (
      set -e
      "${t}"
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
