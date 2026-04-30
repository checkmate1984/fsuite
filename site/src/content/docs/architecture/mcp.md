---
title: MCP Adapter
description: How fsuite exposes itself as an MCP server for Claude Code and other MCP-aware agents.
sidebar:
  order: 1
---

<div class="fs-drone">
  <div class="fs-drone-head">
    <span class="fs-drone-call">MCP</span>
    <span class="fs-drone-tagline">The transport · structured tool exposure for MCP-aware agents</span>
  </div>
  <div class="fs-drone-meta">
    <div><b>Path</b><span>mcp/index.js</span></div>
    <div><b>Wraps</b><span>all 14 fsuite tools</span></div>
    <div><b>Renders</b><span>Monokai structured output</span></div>
    <div><b>Pipe semantics</b><span>sequential (use fbash)</span></div>
  </div>
</div>

## What it does

The MCP adapter (`mcp/index.js`) wraps every fsuite CLI tool in a Model Context Protocol server so that MCP-aware agents — Claude Code, Hermes, Codex with MCP — can call the tools directly without going through their native `Bash` tool.

The adapter does three things:

1. **Schema exposure** — declares each fsuite tool with structured JSON Schema so agents know exactly what arguments to pass
2. **Token-budget enforcement** — caps responses even if a tool emits more than the budget allows
3. **Monokai rendering** — pretty-prints search results, file reads, and tool outputs in the agent's chat surface (the part the author loves most)

Every response includes a `next_hint` field suggesting the strongest follow-up tool, derived from `fmetrics` combo data.

## Why it exists

See [the lightbulb moment](/fsuite/story/lightbulb/). Short version: native `Bash` is a free-form shell with unbounded output. Wrapping fsuite in MCP gives agents structured, schema-aware tool calls instead. The agent stops *running shell commands* and starts *calling tools that return validated JSON*.

## Installation

From the fsuite repo root:

```bash
cd mcp
npm install
```

Then register the server with your MCP-aware client. For Claude Code, add to `~/.claude/mcp_servers.json`:

```json
\{
  "mcpServers": \{
    "fsuite": \{
      "command": "node",
      "args": ["/absolute/path/to/fsuite/mcp/index.js"]
    \}
  \}
\}
```

For other MCP clients, follow their config conventions — the server is stdio-based and uses standard MCP tool exposure.

<div class="fs-mcp-note">
  <h4>⚠ MCP CALLERS — SEQUENTIAL LIMIT</h4>
  <p>The MCP protocol does not pipe. Every fsuite call is sequential — the agent calls <code>fsearch</code>, gets the result, then calls <code>fmap</code> with that result. Correct, but slower than a real pipeline.</p>
  <p><b>Escape hatch:</b> route through <code>fbash</code>. The CLI tools inside it run a real shell, and real shells pipe in parallel. One <code>fbash</code> call gives you full pipeline speed even from MCP.</p>
</div>

## The fbash escape hatch

Inside `fbash`, a real Unix pipe runs at native speed:

```bash
fbash "fsearch -o paths '*.py' src | fmap -o json"
```

That's one MCP call that runs a 2-step pipeline at CLI speed. Use this pattern whenever you'd reach for two sequential MCP calls — they almost always combine into one `fbash` invocation.

```bash
# Triple-chain in one MCP call
fbash "fsearch -o paths '*.py' src \
       | fcontent -o paths 'class' \
       | fmap -o json"
```

## What you get

- All 14 tools exposed as MCP tools with structured schemas
- Token-budgeted responses (enforced even if a tool emits more)
- Monokai-colored rendering of search results, file reads, and tool outputs
- `next_hint` field on every response suggesting the best follow-up

## What it does NOT replace

- **`fbash` is not bypassed.** The MCP wraps it like any other tool. Use `fbash` whenever you'd want shell semantics (pipes, env vars, session state).
- **Hooks are orthogonal.** [Hooks](/fsuite/architecture/hooks/) *block* native `Read` / `Write` / `Edit` / `Grep` / `Glob`. MCP *exposes* fsuite. Use both — hooks force the agent off native primitives, MCP gives it fsuite as the alternative.

## Verification

After registering the server, ask your agent:

```
List the fsuite tools you can call.
```

It should enumerate all 14 by name. If it can only call `fbash` and a couple of others, the schema declaration is the issue — check `mcp/index.js` for the tool-list export.

## Related

- [Hooks &amp; enforcement](/fsuite/architecture/hooks/) — block native primitives so agents prefer fsuite
- [Telemetry](/fsuite/architecture/telemetry/) — what gets recorded on every MCP call
- [Chain combinations](/fsuite/architecture/chains/) — when to fbash-pipe vs when to MCP-call sequentially
