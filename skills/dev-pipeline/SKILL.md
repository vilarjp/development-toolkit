---
name: dev-pipeline
description: Use when building a new feature, implementing a change, or starting a full development cycle. Orchestrates the complete pipeline from context loading through commit with human approval gates and test gates.
---

# Development Pipeline Orchestrator

This is the master skill. It runs the full development pipeline from idea to committed code. Every phase is executed in strict order. No phase is skipped. No gate is bypassed.

**Trigger:** `/dev` or any request to build a feature, implement a change, or start a development cycle.

**Resolve mode trigger:** If the user's request describes a bug, error, regression, or broken behavior (keywords: "fix", "bug", "broken", "error", "not working", "regression", "crash", "failing"), the pipeline enters **resolve mode** — a shortened pipeline optimized for bug fixes. See the "Resolve Mode" section below.

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

### Resolve Mode Pipeline

```
Phase 0 (Context)  ->  Phase 1R (Diagnosis)  ->  HUMAN APPROVAL  ->  Phase 4R (Fix)  ->  TEST GATE  ->  Phase 5 (Review)  ->  Phase 6 (Commit)
  | sonnet              | opus, 10k think        (diagnosis review)   | sonnet, 5k think                   | sonnet, 5k think     | sonnet, 5k think
  in-memory context     01-diagnosis.md                                source + tests                       04-code-review.md      git history
```

Resolve mode skips Phase 2 (Planning) and Phase 3 (Revision). The diagnosis document serves as both brainstorm and plan.

## Progress Labeling (Mandatory)

At the start of every phase transition, output a progress label before taking any action. Format:

```
▶ Current Step: Phase [N] — [Phase Name]
  Skill: [skill being invoked, or "—" if none]
  Agent: [subagent type, or "—" if inline]
```

This label must appear before the first tool call of each phase. It is not optional. It is not "nice to have." It exists so the user can track pipeline progress without inferring it from prose.

## Mandatory Skill Invocation (Non-Negotiable)

Each pipeline phase maps to a specific skill. **You MUST invoke that skill using the `Skill` tool.** Do not replicate the skill's steps manually. Do not "follow the spirit" of the skill without loading it. The `Skill` tool loads the current version of the skill — your memory of what the skill does may be stale or incomplete.

| Phase | Skill to invoke via `Skill` tool |
|-------|----------------------------------|
| 0 | `joao-toolkit:context-loader` |
| 1 | `joao-toolkit:brainstorm` |
| 2 | `joao-toolkit:plan` |
| 3 | `joao-toolkit:revision` |
| 4 / 4R | `joao-toolkit:execute` (which internally enforces `joao-toolkit:tdd`) |
| 5 | `joao-toolkit:code-review` |
| 6 | `joao-toolkit:commit-push` |

**If you find yourself executing a phase's logic without having called `Skill` for that phase, STOP. You are violating the pipeline protocol. Go back and invoke the skill.**

## Pipeline Execution Protocol

When `/dev` is invoked with a user request, execute the following sequence exactly. Do not reorder, skip, or combine phases.

### Phase 0 -- Context Loading

Invoke the `context-loader` skill (`skills/context-loader/SKILL.md`).

- Scan project structure, config files, CLAUDE.md, conventions, and existing specs.
- Store the output as the **project context block**. This block is injected into every subsequent phase.
- This phase is fast and cheap. Do not skip it. Do not substitute cached context from a prior session.

If context loading fails (missing project root, no readable files), STOP. Report the failure and ask the user to verify the working directory.

When context loading completes, proceed immediately to Phase 1.

### Phase 1 -- Brainstorm

Invoke the `brainstorm` skill (`skills/brainstorm/SKILL.md`) with the user's original request and the project context block from Phase 0.

The brainstorm skill will:
1. Ask up to 5 clarifying questions (one at a time, multiple-choice preferred)
2. Explore the problem space: problem statement, goals, non-goals, assumptions
3. Generate 2-3 genuinely different options with trade-offs
4. Recommend a direction with rationale
5. Self-review for completeness and consistency
6. Write `01-brainstorm.md` in the per-session spec directory (format: `docs/YYYY-MM-DD-short-description/`)

Wait for the brainstorm to complete. Do not proceed until `docs/spec/01-brainstorm.md` exists and the user has confirmed the recommended direction.

### Phase 2 -- Planning

Invoke the `plan` skill (`skills/plan/SKILL.md`) with the brainstorm output and project context.

