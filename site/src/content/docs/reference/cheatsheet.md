---
title: Cheat Sheet
description: One-line recipes for every fsuite tool. Copy, paste, adapt.
sidebar:
  order: 1
---

## Discovery

```bash
# Territory scan — one call replaces 10-15 Glob/LS rounds
ftree --snapshot -o json /project

# Unified search — auto-routes by query intent
fs "authenticate" --scope '*.py'

# File discovery
fsearch '*.py' src -o paths

# Directory listing with recon
fls src/providers --mode recon

# Bounded content search
fcontent "authenticate" src/*.py
```

## Reading

```bash
# Symbol skeleton of a file
fmap src/auth.py

# Read exactly one function
fread src/auth.py --symbol authenticate

# Read an exact line range
fread src/auth.py --lines 120:160

# Read with context around a pattern match
fread src/auth.py --around "JWT_SECRET"
```

## Editing

```bash
# Replace an exact line range (fastest mode)
fedit src/auth.py --lines 71:73 --with-text "new code"

# Scope edit to a symbol without needing unique context
fedit src/auth.py --function_name authenticate --replace "old" --with-text "new"

# Insert after an anchor
fedit src/auth.py --after "import foo" --with-text "\nimport bar"

# Create a new file atomically
fwrite src/new.ts --content "file contents"
```

## Shell

```bash
# Token-budgeted shell — suggests fsuite tools when you're doing something silly
fbash --tag build -- npm run build

# Background job
fbash --background -- npm test
```

## Investigation

```bash
fcase init my-bug --goal "trace 401 errors"
fcase note my-bug --body "root cause: stale JWT in redis"
fcase resolve my-bug --summary "added TTL check to middleware"

# Search past cases before starting new work
fcase find --status all --deep --query "auth"
```

## Binary

```bash
# Extract strings
fprobe strings ./binary --pattern VERSION

# Window-read bytes around an offset
fprobe window ./binary --offset 0x1000 --size 256

# In-place patch
fprobe patch ./binary --offset 0x1234 --replace "new bytes"
```

## Measurement

```bash
fmetrics import                  # pull JSONL → SQLite
fmetrics stats -o json           # summary
fmetrics predict /project        # best-next-tool prediction
freplay --session auth-bug       # rerun a traced investigation
```

## Output formats

```bash
-o json     # Programmatic parsing
-o paths    # Pipe file lists into other tools
-o pretty   # Human terminal output (default)
-q          # Existence check, silent, exit code only
```
