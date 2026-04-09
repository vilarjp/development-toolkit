---
name: execute
description: Use when the plan is approved and ready for implementation. Dispatches subagents per the Execution Waves table, enforces TDD (RED→GREEN→REFACTOR), and gates advancement on all tests passing.
---

# Execute (Phase 4)

Implement the approved plan through disciplined, test-driven development. Use parallel subagents for independent tasks. Every line of production code is justified by a failing test.

## Prerequisites

- `02-plan.md` MUST exist in the active spec directory. To find it: CHECK the most recent `docs/YYYY-MM-DD-*/` directory first, then fall back to `docs/spec/`. This is the authoritative implementation reference.
- `03-revision.md` MUST exist in the same spec directory. Amendments in the revision take precedence over the original plan.
- Human approval MUST have been given (Phase 3.8 gate passed). If you are not certain approval was given, STOP and ask.
- **Spec directory:** If the pipeline orchestrator provided a spec directory path, use it. Otherwise, FIND it by checking the most recent `docs/YYYY-MM-DD-*/` directory, falling back to `docs/spec/`.
- Project context from Phase 0 MUST be available. If not, RUN `Skill: development-toolkit:context-loader` first.

If any prerequisite is missing, STOP. Tell the user what is missing and how to fix it.

## Process

EXECUTE these phases in strict order. DO NOT skip phases. DO NOT begin coding without completing validation.

### Phase 4.1 -- Parse the Plan

1. READ `02-plan.md` from the active spec directory
2. READ `03-revision.md` from the active spec directory -- amendments here override the original plan
3. For each implementation step, EXTRACT:
   - Title
   - Files to create or modify
   - Dependencies (which steps must complete first)
   - Acceptance criteria
   - Test strategy
   - Scope estimate (XS/S/M)
   - Parallelization classification ([PARALLEL] or [SEQUENTIAL])
4. EXTRACT the Execution Waves table
5. BUILD the dependency graph in memory: a directed acyclic graph where nodes are steps and edges are dependencies

If the revision document modified any step, use the revised version. The revision always wins.

### Phase 4.2 -- Validate Before Starting

Before writing a single line of code, VERIFY:

1. **Acyclicity:** The dependency graph has no cycles. Trace every path. If a cycle exists, STOP and report.
2. **Parallel safety:** No two [PARALLEL] steps in the same wave share files. Compare file lists for every parallel pair within each wave. If overlap exists, STOP and report.
3. **Test runner:** The test runner MUST exist and work. RUN the project's test command. It MUST either pass (existing tests green) or report "no tests found" (empty suite). If it errors with a configuration problem, fixing the test runner IS the first task -- EXECUTE it before any wave.
4. **Environment:** Required dependencies MUST be installed. The project MUST build. If it does not build, STOP and report.

If any validation fails, STOP and report the specific issue. DO NOT attempt to fix structural problems silently. The human MUST know.

### Phase 4.3 -- Execute Wave by Wave

For each wave in the Execution Waves table, in order:

```
Wave N:
  1. IDENTIFY all steps in this wave
  2. For steps marked [PARALLEL] that share no files:
     → DISPATCH one subagent per step CONCURRENTLY
     → Each subagent MUST receive:
       - Project context (from Phase 0)
       - Full task text (from the plan -- the complete step, not a file reference)
       - TDD rules (load the full content of skills/tdd/SKILL.md — do not summarize from memory)
       - List of files it may touch (scope boundary)
     → WAIT for ALL subagents in this wave to complete
  3. For steps marked [SEQUENTIAL]:
     → EXECUTE one at a time, inline or via single subagent
     → WAIT for each to complete before starting the next
  4. After all steps in the wave complete:
     → RUN the FULL test suite
     → If any test fails:
       a. IDENTIFY which step caused the failure (check which files were touched)
       b. DISPATCH a fix to the responsible subagent
       c. RE-RUN the full test suite
     → RUN the project's code formatter on all files modified in this wave
       (e.g., `npx prettier --write`, `python -m black`, `gofmt -w`).
       This prevents external watchers from reverting changes between phases.
     → DO NOT proceed to the next wave until ALL tests pass
```

The wave gate is absolute. A single failing test blocks all subsequent waves. Fix it or escalate.

### Phase 4.4 -- Subagent Protocol

**MANDATORY TDD INJECTION — DO NOT SKIP THIS STEP.**

1. OPEN and READ the file `skills/tdd/SKILL.md` NOW. DO NOT rely on memory of its contents.
2. EXTRACT the following sections verbatim: The Iron Law, The Cycle (RED/GREEN/REFACTOR/COMMIT), the Step-Back Protocol, and The Delete Rule.
3. INJECT these sections into EVERY subagent prompt under the `## TDD Rules` heading.
4. DO NOT paraphrase, summarize, or abbreviate the TDD rules. Copy them exactly.
5. BEFORE dispatching any subagent, VERIFY that the subagent prompt contains the TDD rules section. If it does not, STOP and add them.

If you skip this step, subagents will deviate from TDD discipline. This has caused failures in past sessions.

The following is a summary for the orchestrator's reference only. Subagents receive the full TDD rules from the source file.

**RED -- Write a failing test:**
1. WRITE a test for the first acceptance criterion
2. RUN the test
3. VERIFY it FAILS
4. If it passes, the test is wrong -- it is not testing the right thing. FIX the test.

