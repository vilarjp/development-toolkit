---
name: brainstorm
description: Use when exploring a new feature, change, or problem before committing to a direction. Produces 01-brainstorm.md in a per-session spec directory with problem statement, goals, options, and recommended direction.
---

# Brainstorm (Phase 1)

Explore the problem space before committing to a solution. This phase produces a structured brainstorm document that feeds the planning phase. Every step below is MANDATORY — DO NOT skip or reorder phases.

## Prerequisites

Phase 0 (context-loader) must have run. If no project context block is present in this conversation, invoke `Skill: development-toolkit:context-loader` NOW before proceeding. This is not optional — do not substitute ad-hoc exploration for the context-loader skill.

## Process

Execute these phases in strict order. Do not skip ahead. Do not write the artifact until Phase 1.6 is complete and the user has confirmed the recommended direction.

### Phase 1.1 -- Understand the Request

READ the user's description of what they want. Then ASK clarifying questions using the structured interview protocol below. The interview merges Socratic questioning (open-ended exploration) with structured mandatory questions (focused coverage).

**Mandatory questions (ALWAYS asked, one at a time, multiple-choice):**

1. **WHY** — What problem does this solve?
   - Options: UX friction / Missing capability / Technical debt / Performance issue / Bug or regression / Other: ___
2. **WHO** — Who is affected?
   - Options: All users / Specific user type: ___ / Developers or operators / Internal systems / Other: ___
3. **OPEN** — Anything else I should know?
   - Options: Nothing else / More context (please share) / There are constraints or gotchas

**Conditional follow-up questions (asked only if mandatory answers are sparse or ambiguous):**

