---
name: plan
description: Use when you have a brainstorm document and need to create a technical implementation plan. Reads 01-brainstorm.md and produces 02-plan.md in the active spec directory with architecture, steps, test strategy, and risk analysis.
---

# Plan (Phase 2)

Produce a detailed technical implementation plan from the brainstorm. This phase translates the "what" and "why" into the "how" -- architecture, steps, tests, and risk mitigation.

## Prerequisites

- A brainstorm artifact (`01-brainstorm.md`) MUST exist in the active per-session spec directory (format: `docs/YYYY-MM-DD-short-description/`). ALSO check the legacy location `docs/spec/01-brainstorm.md`.
- If its frontmatter status is "approved," proceed normally.
- If its status is "draft," WARN the user: "The brainstorm is still in draft. Proceeding, but the plan may need revision if the brainstorm changes." Then proceed.
- If the file does not exist in either location, STOP. Tell the user to run `Skill: development-toolkit:brainstorm` first.

## Process

Execute these phases in strict order. DO NOT skip phases. DO NOT write code.

### Phase 2.1 -- Load Context

1. Read `01-brainstorm.md` from the active spec directory -- understand the recommended direction, goals, non-goals, assumptions, and trade-offs.
2. Read project context from Phase 0 (if not available in the conversation, MUST run `Skill: development-toolkit:context-loader` first).
3. VERIFY that the recommended direction from the brainstorm is compatible with the project's existing architecture and conventions.
4. If there is a conflict between the brainstorm's recommendation and the project reality, surface it now:
   ```
   CONFLICT: The brainstorm recommends [X] but the project [Y].
   Options: [adapt the approach / change the project convention / revisit the brainstorm]
   -> Which direction?
   ```

### Phase 2.2 -- Design Architecture

DEFINE the technical approach for the recommended direction:

- **Data models/schemas** -- if the feature involves data, define the shape (types, interfaces, tables)
- **Component/module boundaries** -- what modules are created or modified, what are their responsibilities
- **API contracts** -- if the feature exposes or consumes APIs, define endpoints, request/response shapes, error handling
- **State management approach** -- if the feature involves state, define where state lives, how it flows, who owns it
- **Design decisions** -- for each non-obvious decision, state the decision and its rationale

Every design decision MUST include a rationale. "Because it is standard" is NOT a rationale. "Because the project already uses this pattern in [specific location] and consistency reduces cognitive load" is a rationale.

Rules:
- ALWAYS prefer extending existing patterns over introducing new ones
- MUST justify any new pattern, dependency, or abstraction against the existing codebase
- DO NOT introduce patterns that contradict project conventions from CLAUDE.md/AGENTS.md
- ALWAYS keep the architecture as simple as the requirements allow -- no "future-proofing"

### Phase 2.3 -- Decompose into Steps

Break the implementation into thin vertical slices (not horizontal layers).

**Thin vertical slice means:** Each step MUST deliver a complete, testable piece of functionality from top to bottom. "Create all the database models" is a horizontal layer. "Implement user creation: model + API endpoint + validation + test" is a vertical slice.

Each step MUST have:
- **Title** -- what this step accomplishes
- **Files** -- specific files to create or modify (at most 3-5 files; if more, break it down further)
- **Dependencies** -- which prior steps MUST be complete before this one starts
- **Acceptance criteria** -- 2-3 testable, specific criteria (not "it works" but "POST /api/users returns 201 with the created user object")
- **Test strategy** -- what to test and how (unit test, integration test, E2E test)
- **Estimated scope** -- XS, S, or M only (L and XL MUST be broken down; see `references/sizing-guide.md`)
- **Parallelization classification** -- [PARALLEL] or [SEQUENTIAL]

**Rules for decomposition:**
- Each step MUST leave the system in a working state (all tests passing)
- Each step MUST be completable in one focused session
- If a step title contains "and," it is two steps. SPLIT it.
- If you cannot describe acceptance criteria in 3 bullets, the step is too large. SPLIT it.
- If a step touches two independent subsystems, it is two steps. SPLIT it.
- Steps MUST NOT have circular dependencies

