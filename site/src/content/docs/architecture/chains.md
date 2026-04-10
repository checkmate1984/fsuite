---
title: Chain Combinations
description: Canonical fsuite tool chains — which sequences actually work for common tasks.
sidebar:
  order: 4
---

## The core chain

```text
ftree → fs → fmap → fread → fedit
```

Use this as your default for "I need to understand and modify something in this repo."

## Investigation chain

```text
fcase init → ftree → fs → fmap → fread → fcase note → fedit → fcase resolve
```

Use this when the work spans multiple sessions or context windows.

## Debugging chain

```text
fbash (reproduce bug) → fs (find relevant code) → fmap → fread → fcase → fedit → fbash (verify fix)
```

`fcase` captures the hypothesis, the repro steps, and the fix — so if the fix fails, the next attempt starts with context.

## Refactoring chain

```text
fcontent (find all call sites) → fsearch (scope files) → fmap (find symbols to update) → fedit --function_name (scoped edits)
```

The key move: use `fedit --function_name` for each symbol instead of doing a text-replace across files. Zero ambiguity.

## Binary investigation chain

```text
fprobe strings → fprobe scan → fprobe window → fprobe patch
```

When you need to work with a compiled binary, an obfuscated bundle, or anything the text-based tools can't read.

## Replay chain

```text
freplay --session <id>
```

Rerun a traced investigation step-by-step. Useful for post-mortems and regression tests.

## Measurement chain

```text
fmetrics import → fmetrics stats → fmetrics predict <project>
```

Ask the telemetry database what worked last time and what probably works next.

> **TODO:** add screenshots / example outputs for each chain.
