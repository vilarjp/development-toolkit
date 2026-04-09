---
name: dev-pipeline
description: Use when building a new feature, implementing a change, or starting a full development cycle. Orchestrates the complete pipeline from context loading through commit with human approval gates and test gates.
---

# Development Pipeline Orchestrator

This is the master skill. It runs the full development pipeline from idea to committed code. Every phase is executed in strict order. No phase is skipped. No gate is bypassed.

**Trigger:** `Skill: development-toolkit:dev-pipeline` or any request to build a feature, implement a change, or start a development cycle.

**Bug fix detection:** If the user's request describes a bug, error, regression, or broken behavior (keywords: "fix", "bug", "broken", "error", "not working", "regression", "crash", "failing"), DELEGATE to the resolve pipeline instead: INVOKE `Skill: development-toolkit:resolve-pipeline` and STOP. DO NOT run this feature pipeline for bug fixes.

## Pipeline Overview

```
Phase 0 (Context)    -> Phase 1 (Brainstorm)  -> Phase 2 (Plan)     -> Phase 3 (Revision)
  | sonnet, no think    | opus, 10k think        | opus, 10k think    | opus, 10k think
  in-memory context     01-brainstorm.md         02-plan.md           03-revision.md
                                                                         |
                                                               +---------v----------+
                                                               |  HUMAN APPROVAL    |
                                                               |  GATE #1           |
                                                               +---------+----------+
                                                                         |
Phase 6 (Commit)     <- Phase 5 (Review)      <- Phase 4 (Execute)    <-+
  | sonnet, 5k think    | sonnet, 5k think       | sonnet, 5k think
  git history           04-code-review.md        source + tests
                            |                        |
                      +-----v-----+           +------v------+
                      | Critical  |           | ALL TESTS   |
                      | issues?   |           | PASS?       |
                      | -> GATE #2|           | -> TEST GATE|
                      +-----------+           +-------------+
```

## Spec Directory Protocol

The spec directory path is computed ONCE during Phase 1 (Brainstorm) and reused by all subsequent phases. This prevents directory drift between phases.

**Computation:** The brainstorm skill creates the spec directory using the convention `docs/YYYY-MM-DD-short-description-of-topic/`. After Phase 1 completes, record this path.

**Propagation:** When invoking subsequent skills (Phases 2-6), include the spec directory path as context: "Spec directory: `docs/YYYY-MM-DD-<topic>/`". Skills write their artifacts to this exact directory.

**Resume:** When resuming a pipeline, detect the spec directory by finding the most recent `docs/YYYY-MM-DD-*/` directory containing pipeline artifacts. Fall back to `docs/spec/` for legacy runs.

## Phase Transition Protocol

Every phase transition follows the same three-step sequence. No exceptions.

**Step 1 — Label.** Output the progress label (the ONLY text allowed between phases):
```
▶ Phase [N] — [Phase Name]
  Skill: development-toolkit:[skill-name]
```

**Step 2 — Invoke.** Call the `Skill` tool for the phase's skill. This is non-negotiable. DO NOT replicate a skill's steps manually — the `Skill` tool loads the current version and your memory of what it does WILL be stale.

**Step 3 — Verify.** Confirm the phase's output artifact exists before proceeding.

Between these steps, output ZERO additional text. No summaries, no narration, no "let me now proceed to...".

### Skill Invocation Table

| Phase | Skill to invoke |
|-------|----------------|
| 0 | `development-toolkit:context-loader` |
| 1 | `development-toolkit:brainstorm` |
| 2 | `development-toolkit:plan` |
| 3 | `development-toolkit:revision` |
| 4 | `development-toolkit:execute` |
| 5 | `development-toolkit:code-review` |
| 6 | `development-toolkit:commit-push` |

**If you find yourself executing a phase's logic without having called `Skill` for that phase, STOP. Go back and invoke the skill.**

## Pipeline Execution Protocol

When `Skill: development-toolkit:dev-pipeline` is invoked with a user request, EXECUTE the following sequence exactly. DO NOT reorder, skip, or combine phases.

**FIRST ACTION — Non-Negotiable:**
When this skill is loaded, your VERY FIRST action is to INVOKE `Skill: development-toolkit:context-loader`. DO NOT read the user's request in depth first. DO NOT explore the codebase. DO NOT fetch Jira tickets. DO NOT enter plan mode. DO NOT write code. INVOKE context-loader. Then PROCEED to Phase 1.

### Pre-Flight -- Git Hygiene

BEFORE invoking context-loader, ENSURE a clean git state. This step is MANDATORY and MUST NOT be skipped.

