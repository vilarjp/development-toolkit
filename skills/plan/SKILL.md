---
name: plan
description: Use after brainstorm to create the technical implementation plan.
---

# Plan (Phase 2)

Produce a detailed technical implementation plan from the brainstorm. This phase translates the "what" and "why" into the "how" — architecture, steps, tests, and risk mitigation.

## Prerequisites

- `01-brainstorm.md` MUST exist in the active spec directory.
- Project context from Phase 0 MUST be available.

## Process

### Phase 2.1 — Load Context

1. Read `01-brainstorm.md` — recommended direction, goals, non-goals, assumptions, trade-offs.
2. Read project context from Phase 0.
3. VERIFY the recommended direction is compatible with existing architecture.
4. If conflict exists, surface it and ask the user to decide.

### Phase 2.2 — Research Phase

DISPATCH parallel research sub-agents (model: latest Opus, effort: high) to gather context before structuring the plan:

**Agent 1: Repo Patterns**
- Search the codebase for similar implementations (e.g., if building a form, find existing forms)
- Report: existing patterns to follow, files to reference, conventions to match

**Agent 2: Solutions History**
- Search `docs/*/06-solutions.md` for past work in the same area
- Report: past decisions, gotchas, approaches that worked or failed

**Agent 3: Ecosystem Practices** (conditional — dispatch only when):
- The plan involves a library/framework not previously used in the codebase, OR
- The area has known security implications, OR
- Agent confidence in the right approach is below 0.70
- Report: recommended approaches, common pitfalls, library recommendations

WAIT for all research agents to complete. Consolidate findings into a research summary that informs the architecture phase.

### Phase 2.3 — Design Architecture

DEFINE the technical approach:

- **Data models/schemas** — if the feature involves data, define the shape
- **Component/module boundaries** — what is created or modified, responsibilities
- **API contracts** — endpoints, request/response shapes, error handling
- **State management** — where state lives, how it flows, who owns it
- **Key Decisions** — for each non-obvious decision, state the decision and its rationale. The rationale MUST reference the brainstorm goals/constraints or research findings.

Every decision MUST include a rationale. "Because it is standard" is NOT a rationale.

Rules:
- Prefer extending existing patterns over introducing new ones
- Justify any new pattern, dependency, or abstraction
- Do NOT contradict CLAUDE.md/AGENTS.md conventions
- Keep architecture as simple as requirements allow

### Phase 2.4 — Decompose into Steps

Break into thin vertical slices (not horizontal layers).

Each step MUST have:
- **Title** — what this step accomplishes
- **Files** — specific files to create or modify (max 3-5; if more, break down further)
- **Test files** — MANDATORY: specific test file paths for behavior-bearing steps
- **Dependencies** — which prior steps must complete first
- **Acceptance criteria** — 2-3 testable, specific criteria
- **Test strategy** — what to test and how (unit/integration/E2E)
- **Estimated scope** — XS, S, or M only (L/XL must be broken down)
- **Classification** — [PARALLEL] or [SEQUENTIAL]

**Rules:**
- Each step leaves the system in a working state
- If a step title contains "and," split it
- If acceptance criteria need >3 bullets, split the step
- No circular dependencies

### Phase 2.5 — Classify Parallelization

**[PARALLEL]** requires ALL of:
- No write-dependency on any in-flight step
- No data flow dependency on incomplete steps
- No shared mutable state

**[SEQUENTIAL]** — everything else. When in doubt, SEQUENTIAL.

Construct Execution Waves table. VERIFY no two PARALLEL steps in the same wave touch the same file.

### Phase 2.6 — Define Test Strategy

- **Pyramid target:** ~70% unit / ~20% integration / ~10% E2E
- Name specific behaviors to test, not categories
- Every behavior-bearing step MUST declare its test file path

### Phase 2.7 — Identify Risks

For each risk: description, impact (H/M/L), specific mitigation.
Also identify edge cases per step and deferred questions.

### Phase 2.8 — Confidence Check

DISPATCH parallel sub-agents (model: latest Opus, effort: high) to audit critical sections of the plan:

**For each step classified as M scope or higher:**
- Does the step's file list match what actually exists in the codebase?
- Are the acceptance criteria testable with the declared test strategy?
- Does the step's dependency chain make sense given the actual code structure?

Surface any confidence gaps to the user before proceeding to write the artifact.

### Phase 2.9 — Self-Review

Verify:
- [ ] Every brainstorm goal has at least one plan step
- [ ] Every brainstorm non-goal is NOT accidentally addressed
- [ ] All steps have acceptance criteria and test strategies
- [ ] All behavior-bearing steps declare test file paths
- [ ] Dependency graph is acyclic
- [ ] PARALLEL classifications are correct (no shared files)
- [ ] No step is sized L or XL
- [ ] No step title contains "and"
- [ ] Wave table matches dependency graph
- [ ] Key Decisions section captures the "why" behind each architectural choice

### Phase 2.10 — Write Artifact

WRITE `02-plan.md` using `templates/02-plan.md` with ALL sections filled:
- YAML frontmatter (phase, date, status: draft, topic, origin)
- Key Decisions (replacing the old Component Diagram section)
- Implementation Steps with all fields including mandatory test file paths
- Execution Waves table
- Test Strategy overview
- Risks and Edge Cases
- Open Questions Deferred
- Changelog section (empty — populated by revision phase)

Complete, no placeholders. Standalone document.

## Boundary Discipline

This phase does NOT: implement code, run tests, install dependencies, execute builds. It produces a plan. Period. If you feel the urge to "just try something," STOP — that is Phase 4 leaking into Phase 2.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The brainstorm already covers the implementation details" | The brainstorm covers the what and why. The plan covers the how. They are different documents. |
| "This change is simple enough to plan in my head" | If you can hold it in your head, you can write it down in 5 minutes. The plan catches what your head misses. |
| "I'll figure out the steps as I go" | That is called hacking. The plan exists so subagents get clear, testable assignments. |
| "Research agents are unnecessary for this codebase" | You do not know what you do not know. The research agents find existing patterns you would have reinvented. |

## Red Flags — Self-Check

- An implementation step has no acceptance criteria
- An implementation step has no test strategy
- A step is sized L or XL without being broken down further
- A step title contains "and" (sign it should be split)
- The wave table does not match the dependency graph
- You skipped the research phase because "the codebase is simple"
- A key decision has no rationale

## Transition

- IF in pipeline: RETURN control to orchestrator.
- IF standalone: INFORM user to invoke `development-toolkit:revision`.
