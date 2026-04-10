<!-- README section: New Tools (v2.2.0+) -->
<!-- Insert after existing ## Tools section, before ## Output Formats -->

---

## `fs` &mdash; unified search orchestrator

One call. Auto-routes. `fs` classifies your query's intent — file, symbol, or content — then builds and fires the optimal fsuite tool chain behind the scenes. You never have to decide whether to reach for `fsearch`, `fcontent`, or `fmap` separately. The drone swarm assembles itself.

```bash
fs [OPTIONS] <query> [path]
```

**What it does:**

`fs` runs a Python engine (`fs-engine.py`) that classifies the query, selects tools, executes them in sequence, and returns ranked results with enrichment metadata and a `next_hint` field for follow-up refinement. Output is pipeline-safe: auto-switches from `pretty` to `json` when stdout is not a terminal.

**Intent classification rules:**

| Query shape | Detected intent | Tool chain fired |
|-------------|-----------------|-----------------|
| `*.py`, `*.log`, `*.rs` | `file` | `fsearch` |
| `renderTool`, `McpServer`, `AuthHandler` (camelCase / PascalCase) | `symbol` | `fsearch` -> `fmap --name` |
| `parse_tokens`, `emit_chunk` (snake_case) | `symbol` | `fsearch` -> `fmap --name` |
| `MAX_RETRIES`, `DB_PATH` (SCREAMING_CASE) | `symbol` | `fsearch` -> `fmap --name` |
| `"error loading config"`, `"failed to connect"` (multi-word quoted) | `content` | `fcontent` |
| `-i symbol authenticate` (forced override) | `symbol` | `fmap --name` |
| `router`, `config`, `logger` (single bare word) | `content` (low-confidence) | `fcontent` |

**Key capabilities:**

- Single entry point for all search intent — no more per-tool decision overhead
- Automatic intent detection from query shape (glob, camelCase, multi-word phrase)
- `--intent` flag to override classification when auto-detection is wrong
- `--scope GLOB` narrows the candidate file set before tool chain execution
- Ranked hits with enrichment: file size, language, symbol count where available
- `next_hint` in JSON output tells the agent what to call next
- Hard caps: `--max-candidates` (default 50), `--max-enrich` (default 15), `--timeout` (default 10s)
- Auto output mode: `pretty` for terminal, `json` for pipe

**Examples:**

```bash
# File search — glob pattern detected
fs "*.py"

# Symbol search — camelCase detected automatically
fs renderTool

# Content search — multi-word phrase detected
fs "error loading config" src/

# Symbol search scoped to TypeScript files only
fs -s "*.ts" McpServer

# Force symbol intent when auto-detection would miss it
fs -i symbol authenticate

# JSON output piped to jq
fs -o json "*.rs" | jq '.hits'

# Scoped content search with explicit path
fs -p /home/user/project "failed to parse"

# Override candidate cap for large monorepos
fs --max-candidates 200 "*.go" /repo
```

**JSON output example:**

```json
{
  "tool": "fs",
  "version": "2.3.0",
  "intent": "symbol",
  "query": "renderTool",
  "hits": [
    {
      "path": "src/tools/render.ts",
      "score": 0.97,
      "symbol": "renderTool",
      "line": 42,
      "language": "typescript"
    }
  ],
  "hit_count": 1,
  "next_hint": "fread src/tools/render.ts --symbol renderTool"
}
```

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `-s, --scope GLOB` | — | Glob filter applied before tool chain (e.g. `"*.py"`) |
| `-i, --intent MODE` | `auto` | Override intent: `auto` \| `file` \| `content` \| `symbol` |
| `-o, --output MODE` | `pretty`/`json` | Output format; auto-selects based on tty |
| `-p, --path PATH` | `.` | Search root; overrides positional path argument |
| `--max-candidates N` | `50` | Cap on candidate files fed into the chain |
| `--max-enrich N` | `15` | Cap on files enriched with symbol/content metadata |
| `--timeout N` | `10` | Wall-time cap in seconds for the full chain |
| `-h, --help` | — | Show usage |
| `--version` | — | Print version |