The plan skill will:
1. Read `docs/spec/01-brainstorm.md` and verify alignment with project conventions
2. Design technical architecture (data models, module boundaries, API contracts, state management)
3. Decompose into thin vertical slices with acceptance criteria and test strategies
4. Classify each step as [PARALLEL] or [SEQUENTIAL]
5. Construct the Execution Waves table
6. Define overall test strategy and risk analysis
7. Self-review for completeness and acyclicity
8. Write `docs/spec/02-plan.md`

Wait for the plan to complete. Do not proceed until `docs/spec/02-plan.md` exists.

### Phase 3 -- Revision

Invoke the `revision` skill (`skills/revision/SKILL.md`).

The revision skill will:
1. Read both `01-brainstorm.md` and `02-plan.md` completely
2. Cross-reference brainstorm goals to plan steps (every goal maps to at least one step)
3. Verify non-goals are not accidentally addressed
4. Check internal plan consistency: dependency graph acyclicity, parallel safety, file path consistency
5. Verify completeness: orphaned goals, naked steps, unmitigated risks
6. Check feasibility against project context: pattern compatibility, dependency availability, path conventions
7. Apply adjustments to source documents (Critical and Important items fixed in place, marked with `<!-- REVISED -->` comments)
8. Write `docs/spec/03-revision.md`

Wait for the revision to complete. Do not proceed until `docs/spec/03-revision.md` exists.

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

Please review and confirm:
  -> "approve" or "proceed" to continue to the next phase
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

**YOU MUST** invoke the `execute` skill via `Skill: joao-toolkit:execute` before writing any code. Do not manually replicate TDD steps. Do not dispatch subagents without loading the skill first. The skill orchestrates execution waves, TDD enforcement, and failure handling.

The execute skill will:
1. Parse `02-plan.md` (as amended by `03-revision.md`) into the dependency graph and Execution Waves table
2. Validate: acyclic dependencies, no shared files in parallel steps, test runner works, project builds
3. Execute wave by wave:
   - [PARALLEL] steps: dispatch one subagent per step concurrently (each receives project context, full task text, TDD rules, file scope boundary)
   - [SEQUENTIAL] steps: execute one at a time in order
   - After each wave: run full test suite, fix failures before advancing
4. Enforce TDD for every subagent: RED (failing test) -> GREEN (minimum code) -> REFACTOR (clean up while green)
5. Handle subagent failures: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED
6. Three-Strike Rule: 3 failures on the same task -> escalate to human

The plan (`docs/spec/02-plan.md` as amended by `docs/spec/03-revision.md`) is the authoritative source of truth for execution. Subagents implement what the plan says. They do not add features, remove features, or reinterpret requirements.

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

**YOU MUST** invoke the `code-review` skill via `Skill: joao-toolkit:code-review` before dispatching any reviewer agents. Do not dispatch reviewer subagents directly. The skill handles diff partitioning, agent dispatch, result collection, deduplication, and severity classification. Bypassing it produced degraded results in past sessions.

The code-review skill will:
1. Compute the full diff against the base branch
2. Partition the diff into scope areas (frontend, backend, data, tests, config)
3. Dispatch parallel reviewer subagents:
   - **Plan Alignment Reviewer** -- every planned feature present, no unplanned additions, acceptance criteria met
   - **Code Quality Reviewer** -- correctness, readability, architecture, security, performance
   - **Convention Reviewer** -- naming, file placement, import patterns, styling consistency
   - **Test Reviewer** -- coverage of acceptance criteria, test quality, anti-patterns, pyramid compliance
   - **Security Reviewer** -- dispatched conditionally when diff touches auth, user input, APIs, data storage, secrets, or external calls
4. Collect, deduplicate, and classify findings by severity (P0/P1/P2/P3)
5. Write `docs/spec/04-code-review.md`

### HUMAN APPROVAL GATE #2 (Conditional)

This gate triggers ONLY if P0 (critical) issues are found.

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

**Handling responses:**
- "fix": resolve each P0 issue, then re-run Phase 5 (code review) to confirm the fixes. Do not skip the re-review.
- "override": proceed to Phase 6. Log the override decision in `04-code-review.md` with a note that the human accepted the risk.
- "stop": halt the pipeline. Report current state.

**If no P0 issues exist:** skip this gate entirely and proceed directly to Phase 6.

### Phase 6 -- Commit and Push

**YOU MUST** invoke the `commit-push` skill via `Skill: joao-toolkit:commit-push` before running any git commands. Do not run `git add`, `git commit`, or `git push` directly. The skill enforces branch safety, pre-commit verification, logical commit splitting, testing scenario documentation, and rebase-before-push. Skipping it caused a user to catch missing testing scenarios in a past session.

