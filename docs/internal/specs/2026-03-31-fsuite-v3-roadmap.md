# fsuite v3 Roadmap: Agent Recovery → Replay Spine → Case Graph

**Date:** 2026-03-31
**Status:** Approved
**Authors:** player3vsgpt + Claude (Opus 4.6) + Codex (GPT-5)
**Validated by:** Triple validation (SQLite, ripgrep, MCP/Node docs)

---

## Core Principle: Absorb Agent Uncertainty

> Don't build tools that merely expose capability. Build tools that absorb agent uncertainty.

1. One call completes one intent, not one sub-step
2. Failures return reality, not just refusal
3. Errors are machine-usable AND human-meaningful
4. Output is budgeted and predictable
5. Telemetry is automatic, never narrated by the agent
6. `next_hint` is suite-wide (already exists in fs, fread, fsearch — extend to ALL tools)

---

## Phase Structure

| Phase | Name | Goal |
|-------|------|------|
| **1** | **Agent Recovery** | When tools fail, they show reality, recovery context, and the next move |
| **2** | **Replay Spine** | Auto-capture replay steps as tools run under active cases |
| **3a** | **Case Graph** | `case_links` table with `references` and `extends` edges |
| **3b** | **ShieldCortex Bridge** | Resolved cases flow into ShieldCortex. Only after local graph stabilizes |

Each phase is independently shippable. Phase 1 makes traces trustworthy. Phase 2 makes traces automatic. Phase 3 makes traces searchable.

---

## Phase 1: Agent Recovery

### 1.1 fedit Failure Context

**Current state:** fedit already reads internally (`fedit:1170`), tracks precondition hashes (`fedit:948`), and emits structured error codes (`fedit:541`).

**Gap:** When fedit fails, it doesn't show reality. "String not found" gives no recovery path.

**Target:** On match failure, return the nearest candidate lines via sliding-window Levenshtein against file content. Include actual content at the target location.

**Schema addition to error response:**

```json
{
  "error_code": "no_match",
  "error_detail": "Replace text not found in file",
  "context": {
    "nearest_snippet": "lines 71-73: actual content here...",
    "actual_lines": ["line 71 content", "line 72 content", "line 73 content"],
    "candidate_matches": [
      {"line": 145, "similarity": 0.87, "preview": "similar text here..."}
    ]
  },
  "next_hint": {
    "tool": "fread",
    "args": {"path": "/src/auth.ts", "lines": "70:80"},
    "reason": "See actual content at failed match location"
  }
}
```

### 1.2 Stale-File Baseline Capture

**Current state:** Precondition hash at `fedit:948` stores expected hash only.

**Gap:** On precondition failure, fedit says "file modified" but doesn't show what changed.

**Target:** At edit-preparation time (when fedit reads internally at `fedit:1170`), capture the matched region +/- 3 lines as `_baseline_excerpt`. This is in-memory/tempfile storage scoped to the edit operation, not persistent DB.

On precondition failure, re-read those lines and diff against the stored excerpt:

```json
{
  "error_code": "precondition_failed",
  "context": {
    "baseline_excerpt": "what was there when you last read",
    "current_excerpt": "what is there now",
    "changes_summary": "Lines 71-73 were modified externally"
  },
  "next_hint": {
    "tool": "fread",
    "args": {"path": "/src/auth.ts", "lines": "68:76"},
    "reason": "Re-read the modified region before retrying edit"
  }
}
```

### 1.3 Quote and Dash Normalization

**Current state:** No normalization. Curly quotes cause "string not found."

**Target:** Before declaring match failure, normalize both search string and file content:
- Curly quotes (U+2018 U+2019 U+201C U+201D) to straight quotes
- Em-dash (U+2014) to hyphen
- Unicode spaces to ASCII space

