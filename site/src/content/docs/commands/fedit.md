---
title: ✂️ fedit
description: Surgical editing — line-range, symbol-scoped, or anchor-based
sidebar:
  order: 8
---

## Surgical editing — line-range, symbol-scoped, or anchor-based

`fedit` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

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

- [fsuite mental model](/getting-started/mental-model/) — how fedit fits into the toolchain
- [Cheat sheet](/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fedit)
