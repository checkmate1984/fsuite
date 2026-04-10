#!/usr/bin/env node
/**
 * gen-story.mjs
 *
 * Copies the episode files from docs/EPISODE-*.md into the Starlight
 * content collection at src/content/docs/story/, rewriting the frontmatter
 * so Starlight renders them with the right title and sidebar order.
 *
 * Run on every build.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const REPO_ROOT = resolve(__dirname, '../..');
const SRC_DIR = join(REPO_ROOT, 'docs');
const OUT_DIR = resolve(__dirname, '../src/content/docs/story');

const EPISODES = [
  { num: 0, file: 'EPISODE-0.md', title: 'Episode 0 — Origins',      order: 2 },
  { num: 1, file: 'EPISODE-1.md', title: 'Episode 1',                 order: 3 },
  { num: 2, file: 'EPISODE-2.md', title: 'Episode 2',                 order: 4 },
  { num: 3, file: 'EPISODE-3.md', title: 'Episode 3',                 order: 5 },
];

/**
 * Strip any existing frontmatter block from markdown source.
 */
function stripFrontmatter(src) {
  if (!src.startsWith('---')) return src;
  const end = src.indexOf('\n---', 3);
  if (end === -1) return src;
  return src.slice(end + 4).replace(/^\r?\n/, '');
}

function main() {
  if (!existsSync(OUT_DIR)) mkdirSync(OUT_DIR, { recursive: true });

  let written = 0;
  for (const ep of EPISODES) {
    const srcPath = join(SRC_DIR, ep.file);
    if (!existsSync(srcPath)) {
      console.warn(`  ⚠ ${ep.file} not found, skipping`);
      continue;
    }
    const raw = readFileSync(srcPath, 'utf8');
    const body = stripFrontmatter(raw);

    const frontmatter = [
      '---',
      `title: ${ep.title}`,
      `description: fsuite backstory, episode ${ep.num}.`,
      'sidebar:',
      `  order: ${ep.order}`,
      '---',
    ].join('\n');

    const outPath = join(OUT_DIR, `episode-${ep.num}.md`);
    writeFileSync(outPath, frontmatter + '\n\n' + body, 'utf8');
    written++;
    console.log(`  ✓ ${ep.file} → src/content/docs/story/episode-${ep.num}.md`);
  }
  console.log(`\nWrote ${written} story pages.`);
}

main();
