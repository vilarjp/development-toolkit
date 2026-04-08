---
name: dev-pipeline
description: Use when building a new feature, implementing a change, or starting a full development cycle. Orchestrates the complete pipeline from context loading through commit with human approval gates and test gates.
---

# Development Pipeline Orchestrator

This is the master skill. It runs the full development pipeline from idea to committed code. Every phase is executed in strict order. No phase is skipped. No gate is bypassed.

**Trigger:** `/dev` or any request to build a feature, implement a change, or start a development cycle.

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

## Model Configuration

| Phase | Skill | Model | Thinking Budget | Runs As |
|-------|-------|-------|----------------|---------|
| 0 | context-loader | claude-sonnet-4-6 | none | inline |
| 1 | brainstorm | claude-opus-4-6 | 10,000 | inline |
| 2 | plan | claude-opus-4-6 | 10,000 | inline |
| 3 | revision | claude-opus-4-6 | 10,000 | inline |
| 4 | execute | claude-sonnet-4-6 | 5,000 | subagents |
| 5 | code-review | claude-sonnet-4-6 | 5,000 | subagents |
| 6 | commit-push | claude-sonnet-4-6 | 5,000 | inline |

Phases 0-3 use the current session (inline). Phases 4 and 5 dispatch parallel subagents. Phase 6 is inline.

## Pipeline Execution Protocol

When `/dev` is invoked with a user request, execute the following sequence exactly. Do not reorder, skip, or combine phases.

### Phase 0 -- Context Loading

Invoke the `context-loader` skill (`skills/context-loader/SKILL.md`).

- Scan project structure, config files, CLAUDE.md, conventions, and existing specs.
- Store the output as the **project context block**. This block is injected into every subsequent phase.
- Model: `claude-sonnet-4-6`, no extended thinking.
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
6. Write `docs/spec/01-brainstorm.md`

Model: `claude-opus-4-6` with thinking budget 10,000 tokens.

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

Model: `claude-opus-4-6` with thinking budget 10,000 tokens.

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

Model: `claude-opus-4-6` with thinking budget 10,000 tokens.

Wait for the revision to complete. Do not proceed until `docs/spec/03-revision.md` exists.

### HUMAN APPROVAL GATE #1

After Phase 3 completes, the pipeline MUST pause. Present this message exactly:

```
=====================================================================
  APPROVAL GATE -- Review Required Before Implementation
=====================================================================

All specification documents are ready for review:

  1. docs/spec/01-brainstorm.md -- Problem exploration and direction
  2. docs/spec/02-plan.md       -- Technical implementation plan
  3. docs/spec/03-revision.md   -- Cross-document review

Please review and confirm:
  -> "approve" or "proceed" to start implementation
  -> "changes needed" with specifics to revise
  -> "stop" to pause the pipeline

  Implementation will NOT begin without your explicit approval.
=====================================================================
```

**Handling responses:**
- "approve", "proceed", "lgtm", "go", "let's go", "looks good", "ship it": proceed to Phase 4.
- "changes needed" or any feedback with specifics: apply the requested changes to the relevant documents, then re-present the gate. Do not re-run the full revision phase unless the changes are structural. For targeted edits, update the documents directly and confirm the changes with the user.
- "stop": halt the pipeline. Report current state and how to resume later.
- Silence or ambiguous response: ask for clarification. Do NOT interpret silence as approval.

This gate is non-negotiable. No rationalization bypasses it. "The user seems eager" does not bypass it. "The plan is straightforward" does not bypass it.

### Phase 4 -- Execution

Invoke the `execute` skill (`skills/execute/SKILL.md`).

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

Model for subagents: `claude-sonnet-4-6` with thinking budget 5,000 tokens.

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

Invoke the `code-review` skill (`skills/code-review/SKILL.md`).

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

Model for subagents: `claude-sonnet-4-6` with thinking budget 5,000 tokens.

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

Invoke the `commit-push` skill (`skills/commit-push/SKILL.md`).

The commit-push skill will:
1. Verify the current branch is NOT master/main (create a feature branch if needed, derived from brainstorm topic)
2. Run pre-commit verification: test suite, linter, debug artifact scan, secrets scan, scope verification
3. Split changes into logical commits (maximum 3 per pipeline run)
4. Write conventional commit messages (or adapt to the project's existing commit style)
5. Rebase onto the latest default branch
6. Push with `-u` flag to set upstream tracking

Model: `claude-sonnet-4-6` with thinking budget 5,000 tokens.

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

Artifacts:
  docs/spec/01-brainstorm.md  -- Problem exploration and direction
  docs/spec/02-plan.md        -- Technical implementation plan
  docs/spec/03-revision.md    -- Cross-document review
  docs/spec/04-code-review.md -- Code review findings

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
