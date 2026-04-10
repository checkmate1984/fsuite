---
title: 📋 fcase
description: Investigation continuity ledger
sidebar:
  order: 11
---

## Investigation continuity ledger

`fcase` is part of the fsuite toolkit — a set of fourteen CLI tools built for AI coding agents.

## Help output

The content below is the **live** `--help` output of `fcase`, captured at build time from the tool binary itself. It cannot drift from the source — regenerating the docs regenerates this section.

```text
fcase — continuity and handoff ledger for fsuite investigations

USAGE
  fcase --help
  fcase --version
  fcase init <slug> --goal ... [--priority ...] [-o pretty|json]
  fcase list [--status <csv|all>] [--include-shadow] [-o pretty|json]
  fcase status <slug> [-o pretty|json]
  fcase find <query> [--deep] [--status <csv|all>] [--include-shadow] [-o pretty|json]
  fcase note <slug> --body ...
  fcase next <slug> --body ... [-o pretty|json]
  fcase handoff <slug> [-o pretty|json]
  fcase export <slug> -o json
  fcase target add <slug> --path ... [--symbol ... --symbol-type ... --rank ... --reason ... --state ...]
  fcase target import <slug> [-o pretty|json] [--input <path|- >]
  fcase evidence <slug> --tool ... [--path ... --symbol ... --lines <start:end> --match-line ... --summary ...] (--body ... | --body-file <path>)
  fcase evidence import <slug> [-o pretty|json] [--input <path|- >]
  fcase hypothesis add <slug> --body ... [--confidence ...]
  fcase hypothesis set <slug> --id ... --status ... [--reason ... --confidence ...]
  fcase reject <slug> (--target-id <id> | --hypothesis-id <id>) [--reason ...]
  fcase resolve <slug> --summary ... [-o pretty|json]
  fcase archive <slug> [-o pretty|json]
  fcase delete <slug> --reason ... --confirm DELETE [-o pretty|json]

DESCRIPTION
  fcase preserves investigation state once the seam is known:
    init         Create a case and open a session
    list         Show cases (default: open only; shadow/session cases hidden unless --include-shadow)
    find         Search resolved/archived cases via FTS (--deep for full text; shadow/session cases hidden unless --include-shadow)
    status       Show current case state
    note         Append a note to a case
    next         Update the next best move
    handoff      Generate a concise handoff packet
    export       Export the full case envelope
    resolve      Mark case as resolved (requires --summary)
    archive      Archive a resolved case
    delete       Tombstone a case (requires --reason and --confirm DELETE)
    target import    Import structured targets from fmap JSON
    evidence import  Import structured evidence from fread JSON
```

## See also

- [fsuite mental model](/fsuite/getting-started/mental-model/) — how fcase fits into the toolchain
- [Cheat sheet](/fsuite/reference/cheatsheet/) — one-line recipes for every tool
- [View source on GitHub](https://github.com/lliWcWill/fsuite/blob/master/fcase)
