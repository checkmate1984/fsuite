---
title: Installation
description: Install fsuite via the install script, the Debian package, or by cloning and symlinking.
sidebar:
  order: 1
---

## Quick install

The fastest path — clone, run the install script, done.

```bash
git clone https://github.com/lliWcWill/fsuite.git
cd fsuite
./install.sh
```

The installer copies all 14 tool binaries into `/usr/local/bin/` (or `~/.local/bin/` if you don't have sudo), and installs the shared runtime libraries alongside them.

## Debian / Ubuntu package

For Debian-based systems, there is a native `.deb` package.

```bash
# Download the latest release
# TODO: paste release URL when published
sudo apt install ./fsuite_*.deb
```

## Manual install (symlink from the repo)

If you want to hack on fsuite itself, keep the repo checked out and symlink the binaries into your `PATH`:

```bash
cd fsuite
for tool in fs ftree fls fsearch fcontent fmap fread fedit fwrite fbash fcase freplay fprobe fmetrics; do
  sudo ln -sf "$(pwd)/$tool" "/usr/local/bin/$tool"
done
```

## Verify the install

```bash
fsuite
# Should print the suite-level mental model and list all 14 tools

fs --help
ftree --help
```

## MCP adapter (optional)

If you want to expose fsuite tools to Claude Code or other MCP-aware agents, see the [MCP adapter page](/architecture/mcp/).

## Claude Code hook enforcement (optional)

If you want your Claude Code agents to be *forced* to use fsuite instead of their native `Read`, `Write`, `Edit`, `Grep`, and `Glob` tools, see the [hooks page](/architecture/hooks/).
