---
phase: plan
date: "{{date}}"
status: draft
topic: "{{topic}}"
origin: "{{spec_dir}}/01-brainstorm.md"
---

# Implementation Plan: {{topic}}

## Technical Architecture

### Design Decisions

1. **{{Decision}}** — {{Rationale}}
2. **{{Decision}}** — {{Rationale}}
3. **{{Decision}}** — {{Rationale}}

### Component Diagram

```
{{ASCII or Mermaid diagram showing component relationships}}
```

## Implementation Steps

### Step 1: {{Title}} [SEQUENTIAL]

- **Files:** `{{path/to/file}}`
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] {{Specific, testable criterion}}
  - [ ] {{Specific, testable criterion}}
- **Test Strategy:** {{Unit test / Integration test / E2E test — what specifically to test}}
- **Estimated Scope:** {{XS | S | M | L | XL}}

### Step 2: {{Title}} [PARALLEL]

- **Files:** `{{path/to/file}}`, `{{path/to/file}}`
- **Dependencies:** Step 1
- **Acceptance Criteria:**
  - [ ] {{Specific, testable criterion}}
  - [ ] {{Specific, testable criterion}}
- **Test Strategy:** {{Unit test / Integration test / E2E test — what specifically to test}}
- **Estimated Scope:** {{XS | S | M | L | XL}}

### Step 3: {{Title}} [PARALLEL]

- **Files:** `{{path/to/file}}`
- **Dependencies:** Step 1
- **Acceptance Criteria:**
  - [ ] {{Specific, testable criterion}}
  - [ ] {{Specific, testable criterion}}
- **Test Strategy:** {{Unit test / Integration test / E2E test — what specifically to test}}
- **Estimated Scope:** {{XS | S | M | L | XL}}

### Step 4: {{Title}} [SEQUENTIAL]

- **Files:** `{{path/to/file}}`
- **Dependencies:** Steps 2, 3
- **Acceptance Criteria:**
  - [ ] {{Specific, testable criterion}}
  - [ ] {{Specific, testable criterion}}
- **Test Strategy:** {{Unit test / Integration test / E2E test — what specifically to test}}
- **Estimated Scope:** {{XS | S | M | L | XL}}

## Execution Waves

| Wave | Steps   | Mode       | Rationale                                    |
|------|---------|------------|----------------------------------------------|
| 1    | Step 1  | SEQUENTIAL | {{Why this must go first}}                   |
| 2    | Steps 2, 3 | PARALLEL | {{Why these can run concurrently}}          |
| 3    | Step 4  | SEQUENTIAL | {{Why this depends on wave 2 completing}}    |

## Test Strategy

### Unit Tests
- **Scope:** {{What units are covered}}
- **Target ratio:** ~70% of total tests

### Integration Tests
- **Scope:** {{What integrations are covered}}
- **Target ratio:** ~20% of total tests

### E2E Tests
- **Scope:** {{What user flows are covered}}
- **Target ratio:** ~10% of total tests

## Risks and Edge Cases

| Risk                        | Impact     | Mitigation                              |
|-----------------------------|------------|-----------------------------------------|
| {{Risk description}}        | {{H/M/L}}  | {{How to prevent or handle it}}        |
| {{Risk description}}        | {{H/M/L}}  | {{How to prevent or handle it}}        |
| {{Risk description}}        | {{H/M/L}}  | {{How to prevent or handle it}}        |

## Open Questions Deferred

1. {{Question that does not block implementation but needs future resolution}}
2. {{Question deferred to a follow-up iteration}}