**GREEN -- Write minimum code to pass:**
1. WRITE the minimum production code to make the failing test pass
2. RUN the test
3. VERIFY it PASSES
4. DO NOT write more code than needed. DO NOT "future-proof." DO NOT add features.

**REFACTOR -- Clean up while green:**
1. REFACTOR the code for clarity, removing duplication
2. RUN all tests
3. VERIFY they still PASS
4. If any test fails during refactoring, UNDO the refactoring and try again

**Repeat** for each acceptance criterion until the step is complete.

Each subagent MUST report back with exactly one status:

- **DONE** -- Task complete. All acceptance criteria met. All tests passing. Include a summary of what was implemented and the test count.
- **DONE_WITH_CONCERNS** -- Task complete, all tests passing, but flagging a potential issue. Describe the concern in detail: what might break, under what conditions, and what the suggested remedy is.
- **NEEDS_CONTEXT** -- Blocked on missing information. State exactly what you need: which file, which type, which API contract, which configuration value. Be specific.
- **BLOCKED** -- Cannot proceed. Explain why: dependency not available, contradictory requirements, infrastructure missing, permission denied. Be specific.

Use the full subagent prompt template from `references/implementer-prompt.md`.

Every subagent report MUST end with a structured result block for machine-parseable orchestration. See the full format in `references/implementer-prompt.md`.

### Phase 4.5 -- Handle Subagent Failures

Process each subagent report:

- **DONE:** PROCEED to the next step or wave gate.
- **DONE_WITH_CONCERNS:** LOG the concern in a running list. PROCEED. REVIEW all concerns during the final code review phase.
- **NEEDS_CONTEXT:** PROVIDE the requested context. RE-DISPATCH the subagent with the additional information. If the context does not exist, ESCALATE to the human.
- **BLOCKED:** ESCALATE to the human immediately. DO NOT attempt to work around a block without human input.

**The Step-Back Protocol:** When a subagent fails repeatedly on the same task:

**Strike 1:** Fix the specific error and retry.
**Strike 2 — STEP-BACK:** Before retrying, the subagent MUST:
  1. STOP coding
  2. Document in implementation notes:
     - What was tried and why it failed (both attempts)
     - What assumption might be wrong
     - Is the plan step ambiguous or contradictory?
  3. Try a fundamentally different approach (not a variation of the same idea)
**Strike 3 — ESCALATE:** If the different approach also fails, ESCALATE to the human with:
  - The task description
  - All three failure attempts with reasoning
  - The step-back analysis from Strike 2
  - Your assessment of whether this is an implementation problem or a plan problem

**Circuit Breaker:** If the escalation reveals a diagnosis or plan problem (not an implementation problem), the orchestrator MUST re-dispatch a targeted investigation or revision before retrying execution.

### Phase 4.6 -- Final Test Gate

After ALL waves are complete:

1. RUN the project's code formatter (if configured) on all files modified during execution — e.g., `npx prettier --write <files>`, `python -m black <files>`, `gofmt -w <files>`. This prevents formatting violations from causing test failures or triggering external tool interference.
2. RUN the FULL test suite
3. RUN the linter (if the project has one configured)
4. RUN the type checker (if the project uses TypeScript, mypy, etc.)

**If everything passes:**
```
All [N] tests pass. Linter clean. Types valid.
Implementation complete. Ready for code review (/code-review).
```

**If anything fails:**
1. IDENTIFY the failure
2. FIX it (one attempt)
3. RE-RUN the full suite
4. If it fails again, try once more (second attempt)
5. If it fails a third time, ESCALATE:
```
Final test gate failed after 3 attempts.
Failing: [test name / lint rule / type error]
Attempted fixes: [what was tried]
The implementation is incomplete. Human intervention needed.
```

### Phase 4.7 -- Collect Implementation Notes

After all waves complete and the final test gate passes, COLLECT implementation notes from all subagents:

1. For each subagent that reported DONE or DONE_WITH_CONCERNS, EXTRACT the Implementation Notes section from its report.
2. COMPILE all notes into a single document organized by wave and step.
3. PASS the compiled notes to Phase 5 (Code Review) as additional context for reviewers.

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

- NEVER dispatch parallel subagents for steps that share files. Even if the plan says [PARALLEL], ALWAYS VERIFY file lists at runtime before dispatching. The runtime check overrides the plan.
- Subagents do NOT communicate with each other. All coordination goes through the orchestrator. If subagent A produces output that subagent B needs, the orchestrator passes it.
- Each subagent starts fresh. No inherited session context. No leftover state. Everything the subagent needs MUST be in its prompt.
- If the project has no test runner yet, setting it up IS the first task. Execute it before any plan wave. A plan without a test runner is not implementable under TDD.
- DO NOT combine steps. Each step MUST be dispatched as a single unit. If two steps seem related, they are still separate dispatches.
- DO NOT reorder waves. Wave 1 before Wave 2 before Wave 3. ALWAYS.

## Anti-Patterns

### "Let Me Just Write All the Code First"
No. TDD means test first, code second. If a subagent produces code without a failing test, REJECT the output and RE-DISPATCH.

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

## Transition

WHEN this skill completes (all waves done, final test gate passed):
- IF running inside a pipeline: RETURN control to the pipeline orchestrator with implementation notes. The orchestrator WILL invoke the code-review skill. DO NOT invoke code-review yourself. DO NOT ask the user what to do next.
- IF running standalone: REPORT implementation complete with test count and implementation notes. INFORM the user: "Implementation complete. All tests pass. Invoke `development-toolkit:code-review` to review the changes."
