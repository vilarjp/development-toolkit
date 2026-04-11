---
name: revision
description: Use after brainstorm and plan are written to cross-check both documents for gaps, inconsistencies, scope creep, and non-goals coverage. Updates 02-plan.md in place, produces 03-revision.md, and triggers human approval gate.
---

# Revision (Phase 3)

Cross-document review that catches errors, gaps, and inconsistencies between the brainstorm and the plan BEFORE any code is written. This is the last checkpoint before implementation begins.

## Prerequisites

- `01-brainstorm.md` MUST exist in the active spec directory.
- `02-plan.md` MUST exist in the same directory.
- Project context from Phase 0 MUST be available.

## Process

### Phase 3.1 — Load Both Documents

1. Read `01-brainstorm.md` — every section, every bullet, every assumption.
2. Read `02-plan.md` — every step, every file list, every acceptance criterion.
3. Ensure project context is loaded.

You MUST have all three inputs before proceeding.

### Phase 3.2 — Cross-Reference Consistency

For each item, verify or flag:

1. **Goal coverage:** Every brainstorm goal maps to at least one plan step.
2. **Non-goal respect:** No plan step implements a non-goal.
3. **Non-goals have negative tests:** The plan's test strategy includes negative test cases for each brainstorm non-goal (verifying that excluded behavior does NOT occur).
4. **Assumption alignment:** Brainstorm assumptions are reflected in plan design decisions.
5. **Direction fidelity:** Plan follows the brainstorm's recommended direction.
6. **Trade-off acknowledgment:** Brainstorm trade-offs appear in plan's risk section.
7. **Constraint adherence:** Plan steps respect brainstorm constraints.
8. **Success criteria:** Plan's output satisfies brainstorm's definition of success.

### Phase 3.3 — Scope Creep Detection

Compare the brainstorm's recommended scope against the plan's total scope:

1. Read the brainstorm's recommended direction complexity (XS-XL).
2. Sum the plan's step estimates.
3. If the plan scope is significantly larger (e.g., brainstorm says M, plan totals L or XL), flag it:

```
SCOPE CREEP DETECTED:
- Brainstorm recommended scope: [M]
- Plan total scope: [L]
- Growth areas: [which steps go beyond the brainstorm's direction]

This may be justified (the brainstorm underestimated) or a sign of scope creep.
Options:
  A) Accept the larger scope (update brainstorm to match)
  B) Trim the plan to match the brainstorm scope
  C) Split into multiple iterations
```

Record the finding in the revision document regardless of the user's decision.

### Phase 3.4 — Internal Plan Consistency

1. **Dependency acyclicity:** No cycles in the dependency graph.
2. **Parallelization correctness:** PARALLEL steps have no shared files or interface dependencies.
3. **File conflict detection:** No two PARALLEL steps in the same wave touch the same file.
4. **Path consistency:** Same file referenced the same way everywhere.
5. **Wave-dependency alignment:** Execution Waves table matches step dependencies.
6. **Acceptance criteria coverage:** Every step has testable acceptance criteria.
7. **Test file paths:** Every behavior-bearing step declares its test file path.
8. **Test strategy coverage:** Test strategy verifies all acceptance criteria.

### Phase 3.5 — Completeness and Feasibility

1. **Orphaned goals:** No brainstorm goals without plan steps.
2. **Naked steps:** No plan steps without acceptance criteria.
3. **Unmitigated risks:** No risks without mitigations.
4. **Test pyramid balance:** Realistic distribution (~70/20/10).
5. **Pattern compatibility:** Proposed patterns compatible with existing codebase.
6. **Dependency availability:** Proposed dependencies installable and compatible.

### Phase 3.6 — Apply Adjustments

For each gap found:

1. **Classify severity:** P0 (blocks execution), P1 (problems during execution), P2 (polish).
2. **For P0 and P1:** Update `02-plan.md` in place with the fix.
3. **Append to plan's Changelog:** After updating the plan, append an entry to the `## Changelog` section of `02-plan.md`:
   ```
   ### Revision [date]
   - [What changed] — [Why, referencing revision gap #]
   ```
4. **For P2:** Record in revision document, do not modify source documents.
5. **Record every change** in the revision document.

Do NOT introduce new features or expand scope. Fix gaps and inconsistencies only.

### Phase 3.7 — Write Revision Artifact

Write `03-revision.md` using `templates/03-revision.md` with:
- Items Reviewed checklist (pass/fail each)
- Scope Creep Check results
- Gaps Found (all gaps with location, severity, resolution)
- Adjustments Made (every change to source docs with rationale)
- Final Sign-Off Checklist
- Verdict: APPROVED or NEEDS CHANGES

Confirm that `02-plan.md` has been updated in place and its Changelog section reflects all revisions.

### Phase 3.8 — HUMAN APPROVAL GATE

```
All three specification documents are ready:
  1. 01-brainstorm.md — Problem exploration and recommended direction
  2. 02-plan.md — Technical implementation plan (updated with revision changes)
  3. 03-revision.md — Cross-document review and adjustments

Reply "go" to proceed to implementation, or describe changes needed.
```

Do NOT proceed without explicit human approval.

## Rules

- Read FULL text of both documents. Do not skim.
- Do NOT introduce new features during revision.
- If a critical gap requires rethinking the approach, say so explicitly.
- The revision document must be complete enough to understand all adjustments without reading the conversation.
- Do NOT skip the human approval gate.

## Transition

- IF in pipeline: RETURN control to orchestrator.
- IF standalone: present the three spec documents and require approval.
