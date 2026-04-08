---
name: code-review
description: Use after implementation is complete and all tests pass. Dispatches parallel reviewer subagents to evaluate code across five axes. Produces docs/spec/04-code-review.md with findings by severity.
---

# Code Review (Phase 5)

Catch defects, convention violations, security issues, and plan misalignment BEFORE code is committed. Multiple independent reviewers examine different aspects in parallel, then findings are merged, deduplicated, and classified by severity.

## Prerequisites

- All tests must pass. If the test gate from Phase 4 has not been met, STOP. Run the test suite and fix failures first.
- A plan artifact (`02-plan.md`) must exist in the active per-session spec directory (format: `docs/YYYY-MM-DD-short-description/`). Also check the legacy location `docs/spec/`. If it does not exist in either location, STOP. The plan-alignment reviewer cannot function without it. In resolve mode, `01-diagnosis.md` serves as the plan reference instead.
- Project context from Phase 0 must be loaded. If not available in the conversation, run `/context` first.

## Reviewer Classification

Reviewers are classified as BLOCKING or non-blocking. Only BLOCKING reviewers affect the pipeline verdict. Non-blocking reviewers provide valuable feedback but do not trigger Gate #2.

| Reviewer | Classification | Rationale |
|----------|---------------|-----------|
| Plan Alignment Reviewer | **BLOCKING** | If the code does not match the plan, it is wrong by definition |
| Code Quality Reviewer | **BLOCKING** | Correctness and security issues must block |
| Convention Reviewer | Non-blocking | Convention violations are important but not commit-blocking |
| Test Reviewer | **BLOCKING** | Weak tests mask bugs and undermine the TDD guarantee |
| Security Reviewer | **BLOCKING** | Security issues always block (when dispatched) |

The pipeline verdict depends ONLY on BLOCKING reviewers. Non-blocking findings are logged in the review artifact and reported to the user, but they do not trigger Gate #2.

## Process

Execute these phases in strict order. Do not skip phases.

### Phase 5.1 -- Compute the Diff

Determine what changed during this pipeline run:

1. Run `git diff` against the base branch (or the commit before this pipeline run began) to get all changes.
2. If the project is not using git, compare the current state against the state before Phase 4 began by examining recently modified files.
3. Identify all changed files and classify them into scope areas:
   - Frontend components (`*.tsx`, `*.vue`, `*.svelte`, `*.jsx`)
   - API routes and backend logic
   - Data models and schemas
   - Test files
   - Configuration and infrastructure

If there is no diff (nothing changed), STOP. There is nothing to review.

### Phase 5.2 -- Partition the Diff

Divide the changed files into scope areas. Each scope area feeds into the appropriate reviewer(s).

Example partitioning for a typical full-stack change:
- **Scope A:** Frontend components and pages
- **Scope B:** API routes, middleware, server-side logic
- **Scope C:** Data models, schemas, migrations
- **Scope D:** Test files
- **Scope E:** Configuration, build, CI/CD

If the total diff is small (fewer than 200 lines across all files), skip partitioning. A single pass by each reviewer covers the entire diff.

### Phase 5.3 -- Dispatch Reviewers

Dispatch the following reviewer subagents IN PARALLEL. They are read-only -- there are no write conflicts between them.

**1. Plan Alignment Reviewer** (always dispatched)
- Agent file: `agents/plan-alignment-reviewer.md`
- Receives: full diff + relevant sections of `docs/spec/02-plan.md` (and `docs/spec/03-revision.md` if it exists)
- Checks: every planned feature is present, no unplanned additions exist without justification, acceptance criteria are met in code or tests

**2. Code Quality Reviewer** (always dispatched)
- Agent file: `agents/code-quality-reviewer.md`
- Receives: diff partitioned by scope area + project context
- Checks: five axes -- correctness, readability, architecture, security, performance (see `references/five-axes.md`)

**3. Convention Reviewer** (always dispatched)
- Agent file: `agents/convention-reviewer.md`
- Receives: diff + project context (conventions section)
- Checks: naming conventions, file placement, import patterns, styling consistency, error handling patterns

**4. Test Reviewer** (always dispatched)
- Agent file: `agents/test-reviewer.md`
- Receives: test file diffs + plan's test strategy section
- Checks: coverage of acceptance criteria, test quality, anti-patterns, pyramid compliance

**5. Security Reviewer** (conditionally dispatched)
- Agent file: `agents/security-reviewer.md`
- Dispatched ONLY when the diff touches any of: authentication or authorization logic, user input handling, API endpoints, data storage or database queries, environment variables or secrets, external service calls or webhooks, file upload/download, session or token management
- Receives: relevant diff sections + security context from project conventions
- Checks: OWASP Top 10, input validation, auth/authz, injection vectors, secrets in code
- Additionally checks: PCI-DSS compliance patterns when the diff touches payment processing, checkout flows, or financial data (see `agents/security-reviewer.md` PCI/E-Commerce Security Module)

Each reviewer receives a prompt constructed from the template in `references/reviewer-prompt.md`, filled in with the reviewer's specific scope, agent file reference, and relevant diff sections.

**Implementation Notes:** If implementation notes were collected during Phase 4 (see `skills/execute/SKILL.md` Phase 4.7), include them in each reviewer's prompt. Implementation notes highlight the implementer's approach, rejected alternatives, concerns, and hotspots — helping reviewers focus on the areas most likely to contain issues.

