---
title: MCP Adapter
description: How fsuite exposes itself as an MCP server for Claude Code and other MCP-aware agents.
sidebar:
  order: 1
---

## What it does

The MCP adapter (`mcp/index.js`) wraps every fsuite CLI tool in a Model Context Protocol server so that MCP-aware agents — Claude Code, Hermes, etc. — can call the tools directly without going through their native `Bash` tool.

## Why it exists

See [the lightbulb moment](/story/lightbulb/). Short version: the MCP was built so agents wouldn't need to pipe through their native `Bash` tool to run fsuite commands. It also adds Monokai-themed structured output rendering, which is the part of fsuite that the author loves the most about the MCP path.

## Installation

```bash
# From the fsuite repo root
cd mcp
npm install
```

Then register the server with your MCP-aware client. For Claude Code, add to `~/.claude/mcp_servers.json`:

```json
{
  "mcpServers": {
    "fsuite": {
      "command": "node",
      "args": ["/absolute/path/to/fsuite/mcp/index.js"]
    }
  }
}
```

## What you get

- All 14 tools exposed as MCP tools with structured schemas
- Token-budgeted responses (the MCP layer enforces caps even if a tool emits more)
- Monokai-colored rendering of search results, file reads, and tool outputs
- `next_hint` field on every response suggesting the best follow-up tool

## What it does NOT replace

- `fbash` still exists and is still the right tool for shell execution. The MCP wraps `fbash`, it doesn't bypass it.
- The hooks layer ([hooks page](/architecture/hooks/)) is orthogonal — use hooks to *block* native tools, use MCP to *expose* fsuite tools cleanly.

> **TODO:** expand this page with auto-generated tool schema reference once the MCP index.js output format stabilizes.
