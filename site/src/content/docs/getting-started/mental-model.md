---
title: Mental Model
description: How the 14 fsuite tools fit together. The chain, the specialists, and the workflow discipline.
sidebar:
  order: 2
---

## The chain

The main fsuite workflow is a straight line from territory scout to surgical edit:

```text
fsuite → fs / ftree / fls → fsearch | fcontent → fmap → fread → fcase → fedit / fwrite → fmetrics
Guide    Unified / Scout / LS   Narrowing             Bridge   Read     Preserve  Mutate           Measure
```

Three specialists orbit the main stack:

- **`fbash`** — Bash replacement with token-budgeting, command classification, and session state
- **`fprobe`** — Binary / bundle inspection + patching when normal reads fail
- **`freplay`** — Derivation chain replay for deterministic reruns

## The discipline

1. **Scout once.** Run `ftree --snapshot` to establish territory. Don't rediscover the repo unless the target changes.
2. **Let `fs` route.** It auto-classifies your query and picks the right narrowing tool. One call beats three.
3. **Map before reading.** `fmap` extracts the symbol skeleton. You'll know what's there before you read a single line.
4. **Read exactly, never approximately.** `fread --symbol NAME` reads one function by name. `fread --lines 120:150` reads an exact range. Don't read whole files.
5. **Preserve investigation state.** Open `fcase init` at the start of non-trivial work. Close with `fcase resolve`. Check `fcase find` before starting new work — a past you may already have the answer.
6. **Edit surgically.** `fedit --lines` is the fastest mode when you have numbers from `fread`. `fedit --function_name` scopes by symbol without needing huge unique context strings.
7. **Never edit blind.** Always inspect context with `fread` before calling `fedit`.
8. **Measure.** `fmetrics` tells you which chains worked and predicts the best next step for any project.

## Why this order matters

Every tool in the chain is **bounded** — capped output, ranked results, structured JSON available. If you run them in order, each tool narrows the work for the next one, and by the time you reach `fedit` you are acting on an exact line range or exact symbol. Zero ambiguity. Zero failed context matches. Zero 10,000-line grep dumps.

If you skip the chain and reach for `fcontent` as your first search, you'll get what grep gives you — a flood — and you'll waste tokens re-narrowing by hand. That's the mistake the chain is built to prevent.