If normalized match succeeds, apply edit using original file characters (brane-code's `findActualString` + `preserveQuoteStyle` pattern). Silent — no extra round-trip.

### 1.4 Path and Symbol Suggestions

**Path:** On ENOENT, Levenshtein against siblings in same directory + basename search up the tree. "Did you mean `/src/auth.ts`?"

**Symbol:** fedit already shells to fmap for `--symbol` at `fedit:598`. On symbol-not-found, return candidate symbols from fmap output. "Did you mean `authenticateUser` (line 47)?"

**Batch mode:** Per-item `next_hint` in batch error arrays (`fedit:1346`), not just top-level failure handling.

### 1.5 Suite-Wide Structured next_hint

**Precedent:** Already exists in fs (`fs-engine.py:467`), fread (`fread:881`), fsearch (`fsearch:625`).

**Schema (frozen):**

```json
{
  "next_hint": {
    "tool": "string (fsuite tool name)",
    "args": {"key": "value pairs for the suggested call"},
    "reason": "string (why this is the right next step)"
  }
}
```

**Extend to:** fedit, fcontent, fmap, ftree, fls, fcase. Machine-followable, not prose.

### 1.6 fcontent --max-columns 500

Add `--max-columns 500 --max-columns-preview` to rg args at the assembly point (`fcontent:451`).

Ripgrep's `--max-columns-preview` shows a truncated preview of long lines rather than omitting them entirely. Native ripgrep behavior — no custom post-processing.

**Validated:** Local `rg --help` confirms `--max-columns-preview` prints a preview for lines exceeding the configured max column limit.

### 1.7 Relative-Path Standardization

**Current state:** MCP renderer shortens paths via `shortPath()` at `mcp/index.js:198`, but raw tool JSON emits absolute paths at `fcontent:518`, `fedit:556`, etc.

**Target:** Dual-emit pattern:
- `path` — canonical absolute path (for replay/evidence durability)
- `display_path` — relative to cwd (for ANSI output, token savings)

MCP renderer uses `display_path`. Replays and fcase evidence always reference canonical `path`.

---

## Phase 2: Replay Spine

### Design Principle

Don't reconstruct replays from telemetry after the fact. Capture replay steps as tools run under an active case.

### 2.1 Active Case State Ownership

**Design:** DB-backed `active_bindings` table (CLI + MCP parity).

```sql
CREATE TABLE active_bindings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  binding_type TEXT NOT NULL CHECK (binding_type IN ('case')),
  binding_key TEXT NOT NULL,  -- actor:cwd_hash:scope_id
  value TEXT NOT NULL,        -- case slug
  created_at TEXT NOT NULL,
  UNIQUE(binding_type, binding_key)
);
```

**binding_key components:**
- `actor` — `${USER}` (from `fcase:529`)
- `cwd_hash` — SHA256 prefix of canonical cwd
- `scope_id` — MCP mode: `process.pid` of server. CLI mode: `$$` (shell PID) or explicit `FSUITE_SCOPE_ID` env var

**Implementation caution:** If one MCP server ever serves multiple independent agents in the same cwd, the explicit `FSUITE_SCOPE_ID` override becomes important. PID-based scoping is the baseline, not the ceiling.

**Lifecycle:**
- `fcase init` writes the binding
- `fcase resolve` deletes the binding
- `_fsuite_common.sh` reads the binding on each tool invocation (one SELECT)

**MCP integration:** Replace module-level `EXEC_OPTS` constant with per-call `buildExecOpts()`:

```js
function buildExecOpts(toolName) {
  const activeCase = getActiveCaseBinding(); // DB read, cached per-call batch
  return {
    timeout: TOOL_TIMEOUT,
    maxBuffer: MAX_BUFFER,
    env: {
      ...process.env,
      ...(activeCase ? { FSUITE_ACTIVE_CASE_SLUG: activeCase } : {}),
    },
  };
}
```

Called at execution site (`mcp/index.js:647`), not at module init.

**Validated:** Node `child_process.execFile` supports per-call `options.env`. fsuite already uses this seam at `mcp/index.js:179`.

### 2.2 Replay Step Auto-Capture

**Mechanism:** When `_fsuite_common.sh` detects `FSUITE_ACTIVE_CASE_SLUG` in the environment, each tool execution appends a replay step to the active case's draft replay after completion.

**New common lib function:** `_fsuite_record_replay_step()` in `_fsuite_common.sh`. Called in each tool's EXIT trap alongside telemetry recording. Parameters: tool, argv, cwd, exit_code, duration_ms, telemetry_run_id.

**Draft replay auto-creation:** On first tool execution with an active case, auto-create a draft replay for that case-session if none exists. Link via `replays.case_id` and new `replays.session_id` column.

**Schema addition:**

```sql
ALTER TABLE replays ADD COLUMN session_id INTEGER
  REFERENCES case_sessions(id) ON DELETE SET NULL;
```

### 2.3 Replay Concurrency

Step insertion wrapped in a transaction:

```sql
BEGIN IMMEDIATE;
INSERT INTO replay_steps (replay_id, order_num, ...)
  VALUES (?, (SELECT COALESCE(MAX(order_num), 0) + 1
              FROM replay_steps WHERE replay_id = ?), ...);
COMMIT;
```

`BEGIN IMMEDIATE` acquires a write lock immediately, preventing parallel tool calls from racing on `MAX(order_num) + 1`. Existing `SQLITE_BUSY_TIMEOUT_MS=5000` at `_fsuite_db.sh:14` handles contention. WAL mode already enabled at `_fsuite_db.sh:131`.

**Validated:** SQLite official transaction docs confirm BEGIN IMMEDIATE semantics.

### 2.4 Replay Lifecycle

| State | When |
|-------|------|
| `draft` | Current session's active replay (steps being appended) |
| `canonical` | Promoted on `fcase resolve` — one per case (unique index at `_fsuite_db.sh:239`) |
| `archived` | Non-promoted drafts from prior sessions |

**On `fcase resolve`:**
1. Promote current session's draft to `canonical`
2. All other `draft` replays for this case become `archived`

**On case reopen + new session:**
1. New `draft` replay created for the new session
2. Prior `canonical` stays `canonical` (historical record)
3. If resolved again, new draft becomes new `canonical`, old canonical becomes `archived`

### 2.5 Resolution Metadata

New JSON column on cases table:

```sql
ALTER TABLE cases ADD COLUMN resolution_metadata TEXT
  NOT NULL DEFAULT '{}';
```

Auto-populated on `fcase resolve`:

```json
{
  "tool_summary": "Read-heavy investigation (47 reads, 3 edits, 2 fmap) across 12 files",
  "tool_counts": {"fread": 47, "fedit": 3, "fmap": 2},
  "files_touched": ["src/auth.ts", "src/middleware.ts"],
  "total_duration_ms": 34200,
  "replay_id": 42
}
```

### 2.6 Case-Aware fmetrics recommend

fmetrics `recommend` already scores combos via replay metadata (`fmetrics:1057`). Add `--case-context` flag that weights combos from resolved cases with similar goals (FTS match on `cases.goal`).

Output: "Investigations like this one used fs->fmap->fread->fedit with 92% success."

---

## Phase 3a: Case Graph

### case_links Table

```sql
CREATE TABLE case_links (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_case_id INTEGER NOT NULL REFERENCES cases(id),
  target_case_id INTEGER NOT NULL REFERENCES cases(id),
  link_type TEXT NOT NULL CHECK (link_type IN ('references', 'extends')),
  reason TEXT,
  created_at TEXT NOT NULL,
  UNIQUE(source_case_id, target_case_id, link_type)
);
```

Only `references` and `extends`. No `contradicts` or `supersedes` — too hard to infer cleanly, creates noisy links.

### Graph-Powered fcase find

When `fcase find` returns results, traverse `case_links` one hop out. Score linked cases by: link count, recency, tool overlap from replay traces. Return `related_cases` array alongside direct matches.

### Auto-Link Suggestions

On `fcase resolve`, scan resolved cases for FTS similarity on goal + resolution_summary. If similarity score > threshold, suggest links (agent confirms, not auto-create).

---

## Phase 3b: ShieldCortex Bridge

**Only after local graph semantics stabilize.**

- On `fcase resolve`, push to ShieldCortex: `remember({title: slug, content: resolution_summary, tags: [tools_used], category: "investigation", project: project_name})`
- On `fcase find`, also call ShieldCortex `recall` for cross-project results
- Link ShieldCortex memory IDs back to case IDs via `case_external_refs` table
- Direction flag: cases flow into memories, but memories don't auto-create cases (prevents circular amplification)

---

## Validation Summary

| Design Decision | Status | Source |
|----------------|--------|--------|
| BEGIN IMMEDIATE for replay steps | **Confirmed** | SQLite official transaction docs + local test |
| --max-columns-preview for fcontent | **Confirmed** | Local `rg --help` output |
| buildExecOpts() for per-call env | **Confirmed** | Node child_process docs + existing seam at `mcp/index.js:179` |
| WAL mode for fcase.db | **Already enabled** | `_fsuite_db.sh:131` |
| active_bindings DB table | **Valid** | No schema conflicts |
| Replay lifecycle constraints | **Valid** | Matches existing unique index at `_fsuite_db.sh:239` |
| scope_id with PID baseline | **Valid** | PID uniqueness per MCP server instance |

---

## What This Roadmap Does NOT Include (Deferred)

- fcontent count-mode / output_mode unification — not enough agent leverage for Phase 1
- Per-message aggregate output budgeting — revisit after Phase 1 ships
- readFileState blocking (native pattern) — rejected by design. fedit self-reads.
- `contradicts` / `supersedes` link types — too noisy, revisit after graph usage patterns emerge
- FSUITE_CASE_ID telemetry column — rejected. Replay spine is the correlation path.
- LSP integration, notebook support, workflow chaining, cron scheduling — P2 novel tools, post-v3

---

## Origin

This spec was produced from a complete reverse engineering of 38 Claude Code native tools from the brane-code source repository, combined with gap analysis against fsuite v2.3.0. The investigation is recorded in fcase `native-tool-dissection` (case #38, resolved 2026-03-31).

Key collaborators:
- 4 parallel agents dissected File I/O, Execution/Search, Agent/Task, and MCP/UX/Novel tools
- Codex provided 5 rounds of architectural review corrections
- Context7 validated SQLite, ripgrep, and MCP design decisions
