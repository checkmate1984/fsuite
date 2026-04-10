---
title: Output Formats
description: The four output modes every fsuite tool supports, and when to use each.
sidebar:
  order: 2
---

Every fsuite tool supports four output modes, selected via `-o <format>` or format-specific flags.

## `pretty` (default)

Human-readable terminal output, colored when stdout is a TTY.

```bash
fs "authenticate" --scope '*.py'
```

Use this when you're reading output yourself. Don't pipe it.

## `json`

Structured JSON, one line per record (JSONL) or a single envelope depending on the tool.

```bash
fs "authenticate" --scope '*.py' -o json
```

Use this for programmatic parsing, automation, and piping into `jq`. Every tool guarantees a stable schema here.

## `paths`

Plain list of file paths, one per line. Pipe-friendly.

```bash
fsearch '*.py' src -o paths | xargs wc -l
```

Use this when the next tool in your pipeline only needs the file paths — not the content, not the metadata.

## `quiet` (`-q`)

No stdout output. Exit code only: `0` = matches found, non-zero = no matches.

```bash
if fsearch '*.py' src -q; then
  echo "Python files found"
fi
```

Use this for existence checks, guards, and silent control flow.

## Stream conventions

- **Results** go to `stdout`
- **Errors** go to `stderr`
- **Progress** goes to `stderr` (only in pretty mode)

This means `fs ... -o json > results.json` captures clean JSON with no noise, even if the tool prints warnings.
