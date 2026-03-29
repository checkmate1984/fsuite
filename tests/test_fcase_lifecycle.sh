#!/usr/bin/env bash
# test_fcase_lifecycle.sh — schema migration tests for fcase lifecycle (v3)
# Run with: bash tests/test_fcase_lifecycle.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FCASE="$REPO_DIR/fcase"
PASS=0; FAIL=0; TOTAL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$expected" == "$actual" ]]; then
    PASS=$((PASS + 1)); echo -e "  \033[0;32m✓\033[0m $label"
  else
    FAIL=$((FAIL + 1)); echo -e "  \033[0;31m✗\033[0m $label"
    echo "    expected: $expected"; echo "    actual:   $actual"
  fi
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$haystack" == *"$needle"* ]]; then
    PASS=$((PASS + 1)); echo -e "  \033[0;32m✓\033[0m $label"
  else
    FAIL=$((FAIL + 1)); echo -e "  \033[0;31m✗\033[0m $label"
    echo "    expected to contain: $needle"
    echo "    haystack: $haystack"
  fi
}

# Use isolated test DB via HOME override (matches existing test pattern)
TEST_HOME=""

setup_test_db() {
  TEST_HOME="$(mktemp -d)"
}

teardown_test_db() {
  rm -rf "${TEST_HOME:-}" 2>/dev/null || true
  TEST_HOME=""
}

run_fcase() {
  HOME="${TEST_HOME}" FSUITE_TELEMETRY=0 "$FCASE" "$@"
}

trap teardown_test_db EXIT

echo ""
echo "═══════════════════════════════════════════"
echo " fcase lifecycle test suite"
echo "═══════════════════════════════════════════"

# ── Section 1: Schema Migration ─────────────────────────────────
echo ""
echo "── Section 1: Schema Migration ──"

setup_test_db

# Create a case to trigger ensure_db (which runs all migrations)
run_fcase init migration-test --goal "Test migration" -o json >/dev/null 2>&1 || true

DB="$TEST_HOME/.fsuite/fcase.db"

# Check new columns exist
result=$(sqlite3 "$DB" "PRAGMA table_info(cases);" 2>&1)
assert_contains "resolution_summary column exists" "$result" "resolution_summary"
assert_contains "resolved_at column exists" "$result" "resolved_at"
assert_contains "archived_at column exists" "$result" "archived_at"
assert_contains "deleted_at column exists" "$result" "deleted_at"
assert_contains "delete_reason column exists" "$result" "delete_reason"

# Check indexes exist
result=$(sqlite3 "$DB" ".indexes" 2>&1)
assert_contains "status+updated index exists" "$result" "idx_cases_status_updated"
assert_contains "events case_id index exists" "$result" "idx_events_case_id"
assert_contains "evidence case_id index exists" "$result" "idx_evidence_case_id"
assert_contains "hypotheses case_id index exists" "$result" "idx_hypotheses_case_id"
assert_contains "targets case_id index exists" "$result" "idx_targets_case_id"
assert_contains "sessions case_id index exists" "$result" "idx_sessions_case_id"

# Check FTS table exists and is queryable
result=$(sqlite3 "$DB" "SELECT count(*) FROM cases_fts;" 2>&1)
assert_eq "FTS table exists and queryable" "1" "$result"

# Check FTS has the case we just created
result=$(sqlite3 "$DB" "SELECT slug FROM cases_fts WHERE cases_fts MATCH 'migration';" 2>&1)
assert_contains "FTS contains migrated case" "$result" "migration-test"

# Check user_version bumped to 3
result=$(sqlite3 "$DB" "PRAGMA user_version;" 2>&1)
assert_eq "user_version is 3" "3" "$result"

# ── Section 2: Idempotency ──────────────────────────────────────
echo ""
echo "── Section 2: Idempotency ──"

# Running init again on same DB should not fail (migration is idempotent)
rc=0
run_fcase init idempotency-test --goal "Second case" -o json >/dev/null 2>&1 || rc=$?
assert_eq "second init succeeds on same DB" "0" "$rc"

# FTS should now have 2 rows
result=$(sqlite3 "$DB" "SELECT count(*) FROM cases_fts;" 2>&1)
assert_eq "FTS has 2 rows after second init" "2" "$result"

teardown_test_db

# ── Section 3: cmd_resolve ─────────────────────────────────────
echo ""
echo "── Section 3: cmd_resolve ──"

setup_test_db

# Create an open case for resolve tests
run_fcase init resolve-test --goal "Test resolve" -o json >/dev/null 2>&1

# resolve without --summary fails
rc=0
out="$(run_fcase resolve resolve-test 2>&1)" || rc=$?
assert_eq "resolve without --summary fails" "1" "$rc"
assert_contains "resolve error mentions --summary" "$out" "resolve requires --summary"

# resolve from open succeeds
rc=0
out="$(run_fcase resolve resolve-test --summary "Found the root cause" 2>&1)" || rc=$?
assert_eq "resolve from open succeeds" "0" "$rc"
assert_contains "resolve pretty output" "$out" "Case 'resolve-test' resolved."

