---
phase: execution
date: "{{date}}"
status: draft
topic: "{{topic}}"
pipeline: "{{dev | resolve}}"
waves_completed: "{{N/N}}"
---

# Execution Log: {{topic}}

## Execution Summary

### Wave 1 — {{description}}

- **Steps completed:** {{Step 1, Step 2}}
- **Test files written:**
  - `{{path/to/test-file}}`
  - `{{path/to/test-file}}`
- **Commit:** `{{short SHA}}` — {{commit message}}
- **Tests passing:** {{YES / NO — details}}

### Wave N — {{description}}

- **Steps completed:** {{Step N}}
- **Test files written:**
  - `{{path/to/test-file}}`
- **Commit:** `{{short SHA}}` — {{commit message}}
- **Tests passing:** {{YES / NO — details}}

## Unexpected Decisions

1. **{{Decision}}** — {{What the plan said vs what was actually done, and why the deviation was necessary}}
2. **{{Decision}}** — {{What the plan said vs what was actually done, and why the deviation was necessary}}

## Verification Mode Changes

{{Infrastructure or configuration changes that used verification mode (run build + run existing tests) instead of full RED-GREEN-REFACTOR. List each file and why TDD was not applicable.}}

- `{{path/to/config-file}}` — {{reason, e.g. "build configuration, no behavior to test"}}
