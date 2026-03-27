#!/usr/bin/env bash
# _fsuite_db.sh — shared SQLite database helpers for fsuite tools (fcase, freplay).
# Sourced (not executed). Provides: ensure_db, db_query, db_exec, migrations.

# Guard: only source once.
[[ -z "${_FSUITE_DB_LOADED:-}" ]] || return 0
_FSUITE_DB_LOADED=1

# ---------------------------------------------------------------------------
# Globals — callers may override before sourcing.
# ---------------------------------------------------------------------------
FCASE_DIR="${FCASE_DIR:-$HOME/.fsuite}"
DB_FILE="${DB_FILE:-$FCASE_DIR/fcase.db}"
SQLITE_BUSY_TIMEOUT_MS="${SQLITE_BUSY_TIMEOUT_MS:-5000}"
SQLITE_SUPPORTS_DOT_TIMEOUT=""

# _FSUITE_DB_TOOL_NAME: callers set this before sourcing so die() prints
# the right tool name (e.g. "fcase" or "freplay").

# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------

die() {
  local code=1
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    code="$1"
    shift
  fi
  echo "${_FSUITE_DB_TOOL_NAME:-fsuite}: $*" >&2
  exit "$code"
}

has() { command -v "$1" >/dev/null 2>&1; }

json_escape() {
  perl -CS -0pe '
    s/\\/\\\\/g;
    s/"/\\"/g;
    s/\x08/\\b/g;
    s/\x0c/\\f/g;
    s/\n/\\n/g;
    s/\r/\\r/g;
    s/\t/\\t/g;
    s/([\x00-\x07\x0b\x0e-\x1f])/sprintf("\\u%04x", ord($1))/ge;
  '
}

sql_quote() {
  local value="${1//\'/\'\'}"
  printf "'%s'" "$value"
}

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ---------------------------------------------------------------------------
# DB existence check (for read-only paths — no side effects)
# ---------------------------------------------------------------------------

db_exists() {
  [[ -f "$DB_FILE" ]]
}

# ---------------------------------------------------------------------------
# SQLite session plumbing
# ---------------------------------------------------------------------------

sqlite_supports_dot_timeout() {
  if [[ -n "$SQLITE_SUPPORTS_DOT_TIMEOUT" ]]; then
    [[ "$SQLITE_SUPPORTS_DOT_TIMEOUT" == "1" ]]
    return
  fi

  local probe_output="" probe_rc=0
  probe_output=$(sqlite3 ':memory:' ".timeout 1" "SELECT 1;" 2>/dev/null) || probe_rc=$?
  if [[ $probe_rc -eq 0 && "$probe_output" == "1" ]]; then
    SQLITE_SUPPORTS_DOT_TIMEOUT="1"
  else
    SQLITE_SUPPORTS_DOT_TIMEOUT="0"
  fi

  [[ "$SQLITE_SUPPORTS_DOT_TIMEOUT" == "1" ]]
}

emit_db_session_prefix() {
  if sqlite_supports_dot_timeout; then
    # Prefer the sqlite shell timeout command when available because it does
    # not leak a result row into stdout before JSON payloads.
    printf '.timeout %s\nPRAGMA foreign_keys=ON;\n' "$SQLITE_BUSY_TIMEOUT_MS"
  else
    # Some environments provide a minimal sqlite3 shim that echoes PRAGMA
    # assignment results. Preserve clean stdout for JSON commands there.
    printf 'PRAGMA foreign_keys=ON;\n'
  fi
}

db_query() {
  local separator=""
  if [[ "${1:-}" == "--separator" ]]; then
    separator="${2:-}"
    [[ -n "$separator" ]] || die "db_query requires a value for --separator"
    shift 2
  fi

  has sqlite3 || die 3 "sqlite3 is required"
  mkdir -p "$FCASE_DIR" 2>/dev/null || die "Cannot create $FCASE_DIR"

  if [[ -n "$separator" ]]; then
    { emit_db_session_prefix; cat; } | sqlite3 -separator "$separator" "$DB_FILE"
  else
    { emit_db_session_prefix; cat; } | sqlite3 "$DB_FILE"
  fi
}

