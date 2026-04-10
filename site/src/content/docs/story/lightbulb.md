---
title: The Lightbulb Moment
description: Why fsuite exists. The real origin story, including the detours, the recursion problem, and the Monokai aesthetic TODO.
sidebar:
  order: 1
---

> **This page is a placeholder.** The canonical lightbulb-moment refresh is being written as the last step of the docs overhaul and will replace this stub shortly.

## The short version

fsuite was always supposed to be **CLI-first**. The MCP server came later. Hooks came later. The whole thing is still catching up to the lightbulb moment that probably should have come first.

## Placeholder framing

1. **Built the fsuite CLI tools** — the core idea
2. **Built the MCP server** — so agents wouldn't have to pipe through their native `Bash` tool
3. **Built `fbash`** — so agents wouldn't need the `Bash` tool *at all*
4. **Discovered Claude Code hooks** — and realized hooks could enforce fsuite usage without needing the MCP at all
5. **Tried to rely on hooks alone** — couldn't. Hooks block native tools but don't route calls. Defaulted back to MCP for the easy path.

## The recursion problem

If you removed the MCP, an agent would have to use its native `Bash` tool to call `fbash` to call `fread`. That's two hops and defeats the point of "use fsuite instead of Bash." The honest truth: without the MCP, the agent would just use its `Bash` tool to call `fread` directly — which still works, but loses the Monokai-colored structured output.

## Monokai TODO

The MCP's Monokai color scheme is the best-looking part of the stack. **It should be on the CLI tools too.** That's a real TODO.

> Full refresh pending — see [Episode 0](/story/episode-0/) for the original framing.