1. RUN `git fetch origin` to get the latest remote state.
2. RUN `git status --porcelain` to CHECK for staged or unstaged changes.
   - IF dirty: RUN `git stash` and INFORM the user: "Stashed [N] uncommitted changes. Restore with `git stash pop` after the pipeline completes."
3. DETERMINE the default branch (main or master) from the remote.
4. DO NOT checkout the default branch — stay on the current branch or defer branch creation to Phase 6 (commit-push).

This step ensures every pipeline run starts from a known-clean state.

### Phase 0 -- Context Loading

Invoke `Skill: development-toolkit:context-loader`.

STORE the output as the **project context block** — it is injected into every subsequent phase. DO NOT skip this phase. DO NOT substitute cached context from a prior session.

If context loading fails, STOP. REPORT the failure and ASK the user to verify the working directory.

### Phase 1 -- Brainstorm

Invoke `Skill: development-toolkit:brainstorm` with the user's original request and the project context block from Phase 0.

WAIT for completion. VERIFY `01-brainstorm.md` exists in the per-session spec directory. DO NOT proceed until the user has confirmed the recommended direction.

### Phase 2 -- Planning

Invoke `Skill: development-toolkit:plan` with the brainstorm output and project context.

WAIT for completion. VERIFY `02-plan.md` exists in the spec directory.

### Phase 3 -- Revision

Invoke `Skill: development-toolkit:revision`.

WAIT for completion. VERIFY `03-revision.md` exists in the spec directory.

### HUMAN APPROVAL GATES (Complexity-Based)

The number and placement of approval gates depends on the complexity classification from Phase 1 (brainstorm). The user chose a checkpoint strategy during the brainstorm phase.

**Strategy A (LOW complexity):** Single gate after Phase 3 (Revision).
**Strategy B (MEDIUM complexity):** Gate after Phase 2 (Planning) and after Phase 3 (Revision).
**Strategy C (HIGH complexity):** Gate after Phase 1 (Brainstorm), after Phase 2 (Planning), and after Phase 3 (Revision).

When a gate fires, PRESENT this message:

```
=====================================================================
  APPROVAL GATE — Review Required Before Proceeding
=====================================================================

Specification documents ready for review:

  [List only the documents produced so far]

Reply with one of:
  -> "go" to proceed to the next phase
  -> "changes needed" with specifics to revise
  -> "stop" to pause the pipeline

Model override (optional — inherited model is used by default):
  -> "model <name>" to change the model for subagents in execution/review
     (e.g., "model opus" for complex logic, "model haiku" for boilerplate)
     Valid values: opus, sonnet, haiku

  The next phase will NOT begin without your explicit approval.
=====================================================================
```

**Handling responses:**
- "approve", "proceed", "lgtm", "go", "let's go", "looks good", "ship it": proceed to the next phase with the inherited model.
- "approve model opus", "proceed model haiku", etc.: proceed with the specified model override. When dispatching subagents in Phase 4 (execute) and Phase 5 (code-review), pass the override via the `model` parameter on the `Agent` tool call (e.g., `Agent(model: "opus", ...)`). The override applies to subagent dispatch only — skills are still invoked inline via the `Skill` tool.
- "changes needed" or any feedback with specifics: APPLY the requested changes to the relevant documents, then RE-PRESENT the gate. DO NOT re-run the full phase unless the changes are structural.
- "stop": HALT the pipeline. REPORT current state and how to resume later.
- Silence or ambiguous response: ASK for clarification. DO NOT interpret silence as approval.

These gates are non-negotiable. No rationalization bypasses them. "The user seems eager" does not bypass them. "The plan is straightforward" does not bypass them.

**The post-Revision gate is ALWAYS present, regardless of strategy.** The complexity-based strategy MUST add earlier gates as specified but NEVER removes the final pre-implementation gate.

### Phase 4 -- Execution

INVOKE `Skill: development-toolkit:execute`. DO NOT write any code before invoking this skill. DO NOT dispatch subagents without loading the skill first.

The plan (`02-plan.md` as amended by `03-revision.md`) is the authoritative source of truth. Subagents MUST implement what the plan says — they MUST NOT add, remove, or reinterpret requirements.

### TEST GATE

After Phase 4 completes, the execute skill runs a final verification:

1. Full test suite
2. Linter (if configured)
3. Type checker (if applicable)

**If everything passes:** proceed to Phase 5.

**If any check fails:**
- The execute skill attempts up to 3 fix-and-retry cycles.
- If tests still fail after 3 attempts, the pipeline escalates to the human:
  ```
  TEST GATE FAILED after 3 attempts.
  Failing: [test name / lint rule / type error]
  Attempted fixes: [summary]
  Human intervention needed before proceeding.
  ```
