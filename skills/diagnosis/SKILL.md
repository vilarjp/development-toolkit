---
name: diagnosis
description: Use when investigating a bug, error, or regression.
---

# Diagnosis (Phase 1R)

Investigate a bug through structured root-cause analysis. This phase replaces brainstorm in the resolve pipeline. Bugs need investigation, not brainstorming.

## Prerequisites

Phase 0 (context-loader) MUST have run. If no project context is available, RUN `Skill: development-toolkit:context-loader` first.

## Process

### Step 1 — DISPATCH the Resolve Investigator

DISPATCH the `resolve-investigator` agent with:
- **Model:** Latest Opus, effort: high
- **Subagent type:** `development-toolkit:resolve-investigator`
- **Prompt includes:**
  - The bug description from the user's original request
  - The project context from Phase 0
  - Any error logs, screenshots, or stack traces provided

The investigator follows a four-phase protocol: root-cause investigation, pattern analysis, hypothesis testing, and reproduction test writing.

WAIT for the investigator to complete. READ its full output.

### Step 2 — VERIFY and Supplement

If the investigator's findings are incomplete:
- RUN targeted `Grep` or `Read` calls on identified files
- Do NOT re-investigate from scratch — supplement what was found
- If the investigator reported NEEDS_CONTEXT or BLOCKED, provide missing context and re-dispatch

If findings are solid, skip this step.

### Step 3 — WRITE 01-diagnosis.md

1. CREATE spec directory: `docs/YYYY-MM-DD-short-description/`
2. WRITE `01-diagnosis.md` using `templates/01-diagnosis.md` with all sections filled:
   - Bug description, investigation trail, pattern analysis
   - Hypotheses table (minimum 3 structurally different, or 2 for narrow bugs)
   - Root cause with file:line references
   - Reproduction test (file, name, RED status or UNTESTABLE with reason)
   - Hotspots, suggested fix, concerns
3. SET frontmatter: `status: draft`, `date`, `topic`, `severity`
4. No placeholders, no TODOs. Complete and standalone.

### Step 4 — CLASSIFY Severity

| Severity | Criteria |
|----------|----------|
| **TRIVIAL** | Single obvious cause, >95% confidence, one-line fix, no side effects |
| **STANDARD** | Clear root cause, non-trivial fix, 1-3 files |
| **COMPLEX** | Multiple causes, race conditions, architectural, 4+ files |

### Step 5 — PRESENT for Human Approval

Present the diagnosis summary:
- Root cause (one sentence)
- Severity classification
- Suggested fix (one sentence)
- Hotspots (file:line list)
- Path to diagnosis document

## Rules

1. **No fixes without root-cause investigation.** Symptom fixes are failure.
2. **No brainstorming solutions.** Diagnosis identifies root cause and suggests a targeted fix.
3. **Reproduction test is mandatory.** If untestable, document why.
4. **Minimal fix only.** Address root cause and nothing else.
5. **If deeper architectural problem is found,** classify as COMPLEX and let the user decide the approach.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I can see the bug, let me just fix it" | You see a symptom. The root cause may be elsewhere. Investigate first. |
| "The stack trace points directly to the problem" | Stack traces show where the failure surfaces, not where it originates. Trace backward. |
| "This is a trivial typo, no investigation needed" | If it is truly trivial (>95% confidence), classify as TRIVIAL and fix. But verify confidence first. |
| "The user already told me the root cause" | The user told you their hypothesis. Your job is to verify it with evidence. |

## Red Flags — Self-Check

- You proposed a fix before completing the investigation protocol
- You have zero hypotheses documented
- You skipped the reproduction test
- You are modifying production code (you are read-only in this phase)
- Your root cause explanation does not reference specific code you actually read

## Transition

- IF in pipeline: RETURN control with diagnosis summary.
- IF standalone: INFORM user to invoke `development-toolkit:execute` or the resolve pipeline.
