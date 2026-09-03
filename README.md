```
╭──────────────────────────────────────────────────╮
│ ● ● ●  afws · audit                              │
├──────────────────────────────────────────────────┤
│                                                  │
│  $ afws audit my-saas-app                        │
│                                                  │
│  ✓ runtime      bun.lock · bun@1.3.14 · node 22  │
│  ✓ framework    next.js app router · no src/     │
│  ✓ styling      stylex · zero-runtime atomic css │
│  ✓ data         supabase ssr · sql migrations    │
│  ✓ scripts      16/16 canonical gates present    │
│  ✓ tests        vitest · playwright · pgtap      │
│                                                  │
│  6 ok · 0 drift · conforming to stack spec       │
│                                                  │
╰──────────────────────────────────────────────────╯
```

**The Agent-Friendly Web Stack: one conventional path per concern, explicit system boundaries, deterministic local verification, and zero combinatorial thrashing.**

`bash 3.2+` · zero dependencies · validated on macOS, Linux, and Apple silicon

## Why this exists

AI coding agents do not fail because they cannot write code. They fail because modern web development offers a combinatorial explosion of choices:

- **Styling thrashing:** 6 ways to style a button (Tailwind classes, `@apply`, CSS Modules, styled-components, Emotion, inline styles) lead agents to mix paradigms, produce conflicting classes, and break specificity.
- **Data access drift:** ORMs with drifting migration states, client-side data queries leaking credentials, and undocumented route handlers create architectural chaos.
- **Speculative caching:** Uncontrolled caching models accidentally serve stale authentication state or leak cross-tenant records.
- **Broken verification loops:** Missing or non-deterministic test suites leave agents guessing whether a change worked, resulting in infinite repair loops.

The **Agent-Friendly Web Stack** solves this by establishing **one constrained, executable path per concern**. It eliminates architectural ambiguity so agents converge on correct solutions in minimal iterations.

## The 16 Stack Decisions

Every layer has exactly one prescribed choice backed by a concrete requirement:

| Layer               | Choice                         | Why & Agent Failure Prevented                                                           |
| ------------------- | ------------------------------ | --------------------------------------------------------------------------------------- |
| **Language**        | TypeScript (Strict)            | Route-aware types eliminate untyped parameters and boundary mistakes.                   |
| **UI**              | React (Next.js)                | Server Components by default; leaf Client Components prevent client-side secret leaks.  |
| **Framework**       | Next.js App Router             | Flat colocation in `app/`; no `src/` indirection, no Pages Router ambiguity.            |
| **Build system**    | Turbopack                      | Sub-second feedback loops for rapid, deterministic local iteration.                     |
| **Styling**         | Meta StyleX                    | Zero-runtime atomic CSS with typed tokens (`stylex.props`); eliminates class collision. |
| **Package manager** | Bun                            | Instant script execution and deterministic lockfile (`bun.lock`).                       |
| **Runtime**         | Node.js Active LTS             | Production compatibility baseline; avoids unsupported Edge Runtime edge cases.          |
| **Backend**         | Supabase Cloud                 | Managed PostgreSQL, Auth, and Storage with zero operational overhead.                   |
| **Database**        | Supabase Postgres              | Relational data integrity, schema constraints, and atomic SQL functions.                |
| **Data access**     | User-Scoped `@supabase/ssr`    | Server-only data boundary; Row Level Security enforced at the database level.           |
| **Database types**  | Supabase CLI Generated         | Machine-generated types prevent drifting, handwritten type definitions.                 |
| **Authentication**  | Supabase Auth + `proxy.ts`     | Secure cookie sessions with standard Next.js cookie refresh middleware.                 |
| **Authorization**   | PostgreSQL RLS + `getClaims()` | Least-privilege PostgreSQL grants; identity verified at every data access.              |
| **Validation**      | Zod                            | Strict boundary parsing at untrusted edges; types derived from schemas.                 |
| **Unit & UI tests** | Vitest + RTL + jsdom           | Fast, deterministic tests for domain logic and synchronous component trees.             |
| **E2E tests**       | Playwright                     | Real browser verification for async Server Components and critical journeys.            |

## Quick start

### 1. Install the skill

Install the skill into your AI agent environment (`.agents/skills` and `.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/neuramance/agent-friendly-web-stack/main/install.sh | bash
```

Or clone and install locally:

```bash
git clone https://github.com/neuramance/agent-friendly-web-stack.git
cd agent-friendly-web-stack
./install.sh
```

### 2. Audit any repository

Audit any web application against the 16 stack decisions:

```bash
bin/afws audit /path/to/project
```

Exit codes: `0` conforming · `1` drift detected (with detailed checklist) · `2` target error.

### 3. Scaffold a new application

Scaffold a clean, conforming Next.js App Router project configured with StyleX and Supabase:

```bash
bin/afws scaffold my-app
```

Use `--dry-run` to preview the exact execution steps without modifying disk.

### 4. Query the specification

Inspect normative sections directly from the command line:

```bash
bin/afws spec stack     # Required stack breakdown
bin/afws spec stylex    # StyleX contract and token rules
bin/afws spec data      # Data and security boundaries
bin/afws spec gate      # Completion gate steps
```

## The Canonical 16-Script Contract

Every conforming application exposes these canonical scripts in `package.json`:

```json
{
  "scripts": {
    "setup": "bunx playwright install chromium && supabase start",
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
    "db:types": "supabase gen types typescript --local > lib/database.types.ts",
    "check": "bun run format:check && bun run lint && bun run typecheck && bun run test && bun run build && bun run test:db && bun run test:e2e"
  }
}
```

`bun run check` is the single non-source-mutating completion gate, executing all verifications in fastest-failure order.

## For AI Agents

Read **[`SKILL.md`](SKILL.md)** and **[`AGENTS.md`](AGENTS.md)**.

The skill is registered for Claude Code, Codex, Antigravity, OpenCode, and Cursor under:

- `.agents/skills/agent-friendly-web-stack/SKILL.md`
- `.claude/skills/agent-friendly-web-stack` (symlink)

## License

MIT © 2026 neuramance
