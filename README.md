# Agent-Friendly Web Stack

An agent skill that selects the core stack for greenfield authenticated relational web applications, such as SaaS apps, internal tools, and CRUD products: TypeScript, Next.js App Router with React, StyleX, Bun, Node.js, and Supabase. It preserves an existing application's stack unless a migration is explicitly requested.

The stack is defined in [`SKILL.md`](SKILL.md).

## Install

Install to `~/.agents/skills` and `~/.claude/skills`:

```bash
curl -fsSL https://raw.githubusercontent.com/neuramance/agent-friendly-web-stack/main/install.sh | bash
```

From a clone, install globally (the default), into the current project, or into a chosen directory:

```bash
./install.sh --global
./install.sh --local
./install.sh --target <dir>
```

## License

MIT © 2026 neuramance
