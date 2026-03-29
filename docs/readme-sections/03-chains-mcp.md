<!-- fsuite README overhaul — section 03 -->
<!-- Generated 2026-03-29 from validated chain data + live MCP source -->

---

## Chain Combination Guide

The chain system is the highest-leverage feature in fsuite. Two tools piped together can answer questions in one command that would take a dozen raw filesystem calls to answer blindly. This section covers the mechanics, the validated patterns, and — critically — what not to chain.

### The Pipe Contract

Every chainable tool communicates via one of two machine-readable output modes:

| Flag | Output | Role |
|------|--------|------|
| `-o paths` | One absolute file path per line | Pipe currency — feeds the next tool |
| `-o json` | Structured JSON | Terminal output for programmatic decisions |

The rule is simple: **producers** emit paths, **consumers** read paths from stdin. Break this contract and the pipe silently produces garbage.

### Compatibility Matrix

#### Producers — tools that can emit file paths

| Tool | Flag | What it produces |
|------|------|-----------------|
| `fsearch` | `-o paths` | File paths matching a glob or name pattern |
| `fcontent` | `-o paths` | File paths containing a literal string |

Both tools support up to 2000 files in a single run.

#### Consumers — tools that accept file paths on stdin

| Tool | stdin behavior | Notes |
|------|---------------|-------|
| `fcontent` | Reads file paths, searches inside them | `stdin_files` mode |
| `fmap` | Reads file paths, maps symbols in each | `stdin_files` mode |

`fcontent` is both a producer and a consumer. This is what makes deep narrowing chains possible.

#### Non-pipe tools — argument-based, not stdin-chainable

These tools take paths or identifiers as positional arguments. They are terminal nodes in a workflow, not pipe links.

| Tool | Why it cannot be piped from | How to use it |
|------|----------------------------|---------------|
| `fread` | Outputs file content, not file paths | Call it after `fmap` identifies the exact symbol or line range |
| `fedit` | `--stdin` reads payload text, not a file list | Call it after `fread` confirms the seam |
| `ftree` | Outputs a tree visualization | Use it first, not mid-chain |
| `fprobe` | Outputs JSON or text report on a single binary | Standalone recon |
| `fcase` | Outputs investigation state | Standalone continuity ledger |
| `freplay` | Outputs derivation history | Standalone tracker |
| `fmetrics` | Reads telemetry database | Standalone analytics |

---

### Named Chain Patterns

These are the validated patterns, tested end-to-end on 2026-03-29.

#### Scout Chain

Purpose: establish territory on a new or unfamiliar codebase.

```bash
ftree --snapshot -o json /project
```

`ftree` with `--snapshot` walks the tree once and caches it. Use this as the first move on any session. It is not a pipe node — it is the orientation step that makes every subsequent chain cheaper.

```bash
# MCP equivalent
ftree(path: "/project", snapshot: true, output: "json")
```

#### Investigation Chain

Purpose: find every file that touches a concept, then get the symbol map.

```bash
fcontent -o paths "authenticate" src | fmap -o json
```

This answers: "which files mention this token, and what functions/classes live in them?" The output is a symbol map you can scan without opening any file.

```bash
# MCP equivalent (sequential calls)
fcontent(query: "authenticate", path: "src", output: "paths")
# → returns file list
fmap(path: "<each file from results>", output: "json")
```

#### Scout-then-Investigate Chain (2-step)

Purpose: narrow by file type first, then by content.

```bash
fsearch -o paths '*.py' src | fcontent -o paths "def authenticate"
```

The `fsearch` pass keeps `fcontent` from scanning unrelated file types. On a polyglot repo this can cut the candidate set by 80%.

#### Surgical Chain

Purpose: get from a concept to an exact edit target in the fewest steps.

```bash
# Step 1 — find the right files
fsearch -o paths '*.rs' src | fcontent -o paths "pub fn"

# Step 2 — map what's in them
fsearch -o paths '*.rs' src | fcontent -o paths "pub fn" | fmap -o json

# Step 3 — read the exact symbol
fread src/auth.rs --symbol authenticate

# Step 4 — edit the seam
fedit src/auth.rs --function authenticate --replace "return true" --with "return verify(token)"
```

Steps 1–2 are a single compound pipe. Steps 3–4 are individual tool calls operating on the exact coordinates the pipe produced.

#### Full Recon Chain

Purpose: new codebase, understand all public API symbols across every source file.