db_exec() {
  has sqlite3 || die 3 "sqlite3 is required"
  mkdir -p "$FCASE_DIR" 2>/dev/null || die "Cannot create $FCASE_DIR"
  { emit_db_session_prefix; cat; } | sqlite3 "$DB_FILE" >/dev/null
}

# ---------------------------------------------------------------------------
# Version-aware database migration
# ---------------------------------------------------------------------------

ensure_db() {
  has sqlite3 || die 3 "sqlite3 is required"
  mkdir -p "$FCASE_DIR" 2>/dev/null || die "Cannot create $FCASE_DIR"

  local current_version=0
  if [[ -f "$DB_FILE" ]]; then
    current_version="$(sqlite3 "$DB_FILE" 'PRAGMA user_version;' 2>/dev/null || echo 0)"
  fi

  # --- Migration to version 1: fcase core tables ---
  if (( current_version < 1 )); then
    db_exec <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS cases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slug TEXT NOT NULL UNIQUE,
  goal TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  priority TEXT NOT NULL DEFAULT 'normal',
  next_move TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS case_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  case_id INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  started_at TEXT NOT NULL,
  ended_at TEXT,
  actor TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS targets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  case_id INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  path TEXT NOT NULL,
  symbol TEXT,
  symbol_type TEXT,
  rank INTEGER,
  reason TEXT,
  state TEXT NOT NULL DEFAULT 'candidate',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS evidence (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  case_id INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  tool TEXT NOT NULL,
  path TEXT,
  symbol TEXT,
  line_start INTEGER,
  line_end INTEGER,
  match_line INTEGER,
  summary TEXT,
  body TEXT NOT NULL,
  payload_json TEXT,
  fingerprint TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS hypotheses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  case_id INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  confidence TEXT,
  reason TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  case_id INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  session_id INTEGER REFERENCES case_sessions(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  payload_json TEXT,
  created_at TEXT NOT NULL
);

PRAGMA user_version=1;
SQL
    current_version=1
  fi

  # --- Migration to version 2: replay tables ---
  if (( current_version < 2 )); then
    db_exec <<'SQL'
PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS replays (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  case_id INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  label TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft','canonical','archived')),
  origin TEXT NOT NULL DEFAULT 'recorded'
    CHECK (origin IN ('recorded','imported','inferred')),
  fsuite_version TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  actor TEXT NOT NULL DEFAULT '',
  parent_replay_id INTEGER REFERENCES replays(id) ON DELETE SET NULL,
  notes TEXT NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_replays_one_canonical_per_case
  ON replays(case_id) WHERE status = 'canonical';

CREATE TABLE IF NOT EXISTS replay_steps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  replay_id INTEGER NOT NULL REFERENCES replays(id) ON DELETE CASCADE,
  order_num INTEGER NOT NULL,
  tool TEXT NOT NULL,
  argv_json TEXT NOT NULL,
  cwd TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('read_only','mutating','unknown')),
  purpose TEXT,
  provenance TEXT NOT NULL DEFAULT 'recorded'
    CHECK (provenance IN ('recorded','imported','inferred')),
  exit_code INTEGER NOT NULL,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  started_at TEXT NOT NULL,
  telemetry_run_id TEXT,
  result_summary TEXT,
  error_excerpt TEXT,
  UNIQUE (replay_id, order_num)
);

CREATE TABLE IF NOT EXISTS replay_step_links (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  step_id INTEGER NOT NULL REFERENCES replay_steps(id) ON DELETE CASCADE,
  link_type TEXT NOT NULL
    CHECK (link_type IN ('evidence','target','hypothesis')),
  link_ref TEXT NOT NULL,
  UNIQUE (step_id, link_type, link_ref)
);

PRAGMA user_version=2;
SQL
    current_version=2
  fi
}

# ---------------------------------------------------------------------------
# Case lookup helpers
# ---------------------------------------------------------------------------

case_id_for_slug() {
  local slug="$1"
  db_query <<<"SELECT id FROM cases WHERE slug = $(sql_quote "$slug");"
}

case_exists_or_die() {
  local slug="$1"
  local case_id
  case_id="$(case_id_for_slug "$slug")"
  [[ -n "$case_id" ]] || die "case not found: $slug"
  printf '%s' "$case_id"
}
