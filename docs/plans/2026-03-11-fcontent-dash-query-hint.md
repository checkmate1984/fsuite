# Fcontent Dash Query Hint Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a smart hint for dash-prefixed literal queries in `fcontent` while preserving hard-fail behavior for unknown options.

**Architecture:** Keep the change local to `fcontent` argument parsing and help text. The parser continues to reject unknown options, but the `-*)` branch appends a targeted `--` usage hint when the offending token looks like a literal search term. Tests cover the hint path, the explicit `--` escape hatch, and normal typo failures.

**Tech Stack:** Bash CLI parsing, existing fsuite shell test harness

---

### Task 1: Add Red Tests

**Files:**
- Modify: `tests/test_fcontent.sh`

Add focused tests for:

- unknown dash-prefixed query emits the targeted hint
- `fcontent -- '--test' /path` works as a literal query
- normal unknown option typos still fail clearly

Run:

```bash
bash tests/test_fcontent.sh
```

Expected: FAIL before implementation.

### Task 2: Patch `fcontent`

**Files:**
- Modify: `fcontent`

Change only:

- help text to show one `--` example for dash-prefixed literal queries
- unknown-option handling to append the targeted hint only for dash-prefixed query-like tokens

Do not:

- auto-convert unknown options into positional queries
- relax validation for misspelled flags

### Task 3: Verify

Run:

```bash
bash tests/test_fcontent.sh
```

Then spot-check help output:

```bash
./fcontent --help
```

Expected: all tests pass and help includes the explicit `-- '--test'` example.
