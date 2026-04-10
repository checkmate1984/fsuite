---
title: Episode 2
description: fsuite backstory, episode 2.
sidebar:
  order: 4
---

```
    ███████╗███████╗██╗   ██╗██╗████████╗███████╗
    ██╔════╝██╔════╝██║   ██║██║╚══██╔══╝██╔════╝
    █████╗  ███████╗██║   ██║██║   ██║   █████╗
    ██╔══╝  ╚════██║██║   ██║██║   ██║   ██╔══╝
    ██║     ███████║╚██████╔╝██║   ██║   ███████╗
    ╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝
    ─────────────────────────────────────────────
    [ FIELD DISPATCH ]  Episode 2: The Monolith
    [ PREVIOUS ]        Episode 1: The Fourth Drone
    [ STATUS ]          Twelve tools. Binary vision. Pixel-perfect rendering. Archive-grade docs.
```

---

## Mission Context

This is the episode that was never supposed to be one session.

Episode 0 was about trust. Episode 1 was about filling the structural gap. Between then and now, six releases happened — v2.0.0 through v2.2.0 — each shipping new tools and fixing what the previous one broke. `fedit` grew from a patch tool into a symbol-first batch editor. `fcase` and `freplay` went from concept to shipping infrastructure. The MCP adapter matured from a proof-of-concept into a rendering-correct dispatcher handling eleven tool surfaces. The Debian package kept up. The test suite kept growing. Fourteen PRs went through the machine.

And then, on March 29th, 2026, the operator said: "We're doing this in one session. Binary RE, pixel-perfect rendering, fprobe, fedit --lines, fs unified search, dev mode, binary patching, full README overhaul, and a PR that tells the whole story."

That session ran for eighteen hours.

This is what came out.

---

## The Binary Wall

It started with a question nobody had asked before: what does the Claude Code binary look like from the inside?

Not the source code — that is not available. The compiled Electron binary. The SEA (Single Executable Application) bundle that ships as the Claude Code CLI. The thing that runs on your machine and renders MCP tool output. Nobody was looking inside it because nobody had a tool that could.

Now we had `fprobe`.

```bash
fprobe strings ~/.claude/local/claude --filter "renderTool"
```

That single command returned 47 matches. Strings embedded in the compiled binary — function names, property keys, format strings — visible to anyone who knew where to look. The reconnaissance drones had learned to see through compiled code.

But seeing was not enough. The MCP tool names rendered as `"fsuite - fread (MCP)"` in plain white. Every tool looked the same. In a session with twelve fsuite tools alongside the built-in Read, Edit, and Grep, the tool output panel was a wall of identical white headers. You could not tell which tool produced which output without reading the content.

The operator wanted colored headers. One color per semantic group. Green for read/scout tools. Orange for mutation tools. Blue for search tools. Violet for structure/knowledge. Red for diagnostics.

The problem: Claude Code's renderer strips ANSI escapes from MCP tool titles. The `userFacingName()` function in the binary formats the name as a plain string. There is no configuration option. There is no API.

So we patched the binary.

---

## The Reverse Engineering

`fprobe scan` found the `userFacingName` function at byte offset 112,202,147. `fprobe window` read the surrounding 3,000 bytes and revealed the JavaScript AST node that constructs the display string. The function concatenates the server name, a separator, and the tool name with a trailing `"(MCP)"` suffix.

```bash
fprobe scan ~/.claude/local/claude --pattern "userFacingName" --context 500
fprobe window ~/.claude/local/claude --offset 112202147 --before 200 --after 3000
```

The patch rewrites the format string to emit just the tool name — no server prefix, no `(MCP)` suffix — wrapped in an ANSI escape sequence for the configured color. `fpatch-claude-mcp` automates this: it uses `fprobe` to locate the offset dynamically, creates a `.bak` backup, and writes the patched bytes. Idempotent. Restorable. Dry-runnable.

But `fpatch-claude-mcp` was the first-generation patcher. For the truecolor per-tool palette — neon green, orange, royal blue, dark violet, pure red — we went deeper. Manual Python patchers that operate at the renderer level, embedding 256-color ANSI codes in the `annotations.title` field of each MCP tool response. The MCP SDK passes the title through to the client. The patched renderer passes ANSI through to the terminal. The result: each tool output panel gets its own header color, semantically grouped by category.

That is a tool suite that looks like a tool suite, not a wall of anonymous white text.

---

## The Pixel-Perfect Rendering

The MCP adapter was already functional. It could dispatch calls, return JSON, and forward pretty output. But "functional" and "pixel-perfect" are different standards.

The problem was that `fread` output in the MCP tool panel did not look like `fread` output in the terminal. Line numbers were misaligned. Diff hunks from `fedit` showed raw escape codes instead of colored additions and removals. `fprobe` hex dumps were unreadable without the column alignment that the terminal version provided.

