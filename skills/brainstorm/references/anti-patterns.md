# Brainstorming Anti-Patterns

Common failure modes during the brainstorm phase. Each one describes a specific way brainstorming goes wrong, gives a concrete example of the failure, and explains how to avoid it.

---

## 1. The Obvious Solution Trap

**What it is:** Jumping to the first solution that comes to mind without exploring alternatives. The first idea feels right because it is familiar, not because it is best.

**Example of the failure:**
User asks for a caching layer. The agent immediately recommends Redis because "that is what everyone uses." It never considers that the dataset fits in memory, that the access pattern is write-heavy (invalidating cache constantly), or that the project already has a database with built-in caching. The Redis approach adds infrastructure complexity for no measurable gain.

**How to avoid it:**
- After your first idea forms, ask: "What would I recommend if this option did not exist?"
- Force yourself to generate at least one option that uses a fundamentally different mechanism.
- Check whether the "obvious" solution is obvious because it is correct or because it is familiar.
- Look at the constraints and goals first, then generate solutions. Do not generate solutions and then check them against goals.

---

## 2. Scope Creep During Brainstorming

**What it is:** The brainstorm starts about feature X, but by the end it has absorbed features Y and Z. Adjacent concerns get pulled in because they "might as well" be addressed.

**Example of the failure:**
User asks to add dark mode support. The brainstorm starts exploring dark mode but then adds "we should also support custom themes" and "let us add a theme editor" and "we need a design tokens system." The original request (dark mode) becomes a three-month project.

**How to avoid it:**
- Write the non-goals list early, before generating options. This creates a boundary.
- When an adjacent concern surfaces, add it to non-goals with a note: "Deferred to future iteration."
- Ask: "Does this directly serve the stated problem, or is it a different problem?"
- If the scope has grown, split into multiple brainstorms. One problem per brainstorm.

---

## 3. Technical Solutioning

**What it is:** Making implementation decisions during brainstorming. The brainstorm phase is for WHAT we are solving and WHY, not HOW we are implementing it. Implementation details belong in the plan phase.

**Example of the failure:**
User wants to add real-time notifications. The brainstorm skips problem exploration and jumps to: "We will use WebSockets with Socket.io, store events in a Redis pub/sub channel, and use a React context provider with useReducer for client state." These are implementation decisions, not brainstorm output. The brainstorm never established what kinds of notifications, how timely they need to be, or whether real-time is even necessary (maybe polling every 30 seconds is fine).

**How to avoid it:**
- Keep the brainstorm at the "what" and "why" level. If you are naming specific libraries, frameworks, or APIs, you have gone too deep.
- Options should describe approaches (e.g., "push-based real-time" vs "poll-based near-real-time" vs "email-based async"), not implementations.
- Save all implementation detail for Phase 2 (planning). The brainstorm feeds the plan; it does not replace it.

**Allowed in brainstorm:**
- High-level approach descriptions ("event-driven vs polling")
- Technology category mentions ("a message queue", "a caching layer")
- Architecture pattern names ("CQRS", "pub/sub", "repository pattern")
- Complexity estimates at the approach level

**NOT allowed in brainstorm:**
- Specific library choices with version numbers
- Function signatures or interfaces
- File paths or directory structures
- Configuration details
- Database schema definitions
- API endpoint specifications

---

## 4. Analysis Paralysis

**What it is:** Generating too many options or exploring too many dimensions without converging on a recommendation. The brainstorm becomes an encyclopedia of possibilities instead of a decision document.

**Example of the failure:**
The brainstorm produces 7 options, each with sub-options, and a comparison matrix with 15 dimensions. The conclusion says "it depends on several factors" and does not make a recommendation. The user is now more confused than before the brainstorm started.

**How to avoid it:**
- Hard limit: 2-3 options maximum. If you have more, merge similar ones or drop the weakest.
- Every brainstorm MUST end with a single recommendation and a clear rationale.
- "It depends" is not a recommendation. Pick one. State the conditions under which you would pick differently. Let the user override.
- Use the goals as a filter. If an option does not serve the stated goals better than another, drop it.

**The limits (hard rules):**

| Constraint | Limit | Rationale |
|-----------|-------|-----------|
| Questions to user | 5 maximum | After 5, you MUST decide with what you have |
| Options generated | 2-3 | More than 3 rarely adds value |
| Rounds of revision | 1 | Write it, self-review it, present it. One pass. |

---

## 5. Confirmation Bias

**What it is:** Asking questions that confirm a pre-existing assumption instead of genuinely exploring the problem space. The questions are leading, and the brainstorm arrives at the answer the agent already had in mind.

**Example of the failure:**
The agent assumes the user wants a REST API. Its clarifying questions are: "Should we use Express or Fastify for the REST API?" and "What REST conventions should we follow?" These questions assume REST is the answer. The user's actual need might be better served by a GraphQL API, a CLI tool, or no API at all.

**How to avoid it:**
- Frame questions about the problem, not the solution. "What systems need to consume this data?" not "Which API framework should we use?"
- Before asking a question, check: "Am I gathering information or confirming my assumption?"
- Include an "Other" option in multiple-choice questions. This signals openness to alternatives.
- If you catch yourself asking implementation questions (how) instead of problem questions (what/why), stop and reframe.

---

## 6. Vague Goals

**What it is:** Goals that cannot be tested or measured. They sound good in a slide deck but provide no guidance for implementation or verification.

**Example of the failure:**
Goals like:
- "Improve the user experience"
- "Make the system more scalable"
- "Modernize the codebase"
- "Better error handling"

None of these can be tested. When is the user experience "improved enough"? What does "more scalable" mean -- 2x? 100x? What does "modernize" look like when you are done?

**How to avoid it:**
- Apply the test: "Could I write an acceptance criterion for this goal?" If not, it is too vague.
- Replace vague goals with specific ones:
  - "Improve the user experience" -> "Reduce checkout flow from 5 steps to 2 steps"
  - "Make the system more scalable" -> "Support 10,000 concurrent connections without degradation"
  - "Modernize the codebase" -> "Migrate from CommonJS to ESM in the auth module"
  - "Better error handling" -> "All API endpoints return structured error responses with error codes, and no unhandled promise rejections in production logs"
- If you cannot make a goal specific, it might be a non-goal or a separate brainstorm topic.
