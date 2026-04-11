---
name: tdd
description: Use when implementing any code change. Enforces the RED-GREEN-REFACTOR cycle for behavior-bearing code and verification mode for infrastructure. No production code without a failing test first.
---

# TDD (Cross-Cutting)

Test-driven development enforcement for all implementation work. This skill is referenced by the execute phase and applies to every subagent.

## Ownership

During pipeline execution (Phase 4), the execute skill loads and injects these rules into subagent prompts. This file is the **single source of truth** for TDD methodology.

When invoked standalone via `Skill: development-toolkit:tdd`, this skill serves as a reference for manual implementation work.

**Subagent self-check:** If you are a subagent and do NOT see TDD rules in your prompt, STOP. Report that TDD rules were not injected.

## Two Modes

### Mode 1: Full TDD (Behavior-Bearing Code)

**Applies to:** Logic, state management, side effects, API handlers, UI components with behavior, services, hooks, utilities with conditional logic.

**The Iron Law: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**

This is absolute. Every line of behavior-bearing production code MUST be justified by a test that failed without it.

### Mode 2: Verification (Infrastructure & Configuration)

**Applies to:** Config files (vite.config, tsconfig, eslint config), build files, type definitions (`.d.ts`), database migrations, static assets, environment variable templates, CI/CD configuration.

**Verification protocol:**
1. Make the change
2. Run the full build: confirm it compiles/transpiles without errors
3. Run the full test suite: confirm no existing tests break
4. If the change affects build output, verify the output is correct

Verification mode does NOT require writing new tests. It requires proving that existing tests and build still pass. If a config change breaks something, the existing test suite catches it.

**When in doubt:** If you're unsure whether something is behavior-bearing or infrastructure, treat it as behavior-bearing and write the test. It's always safe to test more.

## The RED-GREEN-REFACTOR Cycle

```
RED:      Write a test. Run it. It MUST fail. If it passes, the test is wrong.
GREEN:    Write the MINIMUM code to pass. Run tests. They MUST pass.
REFACTOR: Clean up while green. Run tests. They MUST still pass.
COMMIT:   Stage and move to the next cycle.
```

Every acceptance criterion goes through this cycle independently. Do not batch. One criterion, one cycle.

### RED — Write a Failing Test

1. Choose the next acceptance criterion
2. Write ONE test that verifies the criterion
3. Run the test suite
4. The new test MUST fail
5. If it passes:
   - The behavior already exists (check if the criterion is already satisfied)
   - The test is not testing the right thing (fix the test)
   - The test has a tautological assertion (fix the assertion)
6. Do NOT proceed to GREEN until you have a genuine failure

The failure message MUST describe the missing behavior. A good failure: `expected 3 but got undefined`. A bad failure: `TypeError: cannot read property of null` — this means setup is wrong.

### GREEN — Write Minimum Code

1. Write the absolute minimum production code that makes the failing test pass
2. Run the test suite
3. ALL tests MUST pass — not just the new one
4. If other tests break, your code has an unintended side effect. Fix it.

Do NOT:
- Write code "you know you'll need"
- Handle edge cases not covered by a test
- Add error handling not covered by a test
- Optimize prematurely
- Build abstractions

### REFACTOR — Clean Up While Green

1. Look for: duplication, unclear names, long functions, unnecessary complexity
2. Change ONE thing at a time
3. Run tests after EACH change
4. If tests fail, undo the change
5. Stop when the code is clean — do not gold-plate

Refactoring changes structure without changing behavior. If behavior changes, it needs its own RED phase.

### COMMIT — Stage and Continue

After each complete cycle: stage the changed files, move to the next acceptance criterion, start a new RED phase.

## The Prove-It Pattern (Bug Fixes)

When fixing a bug, the cycle is modified. The bug IS the failing test.

```
1. REPRODUCE: Write a test that triggers the bug (must FAIL with current code)
2. CONFIRM:   Verify the failure matches the reported behavior
3. FIX:       Implement the minimum change to fix the bug
4. VERIFY:    Run the test — it MUST now pass
5. REGRESS:   Run the FULL suite — no regressions
```

## Step-Back Protocol

If you fail to make a test pass after 2 attempts:

1. **STOP coding.**
2. **Document** what was tried and why it failed.
3. **Ask:** What assumption might be wrong?
4. **Try a fundamentally different approach** — not a variation of the same idea.
5. **If the different approach also fails**, report BLOCKED. Do not attempt a fourth approach without human input.

## System-Wide Test Check

Before writing production code for any step, PAUSE and verify:

1. **What fires when this code runs?** — Callbacks, middleware, observers, event listeners, lifecycle hooks.
2. **Do tests exercise the real chain?** — Not just the unit in isolation, but the actual execution path including middleware and observers.
3. **Can a test failure leave orphaned state?** — If yes, add teardown/cleanup.
4. **What other interfaces expose this?** — Mixins, HOCs, alternative entry points that call the same logic.
5. **Do error strategies align across layers?** — If the service throws, does the component catch? Does the test verify the error path?

## Test Quality Standards

### Behavior-Focused
Test what the code does, not how. If renaming a private function breaks a test, the test is coupled to implementation.

### DAMP Over DRY
Each test tells a complete story. Duplication in tests is acceptable when it adds clarity.

### Independent
No test depends on another. Every test sets up its own state, runs its assertion, and cleans up.

### Specific Assertions
Assert the exact expected value. Not "is truthy." Not "is not null." The exact value.

```
// Bad
expect(result).toBeTruthy();

// Good
expect(result).toBe(42);
```

## Test Pyramid

- **~70% Unit Tests** — Pure logic in isolation, milliseconds per test
- **~20% Integration Tests** — Component boundaries, real dependencies where feasible
- **~10% E2E Tests** — Critical user flows, full stack

## The Delete Rule

If you wrote production code before writing a test: delete the production code, write the test, watch it fail, rewrite the production code.

No exceptions.

## Anti-Rationalization

| Excuse | Reality |
|--------|---------|
| "I'll write tests after" | You will not. Post-hoc tests test implementation, not behavior. |
| "This is too simple to test" | Then the test is trivial to write. Do it. |
| "Just a config change" | Use verification mode. Run the build and tests. |
| "The deadline is too tight" | The deadline is too tight for debugging. Write the test. |

## Transition

This skill does not transition to another skill. It is active during all implementation work and terminates when the calling context completes.
