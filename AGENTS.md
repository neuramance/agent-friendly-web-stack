# AGENTS.md

Operating contract for AI coding agents working on or with the Agent-Friendly Web Stack.

## Repository Quality Gate

Before completing any change in this repository, execute:

```bash
scripts/agent-verify
```

A red gate means the task is incomplete. Fix the underlying code, never the check.

## Operating Rules

1. Zero comments: Write zero comments in all code. Shebangs (`#!/usr/bin/env bash`) and machine directives are permitted.
2. Max correctness: Solutions must work end-to-end, verified with deterministic executable tests.
3. Least code: Eliminate accidental complexity, extra layers, and speculative abstractions. Keep diffs irreducible.
4. Locality of behavior: Colocate concerns where they execute instead of fracturing cohesive logic.
