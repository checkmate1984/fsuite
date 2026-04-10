---
title: 📝 fwrite
description: Atomic file creation
sidebar:
  order: 9
---

## Atomic file creation

`fwrite` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

## Help output

The content below is the **live** `--help` output of `fwrite`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
# modifications. This is the "create" counterpart to fedit's "modify."
#
# Usage:
#   fwrite <path> --content <text>           Create new file
#   fwrite <path> --content <text> --overwrite   Overwrite existing
#   fwrite <path> --stdin                    Read content from stdin
#   fwrite <path> --from <source>            Copy from source file
#
# Flags:
#   --content <text>    File content (required unless --stdin or --from)
#   --overwrite         Allow overwriting existing files (default: deny)
#   --stdin             Read content from stdin (for piping)
#   --from <path>       Copy content from another file
#   --mkdir             Create parent directories (default: true)
#   --no-mkdir          Don't create parent directories
#   --dry-run           Show what would happen without writing
#   --json              Output result as JSON
#   -q, --quiet         Suppress output, exit code only
#
# Exit codes:
#   0  Success
#   1  Missing arguments
#   2  File exists (no --overwrite)
#   3  Parent directory doesn't exist (--no-mkdir)
#   4  Write failed
#   5  Source file not found (--from)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fwrite fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fwrite)
