---
name: tdd
description: Use when implementing any code change. Enforces the RED→GREEN→REFACTOR cycle. For bug fixes, use the Prove-It pattern. No production code without a failing test first.
---

# TDD (Cross-Cutting)

Test-driven development enforcement for all implementation work. This skill is referenced by the execute phase and applies to every subagent.

## Ownership

During pipeline execution (Phase 4), the execute skill loads and injects these rules into subagent prompts. This file is the **single source of truth** for TDD methodology. The execute skill references it — it does not duplicate it.

When invoked standalone via `Skill: development-toolkit:tdd`, this skill serves as a reference and enforcement guide for manual implementation work outside the pipeline.

**Subagent self-check:** If you are a subagent executing an implementation step and you do NOT see TDD rules injected into your prompt, STOP. Report NEEDS_CONTEXT with the message: 'TDD rules not found in prompt. The execute skill must inject skills/tdd/SKILL.md content.'

## The Iron Law

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**

This is not a suggestion. This is not "when practical." This is not "for complex features." This is absolute. Every line of production code MUST be justified by a test that failed without it.

## Model Configuration

Inherits from the calling context. This skill works with any model. It does not require extended thinking -- it requires discipline.

## The Cycle

```
RED:      Write a test. Run it. It MUST fail. If it passes, the test is wrong.
GREEN:    Write the MINIMUM code to pass. Run tests. They MUST pass.
REFACTOR: Clean up while green. Run tests. They MUST still pass.
COMMIT:   Stage and move to the next cycle.
```

Every acceptance criterion goes through this cycle independently. Do not batch. Do not "write all the tests first." One criterion, one cycle.

### RED -- Write a Failing Test

1. Choose the next acceptance criterion
2. Write ONE test that verifies the criterion
3. Run the test suite
4. The new test MUST fail
5. If it passes, one of these is true:
   - The behavior already exists (check if the criterion is already satisfied)
   - The test is not testing the right thing (fix the test)
   - The test has a tautological assertion (fix the assertion)
6. Do NOT proceed to GREEN until you have a genuine failure

The failure message MUST describe the missing behavior. A good failure: `expected 3 but got undefined`. A bad failure: `TypeError: cannot read property of null` -- this means the test setup is wrong, not that the feature is missing.

### GREEN -- Write Minimum Code

1. Write the absolute minimum production code that makes the failing test pass
2. Run the test suite
3. ALL tests MUST pass -- not just the new one
4. If other tests break, your code has an unintended side effect. Fix it.
5. "Minimum" means minimum. If the test expects `return 3`, write `return 3`. The next test will force the real implementation.

Do NOT:
- Write code "you know you'll need"
- Handle edge cases not covered by a test
- Add error handling not covered by a test
- Optimize prematurely
- Add configuration options
- Build abstractions

### REFACTOR -- Clean Up While Green

1. Look for: duplication, unclear names, long functions, unnecessary complexity
2. Change ONE thing at a time
3. Run tests after EACH change
4. If tests fail, undo the change and try differently
5. Stop when the code is clean -- do not gold-plate

Refactoring means changing structure without changing behavior. If your refactoring changes what the code does (not just how), it is not refactoring -- it is a new feature and needs its own RED phase.

### COMMIT -- Stage and Continue

After each complete RED-GREEN-REFACTOR cycle:
1. Stage the changed files
2. Move to the next acceptance criterion
3. Start a new RED phase

## Step-Back Protocol

If you fail to make a test pass after 2 attempts on the same approach:

1. **STOP coding.** Do not try the same approach a third time.
2. **Document** what was tried and why it failed (both attempts).
3. **Ask:** What assumption might be wrong? Is the acceptance criterion ambiguous or contradictory?
4. **Try a fundamentally different approach** — not a variation of the same idea. A different algorithm, a different data structure, a different decomposition.
5. **If the different approach also fails**, report BLOCKED with the step-back analysis. Do not attempt a fourth approach without human input.

This protocol prevents the common failure mode where an agent retries the same broken approach with minor tweaks, wasting time and context.

See `skills/execute/SKILL.md` Phase 4.5 for how the orchestrator handles step-back escalation.

## The Prove-It Pattern (Bug Fixes)

When fixing a bug, the cycle is modified. The bug IS the failing test.

```
1. REPRODUCE: Write a test that triggers the bug (must FAIL with current code)
2. CONFIRM:   Verify the failure matches the reported behavior
3. FIX:       Implement the minimum change to fix the bug
4. VERIFY:    Run the test -- it MUST now pass
5. REGRESS:   Run the FULL suite -- no regressions
```

