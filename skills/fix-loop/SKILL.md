---
name: fix-loop
description: Addresses code review findings using TDD. Auto-applies safe_auto fixes, presents gated_auto and manual findings for human triage, executes approved fixes, re-runs bounded code review. Repeats until clean or cap reached.
---

# Fix Loop (Phase 5.5)

Process code review findings systematically: auto-fix what's safe, get human approval for the rest, apply fixes with TDD discipline, and re-review to confirm.

## Prerequisites

- `05-code-review.md` MUST exist in the active spec directory with structured findings.
- All findings must have been processed through the confidence gating and dedup pipeline (Phase 5.4 of code-review skill).

## Process

### Step 1 — Parse Findings

Read `05-code-review.md` and parse all findings from the latest round. Partition by autofix class:

| Class | Action | Approval |
|-------|--------|----------|
| `safe_auto` | Apply fix immediately | No approval needed |
| `gated_auto` | Present to human with evidence + suggested fix | Human must approve |
| `manual` | Present to human with evidence | Human must approve |
| `advisory` | Report only | No action |

Exclude `pre_existing: true` findings — they are reported but not acted upon.

### Step 2 — Apply safe_auto Fixes

For each `safe_auto` finding:
1. Read the file at the specified line.
2. Apply the `suggested_fix`.
3. Run the affected tests (tests in the same file or module).
4. If the fix breaks tests: **downgrade to gated_auto** and present to human instead.
5. If the fix passes: record it in the "Applied Fixes" section.

Run the project formatter on all modified files after applying safe_auto fixes.

### Step 3 — Human Triage

Present all `gated_auto` and `manual` findings to the user:

```
The following findings require your decision:

# | Sev | Title | File | Autofix | Confidence
--|-----|-------|------|---------|----------
1 | P0  | ...   | ...  | gated_auto | 0.87
2 | P1  | ...   | ...  | manual     | 0.75

For each finding, reply:
  approve  — fix it (using TDD)
  defer    — skip for now (documented in 06-solutions.md)
  reject   — not a real issue (suppress)

Example: "1: approve, 2: defer"
```

**P0 findings cannot be deferred or rejected** without an explicit override. If the user attempts to defer a P0:
```
P0 findings are critical and cannot be deferred. Options:
  A) Approve the fix
  B) Override — proceed despite P0 (logged as override in review document)
```

### Step 4 — Execute Approved Fixes

For each approved finding:
1. Follow the TDD cycle:
   - **RED:** Write a test that exposes the finding (if not already covered by existing tests).
   - **GREEN:** Apply the minimum fix.
   - **REFACTOR:** Clean up if needed.
2. Run the full test suite after each fix.
3. Commit the fix: `fix(review): [finding title]`

For infrastructure/config fixes: use verification mode (run build + tests, no new test required).

### Step 5 — Re-Review (Bounded)

After all approved fixes are applied:

1. Compute the set of files modified by the fixes.
2. Determine which reviewers to re-dispatch:
   - For each reviewer from Round 1: check if any of their findings were in the modified files.
   - Re-dispatch ONLY those reviewers whose scope was touched.
   - ALWAYS re-dispatch plan-alignment-reviewer if `02-plan.md` exists (alignment is a global property).
3. Re-dispatch selected reviewers with scope limited to modified files only.
4. Process new findings through the same pipeline (validate → segregate → fingerprint → dedup → confidence gate → sort).
5. Append a `## Round N` section to `05-code-review.md` with:
   - Which reviewers were re-dispatched
   - Scope of re-review
   - New/remaining findings
   - Updated verdict

### Step 6 — Evaluate

| Condition | Action |
|-----------|--------|
| 0 P0 + 0 P1 remaining | **APPROVED** — proceed to commit |
| New P0 introduced by fix | Grant Round 3 (hard ceiling) |
| P1 remaining, cap reached | Surface to human: "These P1 issues could not be resolved. Ship or continue?" |
| Hard ceiling (3 rounds) reached | Surface ALL remaining issues: "HUMAN DECISION REQUIRED" |

**Iteration tracking:**
- Round 1 = initial review (always happens)
- Round 2 = first re-review after fixes (normal cap)
- Round 3 = second re-review (only if Round 2 fixes introduced a new P0)
- Hard ceiling: 3 rounds total. After Round 3, no more automatic fixes — human decides.

### Step 7 — Record Deferred Items

For findings the user chose to "defer":
- Record in `06-solutions.md` under a "Deferred Findings" section
- Include: title, severity, file, line, impact, and reason for deferral

## Rules

- safe_auto fixes are applied WITHOUT user approval. This is by design — they are deterministic and behavior-preserving.
- If a safe_auto fix breaks tests, it is NOT safe. Downgrade immediately.
- Every approved fix follows TDD. No fix without a test (unless verification mode applies).
- Re-review scope is limited to changed files. Do not re-review the entire diff.
- The plan-alignment reviewer is always re-dispatched (if plan exists) because any code change can drift from the plan.
- NEVER loop infinitely. The hard ceiling exists to prevent this.

## Transition

- When verdict is APPROVED: RETURN control to orchestrator for commit-push.
- When human decides to ship despite remaining issues: RETURN with override logged.
- IF standalone: inform user of final status and next steps.
