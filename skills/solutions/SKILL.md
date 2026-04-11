---
name: solutions
description: Produces 06-solutions.md at the end of every dev or resolve pipeline, capturing problem summary, approach, key decisions, and gotchas for future reference.
---

# Solutions (End-of-Pipeline)

Capture durable learnings from the pipeline that just completed. This phase produces a solutions document that future sessions can reference when working in the same area of the codebase.

## When to Run

- At the end of every dev pipeline (features)
- At the end of every resolve pipeline (bug fixes)
- NOT for trivial pipeline (no spec directory, no artifacts to synthesize)

## Prerequisites

At least one of these must exist in the active spec directory:
- `01-brainstorm.md` (dev pipeline)
- `01-diagnosis.md` (resolve pipeline)

## Process

This is an **inline synthesis** — no subagents. Read the existing spec artifacts and distill them into a concise solutions document.

### Step 1 — Read All Spec Artifacts

Read every artifact in the active spec directory:
- `01-brainstorm.md` or `01-diagnosis.md` — for problem context and root cause
- `02-plan.md` — for approach and key decisions (dev pipeline only)
- `03-revision.md` — for adjustments made (dev pipeline only)
- `04-execution-log.md` — for unexpected decisions and deviations
- `05-code-review.md` — for issues found and fixed

### Step 2 — Synthesize

Extract and condense:

**Problem Summary:** 2-3 sentences from the brainstorm problem statement or diagnosis bug description. What was the core problem?

**Root Cause (bugs only):** From the diagnosis document. What actually caused the issue? Reference specific files and lines.

**Approach:** From the plan's key decisions or the execution log. What was done and why was this approach chosen over alternatives?

**Key Decisions:** Non-obvious decisions made during the pipeline. Pull from:
- Plan key decisions section
- Revision adjustments
- Execution log unexpected decisions
- Code review findings that led to changes

Each decision should include the rationale and trade-off accepted.

**Gotchas:** Surprises, edge cases, or tricky areas discovered during implementation that a future developer should know about. Pull from:
- Execution log unexpected decisions
- Code review findings (especially P1/P2 that required changes)
- Concerns sections from diagnosis or revision

### Step 3 — Write Artifact

1. WRITE `06-solutions.md` in the active spec directory using `templates/06-solutions.md`
2. SET frontmatter: `status: draft`, `date`, `topic`, `pipeline` (dev or resolve)
3. Keep it concise — this is a reference document, not a narrative

**Quality checks:**
- Every key decision has a rationale (not just "we decided to...")
- Gotchas are specific enough to be actionable (not "be careful with X")
- Root cause (for bugs) references actual code, not abstract descriptions
- The document is useful to someone who has never seen the brainstorm or plan

## Transition

WHEN this skill completes:
- IF running inside a pipeline: RETURN control to the pipeline orchestrator. The pipeline is now complete.
- IF running standalone: INFORM the user that the solutions document has been written.
