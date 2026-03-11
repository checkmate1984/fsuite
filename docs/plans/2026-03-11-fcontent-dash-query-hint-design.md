# Fcontent Dash Query Hint Design

**Date:** 2026-03-11

## Goal

Improve `fcontent` ergonomics for literal queries that start with `-` without weakening the CLI contract for unknown flags.

## Decision

Keep unknown options as hard failures.

When the unknown token starts with `-`, add a targeted hint that shows the literal-query escape hatch:

```text
Query starts with '-'. If you mean a literal search term, use:
  fcontent -o json -- '--test' /path
```

## Why

- avoids silently converting flag typos into searches
- preserves explicit CLI behavior for agents and humans
- teaches the correct `--` form at the exact failure point

## Scope

This patch is intentionally small:

- add the targeted hint for unknown dash-prefixed tokens
- add one help example showing the `--` form
- add focused regression tests in `tests/test_fcontent.sh`

## Non-Goals

- no automatic literal fallback
- no broader parser rewrite
- no fuzzy or heuristic recovery for malformed options
