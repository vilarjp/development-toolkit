---
phase: revision
date: "{{date}}"
status: draft
topic: "{{topic}}"
reviewed:
  - "docs/spec/01-brainstorm.md"
  - "docs/spec/02-plan.md"
---

# Revision: {{topic}}

## Items Reviewed

- [ ] Brainstorm problem statement aligns with plan goals
- [ ] All brainstorm goals have corresponding implementation steps
- [ ] Non-goals are not accidentally addressed in the plan
- [ ] Dependency graph has no cycles
- [ ] PARALLEL steps have no hidden shared-state dependencies
- [ ] SEQUENTIAL steps genuinely require ordering
- [ ] Acceptance criteria are testable and specific
- [ ] Test strategy covers all acceptance criteria
- [ ] Risk mitigations are actionable, not aspirational
- [ ] Estimated scopes are realistic given the file list
- [ ] Execution waves respect the dependency graph

## Gaps Found

### Gap 1: {{Title}}

- **Location:** {{Which document and section}}
- **Severity:** {{P0-Critical | P1-Important | P2-Minor}}
- **Resolution:** {{What was changed or added to address this}}

### Gap 2: {{Title}}

- **Location:** {{Which document and section}}
- **Severity:** {{P0-Critical | P1-Important | P2-Minor}}
- **Resolution:** {{What was changed or added to address this}}

### Gap 3: {{Title}}

- **Location:** {{Which document and section}}
- **Severity:** {{P0-Critical | P1-Important | P2-Minor}}
- **Resolution:** {{What was changed or added to address this}}

## Adjustments Made

### Adjustment 1: {{What changed}}

- **Reason:** {{Why this adjustment was necessary}}

### Adjustment 2: {{What changed}}

- **Reason:** {{Why this adjustment was necessary}}

## Final Sign-Off Checklist

- [ ] All P0 gaps resolved
- [ ] All P1 gaps resolved or explicitly deferred with rationale
- [ ] Dependency graph validated — no cycles, parallelism is safe
- [ ] Execution waves updated to reflect adjustments
- [ ] Plan is implementable as-is — no ambiguous steps remain
- [ ] Test strategy is sufficient to verify all acceptance criteria

## Verdict

**{{APPROVED | NEEDS CHANGES}}**

{{If NEEDS CHANGES: describe what must be addressed before proceeding to execution.}}
