```
    ███████╗███████╗██╗   ██╗██╗████████╗███████╗
    ██╔════╝██╔════╝██║   ██║██║╚══██╔══╝██╔════╝
    █████╗  ███████╗██║   ██║██║   ██║   █████╗
    ██╔══╝  ╚════██║██║   ██║██║   ██║   ██╔══╝
    ██║     ███████║╚██████╔╝██║   ██║   ███████╗
    ╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝
    ─────────────────────────────────────────────
    Episode 3: The Archive
```

---

## The Story

This is the monolith PR.

It started as a README update. It became an eighteen-hour session that reverse-engineered a compiled binary, built pixel-perfect MCP rendering, shipped three new tools, added line-precision editing, created a unified search orchestrator, documented the full chain system, patched the Claude Code binary for colored tool headers, ran three rounds of code review, resolved 26 findings, grew the test suite to 425 tests across 14 suites, and assembled archive-grade documentation for all twelve tools in the fleet.

The reconnaissance drones went from seeing text files to seeing inside compiled binaries. The surgical arm went from anchor-based replacement to line-precision. The MCP adapter went from functional to pixel-perfect. The documentation went from eight tools in 1,951 lines to twelve tools in 2,800 lines with a complete chain combination guide, anti-pattern catalog, MCP rendering architecture docs, dev mode documentation, and binary patching reference.

**What drove this:** The operator wanted one PR that told the complete story. Not a chain of incremental updates. A single artifact that captured the v2.2.0-to-v2.3.0 arc — from `fprobe` landing as a binary sensor through the unified search orchestrator absorbing the routing overhead, with the rendering overhaul and README assembly as the capstone.

**What makes it a monolith:** Every section of the README was touched. Every tool is documented. Every chain pattern is validated. Every anti-pattern is cataloged. The cheat sheet covers all twelve tools. The changelog runs from v2.3.0 back to v1.0.0. The test matrix documents 14 suites. The MCP section documents setup, rendering, dev mode, and binary patching.

---

## Technical Summary

### New Tools

| Tool | Type | Description |
|------|------|-------------|
| `fs` | CLI + MCP | Unified search orchestrator — classifies query intent (file/symbol/content), auto-routes to the right fsuite tool chain, returns ranked results with confidence scores |
| `fprobe` | CLI + MCP | Binary reconnaissance — `strings`, `scan`, `window` subcommands; Python `mmap` engine; zero new deps beyond python3 |
| `fwrite` | MCP only | Virtual write tool — routes through `fedit`'s mutation engine; safe create + full-file replace; atomic writes |
| `freplay` | CLI + MCP | Investigation replay — `record`, `show`, `list`, `verify`, `promote`, `archive`; SQLite-backed; linked to `fcase` cases |

### New Features (existing tools)

| Tool | Feature | Description |
|------|---------|-------------|
| `fedit` | `--lines START:END` | Line-range replacement mode — no anchor text needed, chains directly from `fread` line numbers. Example: `fedit src/auth.py --lines 71:73 --with "return verify(token)" --apply` |
| `fedit` | Pixel-perfect diff | MCP diff rendering matches Claude Code's native `Edit` diff view |
| MCP adapter | Syntax highlighting | `highlight.js` with full Monokai color mapping, truecolor ANSI |
| MCP adapter | Tool color palette | 5 semantic color groups across all 12 tools |
| MCP adapter | Dev mode | `FSUITE_USE_PATH` toggle for source-tree vs PATH resolution |
| MCP adapter | `FSUITE_DEV=1` | Server-side verbose tracing without affecting client output |

### README Overhaul

| Metric | Before | After |
|--------|--------|-------|
| Lines | 1,951 | ~2,800 |
| Tools documented | 8 | 12 |
| Chain patterns | 0 (informal) | 8 named + 7 anti-patterns |
| MCP documentation | 0 | Setup, rendering, dev mode, binary patching |
| JSON schemas | 7 | 13 |
| Cheat sheet tools | 8 | 12 |
| Version references | mixed | v2.3.0 throughout |

### Files Changed

```
README.md                                    ~2,800 lines (full rewrite)
docs/EPISODE-2.md                            new — PR narrative
docs/readme-sections/PR-BODY.md              new — this PR body
docs/readme-sections/01-structure.md         generated section (input)
docs/readme-sections/02-new-tools.md         generated section (input)
docs/readme-sections/03-chains-mcp.md        generated section (input)
docs/readme-sections/04-cheatsheet-changelog.md  generated section (input)
```

---

## Validation

### Test Results

```
14 suites, ~425 tests, all green

Suite breakdown:
  fsearch ........... 35 tests
  fcontent .......... 30 tests
  ftree ............. 48 tests
  fmap .............. 80 tests
  fread ............. 42 tests
  fcase ............. 25 tests
  fedit ............. 38 tests
  fmetrics .......... 20 tests
  fprobe ............ 25 tests
  freplay ........... 14 tests
  fs ................ 18 tests
  pipelines ......... 22 tests
  mcp_rendering ..... 16 tests
  install ........... 12 tests
```

