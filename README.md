# Agent-Friendly Web Stack

**One default stack for greenfield web apps, packaged as an agent skill.**

Built for new browser-based, authenticated, relational apps that work request-response: SaaS products, internal tools, CRUD apps. The skill picks the tools and leaves implementation and workflow to the project. Agents keep an existing app's stack unless you ask to migrate, and depart from a default only when a concrete requirement or you call for it.

## The stack

| Layer         | Choice                                                                  |
| ------------- | ----------------------------------------------------------------------- |
| Language      | TypeScript                                                              |
| Framework     | Next.js App Router · React · Turbopack                                  |
| Styling       | StyleX                                                                  |
| Tooling       | Bun for packages and scripts · Node.js Active LTS runtime               |
| Backend       | Supabase Cloud · Supabase Postgres                                      |
| Auth          | Supabase Auth with `@supabase/ssr`                                      |
| Data          | `@supabase/supabase-js` · PostgreSQL grants and Row Level Security      |
| Schema        | Supabase CLI · SQL migrations · generated TypeScript types              |
| Validation    | Zod                                                                     |
| Testing       | Vitest and Testing Library · pgTAP via Supabase CLI · Playwright        |
| Lint & format | ESLint · Prettier                                                       |

Releases are chosen at scaffold time to be supported and mutually compatible. The full definition is [`SKILL.md`](SKILL.md).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/neuramance/agent-friendly-web-stack/main/install.sh | bash
```

This installs to `~/.agents/skills` and `~/.claude/skills`. From a clone, run `./install.sh --local` to install into the current project, or `./install.sh --target <dir>` to install into another directory.

## License

MIT © 2026 neuramance
