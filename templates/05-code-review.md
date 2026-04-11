---
phase: code-review
date: "{{date}}"
status: draft
topic: "{{topic}}"
reviewers_dispatched:
  - "{{reviewer-name}}"
reviewers_conditional_skipped:
  - "{{reviewer-name}} — {{reason}}"
---

# Code Review: {{topic}}

## Review Summary

- **Total issues found:** {{count}}
- **P0 — Critical (must fix):** {{count}}
- **P1 — Important (should fix):** {{count}}
- **P2 — Moderate (fix if straightforward):** {{count}}
- **P3 — Low (user's discretion):** {{count}}
- **Suppressed (below confidence threshold):** {{count}}
- **Pre-existing (not caused by this diff):** {{count}}

## Reviewer Scope

### Stage 1 — Spec Compliance (Blocking Gate)

| Reviewer | Dispatch | Scope | Files Reviewed |
|----------|----------|-------|----------------|
| plan-alignment-reviewer | {{Dispatched / Skipped — no 02-plan.md}} | Plan vs implementation match | {{file list}} |

**Stage 1 verdict:** {{PASSED — no P0/P1 spec gaps / FAILED — spec gaps found, Stage 2 skipped}}

### Stage 2 — Code Quality (Parallel)

| Reviewer | Dispatch | Scope | Files Reviewed |
|----------|----------|-------|----------------|
| code-quality-reviewer | Always | Correctness, readability, architecture, performance | {{file list}} |
| test-reviewer | Always | Test quality, coverage, TDD adherence | {{file list}} |
| security-reviewer | {{Conditional / Skipped — reason}} | Auth, input validation, data safety, payment code | {{file list}} |
| convention-reviewer | {{Conditional / Skipped — reason}} | Project pattern adherence (non-blocking) | {{file list}} |

## Round 1

### P0 — Critical

| # | Title | File | Line | Impact | Autofix | Confidence | Reviewers |
|---|-------|------|------|--------|---------|------------|-----------|
| 1 | {{title}} | `{{file}}` | {{line}} | {{impact}} | {{safe_auto/gated_auto/manual/advisory}} | {{0.00}} | {{reviewer1, reviewer2}} |

### P1 — Important

| # | Title | File | Line | Impact | Autofix | Confidence | Reviewers |
|---|-------|------|------|--------|---------|------------|-----------|
| 1 | {{title}} | `{{file}}` | {{line}} | {{impact}} | {{autofix}} | {{0.00}} | {{reviewers}} |

### P2 — Moderate

| # | Title | File | Line | Impact | Autofix | Confidence | Reviewers |
|---|-------|------|------|--------|---------|------------|-----------|
| 1 | {{title}} | `{{file}}` | {{line}} | {{impact}} | {{autofix}} | {{0.00}} | {{reviewers}} |

### P3 — Low

| # | Title | File | Line | Impact | Autofix | Confidence | Reviewers |
|---|-------|------|------|--------|---------|------------|-----------|
| 1 | {{title}} | `{{file}}` | {{line}} | {{impact}} | {{autofix}} | {{0.00}} | {{reviewers}} |

### Pre-existing Issues

| # | Title | File | Line | Severity | Reviewers |
|---|-------|------|------|----------|-----------|
| 1 | {{title}} | `{{file}}` | {{line}} | {{severity}} | {{reviewers}} |

### What's Done Well

1. {{Positive observation — specific, not generic}}
2. {{Positive observation — specific, not generic}}

### Residual Risks

- {{Risk that cannot be resolved by code changes alone}}

### Testing Gaps

- {{Area where test coverage is insufficient}}

### Verdict (Round 1)

**{{APPROVED | REQUIRES CHANGES}}**

{{If REQUIRES CHANGES: list the P0 and P1 items that must be addressed.}}

---

## Applied Fixes (safe_auto)

| # | Finding | File | What Was Fixed |
|---|---------|------|----------------|
| 1 | {{original finding title}} | `{{file}}` | {{description of auto-applied fix}} |

## Round 2

### Re-reviewed by: {{reviewer1, reviewer2}}
### Scope: {{files modified by fixes}}

| # | Title | File | Line | Severity | Impact | Autofix | Confidence | Status |
|---|-------|------|------|----------|--------|---------|------------|--------|
| 1 | {{title}} | `{{file}}` | {{line}} | {{severity}} | {{impact}} | {{autofix}} | {{0.00}} | {{NEW / RESOLVED / PERSISTS}} |

### Verdict (Round 2)

**{{APPROVED | REQUIRES CHANGES}}**

{{Final assessment after fix loop. If issues remain after iteration cap (3 rounds max), list them here with "HUMAN DECISION REQUIRED".}}