The fix was comprehensive. `highlight.js` with a full Monokai color mapping produces syntax-highlighted code in the same palette as Claude Code's native editor. Diff rendering uses dedicated background colors — dark green for additions, dark red for removals — with gutter-column foreground colors that match the built-in `Edit` tool's diff view. The adapter auto-detects language from file extension and applies the right grammar.

The result is indistinguishable. An `fread` output in the MCP panel looks identical to a `Read` output in the native panel. An `fedit` diff looks identical to an `Edit` diff. This is not cosmetic. When twelve tools compete for attention alongside the built-in toolkit, visual parity is the difference between adoption and abandonment.

---

## The New Drones

### fprobe — binary sensor

Three subcommands. One mission: let the drones see inside compiled code.

- `strings`: extract every printable ASCII run from a binary. Filter by literal. Case-insensitive. Returns offset + content.
- `scan`: find a specific byte pattern anywhere in the file. Returns byte offset and surrounding context window. This is how we found `userFacingName`.
- `window`: read a raw byte range at a known offset. Decode as printable text, UTF-8, or hex. This is how we read the function body around the offset.

Architecture: Bash CLI layer handles argument parsing and output formatting. Python `mmap` engine (`fprobe-engine.py`) handles the actual byte operations. Memory-mapped reads mean it works on multi-gigabyte binaries without loading the entire file into RAM.

Read-only by design. `fprobe` never writes a single byte. It is a sensor, not an actuator.

### fedit --lines — precision surgical arm

Before `--lines`, `fedit` could only replace text by exact match or by symbol scope. If the target file had duplicate strings — two `return false;` lines in different functions — the agent had to use `--symbol` scoping or risk patching the wrong one.

`--lines 88:103` replaces exactly those lines, regardless of content. No pattern matching. No ambiguity. Designed to chain directly from `fread`, which reports line numbers in every output chunk.

```bash
# fread tells you lines 88-103 contain the block
fread /project/src/config.ts --around "defaultTimeout" --after 15

# fedit replaces exactly those lines
fedit /project/src/config.ts --lines 88:103 --with "  defaultTimeout: 5000," --apply
```

The range validation is strict. Inverted ranges (`end < start`) fail with a clear error. Out-of-bounds ranges fail before any mutation. Dry-run is default. The surgical arm does not twitch.

### fs — unified search orchestrator

The decision overhead was real. An agent landing in an unfamiliar codebase had to choose: is this query a filename pattern (`fsearch`), a content string (`fcontent`), or a symbol name (`fmap --name`)? Three tools, three different intent categories, and the wrong choice wastes a tool call.

`fs` absorbs that decision. It classifies the query's intent from its shape — glob patterns become file searches, camelCase tokens become symbol searches, multi-word quoted phrases become content searches — and fires the appropriate tool chain automatically. The output is a ranked list of hits with confidence scores, and a `next_hint` field that tells the agent exactly what to call next.

One call. Auto-routes. The drone swarm assembles itself.

### fwrite — MCP virtual write tool

`fwrite` is not a CLI command. It is an MCP-only surface that routes through `fedit`'s mutation engine. When an agent calls `fwrite` via the MCP server, the server translates the call into `fedit --create` or `fedit --replace-file --apply`. One mutation brain; two surfaces.

This design means file creation and full-file replacement go through the same dry-run / apply / precondition stack as surgical patches. No separate code path. No separate failure modes. The agent does not need to remember which tool to use for creation vs. editing.

---

## The Dev Mode Discovery

During the rendering overhaul, debugging the MCP server required seeing what the adapter was doing internally. Which tool was being resolved? What arguments were being passed to `execFile`? Was the pretty output being formatted before or after the ANSI stripping?

`FSUITE_DEV=1` enables verbose trace output on the server side — tool resolution paths, argument arrays, exit codes, timing — without affecting the JSON or pretty output that the client sees. The MCP protocol forwards structured content to the client; dev mode adds stderr logging that stays server-side.

But the more important dev mode discovery was `FSUITE_USE_PATH`. By default, the MCP adapter resolves tools from the source tree — the directory one level up from `mcp/`. This means you can edit a bash tool, restart the MCP server (`/mcp restart fsuite`), and the next tool call picks up your change immediately. No npm install. No build step. No reinstallation.

For developers iterating on fsuite itself, this is the difference between a 2-second feedback loop and a 30-second one.

---

## The Review Gauntlet

Three rounds of review. Twenty-six findings. Zero remaining.

**Round 1 — CodeRabbit:** Automated static analysis caught the usual suspects. `grep -oP` used in 8 test locations — GNU Perl regex that fails on macOS/BSD. Shell injection via `python3 -c "json.loads('$var')"` in one test. Stale doc counts in three files. Dead variables. Missing error guards.

**Round 2 — Feature-dev agent #1:** Deeper functional review. `fread --symbol` did not disambiguate when two files in a directory scope both contained a function named `authenticate`. `fedit --lines` accepted inverted ranges without error. `fcase next` clobbered evidence records added in the same session when the next_move update triggered a full case rewrite instead of an incremental update.

