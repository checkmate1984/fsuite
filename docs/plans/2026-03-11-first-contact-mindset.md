# First-Contact Mindset Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update fsuite's README and first-contact CLI guide so agents learn the composable workflow mindset immediately.

**Architecture:** Keep the change narrow and durable. Add a concise mindset section plus one Nightfox proof callout in `README.md`, then mirror the same guidance in `fsuite` output. Use the existing install/help test as the regression surface for the CLI wording.

**Tech Stack:** Bash help text, Markdown docs, shell test harness

---

### Task 1: Add a Red Test For First-Contact Guidance

**Files:**
- Modify: `tests/test_install.sh`

**Step 1: Write the failing test**

Extend `test_fsuite_help_explains_flow` so it also checks for one or two stable mindset phrases, such as:

- `Composable sensor suite`
- `Literal search is a strength here, not a fallback`

**Step 2: Run test to verify it fails**

Run:

```bash
bash tests/test_install.sh
```

Expected: FAIL because the current `fsuite` help does not include the new first-contact framing.

### Task 2: Update `fsuite` First-Contact Output

**Files:**
- Modify: `fsuite`

Add a short first-contact mindset section that covers:

- composable sensor suite framing
- stronger vs weaker combinations without a single sacred path
- aggressive `-o json` / `-o paths` use
- `fmap` as bridge
- `fmap + fread` as the power pair
- literal search as a strength
- intentional `ftree` use
- `fedit` after inspection
- `fmetrics` for observability

### Task 3: Update README With Durable Framing + Proof Callout

**Files:**
- Modify: `README.md`

Add:

- a durable `First-Contact Mindset` or `Tool-Native Reasoning` section
- one short Nightfox case-study proof callout
- updated workflow language in the existing fsuite guidance and `fcontent` section as needed

### Task 4: Verify

Run:

```bash
bash tests/test_install.sh
./fsuite
```

Expected: tests pass and the first-contact `fsuite` output clearly reflects the new mindset.
