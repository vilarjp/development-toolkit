---
name: brainstorm
description: Use when exploring a new feature, change, or problem before committing to a direction. Produces 01-brainstorm.md in a per-session spec directory with problem statement, goals, options, and recommended direction.
---

# Brainstorm (Phase 1)

Explore the problem space before committing to a solution. This phase produces a structured brainstorm document that feeds the planning phase. Every step below is MANDATORY — DO NOT skip or reorder phases.

## Prerequisites

Phase 0 (context-loader) must have run. If no project context block is present in this conversation, invoke `Skill: development-toolkit:context-loader` NOW before proceeding.

## Process

Execute these phases in strict order. Do not skip ahead. Do not write the artifact until Phase 1.7 is complete and the user has confirmed the recommended direction.

### Phase 1.1 — Understand the Request

READ the user's description. Then ASK clarifying questions using the structured interview protocol below.

**Mandatory questions (ALWAYS asked, one at a time, multiple-choice):**

1. **WHY** — What problem does this solve?
   - Options: UX friction / Missing capability / Technical debt / Performance issue / Bug or regression / Other: ___
2. **WHO** — Who is affected?
   - Options: All users / Specific user type: ___ / Developers or operators / Internal systems / Other: ___
3. **OPEN** — Anything else I should know?
   - Options: Nothing else / More context (please share) / There are constraints or gotchas

**Conditional follow-up questions (asked only if mandatory answers are sparse):**

4. Current state — How does it work today?
5. Success criteria — How will you know it is working?

**Rules:**
- ASK ONE question at a time. NEVER batch.
- ALWAYS USE multiple-choice format with an "Other" option.
- Maximum 5 questions total. State remaining unknowns as assumptions.
- STOP early if answers are clear from context.
- Mark the recommended option with `[Recommended]`.

### Phase 1.2 — Explore the Problem Space

After gathering information, PRODUCE:

**Problem Statement:** One paragraph. Specific, not vague. "Checkout takes 3 clicks when it should take 1" not "users are frustrated."

**Goals:** Numbered list. Each MUST be measurable or verifiable — you MUST be able to write an acceptance criterion for it.

**Non-Goals:** Numbered list. What this effort explicitly will NOT address. Prevents scope creep.

**Constraints:** Timeline, tech stack limitations, backwards compatibility requirements, deployment constraints.

**Assumptions:** Numbered list with verification status:
```
1. [assumption] — verified by reading code: YES/NO
2. [assumption] — verified: YES/NO
```

**Key Unknowns:** Open questions. Mark which can be resolved now vs during implementation.

### Phase 1.3 — Generate Options

PRODUCE 2-3 genuinely different approaches. "Different" means meaningfully different trade-offs, not variations of the same idea.

For each option:
- **Name, Description** (2-3 sentences)
- **Pros, Cons** (specific, not generic)
- **Complexity:** XS / S / M / L / XL
- **Risk:** Low / Med / High (with one-line explanation)

**Quality checks:**
- If all options have the same pros/cons pattern, they are not different enough.
- If one option is obviously superior, find its downside.
- Every option MUST have cons.
- Options MUST consider existing codebase patterns from project context.

### Phase 1.4 — Recommend a Direction

CHOOSE one option. STATE:
1. Which option and why
2. The key trade-off being accepted
3. Why alternatives were not chosen (specific reasons)

The recommendation MUST follow logically from goals and constraints.

### Phase 1.5 — Assess Complexity

| Classification | Criteria |
|---------------|----------|
| **LOW** | Single-pattern change, 1-3 files, follows existing pattern, XS-S scope |
| **MEDIUM** | 3-10 files, new component or feature slice, M scope |
| **HIGH** | 10+ files, new architectural pattern, cross-cutting concern, L+ scope |

Present checkpoint strategy to user:
```
Complexity assessed as: **[LOW / MEDIUM / HIGH]**
Recommended checkpoint strategy:
  A) Low: single gate after Revision [Recommended for LOW]
  B) Medium: gate after Planning and after Revision [Recommended for MEDIUM]
  C) High: gate after Brainstorm, after Planning, and after Revision [Recommended for HIGH]
```

WAIT for user confirmation.

### Phase 1.6 — Self-Review

Before writing the artifact, verify EVERY item:

- [ ] Problem statement exists and is specific — not vague or aspirational
- [ ] Goals are measurable or verifiable — each has a way to confirm it's met
- [ ] Non-goals are genuine exclusions — not goals in disguise
- [ ] Constraints are stated — timeline, tech stack, compatibility
- [ ] Infrastructure assumptions are verified — any claim about existing code confirmed by reading the codebase
- [ ] Options are genuinely distinct — not three variations of the same approach
- [ ] Recommended direction is justified — rationale references specific pros/cons, not just "feels right"
- [ ] No placeholder text or "[TBD]" markers
- [ ] No contradictions between goals and non-goals
- [ ] Scope is appropriate for a single iteration

If any check fails, FIX it before proceeding.

### Phase 1.7 — Visual Companion Offer

If the topic has spatial or systemic structure (UI layouts, data flows, component hierarchies, state machines, architecture diagrams), ASK the user:

```
This topic has [spatial/systemic] structure that might benefit from a visual diagram.
Would you like me to create a diagram to complement the brainstorm document?
  A) Yes — create a [type] diagram
  B) No — the text document is sufficient [Recommended if structure is simple]
```

If the user accepts, create the diagram as part of the brainstorm artifact (inline Mermaid or ASCII art in the document).

### Phase 1.8 — Write Artifact

**HARD GATE: Do NOT write the brainstorm file until ALL phases (1.1-1.7) are complete and the user has confirmed the recommended direction.**

Steps:
1. CREATE spec directory: `docs/YYYY-MM-DD-short-description/` (today's date, kebab-case)
2. WRITE `01-brainstorm.md` using the template from `templates/01-brainstorm.md`
3. SET frontmatter: `status: draft`, `complexity`, `date`, `audience: "Technical team (developer or team members)"`
4. REPLACE all `{{placeholder}}` tokens with actual content

The artifact MUST be complete — no placeholders, no TODOs. It MUST be a standalone document readable without conversation context.

## Anti-Patterns

### "This is too simple for brainstorming"
If it touches more than one file or involves a decision between approaches, brainstorm it.

### "I already know the right approach"
Surface it as an assumption. The brainstorm validates assumptions.

### "The user seems impatient"
A 10-minute brainstorm that prevents 2 hours of rework is a bargain.

### "Let me just start coding"
Code without a brainstorm is gambling.

## Transition

WHEN this skill completes:
- IF running inside a pipeline: RETURN control to the pipeline orchestrator.
- IF running standalone: INFORM the user: "Brainstorm complete. Invoke `development-toolkit:plan` when ready to create the implementation plan."
