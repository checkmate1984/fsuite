# fsuite Chain Combination Guide

> Validated on 2026-03-29 via live pipe tests. All combinations tested end-to-end.

## The Pipe Contract

fsuite tools communicate via two pipe-friendly output modes:
- `-o paths` — one file path per line (the pipe currency)
- `-o json` — structured data for programmatic decisions

The pipe chain rule: **producers** output paths, **consumers** read paths from stdin.

## Producers (can output file paths)

| Tool | Flag | What it produces |
|------|------|-----------------|
| `fsearch` | `-o paths` | File paths matching a glob/name pattern |
| `fcontent` | `-o paths` | File paths containing a literal string |

## Consumers (can read file paths from stdin)

| Tool | Stdin behavior | Notes |
|------|---------------|-------|
| `fcontent` | Reads file paths, searches inside them | `stdin_files` mode (up to 2000 files) |
| `fmap` | Reads file paths, maps symbols in them | `stdin_files` mode (up to 2000 files) |

## Non-Pipe Tools (arg-based, not stdin-chainable)

| Tool | Why not | How to use instead |
|------|---------|-------------------|
| `fread` | Takes path as argument | Use after fmap to read specific lines |
| `fedit` | `--stdin` reads payload text, not file list | Use after fread to edit specific seams |
| `ftree` | Takes directory path as argument | Use first to scout, not in a pipe |
| `fprobe` | Takes binary file as argument | Standalone recon tool |
| `fcase` | Takes case slug as argument | Standalone continuity ledger |
| `freplay` | Takes case slug as argument | Standalone derivation tracker |
| `fmetrics` | Operates on telemetry database | Standalone analytics |

## Valid 2-Command Chains

| Chain | Purpose | Example |
|-------|---------|---------|
| `fsearch \| fcontent` | Find files by name, search inside them | `fsearch -o paths '*.py' src \| fcontent "def authenticate"` |
| `fsearch \| fmap` | Find files by name, map their symbols | `fsearch -o paths '*.rs' src \| fmap -o json` |
| `fcontent \| fmap` | Find files containing text, map symbols | `fcontent -o paths "TODO" src \| fmap -o json` |
| `fcontent \| fcontent` | Progressive narrowing | `fcontent -o paths "import" src \| fcontent "authenticate"` |

## Valid 3-Command Chains

| Chain | Purpose | Example |
|-------|---------|---------|
| `fsearch \| fcontent \| fmap` | Find .py files → search for "class" → map symbols | `fsearch -o paths '*.py' \| fcontent -o paths "class" \| fmap -o json` |
| `fsearch \| fcontent \| fcontent` | Triple narrowing | `fsearch -o paths '*.ts' \| fcontent -o paths "export" \| fcontent "async"` |

## Valid 4-Command Chains

| Chain | Purpose | Example |
|-------|---------|---------|
| `fsearch \| fcontent \| fmap \| json parse` | Full pipeline to structured data | `fsearch -o paths '*.sh' \| fcontent -o paths "function" \| fmap -o json \| python3 -c "..."` |

Tested: produced 1956 symbols from the fsuite repo in one pipeline.

## Invalid / Meaningless Chains

| Chain | Why it fails |
|-------|-------------|
| `fread \| anything` | fread outputs file content, not paths — breaks pipe contract |
| `fedit \| anything` | fedit outputs diffs, not paths |
| `ftree \| fcontent` | ftree outputs a tree visualization, not file paths |
| `fmap \| fread` | fmap outputs symbol data (JSON/pretty), not file paths |
| `fprobe \| anything` | fprobe outputs JSON/text, not file paths |
| `fcase \| anything` | fcase outputs investigation state, not file paths |

## MCP Equivalents

In MCP mode (via Claude Code/Codex), tools are called individually — no Unix pipes.
The agent constructs the equivalent chain by calling tools in sequence:

```
CLI pipe:     fsearch -o paths '*.py' | fcontent -o paths "def " | fmap -o json
MCP sequence: fsearch(query: "*.py") → fcontent(query: "def ", path: <from results>) → fmap(path: <from results>)
```

The MCP adapter handles `-o json` internally — agents always get structured JSON back.

## Investigation Patterns

### Pattern 1: "What uses this function?"
```bash
fcontent -o paths "authenticate" src | fmap -o json
# → files containing "authenticate" → their symbol maps
```

### Pattern 2: "Find all Python test files and see what they test"
```bash
fsearch -o paths 'test_*.py' tests | fmap -o json
# → test files → their function/class names
```

### Pattern 3: "Which config files mention this key?"
```bash
fsearch -o paths '*.json' . | fcontent "api_key"
# → JSON files → lines containing "api_key"
```

### Pattern 4: "Full investigation chain"
```bash
# Scout → narrow → map → read → preserve → edit
ftree --snapshot -o json /project
fsearch -o paths '*.rs' src | fcontent -o paths "pub fn" | fmap -o json
fread src/auth.rs --symbol authenticate
fcase init auth-fix --goal "Fix authenticate bypass"
fedit src/auth.rs --function authenticate --replace "return true" --with "return verify(token)"
fmetrics stats
```

### Pattern 5: "Binary recon"
```bash
fprobe scan binary --pattern "renderTool" --context 300
fprobe window binary --offset 112730723 --before 50 --after 200
fprobe strings binary --filter "diffAdded"
```