4. Current state — How does it work today? (when the user's answer to WHY was vague)
5. Success criteria — How will you know it is working? (when no measurable outcome was stated)

**Completeness checklist (internal evaluation — do NOT show this to the user):**

Before deciding whether to ask more questions, EVALUATE:
- [ ] WHY — user articulated problem or motivation
- [ ] WHO — all affected user types identified
- [ ] Happy path — main flow described or confirmed
- [ ] Error states — what happens when things go wrong
- [ ] Scope boundary — what is NOT in scope
- [ ] Assumptions — high-impact ones surfaced

SKIP further probing if all checklist dimensions are covered. CONTINUE with Socratic follow-ups only for uncovered dimensions.

**Rules for all questions:**
- ASK ONE question at a time. NEVER batch multiple questions into one message.
- ALWAYS USE multiple-choice format with an "Other" option. This reduces friction and surfaces options the user may not have considered.
- Maximum 5 questions total (3 mandatory + up to 2 conditional or Socratic). If you still have unknowns after 5 questions, STATE them as assumptions in Phase 1.2.
- STOP asking questions early if the answers are clear from context.
- When presenting options, ALWAYS mark the recommended option with `[Recommended]`.

**Do NOT ask:**
- Implementation questions (that is Phase 2)
- Questions you can answer by reading the codebase
- Questions where only one reasonable answer exists
- Open-ended questions with no options — these waste the user's time

### Phase 1.2 -- Explore the Problem Space

After gathering enough information, PRODUCE these sections:

**Problem Statement:** One paragraph. What is the current state? What is painful or missing? Who is affected? MUST BE specific -- "users are frustrated" is too vague; "checkout takes 3 clicks when it should take 1" is specific.

**Goals:** A numbered list of concrete, measurable goals. Each goal MUST be testable -- you MUST be able to write an acceptance criterion for it. Bad: "improve performance." Good: "reduce page load time below 2 seconds on 3G connections."

**Non-Goals:** A numbered list of what this effort explicitly will NOT address. This is as important as the goals. It prevents scope creep and sets expectations. ALWAYS BE specific about adjacent work that might seem related but is out of scope.

**Assumptions:** A numbered list of everything you are taking as given. Format:
```
ASSUMPTIONS:
1. [assumption]
2. [assumption]
3. [assumption]
-> Correct me now or I proceed with these.
```

**Key Unknowns:** A list of open questions and uncertainties that could affect the direction. ALWAYS MARK which ones can be resolved now versus which ones will be resolved during implementation.

### Phase 1.3 -- Generate Options

PRODUCE 2-3 genuinely different approaches. "Different" means they MUST represent meaningfully different trade-offs, not variations of the same idea.

For each option, provide:
- **Name:** A short, descriptive name
- **Description:** What this approach does, in 2-3 sentences
- **Pros:** Specific advantages (not generic "simple" or "fast")
- **Cons:** Specific disadvantages with concrete impact
- **Complexity:** XS / S / M / L / XL
- **Risk:** Low / Medium / High -- with a one-line explanation of what could go wrong

**Quality checks for options:**
- If all options have the same pros/cons pattern, they are not different enough. RETHINK.
- If one option is obviously superior, you have not explored the space. FIND its downside.
- If an option has no cons, you are not being honest. Every approach has trade-offs. NEVER present an option without cons.
- Options MUST consider the existing codebase patterns from project context. Do NOT propose approaches that conflict with established conventions unless you explicitly call out the convention break and justify it.

### Phase 1.4 -- Recommend a Direction

CHOOSE one option. STATE:
1. Which option and why
2. The key trade-off being accepted (every choice has one)
3. Why the alternatives were not chosen (specific reasons, not "it was less good")

The recommendation MUST follow logically from the goals and constraints established in Phase 1.2. If it does not, something is wrong -- REVISIT.

### Phase 1.5 -- Assess Complexity

Before self-review, CLASSIFY the task's complexity. This classification affects checkpoint placement in the pipeline.

| Classification | Criteria |
|---------------|----------|
| **LOW** | Single-pattern change, 1-3 files, follows existing pattern exactly, XS-S scope |
| **MEDIUM** | 3-10 files, new component or feature slice, M scope |
| **HIGH** | 10+ files, new architectural pattern, cross-cutting concern, external integration, L scope that was decomposed |

Set the `complexity` field in the brainstorm artifact frontmatter.

After determining complexity, PRESENT the checkpoint strategy to the user:

```
Complexity assessed as: **[LOW / MEDIUM / HIGH]**
Recommended checkpoint strategy:
  A) Low: single gate after Revision [Recommended for LOW complexity]
  B) Medium: gate after Planning and after Revision [Recommended for MEDIUM complexity]
  C) High: gate after Brainstorm, after Planning, and after Revision [Recommended for HIGH complexity]

Which strategy would you like to use? (A, B, or C)
```

WAIT for user confirmation before proceeding. DO NOT continue without explicit user confirmation. The chosen strategy is recorded in the brainstorm artifact and the pipeline orchestrator uses it to determine gate placement.

### Phase 1.6 -- Self-Review

Before writing the artifact, VERIFY every item below:

- [ ] No placeholder text or "[TBD]" markers anywhere
- [ ] No contradictions between goals and non-goals
- [ ] All assumptions are stated explicitly, not buried in prose
- [ ] Scope check: is this trying to do too much for a single iteration?
- [ ] Problem statement is specific, not vague
- [ ] Goals are measurable, not aspirational
- [ ] Options are genuinely different, not variations of one idea
- [ ] Recommendation follows from stated goals and constraints
- [ ] Non-goals actually prevent likely scope creep scenarios
- [ ] Complexity estimates are honest, not sandbagged to favor the preferred option

If any check fails, FIX it before proceeding. DO NOT proceed with failing checks.

### Phase 1.7 -- Write Artifact

**HARD GATE: Do NOT write the brainstorm file until ALL exploration phases (1.1-1.6) are complete and the user has confirmed the recommended direction.**

The document MUST reflect genuine exploration -- not a rubber-stamp of the first idea that came to mind. If your brainstorm has only one real option and two filler options, you have failed.

If the user says "just do it" or "skip the brainstorm," EXPLAIN that the brainstorm prevents wasted implementation effort and ASK them to confirm. If they confirm, SKIP it -- but NOTE in subsequent phases that no brainstorm was conducted.

Steps:
1. CREATE a per-session spec directory under `docs/` using the convention: `docs/YYYY-MM-DD-short-description-of-topic/` (e.g., `docs/2026-04-08-user-auth-flow/`). USE today's date and a kebab-case short description derived from the topic.
2. WRITE `01-brainstorm.md` inside that directory using the template from `templates/01-brainstorm.md`
3. SET the `status` field in frontmatter to `draft`
4. SET the `complexity` field in frontmatter to the classification from Phase 1.5
5. FILL IN the `date` field with today's date
6. REPLACE all `{{placeholder}}` tokens with actual content from phases 1.1-1.4

The artifact MUST be complete — no placeholders, no TODOs, no "see above." It MUST be a standalone document that another agent could read without any conversation context.

## Anti-Patterns

These are the ways brainstorming fails. RECOGNIZE them and STOP.

### "This is too simple for brainstorming"
If it touches more than one file, it is not simple. If it involves a decision between approaches, it is not simple. If another developer might have done it differently, it is not simple. Brainstorm it.

### "I already know the right approach"
SURFACE it as an assumption. The brainstorm validates assumptions -- that is its job. If you are right, the brainstorm will be fast. If you are wrong, you just saved hours of rework.

### "The user seems impatient"
Fast bad decisions cost more than slow good ones. A 10-minute brainstorm that prevents 2 hours of rework is a bargain. NEVER let perceived time pressure skip quality gates.

### "Let me just start coding"
Code without a brainstorm is gambling. You might get lucky. You probably will not. The brainstorm exists to make the plan possible and the plan exists to make the code correct. ALWAYS brainstorm.

### "The existing code makes the approach obvious"
The existing code constrains the solution space. It does not decide the solution. There are ALWAYS alternatives within those constraints. EXPLORE them.

See `references/anti-patterns.md` for detailed examples of each failure mode.

## Transition

WHEN this skill completes:
- IF running inside a pipeline: RETURN control to the pipeline orchestrator. DO NOT invoke the next skill yourself. DO NOT ask the user what to do next.
- IF running standalone: PRESENT the brainstorm artifact to the user. INFORM them: "Brainstorm complete. Invoke `development-toolkit:plan` when ready to create the implementation plan."
