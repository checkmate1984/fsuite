---
title: 📖 fread
description: Budgeted reading with symbol + line-range resolution
sidebar:
  order: 7
---

## Budgeted reading with symbol + line-range resolution

`fread` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

<div class="fs-drone">
  <div class="fs-drone-head">
    <span class="fs-drone-call">fread</span>
    <span class="fs-drone-tagline">Budgeted reading · symbol &amp; line-range resolution · PDF + image media</span>
  </div>
  <div class="fs-drone-meta">
    <div><b>Role</b><span class="role-recon">READ</span></div>
    <div><b>Chain position</b><span>5 (read)</span></div>
    <div><b>Pipe</b><span>consumer (--from-stdin)</span></div>
    <div><b>Media</b><span>PDF · image · diff</span></div>
  </div>
</div>

`fread` is `cat` with a brain. It can read a whole file (uncapped by default — you control budget), an exact line range, the first N or last N lines, context windows around a literal pattern, or **one specific symbol resolved by name** in a file or directory.

It also reads media: PDF text extraction, PDF page rasterization, image base64 with auto-resize, and unified-diff hunks from git pipe. The token-budget flags (`--max-lines`, `--max-bytes`, `--token-budget`) cap output before it hits the agent's context.

## Canonical chains

```bash
# Read exactly one symbol — no scrolling, no guessing
fread /project/src/auth.py --symbol authenticate

# Resolve a symbol from a directory scope
fread /project/src --symbol authenticate -o json

# Precise line range
fread /project/src/server.py -r 120:220

# Context window around a pattern
fread /project/src/auth.py --around "def authenticate" -B 5 -A 20

# Pipe currency consumer — fsearch produces, fread consumes first 5
fsearch -o paths '*.py' /project \
  | fread --from-stdin --stdin-format=paths --max-files 5 -o json

# Read git diff context
git diff | fread --from-stdin --stdin-format=unified-diff -B 3 -A 10

# PDF and image reading
fread invoice.pdf
fread paper.pdf --render --pages 1:5
fread screenshot.png
```

## Terminal sample

<div class="fs-term">
  <div class="fs-term-bar"><b>fread(--around teleport)</b> · 66 lines · <span class="fs-term-cost">-829 tokens vs full read</span></div>
<pre><span class="tk-tool">fread</span>(/home/user/Projects/nightfox/src/discord/commands/teleport.ts | head: <span class="tk-num">80</span>)
  [ <span class="tk-num">66</span> lines | <span class="tk-warn">-829 tokens</span> ]
     <span class="tk-line">1</span>  <span class="tk-key">import</span> &#123; ChatInputCommandInteraction &#125; <span class="tk-key">from</span> <span class="tk-str">'discord.js'</span>;
     <span class="tk-line">2</span>  <span class="tk-key">import</span> &#123; discordChatId &#125; <span class="tk-key">from</span> <span class="tk-str">'../id-mapper.js'</span>;
     <span class="tk-line">3</span>  <span class="tk-key">import</span> &#123; sessionManager &#125; <span class="tk-key">from</span> <span class="tk-str">'../../claude/session-manager.js'</span>;
     <span class="tk-line">4</span>  <span class="tk-key">import</span> &#123; config &#125; <span class="tk-key">from</span> <span class="tk-str">'../../config.js'</span>;
     <span class="tk-line">5</span>  <span class="tk-key">import</span> path <span class="tk-key">from</span> <span class="tk-str">'path'</span>;
     <span class="tk-line">6</span>
     <span class="tk-line">7</span>  <span class="tk-key">export async function</span> <span class="tk-fn">handleTeleport</span>(interaction: ChatInputCommandInteraction): Promise&lt;<span class="tk-key">void</span>&gt; &#123;
     <span class="tk-line">8</span>     <span class="tk-key">const</span> chatId = <span class="tk-fn">discordChatId</span>(interaction.user.id);
     <span class="tk-line">9</span>
     <span class="tk-line">10</span> <span class="tk-com">// Try active in-memory session first, then fall back to most recent from history</span>
     <span class="tk-line">11</span> <span class="tk-key">let</span> session = sessionManager.<span class="tk-fn">getSession</span>(chatId);
     <span class="tk-line">12</span> <span class="tk-key">if</span> (!session) &#123;
     <span class="tk-line">13</span>    session = sessionManager.<span class="tk-fn">resumeLastSession</span>(chatId) ?? <span class="tk-key">undefined</span>;
     <span class="tk-line">14</span> &#125;
