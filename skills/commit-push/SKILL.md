---
name: commit-push
description: Use when code is reviewed and ready to commit. Enforces branch safety (never commits to master/main), conventional commits, logical commit splitting, and rebase before push.
---

# Commit and Push (Phase 6)

Safely commit and push code changes with proper git hygiene. This phase enforces one absolute, inviolable rule: NEVER commit or push directly to master or main.

## Prerequisites

- Code review complete (Phase 5). `04-code-review.md` MUST exist in the active spec directory with verdict APPROVE or REQUIRES CHANGES with all P0 issues resolved. To find it: CHECK the most recent `docs/YYYY-MM-DD-*/` directory first, then fall back to `docs/spec/`.
- All tests passing. If tests have not been run since the last code change, RUN them now.
- No P0 issues outstanding from the code review.

## Process

EXECUTE these phases in strict order. DO NOT skip phases. DO NOT bypass checks.

**Phase 6.2 is a HARD GATE.** DO NOT proceed to Phase 6.3 (staging) until ALL checks in Phase 6.2 pass. If you find yourself running `git add` without having run the test suite first, STOP. GO BACK to Phase 6.2.

### Phase 6.1 -- Branch Name Input

This is the first thing that happens. No exceptions.

**ASK the user for the target branch name:**

```
What branch should this be committed to?

Suggested: <type>/<topic-from-brainstorm> (e.g., feat/user-authentication)

Please provide the branch name, or confirm the suggestion.
```

DERIVE the suggestion from the spec artifacts:
1. READ the `topic` field from the brainstorm or diagnosis frontmatter.
2. CONVERT to kebab-case, lowercase, no special characters.
3. DETERMINE the type prefix: `feat/` for features, `fix/` for bug fixes, `chore/` for maintenance, `refactor/` for restructuring, `docs/` for documentation, `test/` for test additions.

**After receiving the branch name:**

1. **CHECK if it is `master` or `main`:**
   - REFUSE. DO NOT stage files. DO NOT create a commit. Explain why and ASK for a different branch name.

2. **CHECK if the branch exists remotely:**
   ```
   git ls-remote --heads origin <branch-name>
   ```
   - If it exists remotely: CHECK OUT to it and PULL latest changes.
     ```
     git checkout <branch-name> && git pull origin <branch-name>
     ```
   - If it does not exist remotely: CREATE it locally.
     ```
     git checkout -b <branch-name>
     ```

3. PROCEED to Phase 6.2.

### Phase 6.2 -- Pre-Commit Verification

RUN ALL of the following checks before staging any files. Every check MUST pass.

**1. Test suite**
- RUN the project's full test suite using the command from project context.
- If any test fails, STOP. FIX the failing test before proceeding. DO NOT commit with failing tests.

**2. Linter**
- If the project has a linter configured (ESLint, Rubocop, Ruff, golangci-lint, etc.), RUN it.
- If the linter reports errors (not warnings), STOP. FIX the lint errors before proceeding.
- If no linter is configured, SKIP this check.

**3. Debug artifact scan**
- SEARCH all changed files for debug artifacts that MUST NOT be committed:
  - `console.log` (in production code, not test files)
  - `debugger` statements
  - `print()` or `puts` used for debugging (not logging)
  - `TODO` comments without a ticket reference (e.g., `TODO` is bad, `TODO(JIRA-123)` is acceptable)
  - `FIXME` or `HACK` comments
  - `binding.pry`, `byebug`, `import pdb; pdb.set_trace()`
- If found: LIST them and ASK the user whether to remove them or keep them. DO NOT silently remove.

**4. Secrets scan**
- SCAN all changed files for patterns that indicate secrets:
  - Strings matching API key formats (long alphanumeric strings, base64 tokens)
  - Variables named `password`, `secret`, `token`, `api_key`, `apiKey`, `API_KEY` assigned to string literals
  - Connection strings with credentials embedded
  - `.env` files or files matching `.env.*`
  - Private keys (`-----BEGIN RSA PRIVATE KEY-----` or similar)
- If found: STOP. DO NOT commit. LIST the findings and WARN the user. NEVER commit secrets.

**5. Scope verification**
- LIST all files that have been modified (`git status`).
- COMPARE against the files listed in `02-plan.md` and `04-code-review.md` from the active spec directory.
- FLAG any modified file that is NOT in the plan or review scope. ASK the user to confirm inclusion or exclude it.

