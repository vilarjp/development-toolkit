# Action Plan: Toolkit Improvements v2.2

**Date:** 2026-04-11
**Scope:** 15 selected candidates (A1–A4, B3–B4, C1–C2, D1–D5, E2, E6) + Durability principle
**Status:** Draft — awaiting approval

---

## Guiding Principle: Durability

> A good suggestion reads like a spec; a bad one reads like a diff.

Artifacts produced by the toolkit (plans, brainstorms, diagnoses, solutions, review findings) must survive radical codebase changes. This means:

- **No file paths** — describe *what* to change by intent ("the user authentication middleware"), not location
- **No line numbers** — they shift with every commit
- **No code snippets** — they rot immediately; describe the *behavior* to achieve
- **Plans describe outcomes, not diffs.** A plan step is "Add rate limiting to the public API endpoints" not "Insert `rateLimiter()` at line 47 of `src/middleware/auth.ts`"

This principle is cross-cutting — it affects templates, reviewer prompts, skill instructions, and the findings schema. It is woven into every wave below rather than isolated in its own.

---

## Wave 1 — Skill Hardening (A1, A2, A3, A4)

**Theme:** Make every skill resilient against the agent taking shortcuts.
**Effort:** Low — additive content, no structural changes.
**Files touched:** Every `SKILL.md`, every agent `.md`.

### 1.1 — Anti-rationalization tables in every skill (A1)

**Current state:** `brainstorm` and `tdd` already have anti-pattern / anti-rationalization sections. The other 11 skills do not.

**Action:** Add a `## Common Rationalizations` section to each skill that lacks one. Each table has two columns: the excuse the agent will generate, and the rebuttal that blocks it.

| Skill | Example rationalizations to cover |
|-------|----------------------------------|
| context-loader | "I already read this project last session" / "CLAUDE.md is enough" |
| plan | "The brainstorm already covers this" / "Small change, no plan needed" |
| revision | "The plan looks fine, nothing to revise" / "The user seems eager to start" |
| execute | "I'll write tests after the code works" / "This wave is too small for a commit" |
| code-review | "Tests pass, so the code is correct" / "I wrote it, I know it's fine" |
| fix-loop | "This finding is a false positive" / "Fixing this would change too much" |
| commit-push | "I'll push later" / "This is just a draft, skip lint" |
| solutions | "Nothing surprising happened" / "The commit messages are enough" |
| diagnosis | "It's probably X" / "Let me try a quick fix first" |
| pr-feedback | "The reviewer is wrong" / "This comment is just style preference" |
| using-toolkit | "This is trivial, skip the pipeline" / "I know which tier this is" |

**Constraint:** Each table must have 3–5 entries. Entries must be specific to the skill's failure modes, not generic.

### 1.2 — Red Flags sections for self-monitoring (A2)