```bash
ftree --snapshot -o json /project
fsearch -o paths '*.rs' src | fcontent -o paths "pub fn" | fmap -o json
fread src/auth.rs --symbol authenticate
fcase init auth-fix --goal "Fix authenticate bypass"
fedit src/auth.rs --function authenticate --replace "return true" --with "return verify(token)"
fmetrics stats
```

Tested against fsuite itself: this pipeline produced 1956 symbols from the repo in one pass.

#### Progressive Narrowing Chain

Purpose: drill through multiple content filters before mapping.

```bash
# Narrow → narrow → map
fsearch -o paths '*.ts' src | fcontent -o paths "export" | fcontent -o paths "async" | fmap -o json
```

Three filters, one final symbol map. Each `fcontent -o paths` stage shrinks the file list. The final `fmap` only runs on files that passed all three gates.

#### Config Key Hunt

Purpose: find which JSON files in a project reference a specific key.

```bash
fsearch -o paths '*.json' . | fcontent "api_key"
```

No `-o paths` on the terminal `fcontent` — you want the match lines, not more paths.

#### Test Coverage Map

Purpose: see what test files exist and what they test.

```bash
fsearch -o paths 'test_*.py' tests | fmap -o json
```

Binary recon workflow (standalone, not a pipe chain):

```bash
fprobe scan binary --pattern "renderTool" --context 300
fprobe window binary --offset 112730723 --before 50 --after 200
fprobe strings binary --filter "diffAdded"
```

---

### MCP vs CLI: Chain Translation

In MCP mode (Claude Code, Codex), there are no Unix pipes. The agent reconstructs the equivalent chain by calling tools sequentially and passing results forward explicitly.

```
CLI pipe:     fsearch -o paths '*.py' | fcontent -o paths "def " | fmap -o json

MCP sequence: fsearch(query: "*.py")
              → returns ["/src/auth.py", "/src/user.py", ...]
              fcontent(query: "def ", path: "/src/auth.py")
              fcontent(query: "def ", path: "/src/user.py")
              → returns filtered list
              fmap(path: "/src/auth.py")
              fmap(path: "/src/user.py")
              → returns symbol maps
```

The MCP adapter always returns structured JSON internally, so agents receive clean data without parsing ANSI output.

Key difference: the CLI pipe is O(1) tool calls. The MCP sequence is O(n) calls proportional to the candidate file count. For large repos, run `fsearch` first to reduce n before calling `fcontent` per file.

---

### Power Pairs

These two-tool combinations cover the majority of agent use cases.

| Pair | Use case |
|------|----------|
| `fsearch → fread` | Find file by name, read exact symbol or line range |
| `fmap + fread` | Map symbols first, then read the one that matches |
| `fcontent → fedit` | Confirm text location, then edit the seam |
| `fprobe → fread` | Find offset in binary, then read source context |
| `fsearch → fmap` | Find files by type, get their full symbol inventory |
| `fcontent → fmap` | Find files by content, understand their structure |

The pattern in every pair: one tool establishes coordinates, the next tool acts on them. Never act without coordinates.

---

### Anti-Patterns

These chains look plausible but break the pipe contract. Each one is a common mistake.

| Anti-pattern | Why it fails | What to do instead |
|-------------|-------------|-------------------|
| `fread \| anything` | `fread` outputs file content, not file paths. The next tool receives raw text and silently ignores or misparses it. | Use `fread` as the terminal step. Get coordinates from `fmap` first. |
| `fedit \| anything` | `fedit` outputs a diff or confirmation message, not paths. | `fedit` is always the final step. Chain ends here. |
| `ftree \| fcontent` | `ftree` outputs a formatted tree visualization. `fcontent` expects one path per line. | Use `fsearch` to produce paths for `fcontent`. `ftree` is for human orientation only. |
| `fmap \| fread` | `fmap` outputs a JSON symbol map or pretty-printed list, not file paths. | After `fmap`, read the exact symbol with `fread --symbol` using the path from `fmap`'s output. |
| `fprobe \| anything` | `fprobe` outputs binary analysis in JSON or text. Not a path emitter. | `fprobe` findings → use the offset/path manually with `fread`. |
| `fcase \| anything` | `fcase` outputs investigation state JSON. Not a path emitter. | `fcase` is a side-channel bookkeeping tool, not a pipeline node. |
| `fcontent` (no `-o paths`) `\| fmap` | Without `-o paths`, `fcontent` outputs match lines with context, not bare paths. | Always add `-o paths` to intermediate `fcontent` calls. |

Rule of thumb: if a tool's output is human-readable prose, colored text, or structured JSON describing file contents — it is not a producer. Only `fsearch -o paths` and `fcontent -o paths` are valid producers.

