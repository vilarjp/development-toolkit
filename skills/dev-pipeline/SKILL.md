---
name: dev-pipeline
description: Use when building a new feature, implementing a change, or starting a full development cycle. Orchestrates the complete pipeline from context loading through commit with human approval gates and test gates.
---

# Development Pipeline Orchestrator

This is the master skill. It runs the full development pipeline from idea to committed code. Every phase is executed in strict order. No phase is skipped. No gate is bypassed.

**Trigger:** `/dev` or any request to build a feature, implement a change, or start a development cycle.

**Bug fix detection:** If the user's request describes a bug, error, regression, or broken behavior (keywords: "fix", "bug", "broken", "error", "not working", "regression", "crash", "failing"), delegate to the resolve pipeline instead: invoke `Skill: development-toolkit:resolve-pipeline` and stop. Do not run this feature pipeline for bug fixes.

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

**Step 2 — Invoke.** Call the `Skill` tool for the phase's skill. This is non-negotiable. Do not replicate a skill's steps manually — the `Skill` tool loads the current version and your memory of what it does may be stale.

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

When `/dev` is invoked with a user request, execute the following sequence exactly. Do not reorder, skip, or combine phases.

**FIRST ACTION — Non-Negotiable:**
When this skill is loaded, your VERY FIRST action is to invoke `Skill: development-toolkit:context-loader`. Do NOT read the user's request in depth first. Do NOT explore the codebase. Do NOT fetch Jira tickets. Do NOT enter plan mode. Do NOT write code. Invoke context-loader. Then proceed to Phase 1.

### Phase 0 -- Context Loading

Invoke `Skill: development-toolkit:context-loader`.

Store the output as the **project context block** — it is injected into every subsequent phase. Do not skip this phase. Do not substitute cached context from a prior session.

If context loading fails, STOP. Report the failure and ask the user to verify the working directory.

### Phase 1 -- Brainstorm

Invoke `Skill: development-toolkit:brainstorm` with the user's original request and the project context block from Phase 0.

Wait for completion. Verify `01-brainstorm.md` exists in the per-session spec directory. Do not proceed until the user has confirmed the recommended direction.

### Phase 2 -- Planning

Invoke `Skill: development-toolkit:plan` with the brainstorm output and project context.

Wait for completion. Verify `02-plan.md` exists in the spec directory.

### Phase 3 -- Revision

Invoke `Skill: development-toolkit:revision`.

Wait for completion. Verify `03-revision.md` exists in the spec directory.

### HUMAN APPROVAL GATES (Complexity-Based)

The number and placement of approval gates depends on the complexity classification from Phase 1 (brainstorm). The user chose a checkpoint strategy during the brainstorm phase.

**Strategy A (LOW complexity):** Single gate after Phase 3 (Revision).
**Strategy B (MEDIUM complexity):** Gate after Phase 2 (Planning) and after Phase 3 (Revision).
**Strategy C (HIGH complexity):** Gate after Phase 1 (Brainstorm), after Phase 2 (Planning), and after Phase 3 (Revision).

When a gate fires, present this message:

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
- "changes needed" or any feedback with specifics: apply the requested changes to the relevant documents, then re-present the gate. Do not re-run the full phase unless the changes are structural.
- "stop": halt the pipeline. Report current state and how to resume later.
- Silence or ambiguous response: ask for clarification. Do NOT interpret silence as approval.

These gates are non-negotiable. No rationalization bypasses them. "The user seems eager" does not bypass them. "The plan is straightforward" does not bypass them.

**The post-Revision gate is always present, regardless of strategy.** The complexity-based strategy may add earlier gates but never removes the final pre-implementation gate.

### Phase 4 -- Execution

Invoke `Skill: development-toolkit:execute`. Do not write any code before invoking this skill. Do not dispatch subagents without loading the skill first.

The plan (`02-plan.md` as amended by `03-revision.md`) is the authoritative source of truth. Subagents implement what the plan says — they do not add, remove, or reinterpret requirements.

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
- Do NOT proceed to code review with failing tests.

### Phase 5 -- Code Review

Invoke `Skill: development-toolkit:code-review`. Do not dispatch reviewer subagents directly — the skill handles diff partitioning, agent dispatch, result collection, deduplication, and severity classification.

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
- "fix": resolve each P0 issue, then re-run Phase 5 (code review) to confirm the fixes. Do not skip the re-review.
- "override": proceed to Phase 6. Log the override decision in `04-code-review.md` with a note that the human accepted the risk.
- "stop": halt the pipeline. Report current state.

**If no P0 issues exist:** skip this gate entirely and proceed directly to Phase 6.

### Phase 6 -- Commit and Push

Invoke `Skill: development-toolkit:commit-push`. Do not run `git add`, `git commit`, or `git push` directly — the skill enforces branch safety, pre-commit verification, logical commit splitting, and rebase-before-push.

### Pipeline Complete

After Phase 6 succeeds, present this summary:

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