---

## `fprobe` &mdash; binary/opaque file reconnaissance

The deep-scan drone for files that `fread` cannot parse. `fprobe` treats its target as a raw byte stream and applies three specialized subcommands: extract printable strings, scan for literal byte patterns with offset context, or read a raw byte window at a known address. Purpose-built for SEA binaries, compiled bundles, and packed assets.

Architecture: Bash CLI layer + Python `mmap` engine (`fprobe-engine.py`). The engine does byte-safe memory-mapped reads — no shell text processing on binary content.

```bash
fprobe strings <file> [--filter <literal>] [--ignore-case] [-o pretty|json]
fprobe scan    <file> --pattern <literal> [--context N] [--ignore-case] [-o pretty|json]
fprobe window  <file> --offset N [--before N] [--after N] [--decode printable|utf8|hex] [-o pretty|json]
```

**Key capabilities:**

- Three focused subcommands map directly to three phases of binary recon
- `strings`: extracts printable ASCII runs (minimum 6 chars); `--filter` narrows to literal matches
- `scan`: finds a literal byte pattern anywhere in the file; returns byte offset + surrounding context window
- `window`: reads a raw byte range at a known offset; decodes as printable text, UTF-8, or hex dump
- Python `mmap` engine — safe on multi-GB binaries, no full-file read into memory
- `--ignore-case` on `strings` and `scan` for case-insensitive matching
- Auto output mode: `pretty` for terminal with color offsets, `json` for pipeline/agent consumption
- Read-only by design — no mutations, no side effects

**Examples:**

```bash
# Extract all printable strings from a compiled binary
fprobe strings ./claude-binary

# Find strings containing a specific token
fprobe strings ./claude-binary --filter "renderTool"

# Scan for a literal pattern and get byte-offset context
fprobe scan ./claude-binary --pattern "userFacingName" --context 500

# Read 3000 bytes around a known offset (from a previous scan hit)
fprobe window ./claude-binary --offset 112202147 --before 200 --after 3000

# Inspect file header as hex (magic bytes, format identification)
fprobe window ./claude-binary --offset 0 --after 16 --decode hex

# Case-insensitive string filter
fprobe strings ./bundle.js --filter "secret" --ignore-case

# JSON output for agent pipeline
fprobe scan ./app.node --pattern "SNAPSHOT_BLOB" -o json | jq '.matches[0].offset'
```

**JSON output example (`scan`):**

```json
{
  "tool": "fprobe",
  "version": "2.2.0",
  "subcommand": "scan",
  "file": "./claude-binary",
  "pattern": "userFacingName",
  "matches": [
    {
      "offset": 112202147,
      "context_before": "...{\"name\":\"",
      "match": "userFacingName",
      "context_after": "\",\"description\":\"..."
    }
  ],
  "match_count": 1
}
```

**Subcommand flags:**

| Subcommand | Flag | Description |
|-----------|------|-------------|
| `strings` | `--filter LITERAL` | Narrow output to strings containing this literal |
| `strings` | `--ignore-case` | Case-insensitive filter matching |
| `scan` | `--pattern LITERAL` | Required. Byte pattern to locate |
| `scan` | `--context N` | Bytes of surrounding context to return (default: 200) |
| `scan` | `--ignore-case` | Case-insensitive pattern matching |
| `window` | `--offset N` | Required. Byte offset to read from |
| `window` | `--before N` | Bytes to include before offset (default: 0) |
| `window` | `--after N` | Bytes to include after offset (default: 200) |
| `window` | `--decode MODE` | Decode output as `printable` (default), `utf8`, or `hex` |
| all | `-o pretty\|json` | Output format; auto-selects based on tty |

---

## `freplay` &mdash; deterministic investigation replay

