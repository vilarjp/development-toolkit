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

{{For bugs only — what caused the issue. Reference specific files and lines. Omit this section for features.}}

## Approach

{{Brief description of the approach taken and why it was chosen over alternatives.}}

## Key Decisions

1. **{{Decision}}** — {{Rationale and any trade-offs accepted}}
2. **{{Decision}}** — {{Rationale and any trade-offs accepted}}

## Gotchas

- {{Something surprising, tricky, or non-obvious that a future developer working in this area should know}}
- {{Edge case discovered during implementation that wasn't anticipated in the plan}}

## Deferred Findings

{{Findings from code review that were deferred (not fixed). Omit this section if no findings were deferred.}}

| Title | Severity | File | Line | Impact | Reason Deferred |
|-------|----------|------|------|--------|-----------------|
| {{title}} | {{P1/P2/P3}} | `{{file}}` | {{line}} | {{impact}} | {{why it was deferred}} |