### Phase 6.3 -- Logical Commit Splitting

ANALYZE all changes and DETERMINE whether they MUST be one commit or multiple commits.

**SPLIT into separate commits when:**
- Changes address different concerns (a new component and an unrelated config fix are two commits)
- A large feature has clearly separable parts (data model, API endpoint, UI component)
- Test infrastructure changes are independent of feature code

**KEEP in one commit when:**
- Implementation and its tests are part of the same TDD cycle
- Changes are tightly coupled (renaming a function and updating all call sites)
- The total change is small (under 100 lines)

**Rules:**
- Maximum 3 commits per pipeline run. If more are needed, the implementation steps MUST have been combined in Phase 2.
- Each commit MUST leave the system in a passing state. VERIFY tests mentally for each commit boundary -- if a commit would break tests, COMBINE it with the next one.
- STAGE specific files per commit. NEVER use `git add -A` or `git add .`. ALWAYS stage files by name:
  ```
  git add src/components/UserForm.tsx src/components/UserForm.test.tsx
  ```

### Phase 6.4 -- Conventional Commit Messages

FORMAT every commit message as:
```
<type>(<scope>): <description>
```

**Types:**
| Type | Use For |
|------|---------|
| `feat` | A new feature visible to the user |
| `fix` | A bug fix |
| `refactor` | Code restructuring without behavior change |
| `test` | Adding or modifying tests only |
| `docs` | Documentation changes only |
| `chore` | Maintenance tasks (deps, config, tooling) |
| `style` | Formatting, whitespace, missing semicolons (no logic change) |
| `perf` | Performance improvement |
| `ci` | CI/CD configuration changes |
| `build` | Build system or dependency changes |

**Rules for the message:**
- ALWAYS USE imperative mood: "add user form" not "added user form" or "adds user form"
- First line MUST be under 72 characters
- Scope MUST be the module or component name: `feat(auth): add login endpoint`
- If the change is a breaking change, ADD `!` after the type: `feat!(api): remove deprecated login endpoint`
- Body (MANDATORY for feature and fix commits, separated by blank line): EXPLAIN WHY the change was made, not WHAT changed. The diff shows the what.
- REFERENCE the spec when applicable: "See 02-plan.md Step 3"
- REFERENCE issues when applicable: "Closes #123" or "Fixes JIRA-456"

**Testing scenarios section (mandatory in commit body for `feat` and `fix` types):**

ALWAYS INCLUDE a "Testing scenarios" section written from a QA perspective — not a developer perspective. The goal is to help QA reproduce and validate the change. USE a before/after format:

```
Testing scenarios:

[Scenario name]
Before: <what happened before this change>
After: <what should happen now>

[Scenario name]
Before: <what happened before this change>
After: <what should happen now>
```

Example:
```
feat(cart): add empty cart message on checkout

Previously, clicking checkout with an empty cart caused a 500 error.
Now it shows a user-friendly message.

Testing scenarios:

Empty cart checkout
Before: Clicking "Checkout" with no items causes a server error page
After: Shows message "Your cart is empty" with a link to continue shopping

Cart with items checkout
Before: Works normally
After: No change — still proceeds to payment as before
```

INCLUDE as many scenarios as are relevant to the change. KEEP language clear and non-technical enough for a QA engineer to follow without reading the code.

**BEFORE writing the message**, CHECK for a commitlint configuration:
- LOOK FOR: `commitlint.config.cjs`, `commitlint.config.js`, `commitlint.config.ts`, `.commitlintrc`, `.commitlintrc.json`, `.commitlintrc.yaml`, or a `commitlint` section in `package.json`
- If found, READ the config to determine the expected format (type-enum, scope rules, header-max-length, etc.)
- The commitlint config takes **precedence** over git log patterns — projects may have mixed historical styles but MUST enforce a specific format going forward

If no commitlint config is found, CHECK the project's recent git log:
```
git log --oneline -10
```
If the project uses a different commit convention (e.g., no types, different format), ADAPT to the project's existing style. DO NOT impose conventional commits on a project that does not use them.

See `references/conventional-commits.md` for detailed examples.

### Phase 6.5 -- Rebase and Push

After all commits are created locally, EXECUTE these steps in order:

1. **FETCH the latest remote state:**
   ```
   git fetch origin
   ```

2. **DETERMINE the default branch:**
   - CHECK for `main` first, then `master`.
   - USE whatever the remote's HEAD points to:
     ```
     git remote show origin | grep 'HEAD branch'
     ```