The investigation flight recorder. `freplay` wraps any fsuite command invocation in a record/replay envelope: it runs the command, captures the invocation arguments, output, exit code, and timestamp into a persistent SQLite store keyed by case slug. Replays can be shown, verified, promoted to canonical status, or exported as JSON for handoffs.

Every recorded replay is linked to an `fcase` case. This closes the loop between investigation state (`fcase`) and the exact commands that produced it (`freplay`).

```bash
freplay record <case-slug> [--purpose "..."] [--link <type:id>]... -- <fsuite-command...>
freplay show   <case-slug> [--replay-id N] [-o pretty|json]
freplay list   <case-slug> [-o pretty|json]
freplay export <case-slug> [--replay-id N] [-o json]
freplay verify <case-slug> [--replay-id N] [-o pretty|json]
freplay promote <case-slug> <replay-id>
freplay archive <case-slug> <replay-id>
```

**Key capabilities:**

- `record`: runs the target fsuite command and stores its full invocation + result
- `show`: retrieves a stored replay (latest, or by `--replay-id`)
- `list`: shows all replays for a case with timestamps and status
- `verify`: validates a stored replay without re-executing — checks paths, tool availability, linked entities
- `promote`: marks a replay as canonical for a case
- `archive`: soft-deletes a replay (recoverable)
- `--purpose` annotates the recording with human-readable intent
- `--link type:id` creates a cross-reference to an `fcase` evidence or hypothesis entry
- `freplay` and `fmetrics` are excluded from recording (denylist — no recursive loops)
- `fedit` recordings are classified `read_only` by default; `mutating` when `--apply` is present
- Verify exit codes: `0` = pass, `1` = warn, `2` = fail

**Examples:**

```bash
# Record a fprobe scan with purpose annotation
freplay record sea-bundle-audit --purpose "Locate snapshot blob marker" -- \
  fprobe scan ./claude-binary --pattern "SNAPSHOT_BLOB" -o json

# Record a fread with a case link
freplay record auth-seam --link evidence:7 -- \
  fread /project/src/auth.ts --symbol authenticate

# Show the latest replay for a case
freplay show auth-seam

# Show a specific replay by ID
freplay show auth-seam --replay-id 3

# List all replays for a case
freplay list sea-bundle-audit

# Verify a replay is still valid (paths exist, tools present)
freplay verify auth-seam --replay-id 2

# Promote replay 2 to canonical
freplay promote auth-seam 2

# Export as JSON for handoff
freplay export auth-seam --replay-id 2 -o json
```

**Subcommand reference:**

| Subcommand | Description |
|-----------|-------------|
| `record` | Run command, store invocation + result |
| `show` | Display a stored replay |
| `list` | List all replays for a case |
| `export` | Export replay as JSON |
| `verify` | Validate replay integrity without executing |
| `promote` | Mark replay as canonical |
| `archive` | Soft-delete a replay |

---

## `fwrite` &mdash; MCP virtual write tool

**`fwrite` is not a CLI command.** It is an MCP-only virtual tool that routes through `fedit`'s mutation engine. When an agent calls `fwrite` via the MCP server, the server translates the call into the appropriate `fedit --create` or `fedit --replace-file --apply` operation. One mutation brain; two surfaces.

This design means agents never need to decide between `fedit` and a separate write primitive. File creation and full-file replacement go through the same dry-run / apply / precondition stack as surgical patches.

**MCP tool signature:**

```json
{
  "name": "fwrite",
  "parameters": {
    "path":      "Absolute file path to write",
    "content":   "File content to write",
    "overwrite": "Replace existing file (default: false = create only)",
    "apply":     "Apply changes (default: true). Set false for dry-run preview."
  }
}
```

**Behavior:**

- `overwrite: false` (default): fails if the file already exists — safe create
- `overwrite: true`: replaces the entire file from `content` — equivalent to `fedit --replace-file --apply`
- `apply: false`: returns a diff preview without writing — dry-run mode inherited from `fedit`
- All writes are atomic: fedit's temp-file + rename pipeline, not a direct `echo >` write