**Action:** Add a `## Red Flags — Self-Check` section to each skill. These are observable signs (checkable against the agent's own behavior mid-execution) that the process is being violated.

| Skill | Example red flags |
|-------|------------------|
| context-loader | "You are referencing a file you have not opened in this session" |
| brainstorm | "You have only one option section" / "Non-goals section is empty" |
| plan | "An implementation step has no acceptance criteria" / "No test strategy for a step" |
| revision | "You approved without naming a single gap" |
| execute | "Production code exists without a corresponding test file" / "You made changes outside the current wave's scope" |
| code-review | "A reviewer's findings section is empty with no explanation" |
| tdd | "You wrote the production code before the failing test" |
| solutions | "Gotchas section is empty after a multi-wave execution" |
| commit-push | "You are on main/master" / "Unstaged files exist that match the change scope" |

**Constraint:** Red flags must be observable from the conversation state — things the agent can actually check, not subjective judgments.

### 1.3 — "Verify before act" pre-flight checklist (A3)

**Action:** Add a `## Pre-Flight Checklist` section to the `execute` skill, injected into each subagent's prompt. Before every code change, the implementer runs through:

1. **File exists** — Read the file before editing. If the file doesn't exist, flag and stop.
2. **Function/class exists** — Grep for the symbol before calling or extending it.
3. **Import paths resolve** — Verify the module path exists in the project.
4. **Directory structure matches** — Don't assume directories exist; verify.
5. **Types/signatures match** — Read the function signature before calling it with arguments.
6. **Test file exists** — If modifying production code, confirm the corresponding test file exists.

**Where it lives:** In `skills/execute/references/implementer-prompt.md` as a mandatory section, and referenced from `skills/tdd/SKILL.md`.

### 1.4 — Skill descriptions as trigger conditions only (A4)

**Current state:** Descriptions contain workflow summaries (e.g., "Dispatches subagents (Sonnet/medium) per Execution Waves, enforces TDD..."). Claude may follow the description instead of reading the full skill body.

**Action:** Rewrite every skill's `description` frontmatter field to contain **only** the triggering condition — when to use it, not what it does.

| Skill | Current (abbreviated) | Proposed |
|-------|----------------------|----------|
| using-toolkit | "Use at session start to discover and apply the right development workflow skill. This is the meta-skill governing tier classification..." | "Use at session start to classify the task and select the right pipeline." |
| context-loader | "Use before any pipeline phase to scan and index the current project context. Reads CLAUDE.md, project structure..." | "Use before any pipeline phase to load project context." |
| brainstorm | "Use when exploring a new feature, change, or problem before committing to a direction. Produces 01-brainstorm.md..." | "Use when exploring a feature, change, or problem before committing to a direction." |
| plan | "Use when you have a brainstorm document and need to create a technical implementation plan. Dispatches research sub-agents..." | "Use after brainstorm to create the technical implementation plan." |
| revision | "Use after brainstorm and plan are written to cross-check both documents for gaps..." | "Use after plan to cross-check documents for gaps and trigger human approval." |
| execute | "Use when the plan is approved and ready for implementation. Dispatches subagents..." | "Use when the plan is approved and ready for implementation." |
| tdd | "Use when implementing any code change. Enforces the RED-GREEN-REFACTOR cycle..." | "Use when implementing any code change." |
| code-review | "Use after implementation is complete and all tests pass. Dispatches conditional reviewer subagents..." | "Use after implementation is complete and all tests pass." |
| fix-loop | "Addresses code review findings using TDD. Auto-applies safe_auto fixes..." | "Use when code review has actionable findings to address." |
| commit-push | "Use when code is reviewed and ready to commit. Enforces branch safety..." | "Use when code is reviewed and ready to commit." |
| solutions | "Produces 06-solutions.md at the end of every dev or resolve pipeline..." | "Use at pipeline end to capture learnings." |
| diagnosis | "Use when investigating a bug, error, or regression. Dispatches the resolve-investigator agent..." | "Use when investigating a bug, error, or regression." |
| pr-feedback | "Fetches unresolved PR review threads, clusters them by concern..." | "Use when a PR has unresolved review threads to address." |

**Constraint:** No description may exceed 80 characters. No description may name tools, models, artifacts, or processes.

---

## Wave 2 — Execution Discipline (D1, D2, D3, D4, D5, E6)

**Theme:** Tighten the execute phase — better escalation, less scope creep, clearer output.
**Effort:** Low — behavioral instructions added to existing skills.
**Files touched:** `skills/execute/SKILL.md`, `skills/execute/references/implementer-prompt.md`, `skills/tdd/SKILL.md`, `templates/04-execution-log.md`.

### 2.1 — Implementer escalation protocol (D1)

**Current state:** Execute skill already defines four statuses (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED) with a Step-Back Protocol (3 strikes). However, the framing is procedural — it doesn't give the subagent explicit permission to stop.

**Action:** Strengthen the escalation protocol in `implementer-prompt.md`:

- Add the explicit statement: *"It is always OK to stop and say 'this is too hard for me.' A BLOCKED report that arrives quickly is more valuable than a DONE report that is wrong."*
- Define each status with concrete examples:
  - **DONE** — all acceptance criteria met, all tests pass, no concerns
  - **DONE_WITH_CONCERNS** — criteria met but something feels off (name it)
  - **NEEDS_CONTEXT** — missing information that isn't in the provided context (name what's missing)
  - **BLOCKED** — cannot proceed without human decision or the task exceeds capability
