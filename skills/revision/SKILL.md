---
name: revision
description: Use after brainstorm and plan are written to cross-check both documents for gaps, inconsistencies, and last-minute adjustments. Produces 03-revision.md in the active spec directory and triggers human approval gate.
---

# Revision (Phase 3)

Cross-document review that catches errors, gaps, and inconsistencies between the brainstorm and the plan BEFORE any code is written. This is the last checkpoint before implementation begins.

## Prerequisites

- A brainstorm artifact (`01-brainstorm.md`) must exist in the active per-session spec directory (format: `docs/YYYY-MM-DD-short-description/`). Also check the legacy location `docs/spec/`.
- A plan artifact (`02-plan.md`) must exist in the same directory.
- If either file is missing, STOP. Tell the user which phase to run first.
- Project context from Phase 0 MUST be available. If not, RUN `Skill: development-toolkit:context-loader` before proceeding.

## Process

Execute these phases in strict order. Do not skip phases. Do not skim documents.

### Phase 3.1 -- Load Both Documents

1. Read `01-brainstorm.md` from the active spec directory -- every section, every bullet, every assumption
2. Read `02-plan.md` from the active spec directory -- every step, every file list, every acceptance criterion
3. If project context is available from an earlier phase, use it. Otherwise, ALWAYS run context-loader.

You MUST have all three inputs loaded before proceeding: brainstorm, plan, and project context. DO NOT begin cross-referencing with partial information.

### Phase 3.2 -- Cross-Reference Consistency

Check brainstorm-to-plan alignment. For each item, verify or flag:

1. **Goal coverage:** VERIFY the plan addresses every goal listed in the brainstorm. Map each brainstorm goal to at least one plan step. If a goal has no corresponding step, flag it.
2. **Non-goal respect:** VERIFY the plan respects every non-goal. Walk through each plan step and check -- no step MUST implement a non-goal. If a step's scope overlaps with a non-goal, flag it.
3. **Assumption alignment:** VERIFY the brainstorm's assumptions are reflected in the plan's design decisions. If the brainstorm assumes X and the plan ignores or contradicts X, flag it.
4. **Direction fidelity:** VERIFY the plan follows the recommended direction from the brainstorm, or has it drifted to a different approach. Minor adaptation is fine. A fundamentally different approach without justification is a critical gap.
5. **Trade-off acknowledgment:** VERIFY trade-offs acknowledged in the brainstorm are accounted for in the plan's risk section. Every brainstorm trade-off MUST appear as either a risk, a mitigation, or an explicit acceptance.
6. **Constraint adherence:** VERIFY plan steps respect the constraints identified in the brainstorm. If the brainstorm says "must work with existing auth system" and a plan step replaces the auth system, flag it.
7. **Scope boundary:** VERIFY the plan's total scope is consistent with the brainstorm's problem statement. A brainstorm about "add dark mode" MUST NOT produce a plan that redesigns the entire theme system.
8. **Success criteria:** VERIFY the plan's collective output, if fully executed, satisfies the brainstorm's definition of success.

See `references/review-checklist.md` for the complete checklist with failure descriptions.

### Phase 3.3 -- Internal Plan Consistency

Check the plan against itself:

1. **Dependency validity:** VERIFY dependencies between steps are valid. Does step N actually need step M's output, or is the dependency artificial?
2. **Dependency acyclicity:** VERIFY dependencies are acyclic. Trace the full graph. If step A depends on B and B depends on A (directly or transitively), the plan is broken.
3. **Parallelization correctness:** VERIFY [PARALLEL]/[SEQUENTIAL] classifications are correct. Apply the formal rule: PARALLEL only if no shared files, no data flow dependency, no shared mutable state.
4. **File conflict detection:** VERIFY file lists in different PARALLEL steps do not conflict. Two steps in the same wave that touch the same file is an error. ALWAYS check every pair.
5. **Path consistency:** VERIFY file paths are consistent. The same file MUST be referenced the same way everywhere. `src/api/users.ts` and `./src/api/users.ts` and `api/users.ts` referencing the same file is a consistency failure.
6. **Wave-dependency alignment:** VERIFY the Execution Waves table matches the step dependencies. Every dependency MUST point to a strictly earlier wave.
7. **Acceptance criteria coverage:** VERIFY every step has acceptance criteria. They MUST be testable and specific.
8. **Test strategy coverage:** VERIFY every step has a test strategy. The test strategy MUST actually verify the acceptance criteria.

### Phase 3.4 -- Completeness Check

1. **Orphaned goals:** VERIFY there are no brainstorm goals with no corresponding plan step. Every goal MUST trace to at least one step.
2. **Naked steps:** VERIFY there are no plan steps with no acceptance criteria. Every step MUST have a definition of done.
3. **Unmitigated risks:** VERIFY there are no risks identified (in either document) without mitigation strategies. "We might hit rate limits" without "We will implement exponential backoff" is incomplete.
4. **Uncovered edge cases:** VERIFY there are no edge cases mentioned in either document without test coverage in the plan. Edge cases that are identified but not tested WILL become production bugs.
5. **Test pyramid balance:** VERIFY the test pyramid is realistic. A plan with 10 implementation steps and 0 integration tests is suspicious. A plan with only E2E tests and no unit tests will be slow and brittle.
6. **Missing infrastructure:** VERIFY the plan does not assume infrastructure that does not exist and is not created by any step. (Test runner, database, CI config, environment variables)

