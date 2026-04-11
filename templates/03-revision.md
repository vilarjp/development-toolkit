---
phase: revision
date: "{{date}}"
status: draft
topic: "{{topic}}"
reviewed:
  - "{{spec_dir}}/01-brainstorm.md"
  - "{{spec_dir}}/02-plan.md"
---

# Revision: {{topic}}

## Items Reviewed

- [ ] Brainstorm problem statement aligns with plan goals
- [ ] All brainstorm goals have corresponding implementation steps
- [ ] Non-goals are not accidentally addressed in the plan
- [ ] Non-goals have corresponding negative test cases in the test strategy
- [ ] Dependency graph has no cycles
- [ ] PARALLEL steps have no shared file scope or shared interface dependencies
- [ ] SEQUENTIAL steps genuinely require ordering
- [ ] Acceptance criteria are testable and specific
- [ ] Test strategy covers all acceptance criteria
- [ ] Every behavior-bearing step declares a test file path
- [ ] Risk mitigations are actionable, not aspirational
- [ ] Estimated scopes are realistic given the file list
- [ ] Execution waves respect the dependency graph
- [ ] Plan scope is proportional to the brainstorm's recommended direction (flag if significantly larger)

## Scope Creep Check

- **Brainstorm recommended scope:** {{XS | S | M | L | XL}}
- **Plan total scope:** {{sum of step estimates}}
- **Creep detected:** {{YES — explain what grew beyond brainstorm scope / NO}}

## Gaps Found

### Gap 1: {{Title}}

- **Location:** {{Which document and section}}
- **Severity:** {{P0-Critical | P1-Important | P2-Minor}}
- **Resolution:** {{What was changed or added to address this}}

### Gap 2: {{Title}}

- **Location:** {{Which document and section}}
- **Severity:** {{P0-Critical | P1-Important | P2-Minor}}
- **Resolution:** {{What was changed or added to address this}}

## Adjustments Made

### Adjustment 1: {{What changed}}

- **Reason:** {{Why this adjustment was necessary}}
- **Updated in plan:** {{YES — section reference / NO}}

## Final Sign-Off Checklist

- [ ] All P0 gaps resolved
- [ ] All P1 gaps resolved or explicitly deferred with rationale
- [ ] Scope creep addressed or acknowledged by user
- [ ] Dependency graph validated — no cycles, parallelism is safe
- [ ] Execution waves updated to reflect adjustments
- [ ] Plan is implementable as-is — no ambiguous steps remain
- [ ] Test strategy is sufficient to verify all acceptance criteria
- [ ] 02-plan.md updated in place with all approved changes
- [ ] 02-plan.md Changelog section documents all revisions

## Verdict

**{{APPROVED | NEEDS CHANGES}}**

{{If NEEDS CHANGES: describe what must be addressed before proceeding to execution.}}
