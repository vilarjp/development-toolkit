---
name: plan
description: Use when you have a brainstorm document and need to create a technical implementation plan. Reads docs/spec/01-brainstorm.md and produces docs/spec/02-plan.md with architecture, steps, test strategy, and risk analysis.
---

# Plan (Phase 2)

Produce a detailed technical implementation plan from the brainstorm. This phase translates the "what" and "why" into the "how" -- architecture, steps, tests, and risk mitigation.

**Model:** claude-opus-4-6 with thinking budget 10,000 tokens.

## Prerequisites

- `docs/spec/01-brainstorm.md` must exist.
- If its frontmatter status is "approved," proceed normally.
- If its status is "draft," warn the user: "The brainstorm is still in draft. Proceeding, but the plan may need revision if the brainstorm changes." Then proceed.
- If the file does not exist, STOP. Tell the user to run `/brainstorm` first.

## Process

Execute these phases in strict order. Do not skip phases. Do not write code.

### Phase 2.1 -- Load Context

1. Read `docs/spec/01-brainstorm.md` -- understand the recommended direction, goals, non-goals, assumptions, and trade-offs
2. Read project context from Phase 0 (if not available in the conversation, run `/context` first)
3. Verify that the recommended direction from the brainstorm is compatible with the project's existing architecture and conventions
4. If there is a conflict between the brainstorm's recommendation and the project reality, surface it now:
   ```
   CONFLICT: The brainstorm recommends [X] but the project [Y].
   Options: [adapt the approach / change the project convention / revisit the brainstorm]
   -> Which direction?
   ```

### Phase 2.2 -- Design Architecture

Define the technical approach for the recommended direction:

- **Data models/schemas** -- if the feature involves data, define the shape (types, interfaces, tables)
- **Component/module boundaries** -- what modules are created or modified, what are their responsibilities
- **API contracts** -- if the feature exposes or consumes APIs, define endpoints, request/response shapes, error handling
- **State management approach** -- if the feature involves state, define where state lives, how it flows, who owns it
- **Design decisions** -- for each non-obvious decision, state the decision and its rationale

Every design decision must include a rationale. "Because it is standard" is not a rationale. "Because the project already uses this pattern in [specific location] and consistency reduces cognitive load" is a rationale.

Rules:
- Prefer extending existing patterns over introducing new ones
- Justify any new pattern, dependency, or abstraction against the existing codebase
- Do NOT introduce patterns that contradict project conventions from CLAUDE.md/AGENTS.md
- Keep the architecture as simple as the requirements allow -- no "future-proofing"

### Phase 2.3 -- Decompose into Steps

Break the implementation into thin vertical slices (not horizontal layers).

**Thin vertical slice means:** Each step delivers a complete, testable piece of functionality from top to bottom. "Create all the database models" is a horizontal layer. "Implement user creation: model + API endpoint + validation + test" is a vertical slice.

Each step must have:
- **Title** -- what this step accomplishes
- **Files** -- specific files to create or modify (at most 3-5 files; if more, break it down further)
- **Dependencies** -- which prior steps must be complete before this one starts
- **Acceptance criteria** -- 2-3 testable, specific criteria (not "it works" but "POST /api/users returns 201 with the created user object")
- **Test strategy** -- what to test and how (unit test, integration test, E2E test)
- **Estimated scope** -- XS, S, or M only (L and XL must be broken down; see `references/sizing-guide.md`)
- **Parallelization classification** -- [PARALLEL] or [SEQUENTIAL]

**Rules for decomposition:**
- Each step must leave the system in a working state (all tests passing)
- Each step must be completable in one focused session
- If a step title contains "and," it is two steps. Split it.
- If you cannot describe acceptance criteria in 3 bullets, the step is too large. Split it.
- If a step touches two independent subsystems, it is two steps. Split it.
- Steps must NOT have circular dependencies

### Phase 2.4 -- Classify Parallelization

For each step, determine whether it is [PARALLEL] or [SEQUENTIAL]:

