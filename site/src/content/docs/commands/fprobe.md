---
title: 🔬 fprobe
description: Binary / bundle inspection + patching
sidebar:
  order: 13
---

## Binary / bundle inspection + patching

`fprobe` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

<div class="fs-drone">
  <div class="fs-drone-head">
    <span class="fs-drone-call">fprobe</span>
    <span class="fs-drone-tagline">Binary / bundle inspection + patching · text tools can't reach</span>
  </div>
  <div class="fs-drone-meta">
    <div><b>Role</b><span class="role-binary">BINARY</span></div>
    <div><b>Chain position</b><span>specialist branch</span></div>
    <div><b>Use when</b><span>target is compiled or obfuscated</span></div>
    <div><b>Subcommands</b><span>strings · scan · window · patch</span></div>
  </div>
</div>

`fprobe` is for the targets text tools can't read — compiled binaries, minified bundles, obfuscated libraries. Four subcommands cover the workflow:

- `strings` — extract printable strings (with length and substring filters)
- `scan` — find a literal byte pattern, return offsets + context
- `window` — read N bytes before/after an offset, decoded as text or hex
- `patch` — write bytes at an offset with safety guards

This is the binary recon branch — when `fcontent` returns nothing because the file isn't text, `fprobe` is the next move.

## Canonical chains

```bash
# Extract printable strings, filtered
fprobe strings /usr/local/bin/myapp --min-len 8 --filter "http"

# Locate a literal pattern
fprobe scan /usr/local/bin/myapp --pattern "userFacingName" -o json

# Read context around an offset
fprobe window /usr/local/bin/myapp --offset 0x100 --before 64 --after 256

# Hex dump
fprobe window /usr/local/bin/myapp --offset 0x100 --after 256 --decode hex

# Full binary recon chain
fprobe scan binary --pattern "renderTool" --context 300 -o json
fprobe strings binary --filter "diffAdded"
fprobe window binary --offset 112730723 --before 50 --after 200
```

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

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fprobe fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fprobe)
