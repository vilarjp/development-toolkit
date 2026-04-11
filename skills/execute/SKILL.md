---
name: execute
description: Use when the plan is approved and ready for implementation. Dispatches subagents (Sonnet/medium) per Execution Waves, enforces TDD, incremental commits per wave, produces 04-execution-log.md.
---

# Execute (Phase 4)

Implement the approved plan through disciplined, test-driven development. Use parallel subagents for independent tasks. Every line of behavior-bearing code is justified by a failing test.

## Prerequisites

- `02-plan.md` MUST exist in the active spec directory.
- `03-revision.md` MUST exist (dev pipeline) or be absent (resolve pipeline).
- Human approval MUST have been given.
- Project context from Phase 0 MUST be available.

## Process

### Phase 4.1 — Parse the Plan

1. READ `02-plan.md` (check `## Changelog` section for revision amendments).
2. If resolve pipeline (no plan): READ `01-diagnosis.md` for suggested fix and hotspots.
3. For each step, EXTRACT: title, files, test files, dependencies, acceptance criteria, test strategy, scope, classification.
4. BUILD the dependency graph (DAG).
5. EXTRACT the Execution Waves table.

### Phase 4.2 — Validate Before Starting

1. **Acyclicity:** Dependency graph has no cycles.
2. **Parallel safety:** No two PARALLEL steps in the same wave share files. VERIFY every pair at runtime before dispatch. The runtime check overrides the plan.
3. **Interface independence:** No two PARALLEL steps share interface dependencies (one creates a function the other calls). If found, downgrade to SEQUENTIAL.
4. **Test runner:** Must work. RUN the project's test command.
5. **Environment:** Project must build.

If any validation fails, STOP and report.

### Phase 4.3 — Execute Wave by Wave

For each wave in order:

```
Wave N:
  1. IDENTIFY all steps in this wave
  2. For PARALLEL steps with no shared files AND no shared interfaces:
     → DISPATCH one subagent per step CONCURRENTLY
     → Model: latest Sonnet, effort: medium
     → Each subagent receives:
       - Project context (Phase 0)
       - Full task text (complete step from plan)
       - TDD rules (load skills/tdd/SKILL.md — FULL content, not summary)
       - System-Wide Test Check (see below)
       - List of files it may touch (scope boundary)
     → WAIT for ALL subagents to complete
  3. For SEQUENTIAL steps:
     → Execute one at a time, inline or via subagent
  4. After all steps in wave complete:
     → RUN full test suite
     → If failures: identify responsible step, dispatch fix, re-run
     → RUN project formatter on all modified files
     → COMMIT: create a commit for this wave's changes
       Message: "feat(wave-N): [description of what this wave accomplished]"
     → DO NOT proceed until ALL tests pass
```

### Phase 4.4 — System-Wide Test Check

INJECT this checklist into every subagent prompt. The subagent MUST verify BEFORE writing production code:

1. **What fires when this code runs?** — Callbacks, middleware, observers, event listeners, lifecycle hooks that trigger as a side effect.
2. **Do tests exercise the real chain?** — Not just the unit in isolation, but the actual execution path including middleware and observers.
3. **Can a test failure leave orphaned state?** — If yes, add teardown/cleanup.
4. **What other interfaces expose this?** — Mixins, HOCs, alternative entry points that call the same logic.
5. **Do error strategies align across layers?** — If the service throws, does the component catch? Does the test verify the error path?

### Phase 4.5 — TDD Injection Protocol

1. OPEN and READ `skills/tdd/SKILL.md` NOW. Do not rely on memory.
2. EXTRACT: The Iron Law, The Cycle, Step-Back Protocol, Delete Rule, System-Wide Test Check, Verification Mode.
3. INJECT into EVERY subagent prompt under `## TDD Rules`.
4. Do NOT paraphrase. Copy exactly.
5. VERIFY the prompt contains TDD rules before dispatch.

For **infrastructure/config changes** (config files, build files, type definitions, migrations, static assets): inject the Verification Mode protocol instead of full TDD. The subagent runs the build + existing tests but does not write new tests.

### Phase 4.6 — Subagent Protocol

Each subagent reports exactly one status:
- **DONE** — All criteria met, tests pass. Summary + test count.
- **DONE_WITH_CONCERNS** — Complete but flagging a potential issue.
- **NEEDS_CONTEXT** — Blocked on specific missing information.
- **BLOCKED** — Cannot proceed. Explain why.

**Step-Back Protocol:**
- Strike 1: Fix the error and retry.
- Strike 2: STOP. Document failures. Try a fundamentally different approach.
- Strike 3: ESCALATE to human with all three attempts.

### Phase 4.7 — Final Test Gate

After ALL waves complete:

1. RUN project formatter on all modified files.
2. RUN full test suite.
3. RUN linter (if configured).
4. RUN type checker (if configured).

If everything passes: proceed to execution log.
If failures: fix (max 3 attempts), then escalate.

### Phase 4.8 — Write Execution Log

WRITE `04-execution-log.md` in the active spec directory using `templates/04-execution-log.md`:

- SET frontmatter: `status: draft`, `date`, `topic`, `pipeline`, `waves_completed`
- For each wave: steps completed, test files written, commit SHA + message, test status
- **Unexpected Decisions:** Any deviation from the plan, with rationale
- **Verification Mode Changes:** Infrastructure/config files that used verification mode instead of TDD

This artifact feeds the code review phase — reviewers use it to understand implementation intent and focus on areas of deviation.

## Subagent Prompt Template

```
# Task: [step title from plan]

## Project Context
[from Phase 0]

## Your Assignment
[full step text including acceptance criteria and test strategy]

## Files You May Touch
[explicit list — do NOT modify files outside this list]

## Test Files
[mandatory test file paths from the plan]

## TDD Rules
[Full content from skills/tdd/SKILL.md]

## System-Wide Test Check
Before writing production code, verify:
1. What callbacks/middleware/observers fire when this runs?
2. Do tests exercise the real execution chain?
3. Can test failure leave orphaned state?
4. What other interfaces expose this logic?
5. Do error strategies align across layers?

## Scope Boundary
Do NOT: modify files outside your assignment, add unplanned features, add comments explaining obvious code, "clean up" adjacent code, install unspecified dependencies.

## Report
DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
```

## Rules

- NEVER dispatch PARALLEL subagents for steps sharing files. Runtime check overrides the plan.
- Subagents do NOT communicate. All coordination through orchestrator.
- Each subagent starts fresh. Everything needed MUST be in its prompt.
- Do NOT combine steps. Each step is a separate dispatch.
- Do NOT reorder waves.
- Each wave ends with a commit before the next wave starts.

## Transition

- IF in pipeline: RETURN control with implementation notes and execution log path.
- IF standalone: report completion, inform user to invoke code-review.
