# Conventional Commits Quick Reference

Conventional Commits is a specification for structuring commit messages to make them human-readable and machine-parseable. This reference covers the format, types, and rules enforced by the commit-push skill.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

- **First line** (header): mandatory, under 72 characters
- **Body**: optional, separated from header by one blank line
- **Footer**: optional, separated from body by one blank line

## Types

### `feat` -- New Feature
A new capability visible to users or consumers of the system.
```
feat(auth): add password reset flow
feat(cart): support multiple shipping addresses
feat(api): add GET /users/:id/orders endpoint
```

### `fix` -- Bug Fix
A correction to existing behavior that was not working as intended.
```
fix(auth): prevent session fixation on login
fix(cart): calculate tax correctly for international orders
fix(api): return 404 instead of 500 for missing user
```

### `refactor` -- Code Restructuring
Internal code change that neither fixes a bug nor adds a feature. Behavior is unchanged.
```
refactor(auth): extract token validation into AuthService
refactor(cart): replace nested callbacks with async/await
refactor(api): consolidate duplicate error handling middleware
```

### `test` -- Tests Only
Adding, modifying, or fixing tests. No production code changes.
```
test(auth): add edge cases for expired token handling
test(cart): cover zero-quantity validation
test(api): add integration tests for order creation
```

### `docs` -- Documentation Only
Changes to documentation files. No code changes.
```
docs(api): add authentication section to README
docs(auth): document password policy requirements
docs: update CONTRIBUTING.md with branch naming rules
```

### `chore` -- Maintenance
Routine tasks that do not modify source code or tests.
```
chore(deps): update lodash to 4.17.21
chore: configure Dependabot for weekly updates
chore(ci): add Node 20 to test matrix
```

### `style` -- Formatting
Whitespace, formatting, missing semicolons. No logic changes.
```
style: apply Prettier formatting to src/
style(auth): fix inconsistent indentation in LoginForm
style: remove trailing whitespace from config files
```

### `perf` -- Performance
A code change that improves performance.
```
perf(api): add database index on orders.user_id
perf(cart): memoize tax calculation for unchanged items
perf(search): switch to batch query for user lookup
```

### `ci` -- CI/CD
Changes to CI configuration files and scripts.
```
ci: add GitHub Actions workflow for PR checks
ci: cache node_modules between CI runs
ci: add deployment step for staging environment
```

### `build` -- Build System
Changes that affect the build system or external dependencies.
```
build: migrate from Webpack to Vite
build: add TypeScript path aliases to tsconfig
build: configure tree-shaking for production bundle
```

## Breaking Changes

A breaking change is any change that requires consumers to modify their code.

Mark breaking changes with `!` after the type (before the colon):
```
feat!(api): remove deprecated /v1/users endpoint
fix!(auth): change session cookie name from 'sid' to 'session_id'
refactor!(cart): rename CartItem.qty to CartItem.quantity
```

Alternatively, include `BREAKING CHANGE:` in the footer:
```
feat(api): restructure user response payload

BREAKING CHANGE: The `user.name` field is now split into `user.firstName` and `user.lastName`. Clients consuming the user object must update their parsing logic.
```

## Scope Conventions

The scope identifies the module, component, or area affected.

**Rules:**
- Use the module or component name, not the file name: `auth`, not `AuthService.ts`
- Use lowercase: `auth`, not `Auth`
- Use kebab-case for multi-word scopes: `user-profile`, not `userProfile`
- Omit scope when the change is cross-cutting: `chore: update dependencies`
- Be consistent within a project: if previous commits use `api`, do not switch to `backend`

**Common scopes:**
- `auth` -- authentication and authorization
- `api` -- API routes and middleware
- `ui` -- user interface components
- `db` -- database models, migrations, queries
- `config` -- configuration and environment
- `deps` -- dependency updates
- `ci` -- continuous integration

## Good vs Bad Commit Messages

### Good Messages

```
feat(auth): add email verification on signup

New users must verify their email before accessing protected routes.
Sends a verification link via SendGrid with a 24-hour expiry.

See 02-plan.md Step 2
```
Why: imperative mood, clear scope, body explains WHY, references the plan.

```
fix(cart): prevent negative quantities in line items

Adds server-side validation to reject quantity < 1. Client-side
validation already existed but could be bypassed via API.

Closes #247
```
Why: describes the fix and the reason it was needed, references the issue.

```
refactor(api): extract error handling into middleware

Consolidates try/catch blocks from 12 route handlers into a single
error-handling middleware. Reduces duplication and ensures consistent
error response format.
```
Why: explains the motivation (duplication, consistency), not just the action.

```
test(auth): cover token expiry and refresh edge cases

Adds tests for: expired access token with valid refresh token,
expired refresh token, concurrent refresh requests, and clock skew
tolerance.
```
Why: lists the specific test cases added.

```
perf(search): add composite index on (user_id, created_at)

The orders list page was doing a full table scan for each user.
This index reduces query time from ~800ms to ~5ms for a user with
500 orders.
```
Why: includes measurable performance data.

### Bad Messages

```
update code
```
Why bad: no type, no scope, no description of what changed or why.

```
feat: stuff
```
Why bad: "stuff" communicates nothing. What feature? What does it do?

```
fix: fixed the bug
```
Why bad: past tense ("fixed" should be "fix"), and "the bug" is not specific.

```
wip
```
Why bad: work-in-progress commits should not exist in the final history. Squash or amend before pushing.

```
feat(auth): add login endpoint, add registration endpoint, add password reset, add email verification, refactor user model, update tests
```
Why bad: this is 6 changes in one commit. Each should be its own commit (or at most 2-3 logically grouped commits).

## Multi-Line Commit Body

Use a body when:
- The description alone does not explain WHY the change was made
- The change has non-obvious implications
- The change references external context (issue, spec, discussion)
- The change is a breaking change that needs migration instructions

**Format:**
```
<header>
                          <-- blank line
<body paragraph 1>
                          <-- blank line (between paragraphs)
<body paragraph 2>
                          <-- blank line
<footer>
```

**Body rules:**
- Explain WHY, not WHAT. The diff shows the what.
- Wrap lines at 72 characters for readability in terminals.
- Use bullet points for lists.
- Do not repeat the header in the body.

## Referencing Issues and Specs

**Close an issue on merge:**
```
Closes #123
Fixes #456
Resolves #789
```

**Reference without closing:**
```
See #123
Related to #456
Part of #789
```

**Reference the project spec:**
```
See 02-plan.md Step 3
Implements acceptance criteria from 02-plan.md Step 5
```

**Reference a Jira ticket:**
```
Closes PROJ-123
See PROJ-456
```

Place references in the footer (after the body, separated by a blank line) or inline in the body.

## Adapting to Project Style

Before writing any commit message, check the project's existing commit history:
```
git log --oneline -10
```

If the project does not use conventional commits, adapt to the project's existing convention. Consistency within a project matters more than adherence to an external standard.

If the project has no discernible convention, use conventional commits as the default. The first commit sets the pattern.