The reproduction test is the most important artifact of a bug fix. It proves the bug existed, proves the fix works, and prevents the bug from returning.

See `references/prove-it-pattern.md` for the detailed guide.

## The Delete Rule

If you wrote production code before writing a test:

1. Delete the production code
2. Write the test
3. Watch the test fail
4. Rewrite the production code to pass the test

No exceptions. Not "but I already know it works." Not "it was just a small helper." Delete it. Write the test. Rewrite the code.

Post-hoc tests verify implementation details because you wrote them to match existing code. Tests written first verify behavior because they define what the code should do.

## Test Quality Standards

### Behavior-Focused
Test what the code does, not how it does it. If you refactor the internals, the tests should still pass. If renaming a private function breaks a test, the test is coupled to implementation.

### DAMP Over DRY
**D**escriptive **A**nd **M**eaningful **P**hrases. Each test tells a complete story. A reader should understand the test without reading other tests, setup methods, or helper functions. Duplication in tests is acceptable when it adds clarity.

```
// DRY but unclear -- what does this test actually verify?
test("case 1", () => {
  assertResult(setup(CASE_1), EXPECTED_1);
});

// DAMP and clear -- the test tells its own story
test("returns free shipping for orders over $50", () => {
  const order = createOrder({ items: [{ price: 60 }] });
  const shipping = calculateShipping(order);
  expect(shipping.cost).toBe(0);
  expect(shipping.method).toBe("standard");
});
```

### Independent
No test depends on another test. No test depends on execution order. Every test sets up its own state, runs its assertion, and cleans up. If you can run any single test in isolation and it passes, your tests are independent.

### Fast
Unit tests run in milliseconds, not seconds. If a unit test takes more than 100ms, it is probably hitting a real database, making a network call, or doing too much. Mock the slow dependency.

### Specific Assertions
Assert the exact expected value. Not "is truthy." Not "is not null." Not "has length greater than 0." The exact value.

```
// Bad: passes with almost any result
expect(result).toBeTruthy();
expect(items.length).toBeGreaterThan(0);
expect(user).toBeDefined();

// Good: passes only with the correct result
expect(result).toBe(42);
expect(items).toEqual(["apple", "banana", "cherry"]);
expect(user.name).toBe("Alice");
```

## Test Pyramid

Target these ratios. Adjust based on the project's nature, but deviations MUST be intentional and justified.

**80% Unit Tests**
- Test pure logic in isolation
- Fast: milliseconds per test
- Mock external dependencies (database, API, file system)
- One behavior per test
- These are the foundation -- if these fail, nothing else matters

**15% Integration Tests**
- Test boundaries between components
- Verify that modules work together correctly
- Use real dependencies where feasible (in-memory database, local API)
- Slower than unit tests, but catch wiring bugs that unit tests miss

**5% E2E Tests**
- Test critical user flows end-to-end
- Exercise the full stack
- Slowest and most brittle -- use sparingly
- Cover the happy path and the most important failure paths

See `references/test-pyramid.md` for the detailed guide with decision rules.

## Anti-Rationalization

Every excuse for skipping TDD has been made before. None of them hold.

| Excuse | Reality |
|--------|---------|
| "I'll write tests after the code works" | You will not. And post-hoc tests test implementation, not behavior. |
| "This is too simple to test" | Then the test is trivial to write. Do it. |
| "I'm just refactoring" | Run existing tests continuously. If none exist, write a characterization test first. |
| "The test framework isn't set up" | Setting it up IS your first task. |
| "I need to see the implementation shape first" | The test DEFINES the shape. That is the point. |
| "This is UI code" | UI logic can be tested. Visual output can be snapshot tested. Interactions can be verified. |
| "I'm blocked on a dependency" | Mock the dependency at the boundary. Test your logic. |
| "The existing code doesn't have tests" | Your code does. Always. |
| "I already know this works" | Prove it. With a test. |
| "It's just a one-line change" | One-line changes break production. Test it. |
| "I'll come back to it" | No you will not. Write it now. |
| "Tests slow down development" | Bugs slow down development. Tests prevent bugs. Tests speed you up. |
| "The deadline is too tight for tests" | The deadline is too tight for debugging. Write the test. |
| "This is throwaway code" | There is no throwaway code. Today's prototype is next month's production system. |

If you find yourself making an excuse, stop. Write the test. Then write the code.

## Transition

This skill does not transition to another skill. It is active during all implementation work and terminates when the calling context (execute phase or standalone implementation) completes. DO NOT ask the user what to do next when implementation finishes — the calling context handles the transition.
