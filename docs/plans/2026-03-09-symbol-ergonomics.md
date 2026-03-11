# Symbol Ergonomics Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `fmap --name <symbol>` and `fread --symbol <name>` as a narrow deterministic workflow seam for symbol-first investigation.

**Architecture:** Keep both changes local to this patch. `fmap` gains a post-extraction ranking/filtering layer over existing symbols, while `fread` resolves exact symbol names through `fmap -o json` within the provided file or directory scope and then reuses the existing bounded-read path. Preserve existing envelopes unless explicitly extended with `query`, `matches`, `symbol_resolution`, or `candidates`.

**Tech Stack:** Bash, `grep`, `awk`, `perl`, shell JSON emission, existing fsuite test harnesses, Python 3 for JSON assertions in tests

---

### Task 1: Add Red Tests For `fmap --name`

**Files:**
- Modify: `tests/test_fmap.sh`
- Modify: `fmap`

**Step 1: Write the failing test**

Extend the existing `tests/test_fmap.sh` fixtures with a small duplicate-name surface that creates:

- one exact `authenticate`
- one substring variant like `authenticate_user`
- one same-name symbol in a sibling file for deterministic ranking tests

Add red tests:

```bash
test_name_exact_hit_json() {
  local output
  output=$(FSUITE_TELEMETRY=0 "${FMAP}" --name authenticate -o json "${TEST_DIR}/src" 2>&1)
  if python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); assert data["query"] == "authenticate"; assert data["matches"][0]["symbol"] == "authenticate"; assert data["matches"][0]["match_kind"] == "exact"' <<< "$output" 2>/dev/null; then
    pass "--name exact hit ranks first in JSON"
  else
    fail "--name exact hit should rank first" "$output"
  fi
}

test_name_exact_beats_substring() {
  local output
  output=$(FSUITE_TELEMETRY=0 "${FMAP}" --name authenticate -o json "${TEST_DIR}/src" 2>&1)
  if python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); matches=data["matches"]; assert matches[0]["match_kind"] == "exact"; assert any(m["match_kind"] == "substring" for m in matches[1:])' <<< "$output" 2>/dev/null; then
    pass "--name exact matches rank before substring matches"
  else
    fail "exact matches should rank before substring matches" "$output"
  fi
}

test_name_type_filter_applies_after_matching() {
  local output
  output=$(FSUITE_TELEMETRY=0 "${FMAP}" --name authenticate -t function -o json "${TEST_DIR}/src" 2>&1)
  if python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); assert data["shown_symbols"] == len(data["matches"]); assert all(m["symbol_type"] == "function" for m in data["matches"])' <<< "$output" 2>/dev/null; then
    pass "--name with -t filters matched results after ranking"
  else
    fail "--name with -t should filter matched symbols" "$output"
  fi
}

test_name_paths_empty_is_non_error() {
  local output rc=0
  output=$(FSUITE_TELEMETRY=0 "${FMAP}" --name DOES_NOT_EXIST -o paths "${TEST_DIR}/src" 2>/dev/null) || rc=$?
  if [[ "${rc:-0}" -eq 0 ]] && [[ -z "$output" ]]; then
    pass "--name paths output is empty and non-error on no match"
  else
    fail "--name paths no-match should be empty and non-error" "rc=${rc:-0} output=$output"
  fi
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
bash tests/test_fmap.sh
```

Expected: FAIL because `--name` is not implemented yet.

**Step 3: Write minimal implementation**

In `fmap`, add:

- `--name <symbol>` parsing and help text
- a local helper that extracts symbol names from existing `text` fields using the same philosophy as `fedit`
- a ranked filtered view over `TMP_SYMBOLS`

Rules:

- case-sensitive exact first
- substring second
- ties by `path`, `line_start`, `symbol_type`
- `total_symbols` remains pre-filter
- `shown_symbols` becomes post-filter result count
- `files[*].symbols[*]` schema stays unchanged

`matches` entry shape:

```json
{
  "path": "/repo/src/auth.py",
  "symbol": "authenticate",
  "symbol_type": "function",
  "line_start": 32,
  "line_end": null,
  "match_kind": "exact",
  "rank": 1
}
```

**Step 4: Run test to verify it passes**

Run:

```bash
bash tests/test_fmap.sh
```

Expected: the new `--name` tests pass and the full fmap suite remains green.

**Step 5: Commit**

```bash
git add fmap tests/test_fmap.sh
git commit -m "feat: add fmap symbol-name filtering"
```

### Task 2: Add Red Tests For `fread --symbol`

**Files:**
- Modify: `tests/test_fread.sh`
- Modify: `fread`

**Step 1: Write the failing test**

Extend `tests/test_fread.sh` fixtures with:

- a file containing a unique exact symbol like `authenticate`
- another file in the same directory containing the same exact symbol for ambiguity
- a distinct symbol to verify file-local resolution

Add red tests:

