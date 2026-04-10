---
title: 🔎 fsearch
description: File / glob discovery
sidebar:
  order: 4
---

## File / glob discovery

`fsearch` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

## Help output

The content below is the **live** `--help` output of `fsearch`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fsearch — fast filename/path search (glob patterns, extensions, agent-friendly)

USAGE
  fsearch [OPTIONS] <pattern_or_ext> [path]

QUICK EXAMPLES
  # Starts-with (glob)
  fsearch 'upscale*' /home/USER

  # Contains substring anywhere (use * on both sides)
  fsearch '*progress*' /var/log

  # Extension search (user can pass "log" or ".log")
  fsearch log /home/USER
  fsearch .log /home/USER

  # End-of-name (suffix)
  fsearch '*error' /var/log

  # Headless / agent-friendly output (paths only)
  fsearch --output paths '*.log' /var/log

  # JSON output (good for AI agents)
  fsearch --output json '*progress*' /home/USER

  # Prefer fd backend if available (faster than find)
  fsearch --backend fd '*.log' /

  # Narrow to config-like roots under HOME (e.g. ~/.config, ~/.local, top-level dotfiles)
  fsearch --config-only opencode.json ~

OPTIONS
  -p, --path PATH
      Search root. If omitted, uses current directory.

  -m, --max N
      Max number of results to print in pretty output. Default: 50
      (JSON output always includes the total count; still prints only up to --max results.)

  -I, --include PATTERN
      Keep only paths matching at least one include pattern.
      Can be repeated for broader selection.
      Pattern supports wildcard matching if it contains *, ?, or [ ].

  -x, --exclude PATTERN
      Exclude paths matching any pattern.
      Can be repeated for broader filtering.
      Pattern supports wildcard matching if it contains *, ?, or [ ].

  --no-default-ignore
      Disable built-in low-signal directory filtering.
      By default, fsearch suppresses dependency/build trees such as:
        node_modules, dist, build, .next, coverage, .git, vendor, target

  --config-only
      Narrow traversal to config-like roots under the requested path.
      Searches recursively in .config/ and .local/, plus top-level hidden
      files/directories at the root path. Intended for fast dotfile/config lookups.
      This preset currently uses a dedicated find-based traversal.

  -b, --backend auto|find|fd
      Choose search backend.
        auto: use fd if installed, else find
        fd:   use fd (fast). Requires fd to be installed
        find: use POSIX find

  --type file|dir|both
      Choose the search surface. Default: file
        file: legacy file-name search
        dir:  directory-oriented nav surface (v1 contract)
        both: file + directory surface

  --match name|path|both
      Choose what the query matches against. Default: name
        name: match file or directory names
        path: match full paths
        both: allow either name or path matching

  --mode auto|literal|glob|ext
      Control query normalization. Default: auto
        auto:    legacy heuristic in file/name mode only
        literal: use the query as-is
        glob:    treat the query as a glob pattern
        ext:     explicit extension mode placeholder

  --preview N
      Reserved shallow preview depth. Default: 0

  -o, --output pretty|paths|json
      pretty: human-friendly header + list (default)
      paths:  print only matching paths, one per line (best for piping/headless use)
      json:   print a compact JSON object (best for AI agents/tools)

  -q, --quiet
      Suppress header line in pretty mode. Useful for scripting.

  --project-name <name>
      Override project name in telemetry.

  -i, --interactive
      Force interactive prompts even if args were provided.

  --install-hints
      Print suggestions to install optional tools (fd, rg) and exit.
      (Does not install automatically; avoids storing credentials.)

  --self-check
      Checks availability of optional tools and prints guidance.
      If you intend to let the script invoke sudo-driven installs, authenticate first:
        sudo -v
      Then re-run with your preferred package installs manually.

  -h, --help
      Show help and exit.

NOTES ON PATTERNS (GLOBS)
  This tool searches FILE NAMES/PATHS (not file contents).
  Wildcards:
    *  matches any characters (including none)
    ?  matches exactly one character
  Common patterns:
    upscale*        "starts with upscale"
    *progress*      "contains progress anywhere"
    *.log           "ends with .log"
    *error          "ends with error"

  IMPORTANT: Quote patterns containing '*' or '?' so your shell doesn't expand them early:
    fsearch '*progress*' /some/path

EXTENSIONS
  Wildcards are preserved (e.g. *progress* or upscale*).
  If you pass:
    .log      -> treated as *.log
    file.txt  -> treated literally as file.txt
  If you pass a short lowercase token (<=4 chars, ^[a-z0-9]+$, not purely numeric):
    py    -> *.py
    main  -> *.main
  Numeric-only tokens are NOT treated as extensions:
    123   -> treated literally as 123

HEADLESS / AI AGENT USAGE
  This script is designed to be easy for an agent to call in "headless" mode:
    fsearch --output json '*token*' /path
  The agent can parse:
    - "total_found"       — number of matches found (lower bound when truncated)
    - "shown"             — number of results in the output
    - "truncated"         — boolean: were results capped at --max?
    - "count_mode"        — "exact" or "lower_bound" (is total_found exact?)
    - "has_more"          — boolean: are there more results beyond shown?
    - "results"           — array of file paths
    - "hits"              — array of objects with path, kind, matched_on, next_hint
    - "backend"           — search backend used (find or fd)
    - "pattern"           — original query
    - "name_glob"         — resolved glob pattern
    - "path"              — search root

  For simple piping (no JSON parsing), use:
    fsearch --output paths '*.log' /var/log | head

SECURITY / SUDO
  This script DOES NOT store passwords. Do not embed admin passwords in scripts.
  If you need privileged scanning or installs:
    1) Authenticate once for your session:
         sudo -v
    2) Run commands with sudo as needed (recommended):
         sudo fsearch '*.log' /var/log
  Or configure tightly scoped sudoers rules (advanced; do carefully).

OPTIONAL TOOLS
  - fd: faster filename search backend than find
  - rg (ripgrep): searches INSIDE file contents (different problem)
  To get install hints:
    fsearch --install-hints
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fsearch fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fsearch)
