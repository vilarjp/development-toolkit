---
phase: solutions
date: "{{date}}"
status: draft
topic: "{{topic}}"
pipeline: "{{dev | resolve}}"
---

# Solutions: {{topic}}

## Problem Summary

{{2-3 sentences describing what was solved. Reference the original brainstorm or diagnosis.}}

## Root Cause

{{For bugs only — describe the mechanism of failure by behavior, not by file path and line number. Example: 'The validation middleware skips empty strings, allowing null values to reach the database layer.' The description must remain valid after refactoring. Omit this section for features.}}

## Approach

{{Brief description of the approach taken and why it was chosen over alternatives.}}

## Key Decisions

1. **{{Decision}}** — {{Rationale and any trade-offs accepted}}
2. **{{Decision}}** — {{Rationale and any trade-offs accepted}}

## Gotchas

- {{Describe as invariants to maintain, not code locations. Example: 'The cache must be invalidated before the write, not after' — not 'Line 42 of cache.ts must run before line 50 of db.ts'}}
- {{Edge case discovered during implementation — describe the behavior trigger and expected response}}

## Deferred Findings

{{Findings from code review that were deferred (not fixed). Omit this section if no findings were deferred.}}

| Title | Severity | File | Line | Impact | Reason Deferred |
|-------|----------|------|------|--------|-----------------|
| {{title}} | {{P1/P2/P3}} | `{{file}}` | {{line}} | {{impact}} | {{why it was deferred}} |
