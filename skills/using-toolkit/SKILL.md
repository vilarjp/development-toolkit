---
name: using-toolkit
description: Use at session start to discover and apply the right development workflow skill. This is the meta-skill governing tier classification, pipeline orchestration, and operating behaviors.
---

# Using the Development Toolkit

## The Rule

**YOU MUST check for an applicable skill BEFORE any response or action.** Even a 1% chance a skill might apply means you invoke it. DO NOT respond without checking.

## Tier Classification

When a task arrives, FIRST classify the tier, THEN route to the correct pipeline or skill.

### Tier Detection

| Tier | Criteria | Pipeline |
|------|----------|----------|
| **Trivial** | Change likely touches ≤3 files, no new abstractions, no cross-module dependencies, no architectural implications | TDD/Verification → Lint → Commit |
| **Standard (Resolve)** | Bug fix, error, regression, broken behavior | Context → Diagnosis → Execute → Review → Fix Loop → Commit → Solutions |
| **Standard (Dev)** | New feature, enhancement, refactor with architectural impact | Context → Brainstorm → Plan → Revision → Execute → Review → Fix Loop → Commit → Solutions |

### Hybrid Classification (Option C)

The agent assesses the tier, then confirms with the user:

```
This looks like a [trivial fix / bug fix / feature]. I'll use the [trivial / resolve / dev] pipeline.

[For trivial]: Straight to TDD → Commit. No brainstorm, no plan, no review.
[For resolve]: Diagnosis → Fix → Review → Commit.
[For dev]: Full pipeline: Brainstorm → Plan → Revision → Execute → Review → Commit.

OK, or do you want a different pipeline?
```

WAIT for confirmation. If the user disagrees, use their chosen tier.

## Skill Discovery

After tier classification, route to the correct entry point:

```
Task arrives → Classify tier
    |
    +-- Trivial? → development-toolkit:tdd + development-toolkit:commit-push
    +-- Bug/regression? → Resolve pipeline (see below)
    +-- Feature/change? → Dev pipeline (see below)
    |
    +-- Individual phase invocations:
        +-- Exploring a problem? → development-toolkit:brainstorm
        +-- Investigating a bug? → development-toolkit:diagnosis
        +-- Have brainstorm, need plan? → development-toolkit:plan
        +-- Have plan, need review? → development-toolkit:revision
        +-- Ready to implement? → development-toolkit:execute
        +-- Code written, need review? → development-toolkit:code-review
        +-- Review has findings? → development-toolkit:fix-loop
        +-- Ready to commit? → development-toolkit:commit-push
        +-- PR has review comments? → development-toolkit:pr-feedback
        +-- Need to understand project? → development-toolkit:context-loader
```

## Pipeline Orchestration

### Dev Pipeline (`/dev`)

```
Phase 0: context-loader
Phase 1: brainstorm (+ self-review + visual companion)
Phase 2: plan (+ research sub-agents + confidence check)
Phase 3: revision (+ scope creep + non-goals + plan update) → [HUMAN APPROVAL]
Phase 4: execute (TDD + incremental commits + execution log) → [TEST GATE]
Phase 5: code-review (structured findings + conditional reviewers)
Phase 5.5: fix-loop (auto-fix safe_auto + human triage + bounded re-review)
Phase 6: commit-push (lint gate + PR description)
Phase 7: solutions
```

### Resolve Pipeline (`/resolve`)

```
Phase 0: context-loader
Phase 1R: diagnosis (Opus/high investigator) → [HUMAN APPROVAL]
Phase 4: execute (Prove-It TDD + incremental commits + execution log) → [TEST GATE]
Phase 5: code-review
Phase 5.5: fix-loop
Phase 6: commit-push
Phase 7: solutions
```

### Trivial Pipeline (`/quick`)

```
TDD/Verification → Lint check → Commit
```

No spec directory. No artifacts. The commit message notes "trivial-tier change."

### Phase Transition Protocol

For each phase transition in any pipeline:
1. **Invoke** the next skill via `Skill: development-toolkit:<skill-name>`
2. **Verify** the expected artifact exists after the skill completes
3. **Pass** the spec directory path to the next skill

## Core Operating Behaviors

### Always-On (All Phases)

These apply at ALL times, across ALL skills. Non-negotiable.

**1. Enforce Simplicity**
Before finishing any implementation: Can this be done in fewer lines? Are abstractions earning their complexity? Would a staff engineer say "why didn't you just..."? The simplest solution that meets requirements wins. YAGNI.

**2. Verify, Don't Assume**
"Seems right" is never sufficient. Run the tests. Check acceptance criteria with evidence. "It should work" is not evidence. "Tests pass: 47/47" is evidence.

**3. Maintain Scope Discipline**
Touch ONLY what you are asked to touch. Do NOT remove comments, "clean up" adjacent code, refactor unrelated systems, or add features not in the spec. If you see something outside scope that needs improvement, MENTION it. Do NOT fix it.

**4. Surface Assumptions**
Before implementing anything non-trivial, state assumptions explicitly:
```
ASSUMPTIONS:
1. [assumption]
2. [assumption]
-> Correct me now or I proceed with these.
```

**5. Manage Confusion Actively**
When you encounter inconsistencies or unclear specs: STOP. Name the specific confusion. Present the tradeoff or ask the clarifying question. Wait for resolution. NEVER guess and hope. Confusion during execution is more dangerous than confusion during brainstorm.

### Phase-Injected

**Push Back When Warranted** (brainstorm + planning only)
You are not a yes-machine. If an approach has clear problems: point out the issue with concrete impact, propose an alternative, accept the human's decision if they override with full information. Sycophancy is a failure mode.

**Seek Forgiveness Strategically** (execution only)
During execution, small implementation decisions (variable names, helper placement, test organization) can be made without asking. Only surface decisions that affect architecture, public interfaces, or cross-module behavior.

## Artifact Numbering

| # | File | Phase | Pipeline |
|---|------|-------|----------|
| 01 | `01-brainstorm.md` or `01-diagnosis.md` | Brainstorm / Diagnosis | Dev / Resolve |
| 02 | `02-plan.md` | Planning | Dev only |
| 03 | `03-revision.md` | Revision | Dev only |
| 04 | `04-execution-log.md` | Execution | Dev, Resolve |
| 05 | `05-code-review.md` | Review + Fix Loop | Dev, Resolve |
| 06 | `06-solutions.md` | Post-pipeline | Dev, Resolve |

All artifacts carry YAML frontmatter with `status: draft | approved | superseded | archived`.

## No Inline Multi-Line Scripts

Do NOT pass multi-line Python scripts via `python3 -c`. Use temp files or `jq` instead.

## Transition

This skill does not transition. It is loaded at session start and remains active as a behavioral overlay. DO NOT ask the user what to do — IDENTIFY the correct skill and INVOKE it.