- Add an anti-rationalization entry: *"I can probably figure this out" → "If you've spent two attempts and are still guessing, report BLOCKED. The orchestrator can reassign or escalate."*

### 2.2 — "Read the test file first" heuristic (D2)

**Action:** Add to `skills/tdd/SKILL.md` as a mandatory step before the RED phase:

> **Step 0 — Survey existing tests.** Before writing any test, read the existing test file (if one exists) for the module under change. Note: fixture patterns, helper functions, naming conventions, describe/context nesting style, assertion library. Your new tests must be indistinguishable from the existing ones in style.

Also add as a red flag: *"You created a new test file when an existing one covers the same module."*

### 2.3 — Minimal change philosophy (D3)

**Action:** Add to `skills/execute/SKILL.md` as a stated constraint, repeated at both the skill level and in the implementer prompt:

> **Minimal Diff Constraint:** Change the least amount of code possible to achieve the goal. Every line in the diff must be traceable to an acceptance criterion in the plan. If you cannot trace it, do not write it.

Add as an anti-rationalization: *"While I'm here, I should also clean up X" → "You are not here to clean up. You are here to deliver the acceptance criteria. Flag it as NOTICED BUT NOT TOUCHING."*

### 2.4 — "NOTICED BUT NOT TOUCHING" pattern (D4)

**Action:** Add to `skills/execute/SKILL.md` and `implementer-prompt.md`:

> **Scope Discipline — NOTICED BUT NOT TOUCHING:** When you notice an out-of-scope improvement opportunity during execution, log it in a `### Noticed But Not Touching` section in the execution log. Format: one line per observation, stating what you noticed and why it's out of scope. Do NOT act on these observations.

Add to `templates/04-execution-log.md` a new section after each wave:

```markdown
### Noticed But Not Touching
- _None this wave_ OR
- [description of observation] — out of scope because [reason]
```

### 2.5 — Confusion management pattern (D5)

**Current state:** `using-toolkit` already has "Manage Confusion Actively" as operating behavior #5. However, it's a brief statement, not a protocol.

**Action:** Expand the existing behavior into a concrete protocol in `skills/execute/SKILL.md` and reference it from `using-toolkit`:

> **Confusion Protocol:**
> 1. **STOP** — Do not write code while confused.
> 2. **NAME** — State the confusion explicitly: "I am confused about X because Y."
> 3. **OPTIONS** — Present the options you see: "Option A: ... / Option B: ..."
> 4. **WAIT** — If in a subagent: report NEEDS_CONTEXT with the confusion. If in the orchestrator: present to the human.
> 5. **PLAN** — Once resolved, state the plan before executing: "PLAN: 1. X, 2. Y, 3. Z → Executing unless you redirect."

Add as a red flag: *"You are writing code with a TODO or FIXME that describes something you don't understand."*

### 2.6 — Structured change summaries (E6)

**Action:** Add a mandatory output section to the execute skill's completion step and to `templates/04-execution-log.md`:

```markdown
## Change Summary

### Changes Made
- [concise description of each logical change, grouped by intent]

### Things I Didn't Touch
- [areas explicitly in scope but deliberately left unchanged, with reason]

### Potential Concerns
- [risks, edge cases not fully covered, performance implications, migration needs]
```

This replaces or supplements the current execution log's final summary. The execute skill must produce this before handing off to code review.

---

## Wave 3 — Review Quality (C1, C2, B4)