### Phase 3.5 -- Feasibility Check

Using the project context from Phase 0:

1. **Pattern compatibility:** VERIFY proposed patterns are compatible with the existing codebase. If the codebase uses functional components and the plan introduces class components, flag it.
2. **Dependency availability:** VERIFY proposed dependencies can be installed. VERIFY there is a plan step that handles installation. VERIFY the proposed versions are compatible with the existing stack.
3. **Path conventions:** VERIFY proposed file paths are consistent with the project's naming conventions and directory structure. If the project uses `kebab-case` files and the plan proposes `PascalCase`, flag it.
4. **Test runner compatibility:** VERIFY proposed test approaches are compatible with the existing test runner. If the project uses Vitest and the plan proposes Jest-specific APIs, flag it.
5. **Configuration gaps:** VERIFY there are no configuration changes needed (environment variables, build config, linter rules) that are not addressed in any plan step.

### Phase 3.6 -- Apply Adjustments

For each gap or inconsistency found in Phases 3.2-3.5:

1. **Classify severity:**
   - **Critical (P0):** Blocks execution. The plan cannot be implemented as written. Examples: cyclic dependency, missing step for a core goal, PARALLEL steps with shared files.
   - **Important (P1):** Could cause problems during execution. Examples: missing edge case coverage, inconsistent file paths, unrealistic test pyramid.
   - **Minor (P2):** Polish. Examples: vague wording in acceptance criteria, missing rationale for a design decision.

2. **For Critical and Important items:** Update the source document (`01-brainstorm.md` or `02-plan.md`) in place. Mark every update with an HTML comment:
   ```
   <!-- REVISED: [brief description of what changed and why] -->
   ```

3. **For Minor items:** Record them in the revision document but do not modify the source documents unless the fix is trivial.

4. **Record every change** in the revision document, regardless of severity.

Do NOT introduce new features or expand scope during this phase. You are fixing gaps and inconsistencies, not adding requirements. If you find that the plan is missing an entire feature, that is a signal to go back to brainstorming, not to add it during revision.

### Phase 3.7 -- Write Revision Artifact

Write `03-revision.md` in the same per-session spec directory where `01-brainstorm.md` and `02-plan.md` were found, using the template from `templates/03-revision.md`.

The revision document MUST include:
- **Items Reviewed:** The full checklist of what was verified, with pass/fail status for each item
- **Gaps Found:** Every gap, with location, severity, and resolution
- **Adjustments Made:** Every change applied to the source documents, with rationale
- **Final Sign-Off Checklist:** Confirmation that all critical and important items are resolved
- **Verdict:** APPROVED or NEEDS CHANGES

Replace all `{{placeholder}}` tokens. No placeholders, no TODOs. The document MUST be complete.

### Phase 3.8 -- HUMAN APPROVAL GATE

After writing the revision, present this message to the user:

```
All three specification documents are ready for review:
  1. 01-brainstorm.md — Problem exploration and recommended direction
  2. 02-plan.md — Technical implementation plan
  3. 03-revision.md — Cross-document review and adjustments

Reply "go" to proceed to implementation, or describe changes needed (specify document and section).
```

Do NOT proceed to execution without explicit human approval. "Sounds good" or "let's go" counts as approval. Silence does not. If the user does not respond, wait.

## Rules

- Read the FULL text of both documents. Do not skim. Do not read only headers. Every bullet, every assumption, every acceptance criterion matters.
- Do NOT introduce new features or scope during revision. Revision fixes what is there. It does not add what is not.
- If you find a critical gap that requires rethinking the approach, say so explicitly. Do not patch over a fundamental problem with a surface-level fix.
- The revision document is a record of what was checked and what was changed. It MUST be complete enough that someone reading only the revision document can understand what was adjusted and why.
- Do NOT skip the human approval gate. This is a hard gate.

## Anti-Patterns

### "Everything Looks Fine"
If your revision finds zero issues, you did not look hard enough. Go back and re-read. Every plan has at least one inconsistency, one missing edge case, or one vague criterion. Find it.

### "I'll Fix It During Implementation"
No. The entire purpose of revision is to fix problems before implementation. Problems found during implementation cost 10x more to fix. Fix them now.

### "This Is Just a Formality"
If you treat revision as a rubber stamp, you will ship bugs. The revision phase exists because humans and AI agents both make mistakes during brainstorming and planning. Revision catches those mistakes. Take it seriously.

### "The Plan Is Too Big to Review Thoroughly"
If the plan is too big to review, it is too big to implement. Flag this as a critical issue and recommend splitting the work into smaller iterations.

## Transition

WHEN this skill completes:
- IF running inside a pipeline: RETURN control to the pipeline orchestrator. The orchestrator WILL present the human approval gate. DO NOT present the gate yourself unless you are running standalone. DO NOT ask the user what to do next.
- IF running standalone: PRESENT the three spec documents (brainstorm, plan, revision) to the user. REQUIRE explicit approval before any implementation begins.