<span class="tk-mut">·</span></pre>
</div>

## Help output

The content below is the **live** `--help` output of `fread`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fread — budgeted file reading with line numbers, token estimates, and pipeline integration.

USAGE
  fread <file>                                   Read file (uncapped by default)
  fread <file> --symbol authenticate             Read one exact symbol block
  fread <dir> --symbol authenticate              Resolve one exact symbol within a directory scope
  fread <file> -r 120:220                        Line range
  fread <file> --head 50                         First N lines
  fread <file> --tail 30                         Last N lines
  fread <file> --around-line 150 -B 5 -A 10      Context around line
  fread <file> --around "pattern" -B 5 -A 10     Context around literal pattern
  fread --paths "~/.codex/auth.json,~/.config/codex/auth.json"   Try paths in order
  ... | fread --from-stdin --stdin-format=paths
  git diff | fread --from-stdin --stdin-format=unified-diff -B 3 -A 10

  fread <image>                                  Read image with auto-resize (PNG/JPEG/GIF/WEBP)
  fread <pdf>                                    Extract PDF text (default mode)
  fread <pdf> --render --pages 1:5               Rasterize PDF pages to images
  fread <pdf> --meta-only                        PDF metadata only

OPTIONS
  --paths P1,P2,...           Comma-separated file paths to try in order (first existing wins)
  -r, --lines START:END       Line range (1-based, inclusive)
  --head N                    Read first N lines
  --tail N                    Read last N lines
  --around-line N             Context around specific line number
  --around PATTERN            Context around first literal pattern match
  --all-matches               With --around: include all matches up to caps
  --symbol NAME               Read exactly one exact symbol match within file or directory scope
  -B, --before N              Lines before (default 5)
  -A, --after N               Lines after (default 10)
  --max-lines N               Cap total emitted lines (0/default = uncapped)
  --max-bytes N               Cap total emitted bytes (0/default = uncapped)
  --token-budget N            Cap by estimated tokens (conservative bytes/3)
  --no-truncate, --full       Disable line, byte, and token caps
  --max-files N               Cap files from stdin paths mode (default 10)
  --from-stdin                Read input from stdin
  --stdin-format FMT          Required with --from-stdin: paths|unified-diff
  --force-text                Read even if binary is detected
  -o, --output FMT            pretty (default), json, paths
  -q, --quiet                 Suppress pretty headers
  --project-name NAME         Override telemetry project name
  --self-check                Verify dependencies
  --install-hints             Print install commands
  --version                   Print version
  -h, --help                  Show help

MEDIA OPTIONS (image + PDF reading)
  --render                    PDF: render pages as images instead of extracting text
  --pages START:END           PDF: page range (1-based, inclusive)
  --meta-only                 Return metadata only (no body / base64)
  --no-resize                 Image: emit raw base64 without auto-resize
  --max-pages N               PDF render: raise 10-page cap
  --max-tokens N              Image: resize-loop token budget (default 6000)
  --no-ingest                 Skip ShieldCortex memory ingest for this read

NOTES
  Budget precedence: token_budget > max_bytes > max_lines
  --symbol is strict: exactly one exact symbol match succeeds; ambiguous or missing matches fail
  --stdin-format=unified-diff reads NEW-side hunk ranges from +++ path and @@ +start,count
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fread fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fread)