**Theme:** Make reviews harder to game — split spec compliance from code quality, add adversarial framing.
**Effort:** Medium — restructures code-review dispatch and adds a new reviewer persona to revision.
**Files touched:** `skills/code-review/SKILL.md`, `skills/code-review/references/reviewer-prompt.md`, `agents/plan-alignment-reviewer.md`, `skills/revision/SKILL.md`, `agents/` (new file).

### 3.1 — Two-stage review: spec compliance then code quality (C1)

**Current state:** Code review dispatches all reviewers in parallel. Plan-alignment-reviewer is one of several, conditional on `02-plan.md` existing. Nothing prevents quality findings from masking missing features.

**Action:** Restructure the code-review skill into two explicit stages:

**Stage 1 — Spec Compliance (blocking gate)**
- Dispatch `plan-alignment-reviewer` first, alone
- It produces its findings
- If any P0 or P1 finding relates to missing/incomplete acceptance criteria → STOP. Do not proceed to Stage 2. Report back to orchestrator for fix-loop.
- Rationale: there's no point reviewing code quality of code that doesn't exist yet

**Stage 2 — Code Quality (parallel)**
- Only after Stage 1 passes (no P0/P1 spec gaps)
- Dispatch remaining reviewers in parallel: code-quality, test, security (conditional), convention (conditional)

**Changes to `code-review/SKILL.md`:**
- Replace the single parallel dispatch with a two-stage process
- Add the gate condition between stages
- Update the `05-code-review.md` template to show two stages

**Changes to `05-code-review.md` template:**
- Add "Stage 1: Spec Compliance" and "Stage 2: Code Quality" sections

### 3.2 — "Suspiciously quick" reviewer framing (C2)

**Action:** Add the following framing to `agents/plan-alignment-reviewer.md` at the top of its instructions:

> **Adversarial Framing:** The implementer finished suspiciously quickly. Their report may be incomplete, inaccurate, or optimistic. Your job is to distrust the self-report and verify against the source of truth: the plan, the acceptance criteria, and the actual code. Do not rubber-stamp. If something looks correct at a glance, look harder.

Also add to the plan-alignment-reviewer's red flags:
- *"Every acceptance criterion is marked as met" → "Statistically unlikely. At least one deserves deeper inspection."*
- *"The implementation looks clean and complete" → "You haven't looked hard enough. Read the actual test assertions."*

### 3.3 — Adversarial document reviewer in revision phase (B4)

**Action:** Create a new agent `agents/adversarial-reviewer.md` — a reviewer persona dispatched during the revision phase (Phase 3) that challenges premises and surfaces unstated assumptions.

**Persona definition:**
- Name: Adversarial Reviewer
- Model: Sonnet/medium
- Dispatch: Always during revision phase (when brainstorm + plan both exist)
- Role: Challenge premises, surface unstated assumptions, stress-test decisions
- Scope: Requirements and plan documents only (not code)

**Adversarial reviewer checklist:**
1. **Premise challenge:** For each stated assumption in brainstorm/plan, ask "What if this is wrong? What breaks?"
2. **Unstated assumptions:** What does the plan assume without saying? (e.g., "assumes single-tenant", "assumes synchronous processing")
3. **Missing failure modes:** What happens when X fails? Is there a plan for it?
4. **Scope boundary stress:** Push on each non-goal — is it really a non-goal, or is it a deferred requirement that will bite later?
5. **Alternative challenge:** For the chosen option, what's the strongest argument for a rejected alternative?

**Changes to `skills/revision/SKILL.md`:**
- Add adversarial reviewer dispatch as a new step in the revision process
- Adversarial findings are included in `03-revision.md` under a dedicated section
- The human approval gate now includes adversarial findings

**Durability enforcement:** Adversarial findings must describe concerns in terms of behaviors and invariants, not file locations or code structures.

---

## Wave 4 — Decision Stress-Testing (B3)

**Theme:** Optional council debate for high-stakes architectural decisions.
**Effort:** Medium-high — new multi-agent pattern, integrated as optional mode in brainstorm/revision.
**Files touched:** `skills/brainstorm/SKILL.md` (or new skill), new `references/council-debate.md`.

