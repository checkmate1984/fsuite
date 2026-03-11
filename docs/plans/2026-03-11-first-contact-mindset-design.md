# First-Contact Mindset Design

**Date:** 2026-03-11

## Goal

Refresh fsuite's first-contact documentation so agents learn the right mindset immediately:

- fsuite is a composable sensor suite, not a single sacred workflow
- there are stronger and weaker combinations, but no one true path
- literal search is a strength here, not a fallback
- agents should stop overcompensating for weak default tool contracts

## Shape

Apply a blended product-facing update:

1. Add a durable `First-Contact Mindset` / `Tool-Native Reasoning` section to the README
2. Add one short proof callout from the Nightfox investigation to show the milestone in practice
3. Update the `fsuite` command output so the same guidance appears at first contact, not only in docs

## Content Priorities

The update should emphasize:

- `-o json` and `-o paths` as default agent surfaces
- `fmap` as a bridge in the middle of the pipeline, not just a producer before `fread`
- strong narrowing combinations such as:
  - `fsearch -> fmap`
  - `fcontent -o paths -> fmap`
  - `fsearch -> fcontent -o paths -> fmap`
- `fmap + fread` as the power pair for understanding code
- `ftree` as powerful but intentional, especially on large repos
- `fedit` only after inspected context
- `fmetrics` for observability, not a reason to spam recon

## Scope

This patch is documentation and guide-output only:

- `README.md`
- `fsuite`
- focused test update for the `fsuite` command output

## Non-Goals

- no full README tone rewrite
- no behavioral changes to operational tools
- no new subcommands or CLI flags
