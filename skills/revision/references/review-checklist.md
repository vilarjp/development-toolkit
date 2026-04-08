# Revision Phase Review Checklist

Complete checklist for the cross-document review. Every item must be checked. Mark each as PASS or FAIL with a brief note.

---

## Brainstorm-to-Plan Alignment (8 checks)

### 1. Goal Coverage
**What to check:** Every goal in the brainstorm has at least one plan step that addresses it.
**How to verify:** Create a mapping: brainstorm goal -> plan step(s). If any goal has no mapping, it is uncovered.
**Failure looks like:** A brainstorm goal says "reduce page load time below 2 seconds" but no plan step addresses performance optimization, caching, or bundle size reduction.

### 2. Non-Goal Respect
**What to check:** No plan step accidentally implements something listed as a non-goal in the brainstorm.
**How to verify:** For each non-goal, scan every plan step's description and acceptance criteria. If any step's output overlaps with a non-goal, it is a violation.
**Failure looks like:** The brainstorm lists "custom theme editor" as a non-goal, but a plan step includes "allow users to customize color palette" -- which is effectively a theme editor.

### 3. Assumption Alignment
**What to check:** Brainstorm assumptions are reflected in plan design decisions. The plan does not contradict or ignore stated assumptions.
**How to verify:** For each brainstorm assumption, find where the plan accounts for it -- in design decisions, constraints, or step details.
**Failure looks like:** The brainstorm assumes "users are authenticated via SSO" but the plan designs a username/password login flow.

### 4. Direction Fidelity
**What to check:** The plan follows the recommended direction chosen in the brainstorm. Minor adaptation is expected. A fundamentally different approach is a red flag.
**How to verify:** Compare the brainstorm's recommended option with the plan's architecture section. The core approach should be recognizable.
**Failure looks like:** The brainstorm recommends "server-side rendering with hydration" but the plan implements a single-page application with client-side rendering.

### 5. Trade-Off Acknowledgment
**What to check:** Trade-offs identified in the brainstorm appear in the plan's risk section, either as accepted risks or with mitigations.
**How to verify:** List every trade-off from the brainstorm's recommendation section. Find each one in the plan's risks or design decisions.
**Failure looks like:** The brainstorm says "this approach trades flexibility for simplicity" but the plan's risk section never mentions the flexibility limitation or how to handle cases where flexibility is needed.

### 6. Constraint Adherence
**What to check:** Plan steps respect every constraint from the brainstorm (technical, time, compatibility, scope).
**How to verify:** For each brainstorm constraint, verify no plan step violates it.
**Failure looks like:** The brainstorm says "must maintain backward compatibility with API v2" but a plan step changes the v2 response format.

### 7. Scope Boundary
**What to check:** The plan's total scope matches the brainstorm's problem statement. The plan does not under-deliver or over-deliver.
**How to verify:** Compare the brainstorm's problem statement and goals with the plan's total output. If the plan delivers significantly more or less, it has drifted.
**Failure looks like:** The brainstorm is about "adding search to the product catalog" but the plan includes steps for faceted filtering, saved searches, search analytics, and search suggestions -- four features when only one was requested.

### 8. Success Criteria Match
**What to check:** If all plan steps are executed successfully, the brainstorm's definition of success is met.
**How to verify:** Imagine all acceptance criteria passing. Does that state satisfy the brainstorm's goals? If not, something is missing.
**Failure looks like:** The brainstorm's success criterion is "users can complete checkout in under 60 seconds" but no plan step includes performance testing or benchmarking of the checkout flow.

---

## Internal Plan Consistency (8 checks)

### 9. Dependency Validity
**What to check:** Each declared dependency is genuine. Step N actually needs step M's output.
**How to verify:** For each dependency arrow, ask: "What specific output of step M does step N consume?" If you cannot name it, the dependency is artificial.
**Failure looks like:** Step 3 declares a dependency on Step 1, but Step 3 only reads a config file that already exists -- it does not need anything Step 1 creates.