### Phase 2.4 -- Classify Parallelization

For each step, DETERMINE whether it is [PARALLEL] or [SEQUENTIAL]:

**[PARALLEL]** -- The step has ALL of these properties:
- No write-dependency on any in-flight step (no two steps write to the same file)
- No data flow dependency on any incomplete step (it does not need output that another step has not yet produced)
- No shared mutable state with any concurrent step

**[SEQUENTIAL]** -- Everything else. WHEN IN DOUBT, mark it SEQUENTIAL. False parallelism causes merge conflicts and race conditions. False sequentiality only costs time.

CONSTRUCT the Execution Waves table:
- Wave 1 = steps with no dependencies
- Wave N = steps whose dependencies are all in waves 1..N-1
- Within a wave: [PARALLEL] if no shared files, [SEQUENTIAL] if shared files

**Validation:** Before finalizing waves, VERIFY that no two [PARALLEL] steps in the same wave touch the same file. If they do, one MUST be moved to a later wave or marked SEQUENTIAL.

For detailed rules and examples, see `references/wave-construction.md`.

### Phase 2.5 -- Define Test Strategy

For each step, the test strategy was already defined in Phase 2.3. Now DEFINE the overall test approach:

- **Test pyramid target:** 80% unit / 15% integration / 5% E2E (adjust based on project conventions)
- **Unit tests:** What pure logic is covered? What mocking is needed? Test in isolation.
- **Integration tests:** What cross-boundary interactions must be verified? Test with real dependencies.
- **E2E tests:** What user flows must work end-to-end? Test from the user's perspective.

If the project has an existing test runner, MUST use it. If not, recommend one based on the project's stack. DO NOT introduce a test runner that conflicts with the project's tooling.

ALWAYS name specific behaviors to test, not categories:
- Bad: "Unit test the component"
- Good: "Unit test: renders loading state, renders error state, renders data, calls onSubmit with form values"

### Phase 2.6 -- Identify Risks

For each risk, MUST provide:
- **Risk description** -- what could go wrong
- **Impact** -- High / Medium / Low
- **Mitigation** -- specific action to prevent or handle it ("be careful" is not a mitigation)

ALSO identify:
- **Edge cases per step** -- specific inputs, states, or conditions that could cause unexpected behavior
- **Deferred questions** -- things that cannot be resolved during planning but will be resolved during implementation

### Phase 2.7 -- Self-Review

Before writing the artifact, VERIFY every item:

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

If any check fails, MUST fix it before proceeding.

### Phase 2.8 -- Write Artifact

WRITE `02-plan.md` in the same per-session spec directory where `01-brainstorm.md` was found, using the template from `templates/02-plan.md`.

MUST fill in ALL sections:
- YAML frontmatter with phase, date, status (draft), topic, and origin (path to brainstorm)
- Technical Architecture section with design decisions and component diagram
- Implementation Steps with all fields per step
- Execution Waves table
- Test Strategy overview
- Risks and Edge Cases table
- Open Questions Deferred list

The artifact MUST be complete -- no placeholders, no TODOs, no "see above." It MUST be a standalone document that another agent could execute without any conversation context.

## Boundary Discipline

This phase does NOT:
- Implement code
- Run tests
- Install dependencies
- Execute build commands
- Learn from execution-time results

It produces a plan. Period. If you feel the urge to "just try something real quick," STOP. That is Phase 4 leaking into Phase 2. Uncertainty about feasibility MUST be captured as a risk in Phase 2.6, NEVER resolved by writing code.

If you find yourself writing function bodies, database queries, or component JSX, STOP. You have crossed the boundary. File paths and function signatures are allowed. Function implementations are NOT.

## Transition

WHEN this skill completes:
- IF running inside a pipeline: RETURN control to the pipeline orchestrator. DO NOT invoke the next skill yourself. DO NOT ask the user what to do next.
- IF running standalone: PRESENT the plan artifact to the user. INFORM them: "Plan complete. Invoke `development-toolkit:revision` when ready to cross-check the plan."