# status becomes resolved
DB="$TEST_HOME/.fsuite/fcase.db"
result=$(sqlite3 "$DB" "SELECT status FROM cases WHERE slug='resolve-test';" 2>&1)
assert_eq "status is resolved after resolve" "resolved" "$result"

# resolution_summary is stored
result=$(sqlite3 "$DB" "SELECT resolution_summary FROM cases WHERE slug='resolve-test';" 2>&1)
assert_eq "resolution_summary stored" "Found the root cause" "$result"

# resolved_at is set
result=$(sqlite3 "$DB" "SELECT CASE WHEN resolved_at IS NOT NULL AND resolved_at != '' THEN 'set' ELSE 'unset' END FROM cases WHERE slug='resolve-test';" 2>&1)
assert_eq "resolved_at is set" "set" "$result"

# next_move is cleared
result=$(sqlite3 "$DB" "SELECT next_move FROM cases WHERE slug='resolve-test';" 2>&1)
assert_eq "next_move cleared on resolve" "" "$result"

# resolve from non-open fails (already resolved)
rc=0
out="$(run_fcase resolve resolve-test --summary "Again" 2>&1)" || rc=$?
assert_eq "resolve from resolved fails" "1" "$rc"
assert_contains "resolve error mentions current status" "$out" "status=open"

# resolve JSON output works
setup_test_db
run_fcase init resolve-json --goal "JSON test" -o json >/dev/null 2>&1
rc=0
out="$(run_fcase resolve resolve-json --summary "Done" -o json 2>&1)" || rc=$?
assert_eq "resolve JSON output succeeds" "0" "$rc"
assert_contains "resolve JSON has resolved status" "$out" '"resolved"'

# Event recorded for resolve
DB="$TEST_HOME/.fsuite/fcase.db"
result=$(sqlite3 "$DB" "SELECT event_type FROM events WHERE case_id=(SELECT id FROM cases WHERE slug='resolve-json') ORDER BY id DESC LIMIT 1;" 2>&1)
assert_eq "resolve event recorded" "case_resolved" "$result"

# Event payload includes prior_status and summary
result=$(sqlite3 "$DB" "SELECT payload_json FROM events WHERE case_id=(SELECT id FROM cases WHERE slug='resolve-json') AND event_type='case_resolved';" 2>&1)
assert_contains "resolve event has prior_status" "$result" '"prior_status":"open"'
assert_contains "resolve event has summary" "$result" '"summary":"Done"'

teardown_test_db

# ── Section 4: cmd_archive ─────────────────────────────────────
echo ""
echo "── Section 4: cmd_archive ──"

setup_test_db

# Create and resolve a case first
run_fcase init archive-test --goal "Test archive" -o json >/dev/null 2>&1
run_fcase resolve archive-test --summary "Resolved for archive" >/dev/null 2>&1

# archive from resolved succeeds
rc=0
out="$(run_fcase archive archive-test 2>&1)" || rc=$?
assert_eq "archive from resolved succeeds" "0" "$rc"
assert_contains "archive pretty output" "$out" "Case 'archive-test' archived."

DB="$TEST_HOME/.fsuite/fcase.db"
result=$(sqlite3 "$DB" "SELECT status FROM cases WHERE slug='archive-test';" 2>&1)
assert_eq "status is archived after archive" "archived" "$result"

# archived_at is set
result=$(sqlite3 "$DB" "SELECT CASE WHEN archived_at IS NOT NULL AND archived_at != '' THEN 'set' ELSE 'unset' END FROM cases WHERE slug='archive-test';" 2>&1)
assert_eq "archived_at is set" "set" "$result"

# archive from non-resolved fails
run_fcase init archive-fail --goal "Should fail" -o json >/dev/null 2>&1
rc=0
out="$(run_fcase archive archive-fail 2>&1)" || rc=$?
assert_eq "archive from open fails" "1" "$rc"
assert_contains "archive error mentions resolved" "$out" "status=resolved"

# Event recorded for archive
result=$(sqlite3 "$DB" "SELECT event_type FROM events WHERE case_id=(SELECT id FROM cases WHERE slug='archive-test') ORDER BY id DESC LIMIT 1;" 2>&1)
assert_eq "archive event recorded" "case_archived" "$result"

# Event payload includes prior_status
result=$(sqlite3 "$DB" "SELECT payload_json FROM events WHERE case_id=(SELECT id FROM cases WHERE slug='archive-test') AND event_type='case_archived';" 2>&1)
assert_contains "archive event has prior_status" "$result" '"prior_status":"resolved"'

teardown_test_db

# ── Section 5: cmd_delete ──────────────────────────────────────
echo ""
echo "── Section 5: cmd_delete ──"

setup_test_db

# Create an open case for delete tests
run_fcase init delete-test --goal "Test delete" -o json >/dev/null 2>&1