### Phase 5.4 -- Collect and Merge Findings

After all reviewers complete:

**1. Collect** all findings from every reviewer into a single list.

**2. Deduplicate.** If two or more reviewers flag the same issue (same file, same line, same underlying problem):
- Keep the finding with the most detailed description and evidence.
- Promote the severity to the highest level assigned by any reviewer. If the Code Quality Reviewer flagged it as P2 and the Security Reviewer flagged it as P0, the merged finding is P0.
- Note all reviewers who identified the issue.

**3. Classify** every finding using the severity guide from `references/severity-guide.md`:
- **P0 (Critical)** -- Blocks commit. Security vulnerability, data loss risk, logic error causing incorrect behavior in the happy path, missing error handling that causes silent data loss, breaking change to a public API without migration.
- **P1 (Important)** -- Should fix before commit. Missing edge case handling, error handling that swallows errors silently, suboptimal pattern that will cause maintenance burden, weak test assertions, missing test for a planned acceptance criterion.
- **P2 (Minor)** -- Nice to have. Naming could be clearer, minor code duplication under 5 lines, missing comment for non-obvious logic, slightly more complex than necessary.
- **P3 (Suggestion)** -- FYI. Alternative approach worth considering, style preference not violating conventions, future improvement opportunity.

**4. Sort** all findings by severity (P0 first, then P1, P2, P3).

### Phase 5.5 -- Write Review Artifact

Write `04-code-review.md` in the same per-session spec directory where the other artifacts were found, using the template from `templates/04-code-review.md`.

Fill in every section:
- YAML frontmatter with phase, date, status, topic, and reviewer list
- Review summary with counts by severity
- Reviewer scope table showing which files each reviewer examined
- All findings grouped by severity, each with file location, description, evidence, reviewer attribution, and suggested fix
- "What's Done Well" section with 2-3 specific positive observations grounded in the actual code
- Verdict: APPROVE (no P0 issues) or REQUIRES CHANGES (P0 issues exist)

The artifact must be complete. No placeholders, no TODOs, no "see above." Another agent must be able to read it without any conversation context.

### Phase 5.6 -- Gate Decision

**Gate decision logic:** Count P0 issues ONLY from BLOCKING reviewers (plan-alignment, code-quality, test, security). P0 issues from non-blocking reviewers (convention) are reported but do not trigger the gate.

**If P0 (critical) issues exist:**

```
CODE REVIEW FOUND [N] CRITICAL ISSUES:

1. [P0 title] — [file:line] — [one-sentence description]
2. [P0 title] — [file:line] — [one-sentence description]
...

These must be resolved before commit. Options:
1. I'll fix these now (proceed to fix, then re-review)
2. Let me review the issues first (pause for human inspection)
```

Do NOT proceed to commit. The pipeline is blocked until all P0 issues are resolved and a re-review confirms the fix.

**If no P0 issues exist:**

```
Code review complete. [N] issues found ([X] P1, [Y] P2, [Z] P3).
No critical issues blocking commit. Proceed to /commit when ready.

P1 issues recommended for fixing before commit:
- [P1 title] — [file:line]
- [P1 title] — [file:line]
```

## Reviewer Dispatch Details

When constructing reviewer prompts, load the template from `references/reviewer-prompt.md` and fill in:
- `[SCOPE]` -- the scope area name (e.g., "Plan Alignment", "Code Quality")
- `[REVIEWER_PERSONA]` -- the reviewer's role description from the agent file frontmatter
- `[AGENT_FILE]` -- the path to the agent's instruction file
- `[PROJECT_CONTEXT]` -- the project context block from Phase 0
- `[PLAN_REFERENCE]` -- the relevant section(s) of `docs/spec/02-plan.md`
- `[DIFF]` -- the git diff for the files in this reviewer's scope

## Severity Classification

Load `references/severity-guide.md` for detailed classification criteria with examples. When in doubt about severity, escalate: it is better to flag a P1 as P0 than to miss a critical issue.

## Rules

- Reviewers MUST read the actual code. "CRITICAL: Do NOT trust any self-reported claims about what the code does." This applies to code comments, variable names, docstrings, and commit messages. Read the logic.
- Every finding MUST include evidence: the specific code line, pattern, or absence that triggered the finding. Findings without evidence are rejected.
- Reviewers MUST NOT rubber-stamp. If the code looks perfect, the reviewer has not looked hard enough. Perfect code is rare. A review that finds zero issues across hundreds of lines is suspicious and must include explicit justification for the clean bill.
- The plan-alignment reviewer is the single source of truth for "is this what we said we'd build?" Other reviewers defer to it on questions of feature completeness and scope.
- If a reviewer finds something outside its scope (e.g., the convention reviewer spots a security issue), it MUST still report it. Cross-scope findings are tagged with the discovering reviewer and the primary scope they belong to.
- The five review axes are defined in detail in `references/five-axes.md`. Reviewers must be familiar with all axes even though each reviewer focuses on a subset.

## Handoff

Code review complete. If no P0 issues: "Review complete. Proceed to `/commit` to commit and push changes." If P0 issues exist: "Review blocked. Fix the critical issues listed above, then re-run `/code-review`."