### 4.1 — Council debate pattern (B3)

**Action:** Add an optional `/council` mode that can be invoked during brainstorm or revision when facing a high-stakes architectural decision. This is NOT part of the default pipeline — it's an on-demand tool.

**Six advisor archetypes:**

| Advisor | Perspective | Asks |
|---------|------------|------|
| Pragmatic Engineer | Delivery, maintainability | "Can a mid-level engineer maintain this?" |
| Architect Advisor | System design, longevity | "How does this look in 2 years?" |
| Security Advocate | Threat modeling, attack surface | "How can this be abused?" |
| Product Mind | User impact, business value | "Does this solve the user's actual problem?" |
| Devil's Advocate | Contrarian, worst case | "What's the strongest case against this?" |
| The Thinker | First principles, simplicity | "Are we solving the right problem?" |

**Debate protocol:**
1. **Position statements** — Each advisor states their view (1 paragraph max)
2. **Steel-manning** — Each advisor must restate the strongest opposing view before arguing against it
3. **Evidence requirements** — Claims must cite project context, not hypotheticals
4. **Concession tracking** — When an advisor changes position, it's recorded explicitly
5. **Synthesis** — After debate, produce a decision record: chosen direction, key trade-offs, what was conceded

**Implementation:** Create `skills/brainstorm/references/council-debate.md` with the full protocol. The brainstorm skill:
- **Auto-invocation:** When brainstorm detects a high-stakes architectural decision (multiple viable options with significant trade-offs, irreversible choices, cross-cutting concerns affecting 3+ system areas), it invokes the council automatically before finalizing the recommendation.
- **Manual invocation:** The human may also invoke the council explicitly at any point during brainstorm or revision.

**Dispatch model:** Each advisor is a Sonnet/medium subagent with the persona prompt. Run 3 at a time (2 rounds) to manage context. The orchestrator synthesizes.

---

## Wave 5 — Knowledge Durability (E2, Durability Principle)

**Theme:** Ensure artifacts are discoverable and survive codebase changes.
**Effort:** Low-medium — content additions to solutions skill + template/schema updates.
**Files touched:** `skills/solutions/SKILL.md`, `templates/*.md`, `findings-schema.json`, `skills/plan/SKILL.md`, `skills/brainstorm/SKILL.md`, `skills/diagnosis/SKILL.md`.

### 5.1 — Discoverability check for knowledge store (E2)

**Action:** Add a final step to `skills/solutions/SKILL.md`:

> **Step N — Discoverability Check.** After writing `06-solutions.md`, verify that a future agent session would find it:
> 1. Read the project's CLAUDE.md (or equivalent rules file).
> 2. Check: does it reference the `docs/` directory or solutions documents?
> 3. If not, propose a one-line addition to CLAUDE.md: `# Solutions — past decisions and gotchas are in docs/*/06-solutions.md`
> 4. Present the proposed edit to the human for approval. Do not edit CLAUDE.md without approval.

### 5.2 — Durability principle enforcement across all artifacts

**Action:** Apply the durability principle to every template and artifact-producing skill.

**Changes to `templates/02-plan.md`:**
- Implementation steps must describe *what* changes by intent, not by file path
- File paths in the "files" field are operational hints, not part of the specification
- Add a note: *"Acceptance criteria must be verifiable from behavior alone, without reference to specific lines or code structure"*

**Changes to `templates/06-solutions.md`:**
- The "Root Cause" section describes the *mechanism* of failure, not the file:line
- The "Gotchas" section describes *invariants to maintain*, not code to avoid changing
- Remove the `file:line` notation from the root cause template

