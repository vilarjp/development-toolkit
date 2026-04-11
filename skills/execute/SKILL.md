---
name: execute
description: Use when the active pipeline is approved and ready for implementation.
---

# Execute (Phase 4)

Implement the approved spec through disciplined, test-driven development. In the dev pipeline this means executing an approved plan. In the resolve pipeline this means executing the approved diagnosis as a minimal root-cause fix. Every line of behavior-bearing code is justified by a failing test.

## Prerequisites

- Human approval MUST have been given for the active pipeline.
- Project context from Phase 0 MUST be available.
- For **dev**: `02-plan.md` and `03-revision.md` MUST exist and be `approved`.
- For **resolve**: `01-diagnosis.md` MUST exist and be `approved`.

## Minimal Diff Constraint

**Change the least amount of code possible to achieve the goal.** Every line in the diff must be traceable to:

- a plan acceptance criterion in the dev pipeline, or
- the confirmed root cause / reproduction test / suggested fix in the resolve pipeline

If you cannot trace a line to one of those sources of truth, do not write it.

This constraint applies to every subagent dispatch. Include it in every implementer prompt.

## Scope Discipline — NOTICED BUT NOT TOUCHING

When you or a subagent notice an out-of-scope improvement opportunity during execution, log it — do NOT act on it.

**Format in the execution log (per wave):**
```
### Noticed But Not Touching
- [observation] — out of scope because [reason]
```

Instruct subagents: "If you notice something worth improving that is outside your acceptance criteria, include it in your report under CONCERNS with prefix 'NOTICED BUT NOT TOUCHING:'. Do not act on it."

## Confusion Protocol

When you or a subagent encounter ambiguity during execution:

1. **STOP** — Do not write code while confused
2. **NAME** — State the confusion explicitly: "I am confused about X because Y"
3. **OPTIONS** — Present the options: "Option A: ... / Option B: ..."
4. **WAIT** — Subagents: report NEEDS_CONTEXT with the confusion. Orchestrator: present to the human
5. **PLAN** — Once resolved, state the plan before executing: "PLAN: 1. X, 2. Y, 3. Z → Executing unless you redirect"

## Process

### Phase 4.1 — Determine Execution Mode

1. If `02-plan.md` exists in the active spec directory, run in **DEV MODE**.
2. Else if `01-diagnosis.md` exists, run in **RESOLVE MODE**.
3. Else STOP — there is no approved execution source of truth.

### Phase 4.2 — Load the Source of Truth

**DEV MODE**
1. READ `02-plan.md` (check `## Changelog` section for revision amendments).
2. For each step, EXTRACT: title, files, test files, dependencies, acceptance criteria, test strategy, scope, classification.
3. BUILD the dependency graph (DAG).
4. EXTRACT the Execution Waves table.

**RESOLVE MODE**
1. READ `01-diagnosis.md`.
2. EXTRACT: root cause, reproduction test, suggested fix, hotspots, concerns, and severity.
3. DEFINE one focused implementation slice that fixes the diagnosed root cause and nothing else.
4. Use the diagnosis as the execution source of truth. Do NOT invent a synthetic plan.

### Phase 4.3 — Validate Before Starting

**DEV MODE**
1. **Acyclicity:** Dependency graph has no cycles.
2. **Parallel safety:** No two PARALLEL steps in the same wave share files. VERIFY every pair at runtime before dispatch. The runtime check overrides the plan.
3. **Interface independence:** No two PARALLEL steps share interface dependencies (one creates a function the other calls). If found, downgrade to SEQUENTIAL.

**ALL MODES**
4. **Test runner:** Must work. RUN the project's test command or the diagnosis reproduction test command if the full suite is too slow to start with.
5. **Environment:** Project must build if the project defines a build step.

If any validation fails, STOP and report.

### Phase 4.4 — Execute DEV Mode Wave by Wave

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

### Phase 4.5 — Execute RESOLVE Mode Minimal Fix

Resolve execution is diagnosis-driven and defaults to sequential work.

1. Re-run the reproduction test or manual reproduction steps. Confirm the bug is still RED.
2. Identify the minimum production code change that addresses the documented root cause.
3. Execute the fix inline or via one focused subagent.
4. If additional support work is required (test helper, fixture update, narrow refactor), keep it tied directly to the fix.
5. Do NOT create synthetic steps or waves just to mimic the dev pipeline.
6. After the fix:
   - run the reproduction test
   - run relevant nearby tests
   - run the full suite before leaving execute
7. Prefer one logical commit for the resolve fix. Split only when a second commit materially improves reviewability.

### Phase 4.6 — System-Wide Test Check

INJECT this checklist into every subagent prompt. The subagent MUST verify BEFORE writing production code:

