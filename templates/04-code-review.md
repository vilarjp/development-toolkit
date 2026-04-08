---
phase: code-review
date: "{{date}}"
status: draft
topic: "{{topic}}"
reviewers:
  - plan-alignment-reviewer
  - code-quality-reviewer
  - convention-reviewer
  - test-reviewer
  - security-reviewer
---

# Code Review: {{topic}}

## Review Summary

- **Total issues found:** {{count}}
- **P0 — Critical (must fix):** {{count}}
- **P1 — Important:** {{count}}
- **P2 — Minor:** {{count}}
- **P3 — Suggestion:** {{count}}

## Reviewer Scope

| Reviewer                  | Scope                                    | Files Reviewed          |
|---------------------------|------------------------------------------|-------------------------|
| Plan Alignment Reviewer   | Plan vs. implementation match            | {{file list}}           |
| Code Quality Reviewer     | Correctness, readability, architecture   | {{file list}}           |
| Convention Reviewer       | Project pattern adherence                | {{file list}}           |
| Test Reviewer             | Test quality, coverage, TDD adherence    | {{file list}}           |
| Security Reviewer         | Auth, input validation, data safety      | {{file list}}           |

## Critical Issues P0 — Must Fix

### P0-1: {{Title}}

- **File:** `{{path/to/file}}:{{line}}`
- **Reviewer:** {{Which reviewer found this}}
- **Description:** {{What is wrong}}
- **Evidence:** {{Code snippet or specific observation}}
- **Suggested Fix:** {{How to resolve}}

## Important Issues P1

### P1-1: {{Title}}

- **File:** `{{path/to/file}}:{{line}}`
- **Reviewer:** {{Which reviewer found this}}
- **Description:** {{What is wrong}}
- **Evidence:** {{Code snippet or specific observation}}
- **Suggested Fix:** {{How to resolve}}

## Minor Issues P2

### P2-1: {{Title}}

- **File:** `{{path/to/file}}:{{line}}`
- **Reviewer:** {{Which reviewer found this}}
- **Description:** {{What could be improved}}
- **Suggested Fix:** {{How to resolve}}

## Suggestions P3

### P3-1: {{Title}}

- **File:** `{{path/to/file}}:{{line}}`
- **Reviewer:** {{Which reviewer found this}}
- **Description:** {{Idea for improvement}}

## What's Done Well

1. {{Positive observation — specific, not generic}}
2. {{Positive observation — specific, not generic}}
3. {{Positive observation — specific, not generic}}

## Verdict

**{{APPROVE | REQUIRES CHANGES}}**

{{If REQUIRES CHANGES: list the P0 and P1 items that must be addressed before approval.}}
