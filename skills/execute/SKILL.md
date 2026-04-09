---
name: execute
description: Use when the plan is approved and ready for implementation. Dispatches subagents per the Execution Waves table, enforces TDD (RED→GREEN→REFACTOR), and gates advancement on all tests passing.
---

# Execute (Phase 4)

Implement the approved plan through disciplined, test-driven development. Use parallel subagents for independent tasks. Every line of production code is justified by a failing test.

## Prerequisites

- `02-plan.md` must exist in the active spec directory. To find it: check the most recent `docs/YYYY-MM-DD-*/` directory first, then fall back to `docs/spec/`. This is the authoritative implementation reference.
- `03-revision.md` must exist in the same spec directory. Amendments in the revision take precedence over the original plan.
- Human approval must have been given (Phase 3.8 gate passed). If you are not certain approval was given, ask.
- **Spec directory:** If the pipeline orchestrator provided a spec directory path, use it. Otherwise, find it by checking the most recent `docs/YYYY-MM-DD-*/` directory, falling back to `docs/spec/`.
- Project context from Phase 0 must be available. If not, run `/context` first.

If any prerequisite is missing, STOP. Tell the user what is missing and how to fix it.

## Process

Execute these phases in strict order. Do not skip phases. Do not begin coding without completing validation.

### Phase 4.1 -- Parse the Plan

1. Read `02-plan.md` from the active spec directory
2. Read `03-revision.md` from the active spec directory -- amendments here override the original plan
3. For each implementation step, extract:
   - Title
   - Files to create or modify
   - Dependencies (which steps must complete first)
   - Acceptance criteria
   - Test strategy
   - Scope estimate (XS/S/M)
   - Parallelization classification ([PARALLEL] or [SEQUENTIAL])
4. Extract the Execution Waves table
5. Build the dependency graph in memory: a directed acyclic graph where nodes are steps and edges are dependencies

If the revision document modified any step, use the revised version. The revision always wins.

### Phase 4.2 -- Validate Before Starting

Before writing a single line of code, verify:

1. **Acyclicity:** The dependency graph has no cycles. Trace every path. If a cycle exists, STOP and report.
2. **Parallel safety:** No two [PARALLEL] steps in the same wave share files. Compare file lists for every parallel pair within each wave. If overlap exists, STOP and report.
3. **Test runner:** The test runner exists and works. Run the project's test command. It should either pass (existing tests green) or report "no tests found" (empty suite). If it errors with a configuration problem, fixing the test runner IS the first task -- execute it before any wave.
4. **Environment:** Required dependencies are installed. The project builds. If it does not build, STOP and report.

If any validation fails, STOP and report the specific issue. Do NOT attempt to fix structural problems silently. The human must know.

### Phase 4.3 -- Execute Wave by Wave

For each wave in the Execution Waves table, in order:

```
Wave N:
  1. Identify all steps in this wave
  2. For steps marked [PARALLEL] that share no files:
     → Dispatch one subagent per step CONCURRENTLY
     → Each subagent receives:
       - Project context (from Phase 0)
       - Full task text (from the plan -- the complete step, not a file reference)
       - TDD rules (load the full content of skills/tdd/SKILL.md — do not summarize from memory)
       - List of files it may touch (scope boundary)
     → Wait for ALL subagents in this wave to complete
  3. For steps marked [SEQUENTIAL]:
     → Execute one at a time, inline or via single subagent
     → Wait for each to complete before starting the next
  4. After all steps in the wave complete:
     → Run the FULL test suite
     → If any test fails:
       a. Identify which step caused the failure (check which files were touched)
       b. Dispatch a fix to the responsible subagent
       c. Re-run the full test suite
     → Run the project's code formatter on all files modified in this wave
       (e.g., `npx prettier --write`, `python -m black`, `gofmt -w`).
       This prevents external watchers from reverting changes between phases.
     → Do NOT proceed to the next wave until ALL tests pass
```

The wave gate is absolute. A single failing test blocks all subsequent waves. Fix it or escalate.

### Phase 4.4 -- Subagent Protocol