### 10. Dependency Acyclicity
**What to check:** The dependency graph has no cycles, direct or transitive.
**How to verify:** Trace every dependency chain to its root. If you visit the same step twice, there is a cycle.
**Failure looks like:** Step A depends on Step B "for the user model," Step B depends on Step C "for the validation rules," Step C depends on Step A "for the error types." Circular.

### 11. Parallelization Correctness
**What to check:** Steps marked [PARALLEL] genuinely have no shared files, no data flow dependency, and no shared mutable state.
**How to verify:** For every pair of [PARALLEL] steps in the same wave, compare their file lists. If ANY file appears in both lists, the parallelization is wrong.
**Failure looks like:** Steps 2 and 3 are both marked [PARALLEL] in Wave 1. Step 2 modifies `src/types/index.ts` to add UserType. Step 3 modifies `src/types/index.ts` to add OrderType. Both write to the same file -- this will cause merge conflicts.

### 12. File Conflict Detection
**What to check:** No two PARALLEL steps in the same wave touch the same file.
**How to verify:** Extract file lists from all steps. For each wave, compute the intersection of file sets for all PARALLEL step pairs. The intersection must be empty.
**Failure looks like:** Wave 2 has three PARALLEL steps. Steps A and B both list `src/config/routes.ts`. This is a write conflict.

### 13. Path Consistency
**What to check:** The same file is referenced identically everywhere in the plan.
**How to verify:** Collect all file paths mentioned in the plan. Normalize them. If the same logical file appears with different path strings, it is inconsistent.
**Failure looks like:** Step 1 references `src/api/users.ts`, Step 3 references `./src/api/users.ts`, Step 5 references `api/users.ts`. All three point to the same file but use different paths.

### 14. Wave-Dependency Alignment
**What to check:** The Execution Waves table matches the step dependencies. Every dependency points to a strictly earlier wave.
**How to verify:** For each step in wave N, verify all its dependencies are in waves 1 through N-1. If any dependency is in wave N or later, the table is wrong.
**Failure looks like:** Step 4 is in Wave 2 and depends on Step 5, which is also in Wave 2. A step cannot depend on another step in the same wave.

### 15. Acceptance Criteria Coverage
**What to check:** Every step has acceptance criteria that are testable and specific.
**How to verify:** For each step, read the acceptance criteria. Ask: "Could I write a test that verifies this?" If not, the criterion is too vague.
**Failure looks like:** A step's acceptance criterion is "the component works correctly." This is not testable. "The component renders a list of 10 items with pagination controls" is testable.

### 16. Test Strategy Coverage
**What to check:** Every step has a test strategy that verifies its acceptance criteria.
**How to verify:** For each acceptance criterion, find the corresponding test in the step's test strategy. If a criterion has no test, it will not be verified.
**Failure looks like:** A step has three acceptance criteria but the test strategy only mentions "unit test the component." Which criteria does the test verify? All three? Only one?

---

## Completeness (6 checks)

### 17. Orphaned Goals
**What to check:** Every brainstorm goal maps to at least one plan step.
**How to verify:** Create a goal-to-step mapping. Any goal without a step is orphaned.
**Failure looks like:** The brainstorm has 5 goals. The plan has 8 steps. But goal 3 ("support offline mode") has no corresponding step anywhere in the plan.

### 18. Naked Steps
**What to check:** No plan step lacks acceptance criteria.
**How to verify:** Scan every step. If the acceptance criteria section is empty, missing, or says "TBD," the step is naked.
**Failure looks like:** Step 6 has a title, file list, and dependencies, but the acceptance criteria section says "See brainstorm." That is not acceptance criteria.

