---
name: resolve-pipeline
description: Use when fixing a bug, error, regression, or broken behavior. Orchestrates a shortened pipeline optimized for bug fixes — diagnosis, targeted fix with prove-it TDD, code review, and commit.
---

# Resolve Pipeline Orchestrator

This is the bug-fix pipeline. It runs a shortened, diagnosis-driven flow from investigation to committed fix. Every phase is executed in strict order. No phase is skipped. No gate is bypassed.

**Trigger:** `Skill: development-toolkit:resolve-pipeline`, or any request that describes a bug, error, regression, or broken behavior (keywords: "fix", "bug", "broken", "error", "not working", "regression", "crash", "failing").

**If the request is a feature, not a bug:** INVOKE the feature pipeline (`Skill: development-toolkit:dev-pipeline`) instead. DO NOT use this pipeline for new features, enhancements, or refactoring.

**FIRST ACTION — Non-Negotiable:**
When this skill is loaded, your VERY FIRST action is to invoke `Skill: development-toolkit:context-loader`. DO NOT explore the codebase ad-hoc. DO NOT attempt a quick fix. DO NOT write code. INVOKE context-loader. Then PROCEED to Phase 1R.

## Pipeline Overview

```
Pre-Flight (Git)  ->  Phase 0 (Context)  ->  Phase 1R (Diagnosis)  ->  APPROVAL GATE  ->  Phase 4R (Fix)  ->  TEST GATE  ->  Phase 5 (Review)  ->  Finding Selection Loop  ->  Phase 6 (Commit)
  git hygiene           context-loader        diagnosis                (diagnosis review)   execute (prove-it)                  code-review           (iterative fix cycle)       commit-push
                        in-memory context     01-diagnosis.md                                source + tests                     04-code-review.md                                 git history
```

Phases 2 (Planning) and 3 (Revision) are skipped. The diagnosis document serves as both investigation and fix plan.

## Phase Transition Protocol

Every phase transition MUST follow the same three-step sequence. No exceptions.

**Step 1 — LABEL.** OUTPUT the progress label (the ONLY text allowed between phases):
```
▶ Phase [N] — [Phase Name] (resolve)
  Skill: development-toolkit:[skill-name]
```

**Step 2 — INVOKE.** CALL the `Skill` tool for the phase's skill. This is non-negotiable. DO NOT replicate a skill's steps manually — the `Skill` tool loads the current version.

**Step 3 — VERIFY.** CONFIRM the phase's output artifact exists before proceeding.

Between these steps, OUTPUT ZERO additional text. No summaries, no narration.

### Skill Invocation Table

| Phase | Skill to invoke |
|-------|----------------|
| 0 | `development-toolkit:context-loader` |
| 1R | `development-toolkit:diagnosis` |
| 4R | `development-toolkit:execute` (loads TDD rules from `skills/tdd/SKILL.md` internally) |
| 5 | `development-toolkit:code-review` |
| 6 | `development-toolkit:commit-push` |

**If you find yourself executing a phase's logic without having called `Skill` for that phase, STOP. GO BACK and INVOKE the skill.**

## Pipeline Execution Protocol

### Pre-Flight -- Git Hygiene

BEFORE invoking context-loader, ENSURE a clean git state. This step is MANDATORY and MUST NOT be skipped.

1. RUN `git fetch origin` to get the latest remote state.
2. RUN `git status --porcelain` to CHECK for staged or unstaged changes.
   - IF dirty: RUN `git stash` and INFORM the user: "Stashed [N] uncommitted changes. Restore with `git stash pop` after the pipeline completes."
3. DETERMINE the default branch (main or master) from the remote.
4. DO NOT checkout the default branch — stay on the current branch or defer branch creation to Phase 6 (commit-push).

This step ensures every pipeline run starts from a known-clean state.

### Phase 0 -- Context Loading

INVOKE `Skill: development-toolkit:context-loader`.

STORE the output as the **project context block**. This block MUST be injected into every subsequent phase. If context loading fails, STOP and REPORT.

### Phase 1R -- Diagnosis

INVOKE `Skill: development-toolkit:diagnosis` with the user's bug description and the project context block from Phase 0.

WAIT for completion. VERIFY `01-diagnosis.md` exists in the per-session spec directory.

### DIAGNOSIS APPROVAL GATE

After the diagnosis skill completes, PRESENT this gate:

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
- "approve", "proceed", "apply", "lgtm", "go", "let's go", "looks good", "ship it": PROCEED based on severity (see below).
- "approve model opus", etc.: PROCEED with the specified model override for subagent dispatch.
- "changes needed" or feedback with specifics: APPLY changes to the diagnosis, then RE-PRESENT the gate.
- "full pipeline": DECLINE the trivial escape hatch — CONTINUE with Phase 4R -> TEST GATE -> Phase 5 -> Phase 6.
- "stop": HALT the pipeline. REPORT current state.
- Silence or ambiguous response: ASK for clarification. DO NOT interpret silence as approval.

### Trivial Escape Hatch

If the diagnosis severity is **TRIVIAL** AND the user approves the trivial path:

The pipeline enters **TRIVIAL mode**. The following phases are **LOCKED OUT** — DO NOT invoke them:
- Phase 4R (Fix) — DO NOT invoke `development-toolkit:execute` or `development-toolkit:tdd`
- Phase 5 (Code Review) — DO NOT invoke `development-toolkit:code-review` or dispatch reviewer agents