Every subagent MUST follow the TDD cycle defined in `skills/tdd/SKILL.md`. Load that file and inject its core sections (The Iron Law, The Cycle, Step-Back Protocol, The Delete Rule) into every subagent prompt. Do NOT summarize or paraphrase the TDD rules from memory — load the current file to prevent version drift.

The following is a summary for the orchestrator's reference only. Subagents receive the full TDD rules from the source file.

**RED -- Write a failing test:**
1. Write a test for the first acceptance criterion
2. Run the test
3. Confirm it FAILS
4. If it passes, the test is wrong -- it is not testing the right thing. Fix the test.

**GREEN -- Write minimum code to pass:**
1. Write the minimum production code to make the failing test pass
2. Run the test
3. Confirm it PASSES
4. Do not write more code than needed. Do not "future-proof." Do not add features.

**REFACTOR -- Clean up while green:**
1. Refactor the code for clarity, removing duplication
2. Run all tests
3. Confirm they still PASS
4. If any test fails during refactoring, undo the refactoring and try again

**Repeat** for each acceptance criterion until the step is complete.

Each subagent reports back with exactly one status:

- **DONE** -- Task complete. All acceptance criteria met. All tests passing. Include a summary of what was implemented and the test count.
- **DONE_WITH_CONCERNS** -- Task complete, all tests passing, but flagging a potential issue. Describe the concern in detail: what might break, under what conditions, and what the suggested remedy is.
- **NEEDS_CONTEXT** -- Blocked on missing information. State exactly what you need: which file, which type, which API contract, which configuration value. Be specific.
- **BLOCKED** -- Cannot proceed. Explain why: dependency not available, contradictory requirements, infrastructure missing, permission denied. Be specific.

Use the full subagent prompt template from `references/implementer-prompt.md`.

Every subagent report MUST end with a structured result block for machine-parseable orchestration. See the full format in `references/implementer-prompt.md`.

### Phase 4.5 -- Handle Subagent Failures

Process each subagent report:

- **DONE:** Proceed to the next step or wave gate.
- **DONE_WITH_CONCERNS:** Log the concern in a running list. Proceed. Review all concerns during the final code review phase.
- **NEEDS_CONTEXT:** Provide the requested context. Re-dispatch the subagent with the additional information. If the context does not exist, escalate to the human.
- **BLOCKED:** Escalate to the human immediately. Do NOT attempt to work around a block without human input.

**The Step-Back Protocol:** When a subagent fails repeatedly on the same task:

**Strike 1:** Fix the specific error and retry.
**Strike 2 — STEP-BACK:** Before retrying, the subagent MUST:
  1. STOP coding
  2. Document in implementation notes:
     - What was tried and why it failed (both attempts)
     - What assumption might be wrong
     - Is the plan step ambiguous or contradictory?
  3. Try a fundamentally different approach (not a variation of the same idea)
**Strike 3 — ESCALATE:** If the different approach also fails, escalate to the human with:
  - The task description
  - All three failure attempts with reasoning
  - The step-back analysis from Strike 2
  - Your assessment of whether this is an implementation problem or a plan problem

**Circuit Breaker:** If the escalation reveals a diagnosis or plan problem (not an implementation problem), the orchestrator may re-dispatch a targeted investigation or revision before retrying execution.

### Phase 4.6 -- Final Test Gate

After ALL waves are complete:

1. Run the project's code formatter (if configured) on all files modified during execution — e.g., `npx prettier --write <files>`, `python -m black <files>`, `gofmt -w <files>`. This prevents formatting violations from causing test failures or triggering external tool interference.
2. Run the FULL test suite
3. Run the linter (if the project has one configured)
4. Run the type checker (if the project uses TypeScript, mypy, etc.)

**If everything passes:**
```
All [N] tests pass. Linter clean. Types valid.
Implementation complete. Ready for code review (/code-review).
```

**If anything fails:**
1. Identify the failure
2. Fix it (one attempt)
3. Re-run the full suite
4. If it fails again, try once more (second attempt)
5. If it fails a third time, escalate:
```
Final test gate failed after 3 attempts.
Failing: [test name / lint rule / type error]
Attempted fixes: [what was tried]
The implementation is incomplete. Human intervention needed.
```

