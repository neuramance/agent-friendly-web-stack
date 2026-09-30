# Agent-Friendly Web Stack

**One default stack for greenfield web apps, packaged as an agent skill.**

Built for new browser-based, authenticated, relational apps that work request-response: SaaS products, internal tools, CRUD apps. It follows create-next-app's defaults, with Oxlint in place of ESLint, and names one choice for every other concern, so agents build instead of re-deciding the stack. Agents keep an existing app's stack unless you ask to migrate, and depart from a default only when a concrete requirement or you call for it.

## The stack

| Concern | Choice |
| --- | --- |
| Language | TypeScript |
| Application framework and UI | Next.js App Router with React |
| Application bundler | Turbopack |
| Styling | Tailwind CSS |
| UI components | shadcn/ui |
| Package manager and task runner | Bun |
| Application runtime | Latest Node.js LTS |
| Backend platform | Supabase Cloud |
| Database | Supabase Postgres |
| Authentication | Supabase Auth with `@supabase/ssr` |
| Data access | `@supabase/supabase-js` |
| Database authorization | PostgreSQL grants and Row Level Security |
| Migrations and database types | Supabase CLI, SQL migrations, and generated TypeScript types |
| Runtime validation | Zod |
| Unit and component testing | Vitest and Testing Library |
| Database testing | pgTAP through Supabase CLI |
| Browser and end-to-end testing | Playwright |
| Linting | Oxlint |
| Formatting | Oxfmt |

[`SKILL.md`](SKILL.md) adds the rules agents follow for releases, linting, and database security.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/neuramance/agent-friendly-web-stack/main/install.sh | bash
```

This installs to `~/.agents/skills` and `~/.claude/skills`. From a clone, run `./install.sh --local` to install into the current project, or `./install.sh --target <dir>` to install into another directory.

## License

MIT © 2026 neuramance
