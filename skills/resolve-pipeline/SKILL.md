---
name: resolve-pipeline
description: Use when fixing a bug, error, regression, or broken behavior. Orchestrates a shortened pipeline optimized for bug fixes — diagnosis, targeted fix with prove-it TDD, code review, and commit.
---

# Resolve Pipeline Orchestrator

This is the bug-fix pipeline. It runs a shortened, diagnosis-driven flow from investigation to committed fix. Every phase is executed in strict order. No phase is skipped. No gate is bypassed.

**Trigger:** `/resolve`, `/fix`, or any request that describes a bug, error, regression, or broken behavior (keywords: "fix", "bug", "broken", "error", "not working", "regression", "crash", "failing").

**If the request is a feature, not a bug:** Use the feature pipeline (`development-toolkit:dev-pipeline`) instead. Do not use this pipeline for new features, enhancements, or refactoring.

**FIRST ACTION — Non-Negotiable:**
When this skill is loaded, your VERY FIRST action is to invoke `Skill: development-toolkit:context-loader`. Do NOT explore the codebase ad-hoc. Do NOT attempt a quick fix. Do NOT write code. Invoke context-loader. Then proceed to Phase 1R.

## Pipeline Overview

```
Phase 0 (Context)  ->  Phase 1R (Diagnosis)  ->  APPROVAL GATE  ->  Phase 4R (Fix)  ->  TEST GATE  ->  Phase 5 (Review)  ->  Phase 6 (Commit)
  context-loader        diagnosis                (diagnosis review)   execute (prove-it)                  code-review           commit-push
  in-memory context     01-diagnosis.md                                source + tests                     04-code-review.md     git history
```

Phases 2 (Planning) and 3 (Revision) are skipped. The diagnosis document serves as both investigation and fix plan.

## Phase Transition Protocol

Every phase transition follows the same three-step sequence. No exceptions.

**Step 1 — Label.** Output the progress label (the ONLY text allowed between phases):
```
▶ Phase [N] — [Phase Name] (resolve)
  Skill: development-toolkit:[skill-name]
```

**Step 2 — Invoke.** Call the `Skill` tool for the phase's skill. This is non-negotiable. Do not replicate a skill's steps manually — the `Skill` tool loads the current version.

**Step 3 — Verify.** Confirm the phase's output artifact exists before proceeding.

Between these steps, output ZERO additional text. No summaries, no narration.

### Skill Invocation Table

| Phase | Skill to invoke |
|-------|----------------|
| 0 | `development-toolkit:context-loader` |
| 1R | `development-toolkit:diagnosis` |
| 4R | `development-toolkit:execute` (loads TDD rules from `skills/tdd/SKILL.md` internally) |
| 5 | `development-toolkit:code-review` |
| 6 | `development-toolkit:commit-push` |

**If you find yourself executing a phase's logic without having called `Skill` for that phase, STOP. Go back and invoke the skill.**

## Pipeline Execution Protocol

### Phase 0 -- Context Loading

Invoke `Skill: development-toolkit:context-loader`.

Store the output as the **project context block**. This block is injected into every subsequent phase. If context loading fails, STOP and report.

### Phase 1R -- Diagnosis

Invoke `Skill: development-toolkit:diagnosis` with the user's bug description and the project context block from Phase 0.

Wait for completion. Verify `01-diagnosis.md` exists in the per-session spec directory.

### DIAGNOSIS APPROVAL GATE

After the diagnosis skill completes, present this gate:

```
=====================================================================
  DIAGNOSIS COMPLETE — Review Required Before Proceeding
=====================================================================

Root cause: [one-sentence summary from diagnosis]
Severity:   [TRIVIAL / STANDARD / COMPLEX]
Fix:        [one-sentence summary of suggested fix]
Hotspots:   [file:line list]

Diagnosis document: docs/YYYY-MM-DD-<topic>/01-diagnosis.md

[If TRIVIAL]:
  This appears to be a trivial fix. Options:
  -> "go" — apply fix directly and commit [Recommended]
  -> "full pipeline" — run full resolve pipeline (execute + review + commit)

[If STANDARD or COMPLEX]:
  -> "go" to continue to Phase 4R (Fix)
  -> "changes needed" with specifics to revise the diagnosis
  -> "stop" to pause the pipeline

Model override (optional — inherited model is used by default):
  -> "model <name>" to change the model for subagents in execution/review
     Valid values: opus, sonnet, haiku

=====================================================================
```

**Handling responses:**
- "approve", "proceed", "apply", "lgtm", "go", "let's go", "looks good", "ship it": proceed based on severity (see below).
- "approve model opus", etc.: proceed with the specified model override for subagent dispatch.
- "changes needed" or feedback with specifics: apply changes to the diagnosis, then re-present the gate.
- "full pipeline": decline the trivial escape hatch — continue with Phase 4R -> TEST GATE -> Phase 5 -> Phase 6.
- "stop": halt the pipeline. Report current state.
- Silence or ambiguous response: ask for clarification. Do NOT interpret silence as approval.

### Trivial Escape Hatch

If the diagnosis severity is **TRIVIAL** AND the user approves the trivial path:

The pipeline enters **TRIVIAL mode**. The following phases are **LOCKED OUT** — do NOT invoke them:
- Phase 4R (Fix) — DO NOT invoke `development-toolkit:execute` or `development-toolkit:tdd`
- Phase 5 (Code Review) — DO NOT invoke `development-toolkit:code-review` or dispatch reviewer agents

**TRIVIAL mode steps (the ONLY steps allowed):**
1. Apply the fix directly (the suggested fix from `01-diagnosis.md`)
2. Write the regression test (the reproduction test from `01-diagnosis.md`)
3. Run the full test suite
4. If tests pass: proceed directly to Phase 6 — invoke `Skill: development-toolkit:commit-push`
5. If tests fail: fix and retry up to 3 times. If still failing, escalate to user.