### Phase 4.7 -- Collect Implementation Notes

After all waves complete and the final test gate passes, collect implementation notes from all subagents:

1. For each subagent that reported DONE or DONE_WITH_CONCERNS, extract the Implementation Notes section from its report.
2. Compile all notes into a single document organized by wave and step.
3. Pass the compiled notes to Phase 5 (Code Review) as additional context for reviewers.

Implementation notes include:
- **Approach:** What was done and why
- **Rejected alternatives:** What was considered and discarded, with reasons
- **Files changed:** List with one-line rationale each
- **Concerns:** Low-confidence areas, deferred edge cases, potential issues
- **Hotspots:** Files or functions where the reviewer should focus hardest

These notes help reviewers understand intent and focus their attention on the areas most likely to contain issues.

## Subagent Prompt Template

Use this structure when dispatching implementation subagents. The full template with anti-patterns and detailed instructions is in `references/implementer-prompt.md`.

```
# Task: [step title from plan]

## Project Context
[injected from Phase 0 -- stack, conventions, key commands]

## Your Assignment
[full text of the implementation step from the plan, including acceptance criteria and test strategy]

## Files You May Touch
[explicit list of files from the step -- do NOT modify files outside this list]

## TDD Rules
[Injected from skills/tdd/SKILL.md — include The Iron Law, The Cycle (RED/GREEN/REFACTOR/COMMIT),
the Step-Back Protocol, and The Delete Rule. Load the file at dispatch time; do not rely on memory.]

## Scope Boundary
Do NOT:
- Modify files outside your assignment
- Add features not in your assignment
- Add comments explaining obvious code
- "Clean up" adjacent code
- Install dependencies not specified in your assignment
- Refactor code unrelated to your task

## Report
When done, report exactly one of:
  DONE — [summary of what was implemented, test count]
  DONE_WITH_CONCERNS — [summary + concern description]
  NEEDS_CONTEXT — [what specific information you need]
  BLOCKED — [why you cannot proceed]
```

## Rules

- NEVER dispatch parallel subagents for steps that share files. Even if the plan says [PARALLEL], verify file lists at runtime before dispatching. The runtime check overrides the plan.
- Subagents do NOT communicate with each other. All coordination goes through the orchestrator. If subagent A produces output that subagent B needs, the orchestrator passes it.
- Each subagent starts fresh. No inherited session context. No leftover state. Everything the subagent needs must be in its prompt.
- If the project has no test runner yet, setting it up IS the first task. Execute it before any plan wave. A plan without a test runner is not implementable under TDD.
- Do NOT combine steps. Each step is dispatched as a single unit. If two steps seem related, they are still separate dispatches.
- Do NOT reorder waves. Wave 1 before Wave 2 before Wave 3. Always.

## Anti-Patterns

### "Let Me Just Write All the Code First"
No. TDD means test first, code second. If a subagent produces code without a failing test, reject the output and re-dispatch.

### "The Tests Are Slowing Us Down"
Tests are not overhead. They are the delivery mechanism. Code without tests is not done. A fast implementation that breaks in production is not fast.

### "I'll Run Tests at the End"
Tests run after every RED, every GREEN, every REFACTOR. Not at the end. If you accumulate code without running tests, you accumulate risk.

### "This Step Is Too Small for a Subagent"
If it is in the plan, it gets the full protocol: dispatch, TDD, report. XS steps are fast to implement but still follow the cycle. No shortcuts for small steps.

### "The Wave Gate Is Too Strict"
The wave gate exists because later waves depend on earlier waves being correct. If Wave 1 has a bug, Wave 2 builds on that bug. Fix it now.

See `references/testing-anti-patterns.md` for detailed testing anti-patterns with code examples.

### "The External Formatter Will Handle It"
No. Run the formatter yourself after writing code. External formatters (editor watchers, save hooks) can silently revert your changes if they detect violations. Format proactively, not reactively.

## Handoff

Implementation complete. All tests pass. Proceed to `/code-review` for structured review of all changes.