**Changes to `findings-schema.json`:**
- The `file` and `line` fields remain (they're operational — reviewers need them to point at code)
- Add a new field: `"intent": "string"` — a file/line-independent description of what the finding is about
- The `suggested_fix` field must describe the fix as a behavioral change, not a code diff
- Add to schema documentation: *"The `intent` field must be meaningful even if the file is renamed or the code is restructured."*

**Changes to skill instructions (plan, brainstorm, diagnosis, solutions):**
- Add to each: *"When describing changes, fixes, or decisions in artifacts, describe them by intent and behavior. Do not embed file paths, line numbers, or code snippets into prose sections. These artifacts must remain valid after the codebase is refactored."*

**Changes to `agents/plan-alignment-reviewer.md`:**
- Add a check: *"Flag any acceptance criterion that can only be verified by checking a specific file path or line number. Acceptance criteria must be behavior-based."*

---

## Implementation Order and Dependencies

```
Wave 1 (Skill Hardening)     ─── no dependencies, start immediately
  ├── 1.1 Anti-rationalization tables
  ├── 1.2 Red Flags sections
  ├── 1.3 Verify-before-act checklist
  └── 1.4 Skill description rewrite

Wave 2 (Execution Discipline) ─── no dependencies on Wave 1
  ├── 2.1 Escalation protocol
  ├── 2.2 Read test file first
  ├── 2.3 Minimal change constraint
  ├── 2.4 NOTICED BUT NOT TOUCHING
  ├── 2.5 Confusion management
  └── 2.6 Structured change summaries

Wave 3 (Review Quality)       ─── depends on Wave 1.2 (red flags in reviewers)
  ├── 3.1 Two-stage review          ← depends on 3.2
  ├── 3.2 Suspiciously quick framing
  └── 3.3 Adversarial document reviewer

Wave 4 (Decision Stress-Test)  ─── no hard dependencies, can parallel with Wave 3
  └── 4.1 Council debate pattern

Wave 5 (Knowledge Durability)  ─── no hard dependencies, can parallel with Waves 3–4
  ├── 5.1 Discoverability check
  └── 5.2 Durability enforcement (cross-cutting)
```

Waves 1 and 2 can execute in parallel — they touch different files.
Waves 3, 4, and 5 can mostly execute in parallel after Waves 1–2.

---

## Effort Summary

| Wave | Items | Effort | New files | Modified files |
|------|-------|--------|-----------|----------------|
| 1 | A1, A2, A3, A4 | Low | 0 | 14 SKILL.md + 6 agent .md |
| 2 | D1, D2, D3, D4, D5, E6 | Low | 0 | 4 (execute, tdd, using-toolkit, template) |
| 3 | C1, C2, B4 | Medium | 1 (adversarial-reviewer.md) | 4 (code-review, plan-alignment, revision, template) |
| 4 | B3 | Medium-high | 1 (council-debate.md) | 1 (brainstorm) |
| 5 | E2, Durability | Low-medium | 0 | 7 (solutions, templates, schema, skill instructions) |

**Total new files:** 2
**Total modified files:** ~25 (some touched in multiple waves)

---

## Verification Criteria

Each wave is complete when:

1. **Wave 1:** Every skill has a Common Rationalizations table (3–5 entries), a Red Flags self-check section, and a trigger-only description under 80 characters. Execute skill has the pre-flight checklist.

2. **Wave 2:** Execute skill contains escalation protocol with explicit permission to stop, minimal diff constraint, NOTICED BUT NOT TOUCHING pattern, confusion protocol, and structured change summary template. TDD skill has "read existing tests first" as Step 0.

3. **Wave 3:** Code review runs in two stages (spec compliance gates code quality). Plan-alignment-reviewer has adversarial framing. New adversarial-reviewer agent exists and is dispatched during revision.

4. **Wave 4:** Council debate protocol exists in brainstorm references. Six advisor personas are defined. Brainstorm skill references `/council` as optional mode.

5. **Wave 5:** Solutions skill has discoverability check. All templates enforce durability (no file paths in prose). Findings schema has `intent` field. Plan-alignment-reviewer flags non-behavioral acceptance criteria.