### 19. Unmitigated Risks
**What to check:** Every identified risk has a concrete mitigation strategy.
**How to verify:** For each risk in the plan's risk section, check the mitigation column. "Be careful" and "monitor closely" are not mitigations. "Implement retry with exponential backoff, max 3 attempts" is a mitigation.
**Failure looks like:** Risk: "Third-party API may be unavailable." Mitigation: "Handle gracefully." This does not describe what "gracefully" means.

### 20. Uncovered Edge Cases
**What to check:** Edge cases mentioned in either document have corresponding test coverage in the plan.
**How to verify:** Collect all edge cases from both documents. For each one, find a step whose test strategy covers it.
**Failure looks like:** The brainstorm mentions "what happens if the user has zero items in their cart?" The plan has no test for the empty cart case.

### 21. Test Pyramid Balance
**What to check:** The test strategy has a realistic mix of unit, integration, and E2E tests.
**How to verify:** Count the types of tests across all steps. A plan with 10 steps and only unit tests is likely missing integration coverage. A plan with only E2E tests will be slow and flaky.
**Failure looks like:** 10 implementation steps, 30 unit tests mentioned, 0 integration tests, 0 E2E tests. The plan has no verification that components work together.

### 22. Missing Infrastructure
**What to check:** The plan does not assume infrastructure that does not exist and is not created by any step.
**How to verify:** List every tool, service, and config the plan references (test runner, database, CI pipeline, environment variables). Verify each one either exists in the project or is set up by a plan step.
**Failure looks like:** The plan references "run `npm test`" but the project has no test runner configured and no step creates the test setup.

---

## Feasibility (5 checks)

### 23. Pattern Compatibility
**What to check:** Proposed patterns match the existing codebase conventions.
**How to verify:** Compare the plan's architectural decisions with the project context. If the plan introduces a pattern that contradicts an established convention, flag it.
**Failure looks like:** The existing codebase uses the repository pattern for data access. The plan introduces direct database queries in controller functions.

### 24. Dependency Availability
**What to check:** New dependencies are available, compatible, and accounted for in the plan.
**How to verify:** For each new dependency the plan introduces, check: Is there a step that installs it? Is the version compatible with the existing stack? Is the dependency actively maintained?
**Failure looks like:** The plan uses `@tanstack/react-query v5` but the project is on React 16, which is not supported by v5.

### 25. Path Convention Compliance
**What to check:** Proposed file paths follow the project's naming and directory conventions.
**How to verify:** Compare proposed paths with existing paths in the same directories. If the project uses `kebab-case.ts` and the plan proposes `PascalCase.ts`, flag it.
**Failure looks like:** Existing files: `src/components/user-profile.tsx`, `src/components/order-list.tsx`. Plan proposes: `src/components/PaymentForm.tsx`. Inconsistent naming.

### 26. Test Runner Compatibility
**What to check:** Proposed test patterns work with the project's test runner.
**How to verify:** Check for framework-specific APIs. If the plan uses `jest.mock()` but the project runs Vitest, some APIs may differ. If the plan uses `describe.concurrent` but the runner does not support it, flag it.
**Failure looks like:** The plan's test strategy uses `cy.intercept()` (Cypress) but the project uses Playwright for E2E testing.

### 27. Configuration Gaps
**What to check:** All necessary configuration changes are addressed in the plan.
**How to verify:** List every new environment variable, build config change, linter rule, route registration, or CI change implied by the plan. Verify each one has a step that creates it.
**Failure looks like:** The plan adds a step that reads `process.env.STRIPE_API_KEY` but no step adds this variable to `.env.example` or the deployment configuration.

---

## Using This Checklist

During Phase 3.2-3.5, work through every item in order. For each item:

1. **Verify:** Check the specific condition described
2. **Classify:** If it fails, assign severity (P0-Critical, P1-Important, P2-Minor)
3. **Record:** Note the finding in the revision document
4. **Fix:** For P0 and P1 items, update the source document and mark the change with `<!-- REVISED: ... -->`

Do not skip items because they "probably are fine." Check them. The ones that seem obvious are the ones most likely to be wrong.