**When to use `fwrite` vs `fedit` (agent guidance):**

| Task | Tool |
|------|------|
| Create a new file from scratch | `fwrite` (MCP) |
| Replace an entire file | `fwrite` with `overwrite: true` |
| Surgical inline patch (replace a block, insert after anchor) | `fedit` |
| Line-range replacement | `fedit --lines` |
| Batch patch across multiple files | `fedit --targets-file` |

> `fwrite` is only available in MCP-connected agent sessions. It has no CLI equivalent — running `fwrite` from a shell will produce a "command not found" error. Use `fedit --create` or `fedit --replace-file` for the same operations from the command line.

---

## `fedit` &mdash; line-range replacement mode

> **Addition to existing fedit docs.** This section documents the `--lines` mode shipped in v2.2.0. For the full fedit reference, see [fedit — surgical patching](#fedit--surgical-patching).

### `--lines START:END`

Replaces a specific line range with new content. The replacement is identified by line numbers, not by anchor text — no anchor ambiguity, no pattern matching, no regex. Designed for use directly after `fread` returns line numbers in its output.

**Typical workflow:**

```bash
# 1. Read the file — fread output includes line numbers in every chunk
fread /project/src/config.ts --around "defaultTimeout" --after 15
# Output shows lines 88–103 contain the block you need to replace

# 2. Replace exactly those lines
fedit /project/src/config.ts --lines 88:103 --with "$(cat new-block.ts)"

# 3. Preview the diff (dry-run is default — nothing writes without --apply)
# Output shows unified diff of the replacement

# 4. Apply when confirmed
fedit /project/src/config.ts --lines 88:103 --with "$(cat new-block.ts)" --apply
```

**Key behaviors:**

- Line numbers are 1-indexed, inclusive on both ends (`88:103` replaces lines 88 through 103)
- Combines with `--with TEXT` for inline replacement content
- Combines with `--content-file PATH` for multi-line payloads from a file
- Combines with `--stdin` for pipeline-delivered content
- Dry-run by default — requires explicit `--apply` to mutate
- Fails closed if the line range is out of bounds for the target file
- JSON output (`-o json`) returns `lines_replaced`, `line_start`, `line_end` in the result envelope

**Examples:**

```bash
# Replace lines 88–103 with inline content
fedit /project/src/config.ts --lines 88:103 \
  --with "  defaultTimeout: 5000," \
  --apply

# Replace a block with a multi-line payload from a file
fedit /project/src/handler.py --lines 42:67 \
  --content-file patch-body.py \
  --apply

# Dry-run preview only (default — no --apply)
fedit /project/src/auth.ts --lines 120:135 \
  --with "  return deny(reason);"

# JSON output for agent verification
fedit /project/src/auth.ts --lines 120:135 \
  --with "  return deny(reason);" \
  --apply -o json

# Combine with fread line-number output in an agent loop
RANGE=$(fread /project/src/server.ts --around "startServer" --after 20 -o json \
  | jq -r '"\(.chunks[0].start_line):\(.chunks[0].end_line)"')
fedit /project/src/server.ts --lines "$RANGE" --content-file new-start.ts --apply
```

**JSON output example:**

```json
{
  "tool": "fedit",
  "version": "2.2.0",
  "mode": "lines",
  "file": "/project/src/auth.ts",
  "line_start": 120,
  "line_end": 135,
  "lines_replaced": 16,
  "applied": true,
  "diff": "@@ -120,16 +120,1 @@\n-  return false;\n+  return deny(reason);\n"
}
```

**`--lines` flags summary:**

| Flag | Description |
|------|-------------|
| `--lines START:END` | Line range to replace (1-indexed, inclusive) |
| `--with TEXT` | Inline replacement content |
| `--content-file PATH` | Read replacement content from file |
| `--stdin` | Read replacement content from stdin |
| `--apply` | Write the change (dry-run is default without this flag) |
| `-o json` | Machine-readable output with diff and metadata |