---

## MCP Adapter Layer

### What It Is

`fsuite-mcp` is a thin, stateless Node.js dispatcher that wraps the fsuite bash tools as native MCP tool calls. It does no work itself. Every tool call resolves to an `execFile` invocation against the corresponding bash binary — arguments are passed as an array (never shell-interpolated), and the process exits cleanly after each call.

The adapter's contract:
- **Architecture**: stateless dispatcher — no session, no cache, no shared state between calls
- **Security**: uses `execFile`, not `exec` — shell injection is structurally impossible
- **Rendering**: pretty output is produced by the bash tools, forwarded verbatim to the MCP client
- **SDK**: `@modelcontextprotocol/sdk` v1.28.0, `McpServer` + `registerTool` API

### Setup

**Install dependencies:**

```bash
cd /path/to/fsuite/mcp
npm install
```

Dependencies: `@modelcontextprotocol/sdk`, `zod`, `highlight.js`.

**Register in Claude Code** (`~/.claude/settings.json` or project-level `.claude/settings.json`):

```json
{
  "mcpServers": {
    "fsuite": {
      "command": "node",
      "args": ["/path/to/fsuite/mcp/index.js"],
      "type": "stdio"
    }
  }
}
```

After adding the config, restart Claude Code. The tools appear as `mcp__fsuite__fread`, `mcp__fsuite__fedit`, etc. in the tool list.

**Verify registration:**

```bash
# In a Claude Code session, the tools should appear as:
# mcp__fsuite__ftree, mcp__fsuite__fmap, mcp__fsuite__fread,
# mcp__fsuite__fcontent, mcp__fsuite__fsearch, mcp__fsuite__fedit,
# mcp__fsuite__fwrite, mcp__fsuite__fcase, mcp__fsuite__fprobe,
# mcp__fsuite__fmetrics, mcp__fsuite__fs
```

### Registered Tools

All 12 MCP tools with their functional roles:

| Tool | Category | Description |
|------|----------|-------------|
| `ftree` | Scout | Directory tree with snapshot mode and JSON output. The first call on any new project. |
| `fsearch` | Search | Find files by glob or name pattern. Produces `-o paths` compatible output. |
| `fcontent` | Search | Search file contents for a literal string. Can consume a file list from stdin in CLI mode; in MCP mode, accepts a path or file list directly. |
| `fmap` | Structure | Extract symbol maps (functions, classes, imports, exports) from source files. Core of the investigation chain. |
| `fread` | Read | Budgeted file reading with symbol resolution, line ranges, and context windows around patterns. The primary file reading tool. |
| `fedit` | Mutation | Surgical text editing — replace by function name, exact string, or line range. Emits a diff on completion. |
| `fwrite` | Mutation | Write or overwrite a file. Use when creating new files or when full-file replacement is cleaner than surgical edit. |
| `fcase` | Knowledge | Investigation ledger — init a case, record steps, preserve context across context window boundaries. |
| `freplay` | Knowledge | Derivation tracker — record and replay the reasoning chain for a code change. |
| `fprobe` | Diagnostic | Binary analysis — scan, string extraction, hex window, pattern search in compiled binaries. |
| `fmetrics` | Diagnostic | Usage telemetry — import, stats, and cost prediction for the fsuite tool suite itself. |
| `fs` | Meta | Suite guide — load the mental model, tool index, and workflow summary in one call. |

### Pretty Rendering

The MCP adapter produces terminal-quality output inside Claude Code's tool output pane. This is not cosmetic — it is a deliberate design choice to make tool output scannable without reading every line.

**Syntax highlighting** is applied via `highlight.js` with a full Monokai color mapping. Language is auto-detected from the file extension. The ANSI escape sequences use truecolor (24-bit RGB) matching Claude Code's exact rendering engine.

Monokai scope → ANSI color mapping (direct from source):

| Scope | RGB | Appears as |
|-------|-----|-----------|
| `keyword` / `operator` | `249, 38, 114` | Monokai pink |
| `storage` / `hljs-type` | `102, 217, 239` | Monokai cyan |
| `built_in` / `title` / `attr` | `166, 226, 46` | Monokai green |
| `string` / `regexp` | `230, 219, 116` | Monokai yellow |
| `literal` / `number` / `symbol` | `190, 132, 255` | Monokai purple |
| `params` | `253, 151, 31` | Monokai orange |
| `comment` / `meta` | `117, 113, 94` | Monokai grey |
| `variable` / `property` | `255, 255, 255` | White |

**Diff rendering** uses dedicated backgrounds:

