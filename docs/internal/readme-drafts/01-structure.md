# fsuite — STRUCTURAL section (v2.3.0)
<!-- Source section for README overhaul. Do not edit README.md directly. -->

---

## 1. Hero Header

<p align="center">
<img src="docs/fsuite-hero.jpeg" alt="fsuite - Filesystem Reconnaissance Drones" width="800">
</p>

<p align="center">
<em>Deploy the drones. Map the terrain. Return with intel.</em>
</p>

[![Release](https://img.shields.io/github/v/release/lliWcWill/fsuite?display_name=tag)](https://github.com/lliWcWill/fsuite/releases)
![Debian Package](https://img.shields.io/badge/deb-package%20available-A81D33)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![JSON Output](https://img.shields.io/badge/output-json-0A7EA4)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macOS-444)

---

**A suite-level guide plus twelve operational tools for filesystem reconnaissance, continuity, patching, replay, binary analysis, and analytics.**

`fsuite` provides one suite-level guide command plus twelve operational tools that turn filesystem exploration into a clean, scriptable, agent-friendly investigation workflow:

| Tool | Purpose |
|------|---------|
| **`fsuite`** | Print the suite-level conceptual flow, tool roles, and headless usage guidance |
| **`fs`** | Unified search entry point — classifies query intent and auto-routes to `fsearch`, `fcontent`, or `fmap` |
| **`ftree`** | Visualize directory structure with smart defaults and recon mode |
| **`fsearch`** | Find files by name, extension, or glob pattern |
| **`fcontent`** | Search _inside_ files for text (powered by ripgrep) |
| **`fmap`** | Extract structural skeleton from code (code cartography) |
| **`fread`** | Read files with budgets, ranges, context windows, and diff-aware input |
| **`fcase`** | Preserve investigation state, evidence, and handoffs once the seam is known |
| **`fedit`** | Apply surgical text patches with dry-run diffs, preconditions, and symbol scoping |
| **`fwrite`** | Write or overwrite files from agent output — MCP-native, safe atomic writes (MCP adapter only) |
| **`freplay`** | Deterministic replay of recorded investigation command sequences |
| **`fprobe`** | Binary and opaque-file reconnaissance — strings, scan, and byte-window reads |
| **`fmetrics`** | Analyze telemetry, history, and predicted runtime |

The first reconnaissance tools are the sensor layer. `fs` is the new unified entry point that accepts a raw query, classifies intent (path pattern, literal content, or structural symbol), and builds the right tool chain automatically — removing the decision overhead from the agent's first move. `fcase` is the continuity ledger. `fedit` is the surgical patch arm. `fwrite` is the safe write surface exposed through the MCP adapter. `freplay` is the investigation playback engine. `fprobe` is the binary sensor. `fmetrics` is the flight recorder and analyst. Together they cover **scout -> find/search -> map -> read -> preserve -> edit -> replay -> probe -> measure**. The `fsuite` command is the suite-level explainer that teaches that flow to humans and agents on first contact.

The flow an agent should internalize:

```text
fs → ftree → fsearch | fcontent → fmap → fread → fcase → fedit → freplay → fmetrics
                                                                ↑
                                                            fprobe (binary/opaque files)
```

`fs` auto-routes the opening move. `fprobe` branches off the main pipeline whenever the target is a compiled binary, packed asset, or SEA bundle. Everything else flows left to right.

Works with **Claude Code**, **Codex**, **OpenCode**, and any shell-capable agent harness that can call local binaries.

---

## 2. Install Table

| Install Path | Best For | Status |
|-------------|----------|--------|
| `./install.sh --user` | Fast local install without sudo | Recommended |
| Debian package | Linux release installs | Available |
| Source + manual symlink | Power users and repo hacking | Available |
| MCP adapter (`mcp/`) | Native tool calls in Claude Code / Codex / OpenCode — exposes all tools as first-class MCP calls | Available |
| Homebrew tap | macOS-native package install | Roadmap |
| npm wrapper | Installer/distribution wrapper, not a rewrite | Roadmap |

The MCP adapter (`mcp/index.js`) is a stateless Node.js dispatcher built on `@modelcontextprotocol/sdk`. It uses `execFile` — never `exec` — so arguments are array elements, not shell strings. Add it to your Claude Code or Codex harness config to make every fsuite tool show up as a native tool call alongside `Read`, `Edit`, and `Grep`.

---

## 3. Table of Contents

- [Why This Exists](#why-this-exists-the-lightbulb-moment)
- [Quick Start](#quick-start)
- [First-Contact Mindset](#first-contact-mindset)
- [fsuite Help](#fsuite-help)
- [Fast Paths](#fast-paths-copypaste)
- [Tools](#tools)
  - [fs — unified entry point](#fs--unified-entry-point)
  - [fsearch — filename / path search](#fsearch--filename--path-search)
  - [fcontent — file content search](#fcontent--file-content-search)
  - [ftree — directory structure visualization](#ftree--directory-structure-visualization)
  - [fmap — code cartography](#fmap--code-cartography)
  - [fread — budgeted file reading](#fread--budgeted-file-reading)
  - [fcase — continuity / handoff ledger](#fcase--continuity--handoff-ledger)
  - [fedit — surgical patching](#fedit--surgical-patching)
  - [fwrite — safe atomic writes (MCP adapter)](#fwrite--safe-atomic-writes-mcp-adapter)
  - [freplay — deterministic investigation replay](#freplay--deterministic-investigation-replay)
  - [fprobe — binary / opaque file reconnaissance](#fprobe--binary--opaque-file-reconnaissance)
  - [fmetrics — telemetry analytics](#fmetrics--telemetry-analytics)
- [MCP Adapter](#mcp-adapter)
- [Dev Mode](#dev-mode)
- [Chain Combinations](#chain-combinations)
- [Binary Patching](#binary-patching)
- [Output Formats](#output-formats)
- [Agent / Headless Usage](#agent--headless-usage)
- [Cheat Sheet](#cheat-sheet)
- [Quick Reference — Flags](#quick-reference--flags)
- [Optional Dependencies](#optional-dependencies)
- [Security Notes](#security-notes)
- [Installation](#installation)
- [Changelog](#changelog)
- [License](#license)

---

## 4. Why This Exists: The Lightbulb Moment

We shipped fsuite and thought it was done. Then we pointed Claude Code at the repo, told it to clone, study, and live-test the tools — and asked it to do a *Tony Stark autopsy*: compare fsuite against its own built-in toolkit and tell us honestly what it would change.

It didn't just say "nice tools." It wrote a full self-assessment. Unprompted conclusions. No instructions on what to find.

**The headline finding:**

> *"The gap isn't in any single tool. It's in the reconnaissance layer. I have no native way to answer the question: 'What is this project, how big is it, and where should I look first?'"*
>
> *"fsuite doesn't make any of my tools obsolete, but it fills the reconnaissance gap that is genuinely my weakest phase of operation. I'm good at reading code, editing code, and running commands. I'm bad at efficiently finding what to read in the first place. fsuite is built specifically for that phase, and built specifically for how I operate."*
>
> — Claude Code (Opus 4.5), self-assessment, January 2026

**What the agent said it would do:**

| Tool | Agent's Verdict |
|------|----------------|
| **ftree** | *"Net new capability. Nothing I have comes close."* — Replaces the Explore agent for structural recon. |
| **fsearch** | *"Augment. Use alongside Glob for discovery and pipeline scenarios."* — Pattern normalization + pipeline composability. |
| **fcontent** | *"Augment. Use for pipeline searches and scoped discovery."* — Piped mode + match caps designed for LLM context windows. |

That first round exposed the real missing step: after recon and search, the agent still had to spend extra calls just to read the right slice of a file. `fmap` and `fread` close that gap. `fcase` preserves the investigation once the seam is known. `fedit` turns that bounded context into a safe patch surface. `fmetrics` closes the final loop by turning live usage into operational feedback instead of guesswork.

Since v2.2.0, the fleet has expanded further. `fprobe` extends the sensor layer into binary and opaque files — compiled Node.js SEA bundles, packed assets, anything `fread` can't reach. `freplay` makes recorded investigation sequences deterministically reproducible across agents and sessions. `fs` removes the opening routing decision entirely: give it a raw query and it classifies intent, builds the chain, and returns ranked results without the agent choosing between `fsearch`, `fcontent`, and `fmap` on the first move.

**The workflow shift — before and after:**

```text
BEFORE fsuite:
Spawn Explore agent -> 10-15 internal tool calls -> still blind on structure

AFTER fsuite (v2.3.0):
fs <query> /project  ->  ftree --snapshot -o json  ->  fmap -o json  ->  fread -o json
->  fcase init <seam> --goal "..."  ->  fedit -o json  ->  freplay  ->  fmetrics stats
7-9 calls. Structural context, bounded reads, durable continuity, previewable edits,
replay verification, and runtime measurement. Dramatically fewer invocations.
Binary targets? Add fprobe strings / fprobe scan to the branch.
```

And once those reads are happening in the real world:

```text
AFTER execution:
... -> fcontent -o json (only if exact text confirmation is needed)
    -> fcase handoff <seam> -o json
    -> fedit -o json
    -> freplay --verify
    -> fmetrics import -> fmetrics stats / predict
Search inside the narrowed set, preserve what matters, patch surgically,
verify the replay, then measure what actually happened and plan the next pass.
```

> **Proof callout — Nightfox investigation:** In a live Nightfox runtime incident, the breakthrough came when the operator coached the agent to stop overcompensating and trust fsuite's direct contracts. The useful path was not a sacred sequence. It was a clean combination of `fsearch`, `fmap`, `fread`, and targeted `fcontent` that surfaced a real subprocess-lifecycle bug. The milestone was not just that the tools worked. It was that the agent stopped fighting them.

The full unedited analysis is in **[AGENT-ANALYSIS.md](AGENT-ANALYSIS.md)** — the raw self-assessment, exactly as Claude Code wrote it after studying and testing every tool in this repo.

That document is the pitch. Not because we wrote it, but because the agent did.
