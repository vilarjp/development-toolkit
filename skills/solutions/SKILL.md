---
name: solutions
description: Use at pipeline end to capture learnings.
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

**Root Cause (bugs only):** From the diagnosis document. What actually caused the issue? Describe the mechanism of failure by behavior (e.g., 'the validation middleware skips empty strings, allowing null values to reach the database layer'), not by file path and line number. The description must remain valid after refactoring.

**Approach:** From the plan's key decisions or the execution log. What was done and why was this approach chosen over alternatives?

**Key Decisions:** Non-obvious decisions made during the pipeline. Pull from:
- Plan key decisions section
- Revision adjustments
- Execution log unexpected decisions
- Code review findings that led to changes

Each decision should include the rationale and trade-off accepted.

**Gotchas:** Surprises, edge cases, or tricky areas discovered during implementation that a future developer should know about. Describe gotchas as invariants to maintain (e.g., 'the cache must be invalidated before the write, not after'), not as references to specific code locations. Pull from:
- Execution log unexpected decisions
- Code review findings (especially P1/P2 that required changes)
- Concerns sections from diagnosis or revision

### Step 3 — Write Artifact

1. WRITE `06-solutions.md` in the active spec directory using `templates/06-solutions.md`
2. SET frontmatter: `status: approved`, `date`, `topic`, `pipeline` (dev or resolve)
3. Keep it concise — this is a reference document, not a narrative

**Quality checks:**
- Every key decision has a rationale (not just "we decided to...")
- Gotchas are specific enough to be actionable (not "be careful with X")
- Root cause (for bugs) references actual code, not abstract descriptions
- The document is useful to someone who has never seen the brainstorm or plan

### Step 4 — Discoverability Check

After writing `06-solutions.md`, verify that a future agent session would find it:

1. Read the project's CLAUDE.md (or equivalent rules file)
2. Check: does it reference the `docs/` directory or solutions documents?
3. If not, propose a one-line addition to CLAUDE.md: `# Past solutions and decisions are in docs/*/06-solutions.md`
4. Present the proposed edit to the human for approval. Do not edit CLAUDE.md without approval

If CLAUDE.md does not exist, skip this step — there is no discoverable entry point to update.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Nothing surprising happened, no solutions doc needed" | Every pipeline produces decisions and trade-offs worth recording. Write it. |
| "The commit messages are enough" | Commit messages say what changed. Solutions say why and what to watch out for. |
| "I'll write it later when I have more perspective" | You have maximum context right now. Later means never. |
| "The gotchas section is empty because there were none" | A multi-wave execution with zero gotchas means you are not looking hard enough. Check the execution log. |

## Red Flags — Self-Check

- The Gotchas section is empty after a multi-wave execution
- A key decision has no rationale (just "we decided to...")
- The root cause (for bugs) references abstract descriptions instead of the actual mechanism of failure
- The document would be useless to someone who has never seen the brainstorm or plan
- You skipped the discoverability check

## Transition

WHEN this skill completes:
- IF running inside a pipeline: RETURN control to the pipeline orchestrator. The pipeline is now complete.
- IF running standalone: INFORM the user that the solutions document has been written.
