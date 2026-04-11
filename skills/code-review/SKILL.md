---
name: code-review
description: Use after implementation is complete and all tests pass. Dispatches conditional reviewer subagents (Sonnet/medium) with structured JSON findings, confidence gating, cross-reviewer deduplication, and pre-existing issue segregation. Produces 05-code-review.md.
---

# Code Review (Phase 5)

Catch defects, convention violations, security issues, and plan misalignment BEFORE code is committed. Multiple independent reviewers examine the diff in parallel, producing structured JSON findings that are merged, deduplicated, confidence-gated, and rendered into a human-readable review document.

## Prerequisites

- All tests MUST pass. If the test gate from Phase 4 has not been met, STOP.
- Project context from Phase 0 MUST be loaded.
- `04-execution-log.md` SHOULD exist (provides implementation intent for reviewers).

## Reviewer Inventory

| Reviewer | Dispatch | Blocking | Model |
|----------|----------|----------|-------|
| code-quality-reviewer | Always | Yes | Sonnet/medium |
| test-reviewer | Always | Yes | Sonnet/medium |
| plan-alignment-reviewer | Conditional: `02-plan.md` exists | Yes | Sonnet/medium |
| security-reviewer | Conditional: diff touches auth/input/API/payment/data/env | Yes | Sonnet/medium |
| convention-reviewer | Conditional: area has 3+ files of same type | No | Sonnet/medium |

Orchestrator (this skill) runs on the user's default model.

## Process

### Phase 5.1 — Compute the Diff

1. RUN `git diff` against the base branch to get all changes.
2. Collect the list of changed files.
3. If no diff, STOP — nothing to review.

### Phase 5.2 — Select Reviewers

**Always dispatch:** code-quality-reviewer, test-reviewer.

**Conditional dispatch — evaluate each:**

- **plan-alignment-reviewer:** Check if `02-plan.md` exists in the active spec directory. If yes, dispatch. If no (resolve pipeline trivial fix), skip.
- **security-reviewer:** Read the diff file list. If ANY file touches auth, login, session, user input handling, API endpoints, payment/card/token code, database queries, file uploads, or environment variables — dispatch. Otherwise skip.
- **convention-reviewer:** Check if the diff modifies or creates files in a directory with 3+ existing files of the same type. If yes, dispatch. Otherwise skip.

Log which reviewers were dispatched and which were skipped (with reason) for the review document.

### Phase 5.3 — Dispatch Reviewers

DISPATCH all selected reviewers IN PARALLEL. Model: latest Sonnet, effort: medium.

Each reviewer receives:
1. Their agent definition (from `agents/<reviewer>.md`)
2. The findings schema contract (from `findings-schema.json`)
3. The git diff (limited to their relevant scope)
4. Project context from Phase 0
5. Implementation notes from `04-execution-log.md` (if available)
6. Plan reference: `02-plan.md` and `03-revision.md` (for plan-alignment and test reviewers)
7. Intent summary: 2-3 line description of what this change does and why

**Instruction to each reviewer:** "Return a single JSON object matching the findings schema. Do NOT return markdown. Every finding must have all required fields."

### Phase 5.4 — Collect and Process Findings

After all reviewers complete:

**Step 1: Validate.** Parse each reviewer's JSON output against the schema. Drop malformed findings.

**Step 2: Segregate pre-existing issues.** Findings with `pre_existing: true` are separated. They appear in the review document but do NOT count toward the verdict.

**Step 3: Fingerprint.** For each finding, compute: `id = normalize(file) + line_bucket(line, ±3) + normalize(title)`

**Step 4: Deduplicate.** Merge findings with the same `id`:
- Keep the highest severity
- Keep the strongest evidence (most entries)
- Union evidence arrays
- Set `reviewers` to list all flagging reviewers
- Set `reviewer_agreement` to count
- Boost `confidence` by +0.10 per additional reviewer (cap at 1.0)
- Preserve `original_confidence` (first reviewer's value)

**Step 5: Confidence gate.** Suppress findings below 0.60 confidence. Exception: P0 findings survive at 0.50+.

Confidence tiers:
- **Suppress:** Below 0.60 (speculative noise)
- **Flag:** 0.60–0.69 (include only when clearly actionable)
- **Confident:** 0.70–0.84 (real and important)
- **Certain:** 0.85–1.00 (verifiable from code alone)

**Step 6: Sort.** Severity (P0 first) → confidence (desc) → file path → line.

**Step 7: Collect metadata.** Union all `residual_risks` and `testing_gaps` from all reviewers.

### Phase 5.5 — Write Review Artifact

WRITE `05-code-review.md` using `templates/05-code-review.md`:

- Frontmatter: reviewers dispatched, reviewers skipped with reasons
- Review Summary: counts by severity + suppressed + pre-existing
- Reviewer Scope table
- Round 1 findings: tables grouped by severity (P0, P1, P2, P3)
- Pre-existing issues: separate table
- What's Done Well: positive observations from reviewers
- Residual Risks and Testing Gaps
- Verdict: APPROVED (0 P0 from blocking reviewers) or REQUIRES CHANGES

Store the raw JSON findings alongside the markdown for the fix-loop to parse.

### Phase 5.6 — Present Verdict

**If P0 issues exist from blocking reviewers:**
```
CODE REVIEW: REQUIRES CHANGES — [N] critical issues found.

P0 findings:
1. [title] — [file:line] — autofix: [class] — confidence: [score]
2. ...

Proceeding to fix loop. safe_auto fixes will be applied automatically.
```

Transition directly to the fix-loop skill.

**If no P0 issues:**
```
CODE REVIEW: APPROVED — [N] issues found ([X] P1, [Y] P2, [Z] P3). No critical issues.

P1 recommendations:
- [title] — [file:line]

Proceed to commit, or address P1 issues first?
  A) Commit now (P1s deferred)
  B) Fix P1s first (enter fix loop)
```

## Rules

- Reviewers MUST read actual code. No trusting self-reported claims.
- Every finding MUST include evidence grounded in the diff.
- Severity calibration: style is never P0, SQL injection is never P3.
- The plan-alignment reviewer is the source of truth for "is this what we planned?"
- Cross-scope findings are valid — a convention reviewer spotting a security issue reports it.
- If a reviewer finds nothing, it returns empty findings. Do not fabricate issues.

## Transition

- If P0 issues exist: invoke fix-loop skill.
- If user chooses to fix P1s: invoke fix-loop skill.
- If user chooses to commit: RETURN control to orchestrator for commit-push.
- IF standalone: inform user of next steps.
