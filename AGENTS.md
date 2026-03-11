# fsuite Agent Guide

Use `fsuite` for suite-level guidance first, then use the operational tools for filesystem reconnaissance before opening files blindly or spawning broad exploration loops.

## Mental Model

```text
fsuite -> ftree -> fsearch | fcontent -> fmap -> fread -> fcase -> fedit -> fmetrics
Guide     Scout    Narrowing             Bridge   Read     Preserve  Edit      Measure
```

## Headless Defaults

- Prefer `-o json` for programmatic decisions.
- Prefer `-o paths` when piping into another tool.
- Prefer `pretty` only for human terminal output.
- Results go to `stdout`. Errors go to `stderr`.
- Use `-q` for existence checks and silent control flow.

## Recommended Workflow

```bash
# 0) Load the suite-level guide once
fsuite

# 1) Scout once
ftree --snapshot -o json /project

# 2) Narrow to candidate files
fsearch -o paths '*.py' /project/src

# 3) Map structure before broad reads
fsearch -o paths '*.py' /project/src | fmap -o json

# 4) Read exact context
fread -o json /project/src/auth.py --around "def authenticate" -B 5 -A 20

# 5) Preserve investigation state once the seam is known
fcase init auth-seam --goal "Trace authenticate flow"
fcase next auth-seam --body "Review denial branch before patching"

# 6) Only if exact text confirmation is still needed
fsearch -o paths '*.py' /project/src | fcontent -o json "authenticate"

# 7) Measure and predict
fmetrics import
fmetrics stats -o json
fmetrics predict /project
```

## Workflow Discipline

- Run `fsuite` once if you need the suite-level mental model.
- Run `ftree` once to establish territory.
- Run one narrowing pass with `fsearch`.
- Prefer `fmap` and `fread` before broad `fcontent`.
- Use `fcase` once the seam is known and continuity becomes the bottleneck.
- Use `fcontent` as exact-text confirmation after narrowing, not as the first conceptual repo search.
- Do not rediscover the repo unless the target changes or a contradiction appears.

## Tool Selection

- Need project shape or likely hotspots: `ftree`
- Need candidate filenames: `fsearch`
- Need symbol skeleton without full reads: `fmap`
- Need exact text confirmation across already narrowed files: `fcontent`
- Need bounded file context: `fread`
- Need durable case state, evidence, or a handoff: `fcase`
- Need surgical edits with preview/apply: `fedit`
- Need runtime history or preflight cost: `fmetrics`

For detailed flags and examples, use each tool's `--help`.