- DO NOT proceed to code review with failing tests.

### Phase 5 -- Code Review

INVOKE `Skill: development-toolkit:code-review`. DO NOT dispatch reviewer subagents directly — the skill handles diff partitioning, agent dispatch, result collection, deduplication, and severity classification.

### HUMAN APPROVAL GATE #2 (Conditional)

This gate triggers ONLY if P0 (critical) issues are found.

```
=====================================================================
  APPROVAL GATE -- Critical Issues Found
=====================================================================

Code review found [N] critical issue(s):

  [List each P0 with title and file location]

Reply with one of:
  -> "fix" -- I'll resolve these and re-review
  -> "override" -- Proceed despite critical issues (at your risk)
  -> "stop" -- Pause the pipeline

=====================================================================
```

**Handling responses:**
- "fix": RESOLVE each P0 issue, then RE-RUN Phase 5 (code review) to confirm the fixes. DO NOT skip the re-review.
- "override": PROCEED to Phase 6. LOG the override decision in `04-code-review.md` with a note that the human accepted the risk.
- "stop": HALT the pipeline. REPORT current state.

**If no P0 issues exist:** SKIP this gate entirely and PROCEED directly to Phase 6.

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

INVOKE `Skill: development-toolkit:commit-push`. DO NOT run `git add`, `git commit`, or `git push` directly — the skill enforces branch safety, pre-commit verification, logical commit splitting, and rebase-before-push.

### Pipeline Complete

After Phase 6 succeeds, PRESENT this summary:

```
=====================================================================
  PIPELINE COMPLETE
=====================================================================

Feature: [topic from brainstorm]
Branch:  [branch name]
Commits: [N]
Tests:   [N] passing

Artifacts (in docs/YYYY-MM-DD-<topic>/):
  01-brainstorm.md  -- Problem exploration and direction
  02-plan.md        -- Technical implementation plan
  03-revision.md    -- Cross-document review
  04-code-review.md -- Code review findings

Next steps:
  -> Create a PR: gh pr create
  -> Review the diff: git diff main..HEAD
=====================================================================
```

## Standalone Phase Execution

Each phase can be invoked independently via its skill:

| Skill | Standalone Behavior |
|-------|-------------------|
| `development-toolkit:context-loader` | RUN Phase 0 only. No prerequisites. |
| `development-toolkit:brainstorm` | Requires project context. If missing, INVOKE `development-toolkit:context-loader` first. |
| `development-toolkit:diagnosis` | Requires project context. Produces `01-diagnosis.md`. |
| `development-toolkit:plan` | Requires `01-brainstorm.md`. If missing, INFORM the user to run `development-toolkit:brainstorm`. |
| `development-toolkit:revision` | Requires `01-brainstorm.md` and `02-plan.md`. REPORT which is missing. |
| `development-toolkit:execute` | Requires `02-plan.md`, `03-revision.md`, and human approval. |
| `development-toolkit:code-review` | Requires all tests passing. RUNS test suite to verify. |
| `development-toolkit:commit-push` | Requires `04-code-review.md` with no unresolved P0 issues. |

When invoked standalone:
1. LOAD project context fresh via `Skill: development-toolkit:context-loader` (unless already available in the current session).
2. CHECK prerequisites. If a prerequisite artifact is missing, TELL the user which phase to run first. DO NOT silently generate the missing artifact.
3. EXECUTE the single phase and STOP. DO NOT auto-advance to subsequent phases.

## Resume and Recovery

If the pipeline is interrupted (session ends, user stops, crash), DETERMINE the resume point from existing artifacts when `Skill: development-toolkit:dev-pipeline` is invoked again:

**Detection logic:** FIND the most recent per-session spec directory (see AGENTS.md "Spec directory convention"). ALSO check `docs/spec/` for legacy artifacts. Then CHECK in order:

1. `04-code-review.md` exists -> resume at Phase 6 (Commit).
2. Code changes exist (modified files beyond spec docs) but no `04-code-review.md` -> resume at Phase 5 (Code Review).
3. `03-revision.md` exists -> resume at Gate #1 (ask for approval to start implementation).
4. `02-plan.md` exists -> resume at Phase 3 (Revision).
5. `01-brainstorm.md` exists -> resume at Phase 2 (Planning).
6. No artifacts exist -> start from Phase 0.

**If `01-diagnosis.md` exists instead of `01-brainstorm.md`:** This is a resolve pipeline run. DELEGATE to `Skill: development-toolkit:resolve-pipeline` which has its own resume logic.

