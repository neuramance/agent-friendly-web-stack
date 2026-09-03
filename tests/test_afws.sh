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
}

test_spec_stack() {
  local out
  out="$("${AFWS}" spec stack)"
  printf '%s\n' "${out}" | grep -q "Next.js App Router"
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

test_audit_conforming_project() {
  local tmp
  tmp="$(mktemp -d)"
  touch "${tmp}/bun.lock"
  touch "${tmp}/next.config.ts"
  touch "${tmp}/babel.config.js"
  touch "${tmp}/postcss.config.js"
  touch "${tmp}/proxy.ts"
  mkdir -p "${tmp}/app"
  mkdir -p "${tmp}/supabase/migrations"

  cat <<'EOF' > "${tmp}/package.json"
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

  local out
  out="$("${AFWS}" audit "${tmp}")"
  local code=$?
  rm -rf "${tmp}"

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
  out="$("${AFWS}" audit "${tmp}" || code=$?)"
  rm -rf "${tmp}"

  test "${code}" -eq 1
  printf '%s\n' "${out}" | grep -q "pages/ router forbidden"
  printf '%s\n' "${out}" | grep -q "src/ indirection forbidden"
  printf '%s\n' "${out}" | grep -q "tailwindcss forbidden"
  printf '%s\n' "${out}" | grep -q "packageManager != bun@"
}

test_scaffold_dry_run() {
  local out
  out="$("${AFWS}" scaffold my-test-app --dry-run)"
  printf '%s\n' "${out}" | grep -q "bunx create-next-app@latest"
  printf '%s\n' "${out}" | grep -q "@stylexjs/stylex"
}

test_installer() {
  local tmp
  tmp="$(mktemp -d)"
  "${INSTALLER}" --target "${tmp}" --no-bin >/dev/null
  test -f "${tmp}/.agents/skills/agent-friendly-web-stack/SKILL.md"
  test -L "${tmp}/.claude/skills/agent-friendly-web-stack"
  rm -rf "${tmp}"
}

run_all() {
  local tests=(
    test_help
    test_spec_stack
    test_spec_invalid
    test_audit_missing_dir
    test_audit_empty_dir
    test_audit_conforming_project
    test_audit_drifting_project
    test_scaffold_dry_run
    test_installer
  )

  local pass=0
  local fail=0
  local t
  for t in "${tests[@]}"; do
    if "${t}"; then
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
