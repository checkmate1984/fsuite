---
title: 🔀 fs
description: Universal search orchestrator — auto-routes to the right fsuite tool
sidebar:
  order: 1
---

## Universal search orchestrator — auto-routes to the right fsuite tool

`fs` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

## Help output

The content below is the **live** `--help` output of `fs`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fs — unified search meta-tool

USAGE
  fs [OPTIONS] <query> [path]

OPTIONS
  -s, --scope GLOB     Glob filter for file narrowing (e.g. "*.py")
  -i, --intent MODE    Override: auto|file|content|symbol|nav (default: auto)
  --config-only        Narrow file/nav searches to config-like roots under [path]
  -c, --compact        Nav-only compact JSON: relative paths, no next_hint
  -o, --output MODE    pretty|json (default: pretty for tty, json for pipe)
  -p, --path PATH      Search root (default: .). Overrides positional [path].
  --max-candidates N   Override candidate file cap (default: 50)
  --max-enrich N       Override enrichment file cap (default: 15)
  --timeout N          Override wall time cap in seconds (default: 10)
  -h, --help           Show help
  --version            Show version

DESCRIPTION
  Classifies your query as file / symbol / content intent, then builds
  and runs the optimal fsuite tool chain. Returns ranked hits with
  enrichment and a next_hint for follow-up refinement.

EXAMPLES
  fs "*.py"                         # file search — glob
  fs renderTool                     # symbol search — camelCase detected
  fs "error loading config" src/    # content search — multi-word
  fs -s "*.ts" McpServer            # symbol search, scoped to .ts files
  fs -i symbol authenticate         # force symbol intent
  fs -i nav docs                    # explicit path navigation
  fs --config-only opencode.json ~  # fast config-file lookup under HOME
  fs -i nav -c docs                 # nav-only compact JSON/result shaping
  fs -o json "*.rs" | jq '.hits'    # JSON output for piping
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fs fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fs)
