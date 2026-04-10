---
title: 🔬 fprobe
description: Binary / bundle inspection + patching
sidebar:
  order: 13
---

## Binary / bundle inspection + patching

`fprobe` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

## Help output

The content below is the **live** `--help` output of `fprobe`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fprobe — binary/opaque file reconnaissance

USAGE
  fprobe strings <file> [--filter <literal>] [--ignore-case] [-o pretty|json]
  fprobe scan    <file> --pattern <literal> [--context N] [--ignore-case] [-o pretty|json]
  fprobe window  <file> --offset N [--before N] [--after N] [--decode printable|utf8|hex] [-o pretty|json]
  fprobe patch   <file> --target <text> --replacement <text> [--dry-run]

  fprobe --version
  fprobe --help

DESCRIPTION
  Binary reconnaissance and surgical patching for opaque files — compiled
  binaries, SEA bundles, packed assets.

  strings   Extract printable ASCII runs (≥6 chars). --filter narrows to matches.
  scan      Find literal byte patterns. Returns offset + surrounding context.
  window    Read raw bytes at a known offset. Decode as printable, utf8, or hex.
  patch     Find and replace a literal byte pattern. Same-length enforced (pads
            with spaces if replacement is shorter). Creates .bak backup on first
            write. Uses rename for atomic swap (handles "Text file busy").

OUTPUT MODES
  -o pretty   Human-readable (default for terminal)
  -o json     Machine-readable JSON (default when piped)

EXAMPLES
  fprobe strings claude-binary --filter "renderTool"
  fprobe scan claude-binary --pattern "userFacingName" --context 500
  fprobe window claude-binary --offset 112202147 --before 200 --after 3000
  fprobe window claude-binary --offset 0 --after 16 --decode hex
  fprobe patch claude-binary --target 'if(P&&!P.success)return null' --replacement 'if(0&&!P.success)return null'
  fprobe patch claude-binary --target 'old text' --replacement 'new text' --dry-run
```

## See also

- [fsuite mental model](/getting-started/mental-model/) — how fprobe fits into the toolchain
- [Cheat sheet](/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fprobe)
