---
title: Telemetry
description: How fsuite records tool usage in JSONL + SQLite for analytics, prediction, and replay.
sidebar:
  order: 3
---

## What gets recorded

Every fsuite tool emits a JSONL telemetry event on completion. The event includes:

- Tool name, arguments, exit code, duration
- Input size, output size, match count
- Backend used (bash, mcp, etc.)
- Hardware snapshot (cpu, memory)

Events land in `~/.fsuite/telemetry.jsonl` by default.

## Import to SQLite

```bash
fmetrics import
```

This pulls the JSONL events into `~/.fsuite/telemetry.db` (SQLite) for fast query. From there:

```bash
# Summary stats
fmetrics stats -o json

# Predict the best next tool for a given project state
fmetrics predict /path/to/project
```

## Privacy

Telemetry is **local only**. Nothing is sent anywhere. You can delete `~/.fsuite/` at any time to wipe history.

Disable telemetry globally by setting:

```bash
export FSUITE_TELEMETRY=0
```

## Planned

- Model / agent / session ID tracking so benchmarks can distinguish which AI model invoked each tool call (OpenTelemetry GenAI semantic conventions)
- Per-session trace correlation

> **TODO:** link to the telemetry model-tracking plan once the migration lands.
