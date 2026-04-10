# fsuite docs site

Starlight-powered knowledge base for fsuite. Self-hosted, static, dropped onto a VPS behind nginx.

## Stack

- [Astro](https://astro.build) — the framework
- [Starlight](https://starlight.astro.build) — the docs theme
- [Pagefind](https://pagefind.app) — built-in self-hosted search (ships with Starlight)
- Monokai Shiki theme — matches the color vibe of the fsuite MCP output

## Layout

```
site/
├── astro.config.mjs          # Starlight configuration (sidebar, theme, social links)
├── package.json              # npm scripts + deps
├── scripts/
│   ├── gen-commands.mjs      # Runs `./<tool> --help` for all 14 tools, writes src/content/docs/commands/*.md
│   └── gen-story.mjs         # Copies docs/EPISODE-*.md into src/content/docs/story/
├── src/
│   ├── assets/
│   │   └── fsuite-hero.jpeg  # Copied from ../docs/fsuite-hero.jpeg
│   ├── content.config.ts     # Starlight content collection schema
│   ├── content/docs/
│   │   ├── index.mdx                    # Landing (splash layout)
│   │   ├── getting-started/             # installation, mental-model, first-contact
│   │   ├── commands/                    # AUTO-GENERATED from --help (do not edit by hand)
│   │   ├── story/                       # lightbulb + episode-0..3 (episodes are auto-copied)
│   │   ├── architecture/                # mcp, hooks, telemetry, chains
│   │   └── reference/                   # cheatsheet, output-formats, changelog
│   └── styles/
│       └── custom.css                   # Monokai-adjacent accents on top of the Starlight theme
└── tsconfig.json
```

## Development

```bash
cd site
npm install
npm run dev              # Astro dev server with HMR at http://localhost:4321
```

## Build

```bash
npm run build            # Runs gen:commands, then `astro build`. Output in site/dist/
npm run preview          # Serve the built site locally
```

The `build` script automatically regenerates the command pages before the Astro build, so the live `--help` output is always in sync with the shipped tool binaries.

## Regenerating content

```bash
npm run gen:commands     # Writes src/content/docs/commands/*.md (14 files)
npm run gen:story        # Writes src/content/docs/story/episode-0.md … episode-3.md
```

Run these after changing any tool's `--help` output or any `docs/EPISODE-*.md` file.

## Deploy

The built output is pure static HTML/CSS/JS in `site/dist/`. To deploy to a VPS:

```bash
# On your dev machine
npm run build
rsync -avz --delete dist/ user@vps:/var/www/fsuite-docs/

# On the VPS (nginx example)
# /etc/nginx/sites-available/fsuite-docs
# server {
#   listen 443 ssl http2;
#   server_name docs.fsuite.ai;           # TODO: pick the real domain
#   root /var/www/fsuite-docs;
#   index index.html;
#   location / {
#     try_files $uri $uri/ $uri.html =404;
#   }
# }
```

> **Domain TBD:** candidates are `docs.fsuite.ai`, `fsuite.alignedintegrity.ai`, or a brand-new `fsuite.cli` style domain. Update `astro.config.mjs` (`site:` field) once chosen.

## Future work

- [ ] Auto-publish on every `git push` to master (GitHub Actions → rsync to VPS)
- [ ] Add versioned docs once the project hits v4.0
- [ ] ShieldCortex docs as a second content collection (multi-product path)
- [ ] Wire changelog page to `debian/changelog` or GitHub releases
- [ ] Add the `install-hooks.sh` script referenced in architecture/hooks.md
- [ ] Screenshots and GIFs for each chain in architecture/chains.md
- [ ] Refresh story/lightbulb.md with the canonical lightbulb-moment narrative
