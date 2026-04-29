---
title: 📂 fls
description: Structured directory listing with recon mode
sidebar:
  order: 3
---

## Structured directory listing with recon mode

`fls` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

<div class="fs-drone">
  <div class="fs-drone-head">
    <span class="fs-drone-call">fls</span>
    <span class="fs-drone-tagline">Structured directory listing · ls replacement with recon mode</span>
  </div>
  <div class="fs-drone-meta">
    <div><b>Role</b><span class="role-recon">RECON</span></div>
    <div><b>Chain position</b><span>specialist</span></div>
    <div><b>Pipe</b><span>not chainable</span></div>
    <div><b>Output</b><span>pretty · json</span></div>
  </div>
</div>

`fls` is the surgical version of `ftree` — one directory, one level deep (configurable), with structured metadata: type, size, language hints. When `ftree` would be too noisy and `cat`-ing a path tells you nothing, `fls` shows you exactly what's in this folder and nothing else.

`--recon` mode adds per-entry sizes and counts in a clean column layout. JSON mode lets agents make programmatic decisions on what to read next.

## Canonical chains

```bash
# Structured listing — type, size, language hints
fls /project/src

# Recon mode — sizes + counts, scannable column layout
fls /project/src/telegram --recon

# JSON for agents
fls /project -o json

# Limit depth (default 1, often plenty)
fls /project --depth 1
```

## Terminal sample

<div class="fs-term">
  <div class="fs-term-bar"><b>fls(/project/src/telegram)</b> · recon mode</div>
<pre><span class="tk-tool">fls</span>(<span class="tk-str">"/home/user/Projects/nightfox/src/telegram"</span> | mode: <span class="tk-str">"recon"</span>)
  <span class="tk-arrow">└─</span> Recon(/home/user/Projects/nightfox/src/telegram, depth=1)
     <span class="tk-num">7</span> entries (7 visible, <span class="tk-num">0</span> default-excluded)
<span class="tk-mut">·</span>
     message-sender.ts          —    <span class="tk-num">17.9K</span>
     telegraph.ts               —    <span class="tk-num">12K</span>
     terminal-renderer.ts       —    <span class="tk-num">10.3K</span>
     markdown.ts                —    <span class="tk-num">6.7K</span>
     terminal-settings.ts       —    <span class="tk-num">2.8K</span>
     session-lane.ts            —    <span class="tk-num">1.2K</span>
     deduplication.ts           —    <span class="tk-num">1005</span>
<span class="tk-mut">·</span></pre>
</div>

## Help output

The content below is the **live** `--help` output of `fls`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fls — list directory contents (thin ftree router)

USAGE
  fls [options] [path]

MODES
  (default)        List direct children          → ftree -L 1
  -t, --tree       Little tree, shallow structure → ftree -L 2
  -r, --recon      Recon with sizes and counts   → ftree --recon -L 1

OPTIONS
  -o, --output <fmt>   pretty (default) or json
  -h, --help           Show this help
  --version            Show version

HEADLESS / AI AGENT USAGE
  fls -o json /path      Structured JSON — inherits ftree's JSON contract.
  fls -t -o json /path   Shallow tree as JSON.
  fls -r -o json /path   Recon metadata as JSON.

  Output IS ftree output. Parse the same fields: tool, mode, depth,
  total_dirs, total_files, entries (recon), tree output (tree mode).

EXAMPLES
  fls                    List cwd
  fls src/               List src/
  fls -t src/            Shallow tree of src/
  fls -r .               Recon: sizes and item counts
  fls -o json src/       JSON for agents
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fls fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fls)