Each phase can be invoked independently via its slash command:

| Command | Skill | Standalone Behavior |
|---------|-------|-------------------|
| `/context` | context-loader | Run Phase 0 only. No prerequisites. |
| `/brainstorm` | brainstorm | Requires project context. If missing, runs `/context` first. |
| `/diagnose` | diagnosis | Requires project context. Produces `01-diagnosis.md`. |
| `/plan` | plan | Requires `01-brainstorm.md`. If missing, tells user to run `/brainstorm`. |
| `/revise` | revision | Requires `01-brainstorm.md` and `02-plan.md`. Reports which is missing. |
| `/execute` | execute | Requires `02-plan.md`, `03-revision.md`, and human approval. |
| `/review` | code-review | Requires all tests passing. Runs test suite to verify. |
| `/commit` | commit-push | Requires `04-code-review.md` with no unresolved P0 issues. |

When invoked standalone:
1. Load project context fresh via `/context` (unless already available in the current session).
2. Check prerequisites. If a prerequisite artifact is missing, tell the user which phase to run first. Do NOT silently generate the missing artifact.
3. Execute the single phase and stop. Do not auto-advance to subsequent phases.

## Resume and Recovery

If the pipeline is interrupted (session ends, user stops, crash), determine the resume point from existing artifacts when `/dev` is invoked again:

**Detection logic:** Find the most recent per-session spec directory (see AGENTS.md "Spec directory convention"). Also check `docs/spec/` for legacy artifacts. Then check in order:

1. `04-code-review.md` exists -> resume at Phase 6 (Commit).
2. Code changes exist (modified files beyond spec docs) but no `04-code-review.md` -> resume at Phase 5 (Code Review).
3. `03-revision.md` exists -> resume at Gate #1 (ask for approval to start implementation).
4. `02-plan.md` exists -> resume at Phase 3 (Revision).
5. `01-brainstorm.md` exists -> resume at Phase 2 (Planning).
6. No artifacts exist -> start from Phase 0.

**If `01-diagnosis.md` exists instead of `01-brainstorm.md`:** This is a resolve pipeline run. Delegate to `Skill: development-toolkit:resolve-pipeline` which has its own resume logic.

**Resume protocol:**
1. Run `/context` to load fresh project context (always -- cached context from a dead session is stale).
2. Read all existing spec artifacts to rebuild the pipeline state.
3. Present the resume point to the user:
   ```
   PIPELINE RESUME
   Found existing artifacts:
     [list what exists with status]
   Resuming at: Phase [N] ([name])
   -> "continue" to proceed from here
   -> "restart" to start the pipeline from scratch
   -> "phase N" to jump to a specific phase
   ```
4. Wait for the user to confirm before proceeding. Do NOT auto-resume.

If the user says "restart," archive existing specs by renaming the spec directory to `docs/<dir>-archived-<timestamp>/` and start fresh from Phase 0.

## Rules

These rules apply to the orchestrator at all times. They are not suggestions.

1. **NEVER skip a phase in the full pipeline.** Phase 0 through Phase 6, in order. "This is a simple change" does not justify skipping brainstorm and plan. Simple changes are fast to brainstorm and plan. They are not exempt.

2. **NEVER proceed past a gate without explicit human approval.** Gate #1 requires approval before implementation. Gate #2 requires approval when critical issues exist. Silence is not approval. Ambiguity is not approval. Only explicit confirmation is approval.

3. **NEVER write code before Phase 4.** Phases 0-3 are thinking phases. They produce documents, not code. If you find yourself writing function bodies, component JSX, database queries, or any implementation during Phases 0-3, STOP. You have crossed a phase boundary.

4. **The plan is the source of truth for execution.** `02-plan.md` as amended by `03-revision.md` is the authoritative reference. Subagents implement what the plan says. The orchestrator does not reinterpret, expand, or reduce the plan.

5. **Every line of production code must be justified by a failing test.** TDD is enforced in Phase 4 via the `tdd` skill. No exceptions for "trivial" code, configuration files, or "obvious" implementations.

6. **If any phase fails, diagnose before retrying.** Do not blindly re-run a failed phase. Read the error, understand the cause, fix the input or environment, then retry. Repeating the same action expecting a different result is not a recovery strategy.

7. **Spec artifacts are append-only during execution.** Once Phase 4 begins, `01-brainstorm.md`, `02-plan.md`, and `03-revision.md` are frozen. They may be referenced but not modified. If execution reveals a plan problem, escalate to the human rather than silently editing the plan.

8. **Subagents are stateless and isolated.** Each subagent receives its full context in the dispatch prompt. Subagents do not communicate with each other. All coordination flows through the orchestrator. If subagent A produces output that subagent B needs, the orchestrator passes it.

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
| "I'll use EnterPlanMode to think this through" | The pipeline IS the thinking structure. Do not enter plan mode. Invoke context-loader and let the pipeline phases do the thinking. |
