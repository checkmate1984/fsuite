---
title: First Contact
description: The first ten minutes with fsuite — what to run, what to notice, and what to do next.
sidebar:
  order: 3
---

## The first ten minutes

You've just installed fsuite. Here's the shortest path to understanding what it actually does.

### 1. Load the mental model

```bash
fsuite
```

`fsuite` itself is the suite-level guide. It prints the chain, the discipline, and the tool list in one shot. Read it once.

### 2. Scout any project

```bash
cd /path/to/any/project
ftree --snapshot -o json . | head -50
```

`ftree` returns the full tree AND recon data (sizes, types, flags) in one call. Note how it caps output automatically — no 10,000-line floods.

### 3. Run a one-shot search

```bash
fs "TODO" --scope '*.py'
```

`fs` auto-classifies your query. Given a string + glob scope, it routes to content search. Given a path glob, it routes to file search. Given a code identifier, it routes to symbol search. **One call instead of three.**

### 4. Map a file before reading it

```bash
fmap src/some_file.py
```

`fmap` lists the symbol skeleton — functions, classes, imports, constants — with line numbers. You'll know the structure before opening the file.

### 5. Read exactly one function

```bash
fread src/some_file.py --symbol name_of_function
```

`fread` reads exactly the function you asked for. Not the file. Not a guess. The function.

### 6. Open a case

```bash
fcase init first-contact --goal "Explore fsuite on this project"
fcase note first-contact --body "Scouted, mapped, read one function"
fcase resolve first-contact --summary "Got the vibe. Moving on."
```

`fcase` preserves investigation state across sessions. Your notes survive context compaction and you can re-load them with `fcase list` next time.

## What you should notice

- Every command output is **capped**. No flood, ever.
- Every command has `-o json` for programmatic parsing.
- Every command has `-q` for silent existence checks.
- Several commands return `next_hint` — telling you which fsuite tool to reach for next. **Take the hint.**

## What to do next

- [Read the mental model](/fsuite/getting-started/mental-model/) — the discipline that makes the chain work
- [Browse the command reference](/fsuite/commands/fs/) — one page per tool, with live `--help` output
- [Read Episode 0](/fsuite/story/episode-0/) — how fsuite came to be and what it was trying to fix