# delete without --reason fails
rc=0
out="$(run_fcase delete delete-test --confirm DELETE 2>&1)" || rc=$?
assert_eq "delete without --reason fails" "1" "$rc"
assert_contains "delete error mentions --reason" "$out" "delete requires --reason"

# delete without --confirm fails
rc=0
out="$(run_fcase delete delete-test --reason "Duplicate" 2>&1)" || rc=$?
assert_eq "delete without --confirm fails" "1" "$rc"
assert_contains "delete error mentions --confirm" "$out" "delete requires --confirm DELETE"

# delete with wrong confirm string fails
rc=0
out="$(run_fcase delete delete-test --reason "Duplicate" --confirm yes 2>&1)" || rc=$?
assert_eq "delete with --confirm yes fails" "1" "$rc"
assert_contains "delete wrong confirm mentions DELETE" "$out" "delete requires --confirm DELETE"

# delete from open succeeds (tombstones)
rc=0
out="$(run_fcase delete delete-test --reason "Duplicate case" --confirm DELETE 2>&1)" || rc=$?
assert_eq "delete from open succeeds" "0" "$rc"
assert_contains "delete pretty output" "$out" "Case 'delete-test' tombstoned. Reason: Duplicate case"

DB="$TEST_HOME/.fsuite/fcase.db"

# Row still exists (tombstoned, not removed)
result=$(sqlite3 "$DB" "SELECT COUNT(*) FROM cases WHERE slug='delete-test';" 2>&1)
assert_eq "deleted row still exists" "1" "$result"

# Status is deleted
result=$(sqlite3 "$DB" "SELECT status FROM cases WHERE slug='delete-test';" 2>&1)
assert_eq "status is deleted" "deleted" "$result"

# deleted_at is set
result=$(sqlite3 "$DB" "SELECT CASE WHEN deleted_at IS NOT NULL AND deleted_at != '' THEN 'set' ELSE 'unset' END FROM cases WHERE slug='delete-test';" 2>&1)
assert_eq "deleted_at is set" "set" "$result"

# delete_reason is stored
result=$(sqlite3 "$DB" "SELECT delete_reason FROM cases WHERE slug='delete-test';" 2>&1)
assert_eq "delete_reason stored" "Duplicate case" "$result"

# next_move is cleared
result=$(sqlite3 "$DB" "SELECT next_move FROM cases WHERE slug='delete-test';" 2>&1)
assert_eq "next_move cleared on delete" "" "$result"

# status still works on deleted case
rc=0
out="$(run_fcase status delete-test 2>&1)" || rc=$?
assert_eq "status works on deleted case" "0" "$rc"
assert_contains "status shows deleted case" "$out" "delete-test"

# export still works on deleted case
rc=0
out="$(run_fcase export delete-test -o json 2>&1)" || rc=$?
assert_eq "export works on deleted case" "0" "$rc"
assert_contains "export shows deleted slug" "$out" "delete-test"

# delete from already-deleted fails
rc=0
out="$(run_fcase delete delete-test --reason "Again" --confirm DELETE 2>&1)" || rc=$?
assert_eq "delete from deleted fails" "1" "$rc"
assert_contains "delete error mentions already deleted" "$out" "already deleted"

# delete from resolved
run_fcase init delete-resolved --goal "Resolve then delete" -o json >/dev/null 2>&1
run_fcase resolve delete-resolved --summary "Done" >/dev/null 2>&1
rc=0
out="$(run_fcase delete delete-resolved --reason "Superseded" --confirm DELETE 2>&1)" || rc=$?
assert_eq "delete from resolved succeeds" "0" "$rc"

# delete from archived
run_fcase init delete-archived --goal "Archive then delete" -o json >/dev/null 2>&1
run_fcase resolve delete-archived --summary "Done" >/dev/null 2>&1
run_fcase archive delete-archived >/dev/null 2>&1
rc=0
out="$(run_fcase delete delete-archived --reason "Retired" --confirm DELETE 2>&1)" || rc=$?
assert_eq "delete from archived succeeds" "0" "$rc"

# Event recorded for delete
result=$(sqlite3 "$DB" "SELECT event_type FROM events WHERE case_id=(SELECT id FROM cases WHERE slug='delete-test') ORDER BY id DESC LIMIT 1;" 2>&1)
assert_eq "delete event recorded" "case_deleted" "$result"

# Event payload includes prior_status and reason
result=$(sqlite3 "$DB" "SELECT payload_json FROM events WHERE case_id=(SELECT id FROM cases WHERE slug='delete-test') AND event_type='case_deleted';" 2>&1)
assert_contains "delete event has prior_status" "$result" '"prior_status":"open"'
assert_contains "delete event has reason" "$result" '"reason":"Duplicate case"'

teardown_test_db

echo ""
echo "═══════════════════════════════════════════"
echo " Results: $PASS passed, $FAIL failed, $TOTAL total"
echo "═══════════════════════════════════════════"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
