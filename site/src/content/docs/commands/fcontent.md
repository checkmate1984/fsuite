---
title: 📄 fcontent
description: Bounded content search (token-capped ripgrep)
sidebar:
  order: 5
---

## Bounded content search (token-capped ripgrep)

`fcontent` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

## Help output

The content below is the **live** `--help` output of `fcontent`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fcontent — search inside files (uses ripgrep "rg"), agent-friendly

USAGE
  fcontent [OPTIONS] <query> [path]

MODES
  1) Directory mode:
     fcontent "needle" /some/dir
     - Searches recursively under /some/dir

  2) Piped file-list mode (best with fsearch):
     fsearch --output paths '*.log' /var/log | fcontent "ERROR"
     - Reads file paths from stdin and searches only those files

OPTIONS
  -p, --path PATH
      Directory to search (recursive). Default: current directory.
      Ignored if paths are provided via stdin.

  -o, --output pretty|paths|json
      pretty: human-readable summary + sample matches (default)
      paths:  print unique file paths that matched (one per line)
      json:   print compact JSON with match metadata (best for AI agents)

  -m, --max-matches N
      Limit number of printed matches in pretty/json output. Default: 200

  -n, --max-files N
      When reading from stdin, limit number of file paths consumed (safety). Default: 2000

  -q, --quiet
      Suppress header lines in pretty mode. Useful for scripting.

  --project-name <name>
      Override project name in telemetry.

  --rg-args "..."
      Extra arguments passed to rg (advanced).
      Example: --rg-args "-i --hidden"

  --no-default-ignore
      Disable built-in low-signal directory filtering in directory mode.
      By default, fcontent suppresses dependency/build trees such as:
        node_modules, dist, build, .next, coverage, .git, vendor, target

  --install-hints
      Print how to install rg and exit.

  --self-check
      Verify rg exists and show setup tips. Exit.

  -h, --help
      Show help and exit.

NOTES
  - This tool searches file CONTENTS, not filenames.
  - For filenames/paths, use fsearch.
  - Quote your query if it contains spaces:
      fcontent "fatal error" /path
  - If your literal query starts with '-', terminate options first:
      fcontent -o json -- '--test' /path

HEADLESS / AI AGENT USAGE
  Best outputs for agents:
    fcontent --output json "token" /path
    fcontent --output paths "ERROR" < <(fsearch --output paths '*.log' /path)

SECURITY / SUDO
  This tool does not store credentials.
  If you need to read protected files, run with sudo:
    sudo fcontent "needle" /var/log
  If installing packages, authenticate once first:
    sudo -v
```

## See also

- [fsuite mental model](/getting-started/mental-model/) — how fcontent fits into the toolchain
- [Cheat sheet](/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fcontent)
