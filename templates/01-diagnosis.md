---
phase: diagnosis
date: "{{date}}"
status: "{{status}}"
topic: "{{topic}}"
severity: "{{TRIVIAL | STANDARD | COMPLEX}}"
---

# Diagnosis: {{topic}}

## Bug Description

{{What was reported. Expected behavior vs actual behavior. Who is affected.}}

## Investigation Trail

| Step | What I Searched/Ran | What I Found |
|------|---------------------|--------------|
| 1    | {{grep/read/bash}}  | {{finding}}  |
| 2    | {{grep/read/bash}}  | {{finding}}  |
| 3    | {{grep/read/bash}}  | {{finding}}  |

## Pattern Analysis

{{Working examples found in the codebase. How the working code differs from the broken code. Key observations from the comparison.}}

## Hypotheses

| # | Hypothesis | Evidence For | Evidence Against | Verdict |
|---|-----------|-------------|-----------------|---------|
| 1 | {{structurally different hypothesis}} | {{evidence}} | {{evidence}} | {{CONFIRMED / REJECTED / INCONCLUSIVE}} |
| 2 | {{structurally different hypothesis}} | {{evidence}} | {{evidence}} | {{CONFIRMED / REJECTED / INCONCLUSIVE}} |
| 3 | {{structurally different hypothesis}} | {{evidence}} | {{evidence}} | {{CONFIRMED / REJECTED / INCONCLUSIVE}} |

Hypotheses MUST be structurally different (e.g., "missing null check" vs "race condition" vs "wrong API contract").

## Root Cause

{{Clear explanation of WHY the bug happens, referencing evidence from the hypotheses table. Reference specific files and lines.}}

## Reproduction Test

- **File:** `{{path/to/test-file}}`
- **Test name:** `{{descriptive name including bug reference}}`
- **Status:** {{RED (fails as expected) | UNTESTABLE — reason}}

## Hotspots

| File:Function | Why Reviewer Should Focus Here |
|--------------|-------------------------------|
| {{path:function}} | {{reason}} |

## Suggested Fix

{{Brief description of the fix approach. Reference the root cause and the specific code to change.}}

## Concerns

{{Low-confidence areas, risks of the suggested fix, potential regressions, things to watch out for.}}
