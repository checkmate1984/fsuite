---
title: ✂️ fedit
description: Surgical editing — line-range, symbol-scoped, or anchor-based
sidebar:
  order: 8
---

## Surgical editing — line-range, symbol-scoped, or anchor-based

`fedit` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

<div class="fs-drone">
  <div class="fs-drone-head">
    <span class="fs-drone-call">fedit</span>
    <span class="fs-drone-tagline">Surgical patches · line-range · symbol-scoped · anchor-based</span>
  </div>
  <div class="fs-drone-meta">
    <div><b>Role</b><span class="role-edit">PATCH</span></div>
    <div><b>Chain position</b><span>7 (act)</span></div>
    <div><b>Default</b><span>dry-run (CLI)</span></div>
    <div><b>Guard</b><span>--expect · --expect-sha256</span></div>
  </div>
</div>

`fedit` makes edits without ambiguity. Three modes: **line-range** (`--lines 71:73`), **symbol-scoped** (`--function auth`, `--class AuthHandler`), and **anchor-based** (`--after 'def auth(...):'`). No more failed matches because of whitespace drift or an agent picking the wrong block of identical-looking code.

Default is dry-run on the CLI — you see the diff, then add `--apply` to commit. Guard rails: `--expect` requires a literal string to be present first; `--expect-sha256` requires the file to match a known content hash.

## Canonical chains

```bash
# Surgical replace — preview first
fedit /project/src/auth.py --replace 'old text' --with 'new text'
fedit /project/src/auth.py --replace 'old text' --with 'new text' --apply

# Line-range replace
fedit /project/src/auth.py --lines 71:73 --with "    return deny()\n"

# Symbol-scoped — function or class block
fedit /project/src/auth.py --function authenticate --replace 'X' --with 'Y'
fedit /project/src/auth.py --class AuthHandler --after '...' --with '...'

# Anchor-based insert
fedit /project/src/auth.py --after 'def authenticate(user):' --content-file patch.txt

# Batch patch via pipe
fsearch -o paths '*.py' /project \
  | fedit --targets-file - --targets-format paths \
          --replace 'x' --with 'y' --apply

# Symbol-scoped batch from fmap output
fedit --targets-file map.json --targets-format fmap-json \
      --function auth --replace 'X' --with 'Y' --apply

# Guarded edit — refuses if file content drifted
fedit /project/src/auth.py --expect-sha256 abc123 \
      --replace 'X' --with 'Y' --apply
```

## Help output

The content below is the **live** `--help` output of `fedit`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fedit — surgical, preview-first file editing for fsuite.

USAGE
  fedit <file> --replace OLD --with NEW [--apply]
  fedit <file> --function NAME --replace OLD --with NEW [--apply]
  fedit <file> --after TEXT --content-file patch.txt [--apply]
  fedit --targets-file paths.txt --targets-format paths --replace OLD --with NEW
  fedit --create <file> --content-file newfile.txt [--apply]
  fedit --replace-file <file> --content-file rewritten.txt [--apply]

PATCH OPTIONS
  --replace TEXT              Replace an exact text block
  --with TEXT                 Replacement or insertion payload
  --after TEXT                Insert payload after exact anchor text
  --before TEXT               Insert payload before exact anchor text
  --content-file PATH         Read payload from file
  --stdin                     Read payload from stdin

SYMBOL SHORTCUTS (resolved to --symbol + --symbol-type)
  --function NAME             Scope to function NAME
  --class NAME                Scope to class NAME
  --method NAME               Scope to function NAME (alias for --function)
  --import NAME               Scope to import NAME
  --constant NAME             Scope to constant NAME
  --type NAME                 Scope to type NAME

SYMBOL OPTIONS
  --symbol NAME               Scope patching to one fmap-resolved symbol
  --symbol-type TYPE          Restrict symbol match (function, class, import, ...)
  --fmap-json PATH            Reuse existing fmap JSON instead of running fmap

PRECONDITIONS
  --expect TEXT               Require existing file to contain this text
  --expect-sha256 HASH        Require existing file hash to match

BATCH MODE
  --targets-file PATH         Read target files from PATH (use - for stdin)
  --targets-format FMT        Required with --targets-file: paths | fmap-json

CONTROL
  --allow-multiple            Allow all matches for replace/anchor operations
  --apply                     Write the edited file(s)
  --dry-run                   Preview diff only (default)
  --create                    Create a new file (fails if file exists)
  --replace-file              Replace the entire target file from payload
  --no-validate               Skip structural validation (escape hatch for JSONC, test fixtures)
  -o, --output FMT            pretty (default), json, paths
  --project-name NAME         Override telemetry project name
  --self-check                Verify dependencies
  --install-hints             Print install commands
  --version                   Print version
  -h, --help                  Show help

BEHAVIOR
  - Dry-run is the default. Nothing mutates unless --apply is present.
  - Patch operations fail closed when anchors are missing or ambiguous.
  - --symbol scopes patch operations to the chosen fmap symbol block.
  - Symbol shortcuts are sugar: --function X equals --symbol X --symbol-type function.
  - Batch mode is preflighted all-or-nothing: all planning completes before writes.
  - Structured files (JSON, YAML, TOML, XML) are validated before writing.
  - Use --no-validate to bypass structural validation (e.g. JSONC with comments).
  - JSON output is intended for agent/harness consumption.

HEADLESS / AI AGENT USAGE
  fedit -o json file.ts --replace "old" --with "new"
  fedit -o json file.ts --function authenticate --replace "return False" --with "return deny()"
  printf 'a.py\nb.py\n' | fedit --targets-file - --targets-format paths --replace 'x' --with 'y'
  fmap -o json src > map.json && fedit --targets-file map.json --targets-format fmap-json --function auth --replace 'x' --with 'y' -o json
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fedit fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fedit)