1. **What fires when this code runs?** — Callbacks, middleware, observers, event listeners, lifecycle hooks that trigger as a side effect.
2. **Do tests exercise the real chain?** — Not just the unit in isolation, but the actual execution path including middleware and observers.
3. **Can a test failure leave orphaned state?** — If yes, add teardown/cleanup.
4. **What other interfaces expose this?** — Mixins, HOCs, alternative entry points that call the same logic.
5. **Do error strategies align across layers?** — If the service throws, does the component catch? Does the test verify the error path?

### Phase 4.7 — TDD Injection Protocol

1. OPEN and READ `skills/tdd/SKILL.md` NOW. Do not rely on memory.
2. EXTRACT: The Iron Law, The Cycle, Step-Back Protocol, Delete Rule, System-Wide Test Check, Verification Mode.
3. INJECT into EVERY subagent prompt under `## TDD Rules`.
4. Do NOT paraphrase. Copy exactly.
5. VERIFY the prompt contains TDD rules before dispatch.

For **infrastructure/config changes** (config files, build files, type definitions, migrations, static assets): inject the Verification Mode protocol instead of full TDD. The subagent runs the build + existing tests but does not write new tests.

### Phase 4.8 — Subagent Protocol

Each subagent reports exactly one status:
- **DONE** — All criteria met, tests pass. Summary + test count.
- **DONE_WITH_CONCERNS** — Complete but flagging a potential issue.
- **NEEDS_CONTEXT** — Blocked on specific missing information.
- **BLOCKED** — Cannot proceed. Explain why.

**Step-Back Protocol:**
- Strike 1: Fix the error and retry.
- Strike 2: STOP. Document failures. Try a fundamentally different approach.
- Strike 3: ESCALATE to human with all three attempts.

### Phase 4.9 — Final Test Gate

After ALL waves complete:

1. RUN project formatter on all modified files.
2. RUN full test suite.
3. RUN linter (if configured).
4. RUN type checker (if configured).

If everything passes: proceed to execution log.
If failures: fix (max 3 attempts), then escalate.

### Phase 4.10 — Write Execution Log

WRITE `04-execution-log.md` in the active spec directory using `templates/04-execution-log.md`:

- SET frontmatter: `status: approved`, `date`, `topic`, `pipeline`, `waves_completed`
- For dev: for each wave, record steps completed, test files written, commit SHA + message, test status
- For resolve: treat the focused fix as one execution item (or one wave if you prefer), and record the reproduction test plus the fix scope
- **Unexpected Decisions:** Any deviation from the plan, with rationale
- **Verification Mode Changes:** Infrastructure/config files that used verification mode instead of TDD
- **Change Summary** — Required final section with three subsections:
  - **Changes Made:** Concise description of each logical change, grouped by intent
  - **Things I Didn't Touch:** Areas explicitly in scope but deliberately left unchanged, with reason
  - **Potential Concerns:** Risks, edge cases not fully covered, performance implications, migration needs

This artifact feeds the code review phase — reviewers use it to understand implementation intent and focus on areas of deviation.

## Subagent Prompt Template

```
# Task: [step title from plan]

## Project Context
[from Phase 0]

## Your Assignment
[full step text including acceptance criteria and test strategy, OR the diagnosis-derived fix scope]

## Files You May Touch
[explicit list — do NOT modify files outside this list]

## Test Files
[mandatory test file paths from the plan, OR the diagnosis reproduction test plus any nearby tests being updated]

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
- In dev mode: do NOT combine plan steps. Each step is a separate dispatch.
- In dev mode: do NOT reorder waves.
- In dev mode: each wave ends with a commit before the next wave starts.
- In resolve mode: prefer a single focused fix flow. Do not invent plan-like structure that the diagnosis did not produce.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll write tests after the code works" | The TDD skill is non-negotiable. No production code without a failing test. |
| "This wave is too small for a commit" | Every wave ends with a commit. This is how we isolate regressions. |
| "I need to refactor this adjacent code to make my change clean" | You are here to deliver acceptance criteria, not to renovate. Flag it as NOTICED BUT NOT TOUCHING. |
| "The subagent can figure out the context on its own" | Subagents start with zero context. Everything they need MUST be in their prompt. |
| "I'll combine these two steps to save time" | Steps are separate for a reason — they have independent acceptance criteria and TDD cycles. Do not combine. |

## Red Flags — Self-Check

- Production code exists without a corresponding test file
- You made changes outside the current wave's scope
- A subagent was dispatched without TDD rules in its prompt
- Two parallel subagents in the same wave are touching the same file
- You skipped the final test gate after the last wave
- A wave completed without a commit
- You combined multiple plan steps into a single subagent dispatch
- You are writing code while confused about the acceptance criteria

## Transition

- IF in pipeline: RETURN control with implementation notes and execution log path.
- IF standalone: report completion, inform user to invoke code-review.
