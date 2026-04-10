---
title: Hooks & Enforcement
description: How to block an agent's native Read/Write/Edit/Grep/Glob tools and force them to use fsuite instead.
sidebar:
  order: 2
---

## The problem

By default, coding agents reach for their native tools — `Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`. Those tools flood context, read entire files, and fail on whitespace drift. fsuite exists to fix that, but only if the agent actually uses fsuite.

## The solution

Claude Code hooks can intercept tool calls *before* they run, inspect the tool name, and either allow, reject, or redirect. A `PreToolUse` hook that rejects `Read` with the message `"Use fsuite fread instead"` will force the agent to switch tools.

## Example hook configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Use fsuite fread instead of native Read. Use fsuite structured reads with symbol/range control. Example: fread --symbol NAME path' >&2; exit 2"
          }
        ]
      }
    ]
  }
}
```

Apply the same pattern to `Write`, `Edit`, `Grep`, and `Glob` to fully enforce fsuite usage.

## Why hooks + MCP together

Hooks **block** native tools. They cannot route or translate calls. MCP **exposes** fsuite tools with schemas. An agent under both:

1. Reaches for `Read` → hook blocks → agent sees the error message
2. Agent tries again with `fread` from the fsuite MCP → succeeds

The two layers are complementary, not redundant.

> **TODO:** ship a `scripts/install-hooks.sh` that adds the correct hook config to `~/.claude/settings.json` idempotently.