3. **REBASE onto the latest default branch:**
   ```
   git pull --rebase origin <default-branch>
   ```

4. **If merge conflicts arise:**
   - For trivial conflicts (whitespace, import order, auto-generated lock files): ATTEMPT auto-resolution.
   - For non-trivial conflicts (logic changes, overlapping edits): STOP. SHOW the conflicting files and hunks to the user. DO NOT guess.
   ```
   MERGE CONFLICT in <file>:

   <<<<<<< HEAD (remote)
   [their code]
   =======
   [your code]
   >>>>>>> <branch> (local)

   This conflict is non-trivial. Please resolve manually or tell me which version to keep.
   ```

5. **PUSH the branch:**
   ```
   git push -u origin <branch-name>
   ```
   If the push is rejected because the remote branch has diverged, DO NOT force push. FETCH, REBASE, and try again.

6. **REPORT:**
   ```
   Changes committed to `<branch-name>`. [N] commit(s) pushed.

   Commits:
   - <hash> <type>(<scope>): <description>
   - <hash> <type>(<scope>): <description>
   ```

## Branch Naming Convention

| Type | Use For | Example |
|------|---------|---------|
| `feat/` | New features | `feat/user-authentication` |
| `fix/` | Bug fixes | `fix/login-redirect-loop` |
| `chore/` | Maintenance tasks | `chore/update-dependencies` |
| `refactor/` | Code restructuring | `refactor/extract-auth-service` |
| `docs/` | Documentation changes | `docs/api-reference` |
| `test/` | Test additions or improvements | `test/auth-edge-cases` |

Branch names are kebab-case, lowercase, no special characters, no spaces. Maximum 50 characters after the prefix.

## ABSOLUTE RULES

These rules have no exceptions. They cannot be overridden by user request, project convention, time pressure, or any other justification.

1. **NEVER commit to master or main.** No exceptions. Ever. If on master or main, CREATE a branch first. If the user asks to commit to main, REFUSE and EXPLAIN why.

2. **NEVER use `git push --force` without explicit human approval.** If a force push is needed (e.g., after interactive rebase), EXPLAIN the consequences and ASK for confirmation. Even with approval, ALWAYS USE `--force-with-lease` over `--force`.

3. **NEVER use `--no-verify` to skip pre-commit hooks.** If hooks fail, FIX the underlying issue. Hooks exist for a reason. Bypassing them defeats the purpose of the quality gate.

4. **NEVER use `git add -A` or `git add .` to stage files.** ALWAYS STAGE specific files by name. Mass staging picks up unintended files: debug logs, .env files, build artifacts, OS files (.DS_Store), editor files (.idea/, .vscode/).

5. **NEVER commit files that may contain secrets.** This includes `.env`, `credentials.json`, `*.pem`, `*.key`, `serviceAccountKey.json`, and any file containing API keys, tokens, or passwords. If the user explicitly asks to commit such a file, REFUSE and EXPLAIN the risk.

6. **NEVER skip pre-commit verification (Phase 6.2).** DO NOT rely on Husky hooks as the only safety net. RUN the test suite, linter, and type checker proactively before staging. "Tests passed in Phase 4" does not mean they still pass now — formatter interference, merge conflicts, or manual edits can break them.

## Error Recovery

**If a commit was made to master/main by mistake:**
1. DO NOT push.
2. CREATE a branch from the current state: `git checkout -b <type>/<topic>`
3. RESET master/main to the remote state: `git branch -f main origin/main`
4. The commits are now on the feature branch. PUSH the feature branch.

**If secrets were accidentally staged:**
1. UNSTAGE immediately: `git reset HEAD <file>`
2. If already committed but not pushed: RUN `git reset --soft HEAD~1`, REMOVE the secret, RECOMMIT.
3. If already pushed: the secret is compromised. ROTATE the credential immediately. Then REMOVE from history with `git filter-branch` or `git-filter-repo`.

## Transition

WHEN this skill completes:
- REPORT the commit summary (branch, commit hashes, test count).
- IF running inside a pipeline: RETURN control to the pipeline orchestrator. The orchestrator WILL display the pipeline complete message. DO NOT display it yourself.
- IF running standalone: DISPLAY the commit summary and INFORM the user the work is committed and pushed.

DO NOT ask "what would you like to do next?". The pipeline is complete.
