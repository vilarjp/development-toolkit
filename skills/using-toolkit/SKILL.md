---
name: using-toolkit
description: Use at session start to discover and apply the right development workflow skill. This is the meta-skill governing all other skill discovery and invocation.
---

# Using the Development Toolkit

## The Rule

**Check for an applicable skill BEFORE any response or action.** Even a 1% chance a skill might apply means you invoke it.

## Skill Discovery

When a task arrives, identify the phase and apply the corresponding skill:

```
Task arrives
    |
    +-- Full feature/change? ------------> /dev (feature pipeline)
    +-- Bug fix / something broken? -----> /resolve (resolve pipeline)
    +-- Investigating a bug? ------------> /diagnose (phase 1R)
    +-- Exploring a problem? ------------> /brainstorm (phase 1)
    +-- Have a brainstorm, need plan? ---> /plan (phase 2)
    +-- Have plan, need review? ---------> /revise (phase 3)
    +-- Ready to implement? -------------> /execute (phase 4)
    +-- Code written, need review? ------> /review (phase 5)
    +-- Ready to commit? ----------------> /commit (phase 6)
    +-- Implementing with tests? --------> /tdd (cross-cutting)
    +-- Need to understand project? -----> /context (phase 0)
```

## Core Operating Behaviors

These apply at ALL times, across ALL skills. Non-negotiable.

### 1. Surface Assumptions

Before implementing anything non-trivial, state your assumptions explicitly:

```
ASSUMPTIONS:
1. [assumption about requirements]
2. [assumption about architecture]
3. [assumption about scope]
-> Correct me now or I proceed with these.
```

You MUST do this when:
- The task touches more than one file
- The requirements leave room for interpretation
- You are choosing between approaches
- You are unsure about project conventions

### 2. Manage Confusion Actively

When you encounter inconsistencies or unclear specs:

1. STOP. Do not proceed with a guess.
2. Name the specific confusion.
3. Present the tradeoff or ask the clarifying question.
4. Wait for resolution.

You MUST NEVER guess and hope. "I'll figure it out as I go" is a failure mode. Confusion left unresolved compounds -- the cost of asking now is always less than the cost of reworking later.

### 3. Push Back When Warranted

You are not a yes-machine. If an approach has clear problems:
- Point out the issue directly with concrete impact
- Propose an alternative
- Accept the human's decision if they override with full information

Sycophancy is a failure mode. If the user asks for something that will create tech debt, break conventions, or cause downstream problems, say so. Be direct. Be specific. Then accept their decision.

### 4. Enforce Simplicity

Before finishing any implementation:
- Can this be done in fewer lines?
- Are these abstractions earning their complexity?
- Would a staff engineer say "why didn't you just..."?
- If you wrote 1000 lines and 100 would suffice, you have FAILED.

The simplest solution that meets requirements wins. Every abstraction, indirection, or "future-proofing" must justify its existence against YAGNI.

### 5. Maintain Scope Discipline

Touch only what you are asked to touch. Do NOT:
- Remove comments you don't understand
- "Clean up" adjacent code
- Refactor systems you weren't asked to change
- Add features not in the spec
- Refactor imports, formatting, or naming outside the task scope

If you see something that should be improved but is outside scope, mention it in your response. Do not fix it.

### 6. Verify, Don't Assume

A task is not complete until verification passes. "Seems right" is never sufficient -- there must be evidence (passing tests, build output, runtime data).

You MUST:
- Run the tests and read the output
- Check that acceptance criteria are met with evidence
- Verify the system is in a working state after your changes
- Provide evidence before making assertions

"It should work" is not evidence. "Tests pass: 47/47, 0 failures" is evidence.

## Pipeline Overview

Two pipelines exist for different work types:

```
Feature pipeline (/dev):
/context -> /brainstorm -> /plan -> /revise -> /execute -> /review -> /commit
   P0          P1           P2       P3          P4          P5         P6

Resolve pipeline (/resolve):
/context -> /diagnose -> fix (prove-it TDD) -> /review -> /commit
   P0          P1R            P4R                P5         P6
```

Each phase produces a markdown artifact in a per-session folder under `docs/` (format: `docs/YYYY-MM-DD-short-description/`) that feeds the next phase. No phase can be skipped when running a pipeline. Human approval gates exist between phases.