**TRIVIAL mode guard:** If you find yourself about to invoke `development-toolkit:execute`, `development-toolkit:tdd`, `development-toolkit:code-review`, or dispatch any reviewer agent — STOP. You are violating TRIVIAL mode. The user approved the shortcut. Respect it.

### Phase 4R -- Fix (Prove-It TDD)

Invoke `Skill: development-toolkit:execute` with the following modifications:
1. Read `01-diagnosis.md` instead of `02-plan.md`
2. The reproduction test from the diagnosis IS the first RED test — do not write a new one
3. Follow the Prove-It pattern: reproduce, confirm failure, fix, verify, run full suite
4. The fix must be minimal — address the root cause and nothing else
5. A regression test must exist when done (the reproduction test serves as this)

### TEST GATE

After Phase 4R completes, verify:
1. Full test suite passes
2. Linter clean (if configured)
3. Type checker valid (if applicable)

**If everything passes:** proceed to Phase 5.

**If any check fails:**
- Attempt up to 3 fix-and-retry cycles.
- If still failing after 3 attempts:
  ```
  TEST GATE FAILED after 3 attempts.
  Failing: [test name / lint rule / type error]
  Attempted fixes: [summary]
  Human intervention needed before proceeding.
  ```
- Do NOT proceed to code review with failing tests.

### Phase 5 -- Code Review

Invoke `Skill: development-toolkit:code-review`.

In resolve mode, the code-review skill uses `01-diagnosis.md` as the plan reference instead of `02-plan.md`.

### HUMAN APPROVAL GATE #2 (Conditional)

This gate triggers ONLY if P0 (critical) issues are found:

```
=====================================================================
  APPROVAL GATE -- Critical Issues Found
=====================================================================

Code review found [N] critical issue(s):

  [List each P0 with title and file location]

Options:
  -> "fix" -- I'll resolve these and re-review
  -> "override" -- Proceed despite critical issues (at your risk)
  -> "stop" -- Pause the pipeline

=====================================================================
```

**If no P0 issues exist:** skip this gate and proceed to Phase 6.

### Phase 6 -- Commit and Push

Invoke `Skill: development-toolkit:commit-push`.

### Pipeline Complete

```
=====================================================================
  RESOLVE PIPELINE COMPLETE
=====================================================================

Bug:     [topic from diagnosis]
Branch:  [branch name]
Commits: [N]
Tests:   [N] passing

Artifacts (in docs/YYYY-MM-DD-<topic>/):
  01-diagnosis.md   -- Root-cause investigation
  04-code-review.md -- Code review findings

Next steps:
  -> Create a PR: gh pr create
  -> Review the diff: git diff main..HEAD
=====================================================================
```

## Resume and Recovery

If the pipeline is interrupted, determine the resume point from existing artifacts:

**Detection logic (check in order):**

1. `04-code-review.md` exists -> resume at Phase 6 (Commit).
2. Code changes exist (modified files beyond spec docs) but no `04-code-review.md` -> resume at Phase 5 (Code Review).
3. `01-diagnosis.md` exists -> resume at Diagnosis Approval Gate (present diagnosis for approval first).
4. No artifacts exist -> start from Phase 0.

**Resume protocol:**
1. Run `/context` to load fresh project context (always — cached context is stale).
2. Read all existing spec artifacts.
3. Present the resume point:
   ```
   RESOLVE PIPELINE RESUME
   Found existing artifacts:
     [list what exists with status]
   Resuming at: Phase [N] ([name])
   -> "continue" to proceed from here
   -> "restart" to start the pipeline from scratch
   ```
4. Wait for confirmation. Do NOT auto-resume.

## Rules

1. **Do NOT brainstorm solutions for bugs.** The diagnosis identifies the root cause and suggests a fix. Brainstorming options is for features, not bugs.
2. **Do NOT plan or revise for bugs.** The diagnosis serves as both investigation and plan. Phases 2 and 3 do not exist in this pipeline.
3. **The reproduction test is mandatory.** If the bug cannot be reproduced in a test, document why in the diagnosis and proceed with caution.
4. **Minimal fix only.** Do not refactor, clean up, or improve adjacent code during a bug fix. One bug, one fix, one test.
5. **If the fix reveals a deeper architectural problem,** STOP. Escalate to the user. The bug may require a feature-level pipeline run instead.
6. **NEVER skip a phase.** Phase 0 -> 1R -> Gate -> 4R -> Test Gate -> 5 -> 6. In order.
7. **NEVER proceed past a gate without explicit human approval.**
8. **Spec artifacts are frozen during execution.** Once Phase 4R begins, `01-diagnosis.md` is read-only. If execution reveals a diagnosis problem, escalate.

## Anti-Rationalization Table

| Thought | Reality |
|---------|---------|
| "This bug is obvious, skip diagnosis" | Obvious bugs have caused production incidents. Investigate first. |
| "Let me just try a quick fix" | Quick fixes address symptoms. Diagnosis finds root causes. |
| "The diagnosis is overkill for this" | If it is truly trivial, the diagnosis will be fast and the escape hatch will fire. |
| "I know the TDD/review/commit steps" | Skills evolve. Invoke the Skill tool — it loads the current version. |
| "The trivial fix should still go through full review" | The user approved the shortcut. TRIVIAL mode is LOCKED. Respect it. |
| "Gate approval is just a formality" | Gates exist because humans catch things agents miss. |
| "I'll dispatch the agents directly" | The skill handles orchestration. Bypass it and you miss error recovery. |
| "Let me explore the code / try a quick fix first" | Context-loader handles project scanning. Diagnosis handles investigation. Start with Phase 0. |
