# Symbol Ergonomics Design

**Date:** 2026-03-09

## Goal

Add the next narrow workflow seam after trust hardening:

- `fmap --name <symbol>`
- `fread --symbol <name>`

This patch is limited to symbol ergonomics. It does not start `fcase`, fuzzy matching, or a shared symbol subsystem rewrite.

## Positioning

The current sprint order remains:

1. `fmetrics` trust hardening
2. symbol ergonomics in `fmap` and `fread`
3. `fcase` after the trust and ergonomics sprint lands

This patch covers step 2 only.

## Recommended Shape

Use a narrow overlay on existing symbol data.

### Why this shape

- smallest patch
- lowest contract risk
- deterministic behavior
- no drift into fuzzy search or orchestration

Rejected alternatives:

- shared symbol subsystem refactor first
- broader search-style symbol lookup
- fuzzy or semantic matching

## `fmap --name <symbol>`

### Behavior

- extraction logic stays unchanged
- matching runs only over extracted symbol names
- v1 matching is case-sensitive
- exact match means `symbol == query`
- substring match means `query` is contained in `symbol`
- no fuzzy matching
- no normalization
- no repo-wide magic beyond the existing mapping scope

### Interaction with `-t`

When `--name` and `-t` are both present:

1. extract normally
2. rank symbol-name matches
3. apply `-t` as a `symbol_type` filter over matched results
4. apply final deterministic ordering

### Ranking

- exact matches first
- substring matches second
- ties broken by:
  - `path`
  - `line_start`
  - `symbol_type`

### Output contract

Keep the existing top-level envelope and existing `files[*].symbols[*]` schema unchanged.

When `--name` is active, add:

- `query`
- `matches`

Each match should include:

- `path`
- `symbol`
- `symbol_type`
- `line_start`
- `line_end`
- `match_kind`
- `rank`

### Count semantics with `--name`

- `total_symbols` = total extracted symbols before name filtering
- `shown_symbols` = number of returned symbols after `--name` and `-t` filtering
- `matches` = ranked matched symbols

When `--name` is active, `files` may be filtered down to matched files and matched symbols only.

### Line metadata

- `line_start` should always be present
- `line_end` may be `null`
- populate `line_end` only when block boundary is cheap to derive
- never invent fake end lines

### Empty-result behavior

`fmap --name foo` with no matches:

- pretty: clear no-symbol-matches style output
- json: valid envelope with `query`, `matches=[]`, `shown_symbols=0`, and filtered or empty `files`
- paths: print nothing
- exit code stays aligned with current non-error empty-result behavior

## `fread --symbol <name>`

### Behavior

- resolves through symbol-aware lookup, not broad text grep
- strict v1 behavior
- if target is a file, resolve only within that file
- if target is a directory, resolve only within that directory mapping scope

Strong hit in v1 means:

- exactly one exact extracted-name match

Substring matches never auto-resolve in v1.

### Success / failure rules

- exactly one exact match -> read that symbol directly
- multiple exact matches -> fail with `error_code=symbol_ambiguous`
- zero exact matches -> fail with `error_code=symbol_not_found`

On ambiguity failure, include deterministic candidates using the same ordering as `fmap`.

### Optional `--symbol-type`

If it falls out nearly free, add:

- `--symbol-type <type>`

But only as a post-name exact-match disambiguator. It is not a new search mode and it must not enable fuzzy fallback behavior.

### Output contract

On success:

- preserve the existing bounded-read envelope
- add `symbol_resolution` with:
  - `query`
  - `symbol`
  - `symbol_type`
  - `path`
  - `line_start`
  - optional `line_end`

On ambiguity failure:

- include a structured `candidates` array with:
  - `path`
  - `symbol`
  - `symbol_type`
  - `line_start`
  - optional `line_end`

## Reuse philosophy

Use the same symbol-name extraction philosophy as `fedit`, but do not stop to build a shared resolver first.

If a tiny shared helper falls out almost free, that is acceptable. Otherwise keep the coupling local to this patch.

## Testing Strategy

### `tests/test_fmap.sh`

Add red tests for:

- exact hit returns `matches[0]` with `match_kind=exact`
- exact/substring ordering is deterministic
- `-t` filters matched results after name matching
- counts stay honest
- no-match `-o paths` output is empty and non-error

### `tests/test_fread.sh`

Add red tests for:

- exact single symbol resolves and reads the correct chunk
- ambiguous exact symbol fails with `symbol_ambiguous` and deterministic candidates
- missing exact symbol fails with `symbol_not_found`
- directory target scope works
- file target scope stays file-local
- if `--symbol-type` lands, one focused disambiguation test

## Non-goals

- fuzzy matching
- case folding
- substring fallback in `fread`
- interactive selection
- orchestration
- `fcase`
- symbol subsystem rewrite

## Recommendation

Ship `fmap --name` and `fread --symbol` as a tight deterministic seam. The patch should read as symbol ergonomics only.
