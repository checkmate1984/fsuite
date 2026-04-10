#!/usr/bin/env node
/**
 * gen-commands.mjs
 *
 * Runs each fsuite tool with `--help`, captures output, and writes one Markdown
 * page per tool into src/content/docs/commands/.
 *
 * Re-run on every build. Source of truth is the CLI binaries themselves, so
 * the docs site cannot drift from the real help text.
 */

import { execSync } from 'node:child_process';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Resolve the fsuite repo root (one level up from site/)
const REPO_ROOT = resolve(__dirname, '../..');
const OUT_DIR = resolve(__dirname, '../src/content/docs/commands');

// Per-tool metadata: sidebar title, emoji, one-liner description
const TOOLS = [
  { name: 'fs',       order: 1,  emoji: '🔀', title: 'fs',       tagline: 'Universal search orchestrator — auto-routes to the right fsuite tool' },
  { name: 'ftree',    order: 2,  emoji: '🌲', title: 'ftree',    tagline: 'Territory scout — full tree + recon data in one call' },
  { name: 'fls',      order: 3,  emoji: '📂', title: 'fls',      tagline: 'Structured directory listing with recon mode' },
  { name: 'fsearch',  order: 4,  emoji: '🔎', title: 'fsearch',  tagline: 'File / glob discovery' },
  { name: 'fcontent', order: 5,  emoji: '📄', title: 'fcontent', tagline: 'Bounded content search (token-capped ripgrep)' },
  { name: 'fmap',     order: 6,  emoji: '🗺️', title: 'fmap',     tagline: 'Symbol cartography — functions, classes, imports, constants' },
  { name: 'fread',    order: 7,  emoji: '📖', title: 'fread',    tagline: 'Budgeted reading with symbol + line-range resolution' },
  { name: 'fedit',    order: 8,  emoji: '✂️', title: 'fedit',    tagline: 'Surgical editing — line-range, symbol-scoped, or anchor-based' },
  { name: 'fwrite',   order: 9,  emoji: '📝', title: 'fwrite',   tagline: 'Atomic file creation' },
  { name: 'fbash',    order: 10, emoji: '💻', title: 'fbash',    tagline: 'Token-budgeted shell execution with classification and session state' },
  { name: 'fcase',    order: 11, emoji: '📋', title: 'fcase',    tagline: 'Investigation continuity ledger' },
  { name: 'freplay',  order: 12, emoji: '⏪', title: 'freplay',  tagline: 'Derivation chain replay — rerun a traced investigation' },
  { name: 'fprobe',   order: 13, emoji: '🔬', title: 'fprobe',   tagline: 'Binary / bundle inspection + patching' },
  { name: 'fmetrics', order: 14, emoji: '📊', title: 'fmetrics', tagline: 'Telemetry analytics + tool-chain prediction' },
];

/**
 * Run `./toolname --help` from the repo root and return stdout.
 * Some tools write help to stderr, so we merge both streams.
 */
function captureHelp(toolName) {
  const toolPath = join(REPO_ROOT, toolName);
  if (!existsSync(toolPath)) {
    return `_Tool binary not found at \`${toolPath}\`._`;
  }
  try {
    const out = execSync(`"${toolPath}" --help 2>&1`, {
      cwd: REPO_ROOT,
      encoding: 'utf8',
      timeout: 10_000,
      maxBuffer: 1024 * 1024,
    });
    return out.trim();
  } catch (err) {
    // Some tools exit non-zero on --help; stdout is still captured on err.stdout
    if (err.stdout) return err.stdout.toString().trim();
    return `_Error capturing help: ${err.message}_`;
  }
}

/**
 * Build a markdown page for one tool.
 */
function buildPage(tool) {
  const helpText = captureHelp(tool.name);
  const frontmatter = [
    '---',
    `title: ${tool.emoji} ${tool.title}`,
    `description: ${tool.tagline}`,
    `sidebar:`,
    `  order: ${tool.order}`,
    '---',
  ].join('\n');

  const body = `
## ${tool.tagline}

\`${tool.name}\` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

## Help output

The content below is the **live** \`--help\` output of \`${tool.name}\`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

\`\`\`text
${helpText}
\`\`\`

## See also

- [fsuite mental model](/getting-started/mental-model/) — how ${tool.name} fits into the toolchain
- [Cheat sheet](/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/${tool.name})
`;

  return frontmatter + '\n' + body;
}

/**
 * Entry point.
 */
function main() {
  if (!existsSync(OUT_DIR)) {
    mkdirSync(OUT_DIR, { recursive: true });
  }

  let written = 0;
  for (const tool of TOOLS) {
    const page = buildPage(tool);
    const outPath = join(OUT_DIR, `${tool.name}.md`);
    writeFileSync(outPath, page, 'utf8');
    written++;
    console.log(`  ✓ ${tool.name.padEnd(10)} → src/content/docs/commands/${tool.name}.md`);
  }
  console.log(`\nWrote ${written} command pages.`);
}

main();