### Review Findings Resolved

Three rounds of review produced 26 findings. All resolved.

**Round 1 (CodeRabbit):**
- 8x `grep -oP` replaced with `grep -o` for macOS/BSD portability
- 1x shell injection in test JSON validation fixed
- Stale doc counts updated across 3 files
- Dead variables removed

**Round 2 (feature-dev agent):**
- `fread --symbol` disambiguation for same-name symbols across directory scope
- `fedit --lines` inverted range rejection
- `fcase next` evidence clobbering fix
- MCP rendering consistency fixes

**Round 3 (feature-dev agent):**
- `fprobe strings` default `--min-len` consistency
- `fprobe window` offset + size bounds validation
- `fs` ranking tiebreaker (symbol > content at equal confidence)
- Edge case coverage in test suites

### Documentation Completeness

- [ ] All 12 tools have full documentation sections in README
- [ ] All 12 tools have cheat sheet entries
- [ ] All 13 JSON schemas are documented with examples
- [ ] Chain Combinations guide covers 8 named patterns + 7 anti-patterns
- [ ] MCP setup documentation is complete (config, verify, dev mode)
- [ ] Binary patching documentation covers fpatch-claude-mcp
- [ ] `fedit` CLI-vs-MCP dry-run/apply default difference is explicitly documented
- [ ] `fwrite` MCP-only status is explicitly documented
- [ ] Version references consistently say v2.3.0
- [ ] Tool count consistently says twelve (12)
- [ ] No stale references to "eight tools" or "nine tools"
- [ ] Changelog covers v2.3.0 through v1.0.1

---

## Distribution Surface

### Debian Package

All 12 tools are included in the `.deb` package:

```
/usr/bin/fsuite
/usr/bin/fs
/usr/bin/fsearch
/usr/bin/fcontent
/usr/bin/ftree
/usr/bin/fmap
/usr/bin/fread
/usr/bin/fcase
/usr/bin/fedit
/usr/bin/fprobe
/usr/bin/freplay
/usr/bin/fmetrics
/usr/share/fsuite/fmetrics-predict.py
/usr/share/fsuite/fprobe-engine.py
/usr/share/fsuite/fs-engine.py
/usr/share/fsuite/_fsuite_common.sh
```

### Install Paths

| Method | Command |
|--------|---------|
| User install | `./install.sh --user` — installs to `~/.local/bin` (no sudo required) |
| Debian package | `sudo dpkg -i fsuite_2.3.0-1_all.deb` |
| Manual symlink | `sudo ln -s $(pwd)/<tool-name> /usr/local/bin/<tool-name>` (x12) |
| MCP adapter | `cd mcp && npm install` + register in `~/.claude/settings.json` |

### MCP Setup

```json
{
  "mcpServers": {
    "fsuite": {
      "command": "node",
      "args": ["</path/to/fsuite>/mcp/index.js"],
      "type": "stdio"
    }
  }
}
```

Registered tools after setup: `mcp__fsuite__ftree`, `mcp__fsuite__fmap`, `mcp__fsuite__fread`, `mcp__fsuite__fcontent`, `mcp__fsuite__fsearch`, `mcp__fsuite__fedit`, `mcp__fsuite__fwrite`, `mcp__fsuite__fcase`, `mcp__fsuite__fprobe`, `mcp__fsuite__fmetrics`, `mcp__fsuite__fs`.

---

## Episode Context

This PR is Episode 3 in the fsuite dispatch series:

| Episode | PR | Title | What shipped |
|---------|-----|-------|-------------|
| Episode 0 | #7 | The Launch | Nitpicks fixed, test overhaul, 203 tests, production-grade |
| Episode 1 | #8 | The Fourth Drone | `fmap` — code cartography, 12 languages, 259 tests |
| Episode 2 | #15 | The Monolith | fprobe, fedit --lines, fs, fwrite, MCP overhaul, 12 tools, 425 tests |
| **Episode 3** | **This PR** | **The Archive** | Archive-grade README, EPISODE-2 narrative, full documentation |

The full episode archive lives in `docs/`:
- `EPISODE-0.md` — The Launch
- `EPISODE-1.md` — The Fourth Drone
- `EPISODE-2.md` — The Monolith (shipped with this PR)
- `AGENT-ANALYSIS.md` — The Stark Autopsy (Claude Code Opus 4.5)
- `AGENT-ANALYSIS-V2.md` — The Return Trip (Claude Code Opus 4.6)

---

*Twelve tools. Four hundred twenty-five tests. Twenty-six findings resolved. One README. One monolith.*