| Diff line type | Background RGB | Gutter fg RGB |
|---------------|---------------|--------------|
| Added line | `2, 40, 0` | `80, 200, 80` |
| Removed line | `61, 1, 0` | `220, 90, 90` |

The diff renderer is pixel-matched to Claude Code's native diff view — the result is indistinguishable from the built-in `Edit` tool's output.

### Tool Color Palette

Each tool gets a distinct 256-color ANSI code for its header in the tool output pane. The palette follows a semantic grouping:

| Color | ANSI 256 | Tools | Semantic role |
|-------|----------|-------|--------------|
| Neon green | `46` | `fread`, `ftree`, `freplay` | Read / scout — safe, non-mutating |
| Orange | `208` | `fedit`, `fwrite` | Mutation — write operations |
| Royal blue | `27` | `fcontent`, `fsearch`, `fs` | Search — content and structure discovery |
| Dark violet | `129` | `fmap`, `fcase` | Structure / knowledge — symbol maps and case state |
| Pure red | `196` | `fprobe`, `fmetrics` | Diagnostic / recon — binary and telemetry analysis |

The color is embedded as an ANSI escape in the tool's `annotations.title` field. The binary patch (`fpatch-claude-mcp`) enables Claude Code's renderer to pass the title through verbatim rather than stripping ANSI.

---

## Dev Mode

### FSUITE_USE_PATH Toggle

By default, `mcp/index.js` resolves tool binaries from the source tree — the directory one level up from `mcp/`. This means edits to source bash scripts take effect on the next MCP server restart without reinstallation.

```bash
# Default (source tree mode — dev workflow)
node mcp/index.js

# Force PATH resolution (production / installed binaries)
FSUITE_USE_PATH=1 node mcp/index.js
```

### How resolveTool() Works

```javascript
const FSUITE_SRC_DIR = process.env.FSUITE_USE_PATH
  ? null
  : join(dirname(new URL(import.meta.url).pathname), "..");

function resolveTool(name) {
  if (FSUITE_SRC_DIR) return join(FSUITE_SRC_DIR, name);
  return name; // resolve from PATH
}
```

When `FSUITE_USE_PATH` is unset (default), `FSUITE_SRC_DIR` is the repo root (parent of `mcp/`). `resolveTool("fread")` returns `/path/to/fsuite/fread` — the source file, not the installed binary.

When `FSUITE_USE_PATH=1`, `FSUITE_SRC_DIR` is `null`, and `resolveTool` returns the bare name, letting `execFile` find it on `$PATH`.

### Edit → Restart → Live Changes Workflow

```bash
# 1. Edit a source tool
vim /path/to/fsuite/fread

# 2. Restart the MCP server
# In Claude Code: /mcp restart fsuite
# Or kill and relaunch the node process

# 3. Next tool call picks up the change immediately
# No npm install, no build step required
```

The only time you need `FSUITE_USE_PATH=1` is when running the MCP server against a globally installed fsuite where the source tree is not authoritative (e.g., CI or a shared environment).

---

## Binary Patching

### fpatch-claude-mcp

`fpatch-claude-mcp` patches the Claude Code Electron binary to clean up how MCP tool names render in the tool output header.

**What it patches:**

The binary contains a `userFacingName()` function that formats MCP tool names as `"fsuite - fread (MCP)"` in plain white. The patch rewrites this to emit just `"fread"` in the configured color (default: bold cyan). It uses `fprobe` to locate the relevant byte offset dynamically, so it survives minor Claude Code version updates without a hardcoded offset.

**Safety:**

- Creates a `.bak` backup before writing any bytes.
- Idempotent: running twice does not corrupt the binary.
- `--dry-run` shows what would be patched without writing.
- `--restore` reverts from the `.bak` backup.

```bash
fpatch-claude-mcp                    # Apply patch (bold cyan, latest binary)
fpatch-claude-mcp --dry-run          # Preview only
fpatch-claude-mcp --color green      # Use a different color
fpatch-claude-mcp --binary PATH      # Target a specific binary version
fpatch-claude-mcp --restore          # Revert to .bak
```

Available colors: `cyan`, `green`, `yellow`, `magenta`, `bold_cyan`, `bold_green`.

**Status note:** `fpatch-claude-mcp` is the original bash-based patcher. Current binary work — including the truecolor title embedding used by the tool palette — is done via manual Python patchers that operate at the renderer level rather than the `userFacingName` function. `fpatch-claude-mcp` remains available for the `userFacingName` patch specifically, but should be treated as a maintenance-mode tool.