```bash
test_symbol_exact_single_match_reads_chunk() {
  local output
  output=$(FSUITE_TELEMETRY=0 "${FREAD}" "${TEST_DIR}/auth_unique.py" --symbol authenticate -o json 2>/dev/null)
  if python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); assert data["symbol_resolution"]["symbol"] == "authenticate"; assert data["chunks"][0]["start_line"] >= 1' <<< "$output" 2>/dev/null; then
    pass "--symbol exact single match resolves and reads"
  else
    fail "--symbol exact single match should read symbol" "$output"
  fi
}

test_symbol_ambiguous_fails_with_candidates() {
  local output rc=0
  output=$(FSUITE_TELEMETRY=0 "${FREAD}" "${TEST_DIR}/src" --symbol authenticate -o json 2>/dev/null) || rc=$?
  if [[ "${rc:-0}" -ne 0 ]] && python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); assert data["errors"][0]["error_code"] == "symbol_ambiguous"; assert len(data.get("candidates", [])) >= 2' <<< "$output" 2>/dev/null; then
    pass "--symbol ambiguity fails with candidates"
  else
    fail "--symbol ambiguity should fail with candidates" "rc=${rc:-0} output=$output"
  fi
}

test_symbol_missing_fails() {
  local output rc=0
  output=$(FSUITE_TELEMETRY=0 "${FREAD}" "${TEST_DIR}/src" --symbol DOES_NOT_EXIST -o json 2>/dev/null) || rc=$?
  if [[ "${rc:-0}" -ne 0 ]] && [[ "$output" =~ \"error_code\":\"symbol_not_found\" ]]; then
    pass "--symbol missing exact match fails clearly"
  else
    fail "--symbol missing exact match should fail" "rc=${rc:-0} output=$output"
  fi
}

test_symbol_file_scope_is_local() {
  local output rc=0
  output=$(FSUITE_TELEMETRY=0 "${FREAD}" "${TEST_DIR}/auth_unique.py" --symbol sibling_only_symbol -o json 2>/dev/null) || rc=$?
  if [[ "${rc:-0}" -ne 0 ]] && [[ "$output" =~ \"error_code\":\"symbol_not_found\" ]]; then
    pass "--symbol file target scope stays file-local"
  else
    fail "file-local --symbol should not resolve against sibling files" "rc=${rc:-0} output=$output"
  fi
}
```

If `--symbol-type` is added cheaply, add one focused red test proving it only disambiguates exact-name matches.

**Step 2: Run test to verify it fails**

Run:

```bash
bash tests/test_fread.sh
```

Expected: FAIL because `--symbol` is not implemented yet.

**Step 3: Write minimal implementation**

In `fread`, add:

- `--symbol <name>` parsing and help text
- optional `--symbol-type <type>` only if nearly free
- a local resolver that:
  - runs `fmap -o json` on the provided file or directory target
  - extracts exact symbol names only
  - enforces file-local scope for file targets
  - enforces directory-local scope for directory targets
  - succeeds only on exactly one exact-name match
  - fails with `symbol_not_found` or `symbol_ambiguous`

On success:

- compute `line_start` from the matching symbol line
- compute `line_end` only when cheap; otherwise leave it unset in resolution metadata and use the existing read boundary behavior
- reuse the existing bounded-read path
- add `symbol_resolution` to the JSON envelope

On ambiguity:

- emit deterministic `candidates` ordered exactly like `fmap`

**Step 4: Run test to verify it passes**

Run:

```bash
bash tests/test_fread.sh
```

Expected: the new `--symbol` tests pass and the full fread suite remains green.

**Step 5: Commit**

```bash
git add fread tests/test_fread.sh
git commit -m "feat: add fread exact symbol resolution"
```

### Task 3: Tighten Docs And Verify Focused Then Full

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `fsuite`
- Modify: `fmap`
- Modify: `fread`

**Step 1: Write the failing test**

Add or extend help-output assertions in `tests/test_fmap.sh` and `tests/test_fread.sh` so the new flags are documented:

```bash
if [[ "$output" == *"--name"* ]]; then
  pass "fmap help shows --name"
else
  fail "fmap help should show --name"
fi
```

```bash
if [[ "$output" == *"--symbol"* ]]; then
  pass "fread help shows --symbol"
else
  fail "fread help should show --symbol"
fi
```

**Step 2: Run test to verify it fails**

Run:

```bash
bash tests/test_fmap.sh
bash tests/test_fread.sh
```

Expected: FAIL until docs/help text are updated.

**Step 3: Write minimal implementation**

Update:

- `fmap` help text with `--name`
- `fread` help text with `--symbol` and optional `--symbol-type`
- `README.md` examples to show:
  - `fmap --name authenticate -o json /project/src`
  - `fread /project/src/auth.py --symbol authenticate -o json`
- `fsuite` / `AGENTS.md` guidance only if a small example line fits naturally

Do not widen the documentation into orchestration or `fcase`.

**Step 4: Run test to verify it passes**

Run focused suites first:

```bash
bash tests/test_fmap.sh
bash tests/test_fread.sh
```

Then run the full suite:

```bash
bash tests/run_all_tests.sh
```

Expected: all focused tests pass first, then the full suite passes.

**Step 5: Commit**

```bash
git add README.md AGENTS.md fsuite fmap fread tests/test_fmap.sh tests/test_fread.sh
git commit -m "docs: add symbol-first fmap and fread guidance"
```
