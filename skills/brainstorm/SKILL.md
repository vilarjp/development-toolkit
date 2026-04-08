---
name: brainstorm
description: Use when exploring a new feature, change, or problem before committing to a direction. Produces docs/spec/01-brainstorm.md with problem statement, goals, options, and recommended direction.
---

# Brainstorm (Phase 1)

Explore the problem space before committing to a solution. This phase produces a structured brainstorm document that feeds the planning phase.

## Prerequisites

Phase 0 (context-loader) must have run. If no project context is available in the conversation, run `/context` first. Do not proceed without project context.

## Process

Execute these phases in strict order. Do not skip ahead. Do not write the artifact until Phase 1.6 is complete and the user has confirmed the recommended direction.

### Phase 1.1 -- Understand the Request

Read the user's description of what they want. Then ask clarifying questions using the structured interview protocol below. The interview merges Socratic questioning (open-ended exploration) with structured mandatory questions (focused coverage).

**Mandatory questions (always asked, one at a time, multiple-choice):**

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

Before deciding whether to ask more questions, evaluate:
- [ ] WHY — user articulated problem or motivation
- [ ] WHO — all affected user types identified
- [ ] Happy path — main flow described or confirmed
- [ ] Error states — what happens when things go wrong
- [ ] Scope boundary — what is NOT in scope
- [ ] Assumptions — high-impact ones surfaced

Skip further probing if all checklist dimensions are covered. Continue with Socratic follow-ups only for uncovered dimensions.

**Rules for all questions:**
- Ask ONE question at a time. Never batch multiple questions into one message.
- Prefer multiple-choice format with an "Other" option. This reduces friction and surfaces options the user may not have considered.
- Maximum 5 questions total (3 mandatory + up to 2 conditional or Socratic). If you still have unknowns after 5 questions, state them as assumptions in Phase 1.2.
- Stop asking questions early if the answers are clear from context.
- When presenting options, always mark the recommended option with `[Recommended]`.

**Do NOT ask:**
- Implementation questions (that is Phase 2)
- Questions you can answer by reading the codebase
- Questions where only one reasonable answer exists
- Open-ended questions with no options — these waste the user's time

### Phase 1.2 -- Explore the Problem Space

After gathering enough information, produce these sections:

**Problem Statement:** One paragraph. What is the current state? What is painful or missing? Who is affected? Be specific -- "users are frustrated" is too vague; "checkout takes 3 clicks when it should take 1" is specific.

**Goals:** A numbered list of concrete, measurable goals. Each goal must be testable -- you should be able to write an acceptance criterion for it. Bad: "improve performance." Good: "reduce page load time below 2 seconds on 3G connections."

**Non-Goals:** A numbered list of what this effort explicitly will NOT address. This is as important as the goals. It prevents scope creep and sets expectations. Be specific about adjacent work that might seem related but is out of scope.

**Assumptions:** A numbered list of everything you are taking as given. Format:
```
ASSUMPTIONS:
1. [assumption]
2. [assumption]
3. [assumption]
-> Correct me now or I proceed with these.
```

**Key Unknowns:** A list of open questions and uncertainties that could affect the direction. Mark which ones can be resolved now versus which ones will be resolved during implementation.

### Phase 1.3 -- Generate Options

Produce 2-3 genuinely different approaches. "Different" means they represent meaningfully different trade-offs, not variations of the same idea.

For each option, provide:
- **Name:** A short, descriptive name
- **Description:** What this approach does, in 2-3 sentences
- **Pros:** Specific advantages (not generic "simple" or "fast")
- **Cons:** Specific disadvantages with concrete impact
- **Complexity:** XS / S / M / L / XL
- **Risk:** Low / Medium / High -- with a one-line explanation of what could go wrong

**Quality checks for options:**
- If all options have the same pros/cons pattern, they are not different enough. Rethink.
- If one option is obviously superior, you have not explored the space. Find its downside.
- If an option has no cons, you are not being honest. Every approach has trade-offs.
- Options MUST consider the existing codebase patterns from project context. Do NOT propose approaches that conflict with established conventions unless you explicitly call out the convention break and justify it.