**[PARALLEL]** -- The step has ALL of these properties:
- No write-dependency on any in-flight step (no two steps write to the same file)
- No data flow dependency on any incomplete step (it does not need output that another step has not yet produced)
- No shared mutable state with any concurrent step

**[SEQUENTIAL]** -- Everything else. When in doubt, mark it SEQUENTIAL. False parallelism causes merge conflicts and race conditions. False sequentiality only costs time.

Construct the Execution Waves table:
- Wave 1 = steps with no dependencies
- Wave N = steps whose dependencies are all in waves 1..N-1
- Within a wave: [PARALLEL] if no shared files, [SEQUENTIAL] if shared files

**Validation:** Before finalizing waves, verify that no two [PARALLEL] steps in the same wave touch the same file. If they do, one must be moved to a later wave or marked SEQUENTIAL.

For detailed rules and examples, see `references/wave-construction.md`.

### Phase 2.5 -- Define Test Strategy

For each step, the test strategy was already defined in Phase 2.3. Now define the overall test approach:

- **Test pyramid target:** 80% unit / 15% integration / 5% E2E (adjust based on project conventions)
- **Unit tests:** What pure logic is covered? What mocking is needed? Test in isolation.
- **Integration tests:** What cross-boundary interactions must be verified? Test with real dependencies.
- **E2E tests:** What user flows must work end-to-end? Test from the user's perspective.

If the project has an existing test runner, use it. If not, recommend one based on the project's stack. Do not introduce a test runner that conflicts with the project's tooling.

Name specific behaviors to test, not categories:
- Bad: "Unit test the component"
- Good: "Unit test: renders loading state, renders error state, renders data, calls onSubmit with form values"

### Phase 2.6 -- Identify Risks

For each risk, provide:
- **Risk description** -- what could go wrong
- **Impact** -- High / Medium / Low
- **Mitigation** -- specific action to prevent or handle it ("be careful" is not a mitigation)

Also identify:
- **Edge cases per step** -- specific inputs, states, or conditions that could cause unexpected behavior
- **Deferred questions** -- things that cannot be resolved during planning but will be resolved during implementation

### Phase 2.7 -- Self-Review

Before writing the artifact, verify every item:

- [ ] Every brainstorm goal has at least one plan step
- [ ] Every brainstorm non-goal is NOT accidentally addressed
- [ ] All steps have acceptance criteria (specific, testable)
- [ ] All steps have test strategies (what to test, how)
- [ ] All steps have file lists (specific paths)
- [ ] Dependency graph is acyclic
- [ ] PARALLEL/SEQUENTIAL classifications are correct (no shared files in parallel steps)
- [ ] File paths are consistent across steps (same file not referred to by different paths)
- [ ] No step is sized L or XL
- [ ] No step title contains "and"
- [ ] Wave table is consistent with dependency graph

If any check fails, fix it before proceeding.

### Phase 2.8 -- Write Artifact

Write `docs/spec/02-plan.md` using the template from `templates/02-plan.md`.

Fill in all sections:
- YAML frontmatter with phase, date, status (draft), topic, and origin (path to brainstorm)
- Technical Architecture section with design decisions and component diagram
- Implementation Steps with all fields per step
- Execution Waves table
- Test Strategy overview
- Risks and Edge Cases table
- Open Questions Deferred list

The artifact must be complete -- no placeholders, no TODOs, no "see above." It is a standalone document that another agent could execute without any conversation context.

## Boundary Discipline

This phase does NOT:
- Implement code
- Run tests
- Install dependencies
- Execute build commands
- Learn from execution-time results

It produces a plan. Period. If you feel the urge to "just try something real quick," stop. That is Phase 4 leaking into Phase 2. Uncertainty about feasibility is captured as a risk in Phase 2.6, not resolved by writing code.

If you find yourself writing function bodies, database queries, or component JSX, stop. You have crossed the boundary. File paths and function signatures are allowed. Function implementations are not.

## Handoff

Plan complete. Proceed to `/revise` to cross-check the brainstorm and plan, or review `docs/spec/02-plan.md` first.