**TRIVIAL mode steps (the ONLY steps allowed):**
1. APPLY the fix directly (the suggested fix from `01-diagnosis.md`)
2. WRITE the regression test (the reproduction test from `01-diagnosis.md`)
3. RUN the full test suite
4. If tests pass: PROCEED directly to Phase 6 — INVOKE `Skill: development-toolkit:commit-push`
5. If tests fail: FIX and RETRY up to 3 times. If still failing, ESCALATE to user.

**TRIVIAL mode guard:** If you find yourself about to invoke `development-toolkit:execute`, `development-toolkit:tdd`, `development-toolkit:code-review`, or dispatch any reviewer agent — STOP. You are violating TRIVIAL mode. The user approved the shortcut. Respect it.

### Phase 4R -- Fix (Prove-It TDD)

INVOKE `Skill: development-toolkit:execute` with the following modifications:
1. READ `01-diagnosis.md` instead of `02-plan.md`
2. The reproduction test from the diagnosis IS the first RED test — DO NOT write a new one
3. FOLLOW the Prove-It pattern: REPRODUCE, CONFIRM failure, FIX, VERIFY, RUN full suite
4. The fix MUST be minimal — ADDRESS the root cause and nothing else
5. A regression test MUST exist when done (the reproduction test serves as this)

### TEST GATE

After Phase 4R completes, VERIFY:
1. Full test suite MUST pass
2. Linter MUST be clean (if configured)
3. Type checker MUST be valid (if applicable)

**If everything passes:** PROCEED to Phase 5.

**If any check fails:**
- ATTEMPT up to 3 fix-and-retry cycles.
- If still failing after 3 attempts:
  ```
  TEST GATE FAILED after 3 attempts.
  Failing: [test name / lint rule / type error]
  Attempted fixes: [summary]
  Human intervention needed before proceeding.
  ```
- DO NOT proceed to code review with failing tests.

### Phase 5 -- Code Review

INVOKE `Skill: development-toolkit:code-review`.

In resolve mode, the code-review skill MUST use `01-diagnosis.md` as the plan reference instead of `02-plan.md`.

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

**If no P0 issues exist:** SKIP this gate and PROCEED to Phase 6.

### Finding Selection Loop

After Phase 5 (code review) completes and Gate #2 is resolved, the code-review skill presents a finding selection gate (Phase 5.7). The user selects which findings to address.

**IF the user selects findings to fix:**
1. FIX the selected findings (apply minimal targeted changes).
2. RUN the full test suite. ALL tests MUST pass.
3. RE-INVOKE `Skill: development-toolkit:code-review` on the new changes.
4. The code-review skill WILL present the finding selection gate again.
5. REPEAT until the user selects "none" with no remaining P0 issues.

**IF the user selects "none" and no P0 issues remain:** PROCEED to Phase 6.

DO NOT proceed to Phase 6 while the finding selection loop is active. DO NOT auto-fix findings without user selection.

### Phase 6 -- Commit and Push

INVOKE `Skill: development-toolkit:commit-push`.

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

If the pipeline is interrupted, DETERMINE the resume point from existing artifacts:

**Detection logic (CHECK in order):**

1. `04-code-review.md` exists -> RESUME at Phase 6 (Commit).
2. Code changes exist (modified files beyond spec docs) but no `04-code-review.md` -> RESUME at Phase 5 (Code Review).
3. `01-diagnosis.md` exists -> RESUME at Diagnosis Approval Gate (PRESENT diagnosis for approval first).
4. No artifacts exist -> START from Phase 0.

**Resume protocol:**
1. RUN `Skill: development-toolkit:context-loader` to load fresh project context (ALWAYS — cached context is stale).
2. READ all existing spec artifacts.
3. PRESENT the resume point:
   ```
   RESOLVE PIPELINE RESUME
   Found existing artifacts:
     [list what exists with status]
   Resuming at: Phase [N] ([name])
   -> "continue" to proceed from here
   -> "restart" to start the pipeline from scratch
   ```
4. WAIT for confirmation. DO NOT auto-resume.

## Rules

1. **DO NOT brainstorm solutions for bugs.** The diagnosis identifies the root cause and suggests a fix. Brainstorming options is for features, not bugs.
2. **DO NOT plan or revise for bugs.** The diagnosis serves as both investigation and plan. Phases 2 and 3 DO NOT exist in this pipeline.
3. **The reproduction test is MANDATORY.** If the bug cannot be reproduced in a test, DOCUMENT why in the diagnosis and PROCEED with caution.
4. **Minimal fix only.** DO NOT refactor, clean up, or improve adjacent code during a bug fix. One bug, one fix, one test.
5. **If the fix reveals a deeper architectural problem,** STOP. ESCALATE to the user. The bug MUST use a feature-level pipeline run instead.
6. **NEVER skip a phase.** Pre-Flight -> Phase 0 -> 1R -> Gate -> 4R -> Test Gate -> 5 -> Finding Selection Loop -> 6. In order.
7. **NEVER proceed past a gate without explicit human approval.**
8. **Spec artifacts are frozen during execution.** Once Phase 4R begins, `01-diagnosis.md` is read-only. If execution reveals a diagnosis problem, ESCALATE.

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
| "Let me explore the code / try a quick fix first" | Context-loader handles project scanning. Diagnosis handles investigation. START with Pre-Flight, then Phase 0. |

## Transition

WHEN this pipeline completes:
- DISPLAY the RESOLVE PIPELINE COMPLETE summary.
- DO NOT ask "what would you like to do next?"
- DO NOT suggest additional work unless the user asks.
- The pipeline is finished. The session can end or the user can start a new task.