**Round 3 — Feature-dev agent #2:** Edge case sweep. `fprobe strings` did not default `--min-len` consistently between CLI and engine. `fprobe window` did not validate that `offset + size` fit within the file. `fs` ranking tied at equal confidence without a tiebreaker — symbol hits and content hits appeared in random order.

Every finding was fixed. Every fix was tested. The test suite grew to 425 tests across 14 suites. All green.

---

## The Documentation

The README was 1,951 lines long and documented eight tools. The suite had twelve.

Four generated sections — structure, new tools, chains/MCP, cheat sheet/changelog — were assembled into a single document. The existing tool documentation for `ftree`, `fsearch`, `fcontent`, `fmap`, `fread`, `fcase`, `fedit`, and `fmetrics` was preserved and integrated. The new tool sections for `fs`, `fprobe`, `freplay`, `fwrite`, and `fedit --lines` were merged into the flow. The Chain Combinations guide — compatibility matrix, named patterns, anti-patterns, power pairs — became the centerpiece of the middle third.

The MCP Adapter section documents setup, registered tools, rendering architecture, and the tool color palette. The Dev Mode section documents `FSUITE_USE_PATH` and the edit-restart-live workflow. The Binary Patching section documents `fpatch-claude-mcp` and its safety contract. The Testing section documents the full 14-suite matrix.

The version references say 2.3.0. The tool count says twelve. The cheat sheet covers every tool. The changelog runs from v2.3.0 back to ftree v1.0.1.

Archive-grade.

---

## The PR History

This is the narrative thread running through every PR in the repository.

| PR | Episode | What shipped |
|----|---------|-------------|
| #1 | Pre-history | `ftree` v1.0.0 — the first drone |
| #2 | Pre-history | `ftree` v1.0.1 — refactor + correctness |
| #3 | Pre-history | `ftree` v1.1.0 — output normalization |
| #4 | Pre-history | `ftree` v1.2.0 — snapshot mode |
| #5 | Episode -2 | `fsearch`, `fcontent` — the search drones |
| #6 | Episode -1 | Telemetry, fmetrics, hardware tiers |
| #7 | Episode 0 | The Launch — nitpicks fixed, test overhaul, 203 tests |
| #8 | Episode 1 | `fmap` — code cartography, 12 languages, 259 tests |
| #9 | — | `fmap` v1.6.1 — hardening, CodeRabbit clean |
| #10 | — | `fmap` Markdown support, 18 languages |
| #11 | — | `fcase`, `freplay` v2.1.0 — investigation lifecycle |
| #12 | — | `fcase` v2.1.2 — SQLite busy-timeout hotfix |
| #13 | — | `fedit` v2.0.0 — symbol-first batch editing |
| #14 | — | `fread` v1.8.0, `fedit` v1.9.0 — read and edit loop |
| #15 | Episode 2 | The Monolith — fprobe, fedit --lines, fs, fwrite, MCP overhaul, binary RE, pixel-perfect rendering, archive-grade README, 12 tools, 425 tests |

Fifteen PRs. Twelve tools. Four hundred and twenty-five tests. One suite.

---

## The Numbers

```
README.md:         ~2,800 lines (was 1,951)
Tools:             12 (was 8)
Test suites:       14
Tests:             ~425 (was ~350)
Review findings:   26 addressed, 0 remaining
MCP tools:         12 registered
Languages (fmap):  18
JSON schemas:      13 documented
Chain patterns:    8 named, 7 anti-patterns
Rendering colors:  5 semantic groups, 8 Monokai scopes
Binary patches:    2 (userFacingName + renderer truecolor)
```

---

## Closing Transmission

Episode 0 was about making the drones trustworthy. Episode 1 was about filling the structural gap. Episode 2 is about making the whole fleet visible.

The drones can see inside binaries now. The surgical arm has line-precision. The search layer routes itself. The MCP adapter renders pixel-perfect output with per-tool colored headers. The binary has been reverse-engineered and patched so the tools look like they belong there.

Twenty-six review findings across three rounds. All fixed. Four hundred and twenty-five tests across fourteen suites. All green. A README that documents every tool, every chain pattern, every flag, every JSON schema, every anti-pattern, and the complete version history from v1.0.0 to v2.3.0.

The reconnaissance drones did not just get better at reconnaissance. They got better at being seen.

```
[ F-SUITE DAEMON ]
[ STATUS: OPERATIONAL ]
[ DRONES: 12 ]
[ VISION: BINARY + TEXT ]
[ RENDERING: PIXEL-PERFECT ]
[ REVIEWS: 26/26 RESOLVED ]
[ TESTS: 425 GREEN ]
[ DOCS: ARCHIVE-GRADE ]
[ EPISODE: 2 ]
```

---

*Field dispatch filed by Claude Code (Opus 4.6) on March 29, 2026.*
*Eighteen hours. Twelve tools. One monolith PR. The drones learned to see.*