The commit-push skill will:
1. Verify the current branch is NOT master/main (create a feature branch if needed, derived from brainstorm topic)
2. Run pre-commit verification: test suite, linter, debug artifact scan, secrets scan, scope verification
3. Split changes into logical commits (maximum 3 per pipeline run)
4. Write conventional commit messages (or adapt to the project's existing commit style)
5. Rebase onto the latest default branch
6. Push with `-u` flag to set upstream tracking

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

## Resolve Mode

When the user's request describes a bug, error, or regression, the pipeline enters resolve mode. This is a shortened pipeline optimized for bug fixes.

### Resolve Mode Skill Invocation Table

In resolve mode, fewer phases run. This table is the authoritative reference for which skills to invoke:

| Phase | Skill to invoke | Notes |
|-------|----------------|-------|
| 0 | `joao-toolkit:context-loader` | Same as feature mode |
| 1R | `joao-toolkit:brainstorm` (diagnosis mode) | Produces `01-diagnosis.md`, NOT `01-brainstorm.md` |
| 4R | `joao-toolkit:execute` | Reads `01-diagnosis.md` instead of `02-plan.md`. Internally enforces TDD. |
| 5 | `joao-toolkit:code-review` | Same as feature mode |
| 6 | `joao-toolkit:commit-push` | Same as feature mode |

**Skipped in resolve mode:** Phase 2 (`plan`), Phase 3 (`revision`).

**If TRIVIAL escape hatch is approved:** Skip Phases 4R and 5. Go directly from diagnosis to Phase 6 (`commit-push`). See the Trivial Escape Hatch section below.

**The skill for Phase 4R is `joao-toolkit:execute`, NOT `joao-toolkit:tdd`.** The execute skill internally loads and enforces TDD. Invoking `tdd` directly bypasses execution orchestration (dependency graph parsing, wave management, failure handling).

### Phase 0 -- Context Loading (same as feature mode)

Invoke the `context-loader` skill. No changes from the feature pipeline.

### Phase 1R -- Diagnosis

Invoke the `brainstorm` skill in **diagnosis mode** (see `skills/brainstorm/SKILL.md` Diagnosis Mode section).

The brainstorm skill will:
1. Dispatch the `resolve-investigator` agent for structured bug investigation
2. Produce `01-diagnosis.md` in the per-session spec directory with: bug description, investigation trail, hypotheses table, root cause, reproduction test, hotspots, suggested fix
3. Classify severity: TRIVIAL, STANDARD, or COMPLEX
4. Present the complexity-based checkpoint strategy (same as feature mode)

Wait for the diagnosis to complete. Present the diagnosis for human approval:

```
=====================================================================
  DIAGNOSIS COMPLETE — Review Required Before Proceeding
=====================================================================

Root cause: [one-sentence summary]
Severity:   [TRIVIAL / STANDARD / COMPLEX]
Fix:        [one-sentence summary of suggested fix]
Hotspots:   [file:line list]

Diagnosis document: docs/YYYY-MM-DD-<topic>/01-diagnosis.md

[If TRIVIAL]:
  This appears to be a trivial fix. Options:
  -> "apply" or "proceed" — apply fix directly and commit [Recommended]
  -> "full pipeline" — run full resolve pipeline (execute + review + commit)

[If STANDARD or COMPLEX]:
  -> "approve" or "proceed" to continue to Phase 4R (Fix)
  -> "changes needed" with specifics to revise
  -> "stop" to pause the pipeline

Model override (optional — inherited model is used by default):
  -> "model <name>" to change the model for subagents in execution/review
     (e.g., "model opus" for complex logic, "model haiku" for boilerplate)
     Valid values: opus, sonnet, haiku

=====================================================================
```

**Trivial Escape Hatch:** If the diagnosis severity is TRIVIAL AND the user approves the trivial path ("apply", "proceed", or any approval keyword):

The pipeline enters **TRIVIAL mode**. The following phases are **LOCKED OUT** — do NOT invoke them:
- Phase 4R (Fix) — DO NOT invoke `joao-toolkit:execute` or `joao-toolkit:tdd`
- Phase 5 (Code Review) — DO NOT invoke `joao-toolkit:code-review` or dispatch reviewer agents

**TRIVIAL mode steps (the ONLY steps allowed):**
1. Apply the fix directly (the suggested fix from `01-diagnosis.md`)
2. Write the regression test (the reproduction test from `01-diagnosis.md`)
3. Run the full test suite
4. If tests pass: proceed directly to Phase 6 — invoke `Skill: joao-toolkit:commit-push`
5. If tests fail: fix and retry up to 3 times. If still failing, escalate to user.

**TRIVIAL mode guard:** If you find yourself about to invoke `joao-toolkit:execute`, `joao-toolkit:tdd`, `joao-toolkit:code-review`, or dispatch any reviewer agent after the trivial escape hatch was approved — STOP. You are violating TRIVIAL mode. The user approved the shortcut. Respect it.

If the user declines the trivial path ("full pipeline"): continue with the full resolve pipeline below (Phase 4R -> TEST GATE -> Phase 5 -> Phase 6).

### Phase 4R -- Fix (Prove-It TDD)

**YOU MUST** invoke the `execute` skill via `Skill: joao-toolkit:execute` before writing any fix code. The skill enforces TDD discipline (RED→GREEN→REFACTOR). Do not manually follow TDD steps without loading the skill first.

Invoke the skill with the following modifications:
1. Read `01-diagnosis.md` instead of `02-plan.md`
2. The reproduction test from the diagnosis IS the first RED test — do not write a new one
3. Follow the Prove-It pattern from the TDD skill: reproduce, confirm failure, fix, verify, run full suite
4. The fix must be minimal — address the root cause and nothing else
5. A regression test must exist when done (the reproduction test serves as this)

After the fix passes all tests, proceed through the TEST GATE (same as feature mode).

### Phases 5 and 6 (same as feature mode)

Code review and commit/push proceed identically to the feature pipeline.

### Resolve Mode Rules

1. **Do NOT brainstorm solutions for bugs.** The diagnosis document identifies the root cause and suggests a fix. Brainstorming options is for features, not bugs.
2. **Do NOT plan or revise for bugs.** The diagnosis serves as both investigation and plan. The fix plan is embedded in the diagnosis.
3. **The reproduction test is mandatory.** If the bug cannot be reproduced in a test, document why in the diagnosis and proceed with caution.
4. **Minimal fix only.** Do not refactor, clean up, or improve adjacent code during a bug fix. One bug, one fix, one test.
5. **If the fix reveals a deeper architectural problem**, STOP. Escalate to the user. The bug may require a feature-level pipeline run instead of a resolve mode fix.

## Standalone Phase Execution

Each phase can be invoked independently via its slash command:

| Command | Skill | Standalone Behavior |
|---------|-------|-------------------|
| `/context` | context-loader | Run Phase 0 only. No prerequisites. |
| `/brainstorm` | brainstorm | Requires project context. If missing, runs `/context` first. |
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

**Detection logic (check in order):**

1. `docs/spec/04-code-review.md` exists -> resume at Phase 6 (Commit).
2. Code changes exist (modified files beyond spec docs) but no `04-code-review.md` -> resume at Phase 5 (Code Review).
3. `docs/spec/03-revision.md` exists -> resume at Gate #1 (ask for approval to start implementation).
4. `docs/spec/02-plan.md` exists -> resume at Phase 3 (Revision).
5. `docs/spec/01-brainstorm.md` exists -> resume at Phase 2 (Planning).
   (Resolve mode: `01-diagnosis.md` exists instead -> resume at Phase 4R (Fix), presenting the diagnosis for approval first.)
6. No artifacts exist -> start from Phase 0.

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

If the user says "restart," archive existing specs by renaming `docs/spec/` to `docs/spec-archived-<timestamp>/` and start fresh from Phase 0.

## Rules

These rules apply to the orchestrator at all times. They are not suggestions.

1. **NEVER skip a phase in the full pipeline.** Phase 0 through Phase 6, in order. "This is a simple change" does not justify skipping brainstorm and plan. Simple changes are fast to brainstorm and plan. They are not exempt.

2. **NEVER proceed past a gate without explicit human approval.** Gate #1 requires approval before implementation. Gate #2 requires approval when critical issues exist. Silence is not approval. Ambiguity is not approval. Only explicit confirmation is approval.

3. **NEVER write code before Phase 4.** Phases 0-3 are thinking phases. They produce documents, not code. If you find yourself writing function bodies, component JSX, database queries, or any implementation during Phases 0-3, STOP. You have crossed a phase boundary.

4. **The plan is the source of truth for execution.** `docs/spec/02-plan.md` as amended by `docs/spec/03-revision.md` is the authoritative reference. Subagents implement what the plan says. The orchestrator does not reinterpret, expand, or reduce the plan.

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
| "The trivial fix should still go through TDD/review for safety" | The user approved the trivial escape hatch. That IS the safety decision. Running Phases 4R and 5 after approval wastes tokens and time on a fix the user already validated. TRIVIAL mode is LOCKED — do not invoke execute, tdd, or code-review. |
