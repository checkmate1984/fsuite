---
title: 🔀 fs
description: Universal search orchestrator — auto-routes to the right fsuite tool
sidebar:
  order: 1
---

## Universal search orchestrator — auto-routes to the right fsuite tool

`fs` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

<div class="fs-drone">
  <div class="fs-drone-head">
    <span class="fs-drone-call">fs</span>
    <span class="fs-drone-tagline">Unified search orchestrator · the front door</span>
  </div>
  <div class="fs-drone-meta">
    <div><b>Role</b><span class="role-recon">RECON</span></div>
    <div><b>Chain position</b><span>1 (entry)</span></div>
    <div><b>Auto-routes to</b><span>fsearch · fcontent · fmap</span></div>
    <div><b>Intent modes</b><span>auto · file · content · symbol · nav</span></div>
  </div>
</div>

`fs` is the meta-tool — feed it any query and it classifies the intent (filename pattern, in-file content, symbol name, or path navigation), builds the right chain of underlying tools, and returns ranked, enriched hits with a `next_hint` for follow-up.

When in doubt, start here. When you know the exact tool you need, skip it.

## Canonical chains

`fs` is the entry point of every recon chain. It does not pipe — it returns final ranked hits with a `next_hint` you call next.

```bash
# Symbol scout — returns hits + next_hint to fread the right block
fs "renderTool"

# Filename intent forced — looks for files literally named like *.log
fs --intent file "*.log" /var/log

# Scoped symbol search — narrow to TypeScript only
fs --scope "*.ts" McpServer

# Pipe to jq — JSON mode auto-engages on pipe
fs -o json "*.rs" | jq '.hits'
```

## Terminal sample

<div class="fs-term">
  <div class="fs-term-bar"><b>fs(teleport)</b> · symbol intent · <span class="fs-term-cost">328ms · ~80 tokens</span></div>
<pre><span class="tk-dot">●</span> Now let me find the teleport code:
<span class="tk-mut">·</span>
<span class="tk-tool">fs</span>(teleport | path: <span class="tk-str">"/home/user/Projects/nightfox/src"</span> | intent: <span class="tk-str">"symbol"</span> | scope: <span class="tk-str">"*.ts"</span>)
  <span class="tk-arrow">└─</span> symbol (high) via fsearch <span class="tk-arrow">→</span> fcontent <span class="tk-arrow">→</span> fmap
     explicit intent=symbol
     <span class="tk-num">50</span> candidates, <span class="tk-num">1</span> enriched, <span class="tk-num">328</span>ms
<span class="tk-mut">·</span>
     nightfox/src/claude/command-parser.ts <span class="tk-com">(1 matches)</span>
       <span class="tk-num">50</span>  · <span class="tk-str">'/teleport'</span>  <span class="tk-com">// Move session to terminal (forked)</span>
<span class="tk-mut">·</span>
     <span class="tk-cyan">next</span> <span class="tk-arrow">→</span> fread(path: <span class="tk-str">"/home/user/.../command-parser.ts"</span>, around: teleport)
<span class="tk-mut">·</span></pre>
</div>

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