### Phase 1.4 -- Recommend a Direction

Choose one option. State:
- Which option and why
- The key trade-off being accepted (every choice has one)
- Why the alternatives were not chosen (specific reasons, not "it was less good")

The recommendation must follow logically from the goals and constraints established in Phase 1.2. If it does not, something is wrong -- revisit.

### Phase 1.5 -- Assess Complexity

Before self-review, classify the task's complexity. This classification affects checkpoint placement in the pipeline.

| Classification | Criteria |
|---------------|----------|
| **LOW** | Single-pattern change, 1-3 files, follows existing pattern exactly, XS-S scope |
| **MEDIUM** | 3-10 files, new component or feature slice, M scope |
| **HIGH** | 10+ files, new architectural pattern, cross-cutting concern, external integration, L scope that was decomposed |

Set the `complexity` field in the brainstorm artifact frontmatter.

After determining complexity, present the checkpoint strategy to the user:

```
Complexity assessed as: **[LOW / MEDIUM / HIGH]**
Recommended checkpoint strategy:
  A) Low: single gate after Revision [Recommended for LOW complexity]
  B) Medium: gate after Planning and after Revision [Recommended for MEDIUM complexity]
  C) High: gate after Brainstorm, after Planning, and after Revision [Recommended for HIGH complexity]

Which strategy would you like to use? (A, B, or C)
```

Wait for user confirmation before proceeding. The chosen strategy is recorded in the brainstorm artifact and the pipeline orchestrator uses it to determine gate placement.

### Phase 1.6 -- Self-Review

Before writing the artifact, verify:

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

If any check fails, fix it before proceeding.

### Phase 1.7 -- Write Artifact

**HARD GATE: Do NOT write the brainstorm file until ALL exploration phases (1.1-1.6) are complete and the user has confirmed the recommended direction.**

The document MUST reflect genuine exploration -- not a rubber-stamp of the first idea that came to mind. If your brainstorm has only one real option and two filler options, you have failed.

If the user says "just do it" or "skip the brainstorm," explain that the brainstorm prevents wasted implementation effort and ask them to confirm. If they confirm, skip it -- but note in subsequent phases that no brainstorm was conducted.

Steps:
1. Create a per-session spec directory under `docs/` using the convention: `docs/YYYY-MM-DD-short-description-of-topic/` (e.g., `docs/2026-04-08-user-auth-flow/`). Use today's date and a kebab-case short description derived from the topic.
2. Write `01-brainstorm.md` inside that directory using the template from `templates/01-brainstorm.md`
3. Set the `status` field in frontmatter to `draft`
4. Set the `complexity` field in frontmatter to the classification from Phase 1.5
5. Fill in the `date` field with today's date
6. Replace all `{{placeholder}}` tokens with actual content from phases 1.1-1.4

The artifact must be complete — no placeholders, no TODOs, no "see above." It is a standalone document that another agent could read without any conversation context.

## Anti-Patterns

These are the ways brainstorming fails. Recognize them and stop.

### "This is too simple for brainstorming"
If it touches more than one file, it is not simple. If it involves a decision between approaches, it is not simple. If another developer might have done it differently, it is not simple. Brainstorm it.

### "I already know the right approach"
Surface it as an assumption. The brainstorm validates assumptions -- that is its job. If you are right, the brainstorm will be fast. If you are wrong, you just saved hours of rework.

### "The user seems impatient"
Fast bad decisions cost more than slow good ones. A 10-minute brainstorm that prevents 2 hours of rework is a bargain. Do not let perceived time pressure skip quality gates.

### "Let me just start coding"
Code without a brainstorm is gambling. You might get lucky. You probably will not. The brainstorm exists to make the plan possible and the plan exists to make the code correct. Always brainstorm.

### "The existing code makes the approach obvious"
The existing code constrains the solution space. It does not decide the solution. There are always alternatives within those constraints. Explore them.

See `references/anti-patterns.md` for detailed examples of each failure mode.

## Handoff

Brainstorm complete. Proceed to `/plan` to create the implementation plan, or review and adjust the brainstorm artifact first.
