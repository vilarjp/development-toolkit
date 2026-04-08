---
name: brainstorm
description: Use when exploring a new feature, change, or problem before committing to a direction. Produces docs/spec/01-brainstorm.md with problem statement, goals, options, and recommended direction.
---

# Brainstorm (Phase 1)

Explore the problem space before committing to a solution. This phase produces a structured brainstorm document that feeds the planning phase.

**Model:** claude-opus-4-6 with thinking budget 10,000 tokens.

## Prerequisites

Phase 0 (context-loader) must have run. If no project context is available in the conversation, run `/context` first. Do not proceed without project context.

## Process

Execute these phases in strict order. Do not skip ahead. Do not write the artifact until Phase 1.5 is complete and the user has confirmed the recommended direction.

### Phase 1.1 -- Understand the Request

Read the user's description of what they want. Then ask clarifying questions to fill gaps.

**Rules for questions:**
- Ask ONE question at a time. Never batch multiple questions into one message.
- Prefer multiple-choice format with an "Other" option. This reduces friction and surfaces options the user may not have considered.
- Maximum 5 questions before producing output. If you still have unknowns after 5 questions, state them as assumptions in Phase 1.2.
- Stop asking questions early if the answers are clear from context.

**Focus your questions on:**
1. What problem are we solving? (not what feature are we building)
2. For whom? (user persona, system consumer, developer)
3. What does success look like? (measurable outcome)
4. What are the constraints? (time, tech, compatibility, scope)
5. What has been tried before? (prior art, failed approaches)

**Do NOT ask:**
- Implementation questions (that is Phase 2)
- Questions you can answer by reading the codebase
- Questions where only one reasonable answer exists
- Open-ended questions with no options -- these waste the user's time

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

### Phase 1.5 -- Self-Review

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

### Phase 1.6 -- Write Artifact

**HARD GATE: Do NOT write the brainstorm file until ALL exploration phases (1.1-1.5) are complete and the user has confirmed the recommended direction.**

The document MUST reflect genuine exploration -- not a rubber-stamp of the first idea that came to mind. If your brainstorm has only one real option and two filler options, you have failed.

If the user says "just do it" or "skip the brainstorm," explain that the brainstorm prevents wasted implementation effort and ask them to confirm. If they confirm, skip it -- but note in subsequent phases that no brainstorm was conducted.

Steps:
1. Create the `docs/spec/` directory if it does not exist
2. Write `docs/spec/01-brainstorm.md` using the template from `templates/01-brainstorm.md`
3. Set the `status` field in frontmatter to `draft`
4. Fill in the `date` field with today's date
5. Replace all `{{placeholder}}` tokens with actual content from phases 1.1-1.4

The artifact must be complete -- no placeholders, no TODOs, no "see above." It is a standalone document that another agent could read without any conversation context.

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

Brainstorm complete. Proceed to `/plan` to create the implementation plan, or review and adjust `docs/spec/01-brainstorm.md` first.
