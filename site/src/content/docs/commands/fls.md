---
title: 📂 fls
description: Structured directory listing with recon mode
sidebar:
  order: 3
---

## Structured directory listing with recon mode

`fls` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

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

- [fsuite mental model](/getting-started/mental-model/) — how fls fits into the toolchain
- [Cheat sheet](/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fls)
