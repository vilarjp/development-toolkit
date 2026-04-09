---
name: diagnosis
description: Use when investigating a bug, error, or regression. Dispatches the resolve-investigator agent for structured root-cause analysis. Produces docs/YYYY-MM-DD-topic/01-diagnosis.md with investigation trail, hypotheses, root cause, and suggested fix.
---

# Diagnosis (Phase 1R)

Investigate a bug through structured root-cause analysis. This phase replaces brainstorm in the resolve pipeline. Bugs need investigation, not brainstorming.

## Prerequisites

Phase 0 (context-loader) MUST have run. If no project context is available in the conversation, RUN `Skill: development-toolkit:context-loader` first. DO NOT proceed without project context.

## Process

EXECUTE these steps in strict order. Do not skip steps. Do not jump to a fix.

### Step 1 -- DISPATCH the Resolve Investigator

DISPATCH the `resolve-investigator` agent (subagent type: `development-toolkit:resolve-investigator`) with:
- The bug description from the user's original request
- The project context from Phase 0
- Any error logs, screenshots, or stack traces provided

The investigator follows a four-phase protocol: root-cause investigation, pattern analysis, hypothesis testing, and reproduction test writing. It produces a structured diagnosis report.

WAIT for the investigator to complete. READ its full output.

### Step 2 -- VERIFY and Supplement

If the investigator's findings are incomplete or you need to verify a specific claim:
- RUN targeted `Grep` or `Read` calls on the files identified by the investigator
- Do NOT re-investigate from scratch -- supplement what the investigator found
- If the investigator reported NEEDS_CONTEXT or BLOCKED, ALWAYS provide the missing context and re-dispatch

If the investigator's findings are solid, skip this step.

### Step 3 -- WRITE 01-diagnosis.md

CREATE the per-session spec directory: `docs/YYYY-MM-DD-short-description/` (e.g., `docs/2026-04-08-fix-race-condition/`). Use today's date and a kebab-case short description derived from the bug.

WRITE `01-diagnosis.md` using the template from `templates/01-diagnosis.md` with:
- Bug description (reported vs expected vs actual)
- Investigation trail table (every search, read, and command the investigator ran)
- Pattern analysis (working examples compared to broken code)
- Hypotheses table with verdicts (minimum 3 structurally different hypotheses, or 2 for very narrow bugs)
- Confirmed root cause with file:line references
- Reproduction test plan (file path, test name, RED status or UNTESTABLE with reason)
- Hotspots table (files/functions where reviewers should focus)
- Suggested fix (minimal -- address root cause only)
- Concerns (risks, low-confidence areas, potential regressions)

REPLACE all `{{placeholder}}` tokens. No placeholders, no TODOs. The document MUST be complete and standalone.

### Step 4 -- CLASSIFY Severity

APPLY bug-specific complexity criteria:

| Severity | Criteria |
|----------|----------|
| **TRIVIAL** | Single obvious cause, >95% confidence, one-line or few-line fix, no side effects |
| **STANDARD** | Clear root cause, non-trivial fix, 1-3 files affected |
| **COMPLEX** | Multiple interacting causes, race conditions, architectural issues, 4+ files |

SET the `severity` field in the diagnosis document's frontmatter.

### Step 5 -- PRESENT for Human Approval

PRESENT the diagnosis summary to the user. The calling pipeline (resolve-pipeline) handles the approval gate format and trivial escape hatch logic. RETURN control to the pipeline after presenting the diagnosis with:

- Root cause (one sentence)
- Severity classification
- Suggested fix (one sentence)
- Hotspots (file:line list)
- Path to the diagnosis document

## Rules

1. **Do NOT propose fixes without root-cause investigation.** Symptom fixes are failure. A fix that addresses the symptom but not the root cause will break again.

2. **Do NOT brainstorm solutions.** The diagnosis identifies the root cause and suggests a targeted fix. Generating options is for features, not bugs.

3. **The reproduction test is mandatory.** If the bug cannot be reproduced in a test, ALWAYS document why in the diagnosis and proceed with caution. An untestable diagnosis is a risk factor.

4. **Minimal fix only.** The suggested fix MUST address the root cause and nothing else. No refactoring, no cleanup, no "while we're here" improvements.

5. **If the investigation reveals a deeper architectural problem,** CLASSIFY it as COMPLEX and note that a feature-level pipeline may be more appropriate. NEVER decide for the user -- let the user decide.

## Anti-Patterns

### "I Already Know What's Wrong"
ALWAYS surface it as a hypothesis. The investigation validates hypotheses -- that is its job. If you are right, the investigation is fast. If you are wrong, you just avoided shipping a wrong fix.

### "Let Me Just Try This Quick Fix"
No. Fixes without investigation are guesses. Guesses that work by coincidence break when conditions change. Investigate first.

### "The Error Message Tells Me Everything"
Error messages describe symptoms, not causes. The stack trace shows where it crashed, not why. ALWAYS trace backward to the root cause.

### "This Is Obviously a Trivial Bug"
CLASSIFY it as TRIVIAL only after investigation confirms >95% confidence. "Obviously trivial" bugs have caused production incidents.

## Transition

WHEN this skill completes:
- RETURN control to the resolve-pipeline orchestrator with the diagnosis summary (root cause, severity, suggested fix, hotspots, artifact path).
- DO NOT apply any fix yourself. DO NOT write code. DO NOT invoke the execute or tdd skills.
- DO NOT ask the user what to do next — the orchestrator WILL present the diagnosis approval gate.
- IF running standalone: PRESENT the diagnosis to the user. INFORM them: "Diagnosis complete. Invoke `development-toolkit:resolve-pipeline` to proceed with the fix, or review the diagnosis document first."