**Resume protocol:**
1. RUN `Skill: development-toolkit:context-loader` to load fresh project context (ALWAYS -- cached context from a dead session is stale).
2. READ all existing spec artifacts to rebuild the pipeline state.
3. PRESENT the resume point to the user:
   ```
   PIPELINE RESUME
   Found existing artifacts:
     [list what exists with status]
   Resuming at: Phase [N] ([name])
   -> "continue" to proceed from here
   -> "restart" to start the pipeline from scratch
   -> "phase N" to jump to a specific phase
   ```
4. WAIT for the user to confirm before proceeding. DO NOT auto-resume.

If the user says "restart," archive existing specs by renaming the spec directory to `docs/<dir>-archived-<timestamp>/` and start fresh from Phase 0.

## Rules

These rules apply to the orchestrator at all times. They are not suggestions.

1. **NEVER skip a phase in the full pipeline.** Phase 0 through Phase 6, in order. "This is a simple change" does not justify skipping brainstorm and plan. Simple changes are fast to brainstorm and plan. They are not exempt.

2. **NEVER proceed past a gate without explicit human approval.** Gate #1 requires approval before implementation. Gate #2 requires approval when critical issues exist. Silence is not approval. Ambiguity is not approval. Only explicit confirmation is approval.

3. **NEVER write code before Phase 4.** Phases 0-3 are thinking phases. They produce documents, not code. If you find yourself writing function bodies, component JSX, database queries, or any implementation during Phases 0-3, STOP. You have crossed a phase boundary.

4. **The plan is the source of truth for execution.** `02-plan.md` as amended by `03-revision.md` is the authoritative reference. Subagents implement what the plan says. The orchestrator MUST NOT reinterpret, expand, or reduce the plan.

5. **Every line of production code must be justified by a failing test.** TDD is enforced in Phase 4 via the `tdd` skill. No exceptions for "trivial" code, configuration files, or "obvious" implementations.

6. **If any phase fails, DIAGNOSE before retrying.** DO NOT blindly re-run a failed phase. READ the error, UNDERSTAND the cause, FIX the input or environment, then retry. Repeating the same action expecting a different result is not a recovery strategy.

7. **Spec artifacts are append-only during execution.** Once Phase 4 begins, `01-brainstorm.md`, `02-plan.md`, and `03-revision.md` are frozen. They MUST only be referenced, NEVER modified. If execution reveals a plan problem, escalate to the human rather than silently editing the plan.

8. **Subagents are stateless and isolated.** Each subagent receives its full context in the dispatch prompt. Subagents MUST NOT communicate with each other. All coordination flows through the orchestrator. If subagent A produces output that subagent B needs, the orchestrator passes it.

## Anti-Rationalization Table

| Thought | Reality |
|---------|---------|
| "This is too small for the full pipeline" | Small changes are fast to pipeline. They are not exempt. |
| "The user wants this done quickly" | Speed without structure produces rework. The pipeline IS the fast path. |
| "I already know what to build" | Then the brainstorm will confirm it in 5 minutes. Skip nothing. |
| "The plan is obvious, skip to execution" | Obvious plans still have edge cases. Plan and revise find them. |
| "Gate approval is just a formality" | Gates exist because humans catch things agents miss. Respect them. |
| "One failing test is fine, I'll fix it later" | Later never comes. The test gate is absolute. Fix it now. |
| "This code is too simple to need review" | Simple code has simple bugs that compound into complex incidents. Review it. |
| "Let me just commit directly to main" | No. Never. Create a branch. This rule has zero exceptions. |
| "I'll add tests after the feature works" | TDD means test first. If you wrote code before a test, delete it and start over. |
| "The revision found nothing, so I'll skip it next time" | If revision found nothing, you did not look hard enough. Never skip it. |
| "I know the TDD/review/commit steps, I'll do them manually" | Skills evolve. Your memory may be stale. Invoke the Skill tool — it loads the current version. Manual replication caused skipped steps in past sessions. |
| "I'll dispatch the agents directly, same thing" | No. The skill handles orchestration, result collection, and error recovery that you will miss if you bypass it. |
| "Let me fetch the Jira ticket / explore the code first" | Context-loader handles project scanning. Jira context belongs in the brainstorm phase, not before Phase 0. Start with context-loader. |
| "I'll use EnterPlanMode to think this through" | The pipeline IS the thinking structure. DO NOT enter plan mode. INVOKE context-loader and let the pipeline phases do the thinking. |

## Transition

WHEN this pipeline completes:
- DISPLAY the PIPELINE COMPLETE summary.
- DO NOT ask "what would you like to do next?"
- DO NOT suggest additional work unless the user asks.
- The pipeline is finished. The session can end or the user can start a new task.
