---
title: 🗺️ fmap
description: Symbol cartography — functions, classes, imports, constants
sidebar:
  order: 6
---

## Symbol cartography — functions, classes, imports, constants

`fmap` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

<div class="fs-drone">
  <div class="fs-drone-head">
    <span class="fs-drone-call">fmap</span>
    <span class="fs-drone-tagline">Symbol cartography · the keystone — the gap native CLI doesn't fill</span>
  </div>
  <div class="fs-drone-meta">
    <div><b>Role</b><span class="role-keystone">KEYSTONE</span></div>
    <div><b>Chain position</b><span>4 (bridge to read)</span></div>
    <div><b>Pipe</b><span>consumer (stdin paths)</span></div>
    <div><b>Languages</b><span>50+</span></div>
  </div>
</div>

**`fmap` is the headliner.** Native CLI has nothing like it. Given a file or a directory, `fmap` extracts the structural skeleton — every function, class, import, type, constant — with line numbers, in seconds, across 50+ languages.

Why it matters: an agent that runs `fmap` first reads ~1% of a file's bytes and learns what's in it. Then it picks the symbol it actually wants and `fread`s exactly that block. Compare that to `cat`-ing a 3000-line module to figure out which function to look at.

This is the keystone of every investigation chain.

## Canonical chains

```bash
# Map a single file
fmap /project/src/auth.py

# Map every source file in a project
fmap /project

# Filter by symbol-name match — surgical
fmap --name authenticate -o json /project

# Pipe currency — fsearch produces, fmap consumes
fsearch -o paths '*.py' /project | fmap -o json

# Filter symbol type
fmap -t function /project
fmap -t class /project

# Triple chain — narrow text first, then map structure
fcontent -o paths "TODO" /project | fmap -o json

# Followed by surgical fread
fmap --name handleRequest -o json /project | jq '.symbols[0]'
fread /project/src/server.ts --symbol handleRequest
```

## Terminal sample

<div class="fs-term">
  <div class="fs-term-bar"><b>fmap(reconciler.ts)</b> · 27 symbols · typescript <span class="fs-term-cost">~98K tokens saved vs cat</span></div>
<pre><span class="tk-tool">fmap</span>(path: <span class="tk-str">"/home/user/Projects/brane-code/src/ink/reconciler.ts"</span>)
  [ <span class="tk-num">27</span> symbols | typescript ]
     <span class="tk-num">3</span>    <span class="tk-key">import</span>     <span class="tk-key">import</span> &#123; appendFileSync &#125; <span class="tk-key">from</span> <span class="tk-str">'fs'</span>
     <span class="tk-num">4</span>    <span class="tk-key">import</span>     <span class="tk-key">import</span> createReconciler <span class="tk-key">from</span> <span class="tk-str">'react-reconciler'</span>
     <span class="tk-num">5</span>    <span class="tk-key">import</span>     <span class="tk-key">import</span> &#123; getYogaCounters &#125; <span class="tk-key">from</span> <span class="tk-str">'src/native-ts/yoga-layout/index'</span>
     <span class="tk-num">28</span>   <span class="tk-key">import</span>     <span class="tk-key">import</span> applyStyles, &#123; <span class="tk-key">type</span> Styles, <span class="tk-key">type</span> TextStyles &#125; <span class="tk-key">from</span> <span class="tk-str">'./styles'</span>
     <span class="tk-num">60</span>   <span class="tk-key">type</span>       <span class="tk-key">type</span> AnyObject = Record&lt;string, unknown&gt;
     <span class="tk-num">92</span>   <span class="tk-key">function</span>   <span class="tk-key">const</span> diff = (before: AnyObject, after: AnyObject): AnyObject
     <span class="tk-num">95</span>   <span class="tk-key">function</span>   <span class="tk-key">const</span> cleanupYogaNode = (node: DOMElement | TextNode): <span class="tk-key">void</span>
     <span class="tk-num">114</span>  <span class="tk-key">function</span>   <span class="tk-key">function</span> setEventHandler(node: DOMElement, key: string, value: <span class="tk-key">unknown</span>)
     <span class="tk-num">158</span>  <span class="tk-key">function</span>   <span class="tk-key">export function</span> getOwnerChain(fiber: unknown): string[] &#123;
     <span class="tk-num">191</span>  <span class="tk-key">constant</span>   <span class="tk-key">const</span> COMMIT_LOG = process.env.<span class="tk-fn">CLAUDE_CODE_COMMIT_LOG</span>
     <span class="tk-num">205</span>  <span class="tk-key">export</span>     <span class="tk-key">export function</span> recordYogaMs(ms: number): <span class="tk-key">void</span>
     <span class="tk-num">217</span>  <span class="tk-key">function</span>   <span class="tk-key">export function</span> resetProfileCounters(): <span class="tk-key">void</span>
<span class="tk-mut">·</span></pre>
</div>

## Help output

The content below is the **live** `--help` output of `fmap`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fmap — code cartography: extract structural skeleton from source files (agent-friendly)

USAGE
  fmap [OPTIONS] [path]

MODES
  1) Directory mode:
     fmap /project
     - Scans all recognized source files under /project

  2) Single file mode:
     fmap /project/file.js
     - Extracts symbols from one file

  3) Piped file-list mode (best with fsearch):
     fsearch -o paths '*.py' /project | fmap -o json
     - Reads file paths from stdin

OPTIONS
  -o, --output pretty|paths|json
      pretty: human-readable grouped by file (default)
      paths:  unique file paths with symbols, one per line
      json:   structured JSON with symbol metadata

  -m, --max-symbols N
      Cap total symbols shown. Default: 500

  -n, --max-files N
      Cap files processed. Default: 500 (directory), 2000 (stdin)

  -L, --lang <lang>
      Force language (auto-detect by default).
                   Supported: python, javascript, typescript, kotlin, swift, rust, go, java,
                   c, cpp, ruby, lua, php, bash, dockerfile, makefile, yaml, toml, ini, cuda,
                   mojo, hcl, protobuf, graphql, csharp, zig, env, compose, packagejson,
                   gemfile, gomod, requirements, sql, css, html, xml, perl, rlang, elixir,
                   scala, zsh, dart, objc, haskell, julia, powershell, groovy, ocaml,
                   clojure, wasm, markdown

  -t, --type <type>
      Filter symbol types: function, class, import, type, export, constant

  --name <symbol>
      Rank/filter extracted symbols by exact then substring symbol-name match.

  --no-imports
      Skip import lines. Overridden by -t import.

  --no-default-ignore
      Disable built-in ignore list in directory mode.

  -q, --quiet
      Suppress header lines in pretty mode.

  --project-name <name>
      Override project name in telemetry.

  --self-check
      Verify grep is available.

  --install-hints
      Print how to install grep and exit.

  -h, --help
      Show help and exit.

  --version
      Print version and exit.

  SUPPORTED LANGUAGES
    Python, JavaScript, TypeScript, Kotlin, Swift, Rust, Go, Java, C, C++,
    Ruby, Lua, PHP, Bash/Shell, Dockerfile, Makefile, YAML, Markdown

HEADLESS / AI AGENT USAGE
  fmap -o json /project
  fmap --name authenticate -o json /project/src
  fsearch -o paths '*.py' /project | fmap -o json
  fmap -t function -o json /project
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fmap fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fmap)
