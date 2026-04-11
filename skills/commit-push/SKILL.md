---
name: commit-push
description: Use when code is reviewed and ready to commit.
---

# Commit and Push (Final Phase)

Safely commit and push code changes with proper git hygiene. This phase enforces one absolute rule: NEVER commit or push directly to a protected branch such as `main`, `master`, `production`, `prod`, `stable`, `live`, or `trunk`.

## Prerequisites

- Code review complete. `05-code-review.md` MUST exist in the active spec directory with verdict APPROVED or REQUIRES CHANGES with all P0 issues resolved.
- All tests passing.
- No P0 issues outstanding from the code review.
- For trivial pipeline: tests passing and lint clean (no review required).

## Process

### Phase 1 — Branch Name Input

**ASK the user for the target branch name:**

```
What branch should this be committed to?

Suggested: <type>/<topic-from-brainstorm> (e.g., feat/user-authentication)
```

DERIVE the suggestion from spec artifacts:
1. READ the `topic` field from brainstorm or diagnosis frontmatter.
2. CONVERT to kebab-case, lowercase.
3. DETERMINE prefix: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/`.

**After receiving the branch name:**
1. If the requested branch name is a protected branch name (for example `main`, `master`, `production`, `prod`, `stable`, `live`, `trunk`): REFUSE. Ask for a different name.
2. If exists remotely: checkout and pull.
3. If new: create locally with `git checkout -b <branch-name>`.

### Phase 2 — Pre-Commit Verification [HARD GATE]

ALL checks MUST pass before staging any files.

**1. Test suite**
- RUN the project's full test suite.
- If any test fails, STOP. Fix before proceeding.

**2. Linter and Formatter**
- RUN the project's linter (ESLint, Rubocop, Ruff, etc.) if configured.
- RUN the project's formatter (Prettier, etc.) if configured.
- If errors (not warnings), STOP. Fix before proceeding.
- This is a HARD GATE — no commit proceeds with lint errors.

**3. Debug artifact scan**
- SEARCH changed files for: `console.log` (in production code), `debugger`, debug print statements, `TODO` without ticket reference, `FIXME`, `HACK`.
- If found: LIST them and ASK the user whether to remove or keep.

**4. Secrets scan**
- SCAN for: API key patterns, password/secret/token assignments, `.env` files, private keys.
- If found: STOP. NEVER commit secrets.

**5. Scope verification**
- LIST all modified files.
- COMPARE against plan and review scope.
- FLAG any modified file NOT in scope. ASK user to confirm.

### Phase 3 — Logical Commit Splitting

**SPLIT when:**
- Changes address different concerns
- Large feature has clearly separable parts
- Test infrastructure changes are independent of feature code

**KEEP as one when:**
- Implementation and tests are from the same TDD cycle
- Changes are tightly coupled
- Total change is under 100 lines

**Rules:**
- Maximum 3 commits per pipeline run.
- Each commit MUST leave the system in a passing state.
- STAGE specific files. NEVER use `git add -A` or `git add .`.

### Phase 4 — Conventional Commit Messages

Format: `<type>(<scope>): <description>`

| Type | Use For |
|------|---------|
| `feat` | New feature visible to user |
| `fix` | Bug fix |
| `refactor` | Restructuring without behavior change |
| `test` | Tests only |
| `docs` | Documentation only |
| `chore` | Maintenance (deps, config, tooling) |

**Rules:**
- Imperative mood: "add user form" not "added user form"
- First line under 72 characters
- Body (mandatory for feat/fix): explain WHY, not WHAT
- Reference spec: "See 02-plan.md Step 3"
- Reference issues: "Closes #123"

**Testing scenarios section (mandatory for feat/fix):**
```
Testing scenarios:

[Scenario name]
Before: <what happened before>
After: <what happens now>
```

CHECK for commitlint config first. If found, it takes precedence over log patterns.

### Phase 5 — PR Description

If pushing to create a PR, generate the PR description from spec artifacts:

```markdown
## Motivation

{{Why this change was made — extracted from 01-brainstorm.md problem statement}}

## What Changed

{{Summary of changes — extracted from 02-plan.md key decisions and 04-execution-log.md}}

## QA Guide

{{Before/after scenarios from commit messages, expanded with step-by-step reproduction}}

### Before
{{How the feature/bug behaved before this change}}

### After
{{How it behaves now, with specific steps to verify}}

## Spec Artifacts

- Brainstorm: `docs/YYYY-MM-DD-topic/01-brainstorm.md`
- Plan: `docs/YYYY-MM-DD-topic/02-plan.md`
- Review: `docs/YYYY-MM-DD-topic/05-code-review.md`
```

### Phase 6 — Rebase and Push

1. `git fetch origin`
2. Determine default branch: `git remote show origin | grep 'HEAD branch'`
3. `git pull --rebase origin <default-branch>`
4. If conflicts: trivial = auto-resolve, non-trivial = STOP and show user.
5. `git push -u origin <branch-name>`
6. If rejected: DO NOT force push. Fetch, rebase, try again.
7. Report: branch, commit hashes, test count.

## ABSOLUTE RULES

1. **NEVER commit to a protected branch.** No exceptions. Protected branch names include `main`, `master`, `production`, `prod`, `stable`, `live`, and `trunk`.
2. **NEVER `git push --force` without explicit human approval.** Use `--force-with-lease` if approved.
3. **NEVER `--no-verify`.** Fix the underlying issue.
4. **NEVER `git add -A` or `git add .`.** Stage specific files by name.
5. **NEVER commit secrets.** Refuse even if user asks.
6. **NEVER skip pre-commit verification.** Tests and lint MUST pass.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll push to a protected branch just this once, it's a small fix" | There is no exception. Create a branch. The hook will block you anyway. |
| "Tests passed earlier, no need to re-run" | State changes between runs. Re-run. The pre-commit gate exists for a reason. |
| "Lint warnings are fine, only errors matter" | Check the project config. Some projects treat warnings as errors. Run the linter. |
| "I'll write the PR description later" | The spec artifacts exist now. The PR description takes 2 minutes. Later means never. |

## Red Flags — Self-Check

- You are on a protected branch (`main`, `master`, `production`, `prod`, `stable`, `live`, `trunk`)
- You used `git add -A` or `git add .` instead of staging specific files
- You skipped the pre-commit verification gate (tests, lint, secrets)
- You committed without a conventional commit message
- Unstaged files exist that match the change scope
- You are about to force-push without explicit human approval

## Error Recovery

**Commit to a protected branch by mistake:**
1. Do not push. Create branch: `git checkout -b <type>/<topic>`
2. Reset the protected branch to its remote tracking branch before continuing
3. Push the feature branch.

**Secrets staged:**
1. Unstage: `git reset HEAD <file>`
2. If committed but not pushed: `git reset --soft HEAD~1`, remove, recommit.
3. If pushed: secret is compromised. Rotate immediately.

## Transition

WHEN this skill completes:
- REPORT the commit summary (branch, commit hashes, test count).
- IF running inside a pipeline: RETURN control to the pipeline orchestrator.
- IF running standalone: display summary. DO NOT ask "what would you like to do next?"
