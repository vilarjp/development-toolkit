# Severity Classification Guide

Use this guide to classify code review findings consistently across all reviewers. When two severity levels seem applicable, choose the higher one. Err on the side of caution.

## P0 -- Critical (Blocks Commit)

A P0 finding means the code MUST NOT be committed in its current state. Merging this code would cause immediate harm.

### What qualifies as P0

**Security vulnerability**
- SQL injection, command injection, XSS, CSRF bypass
- Authentication bypass or broken authorization
- Exposed secrets: API keys, tokens, passwords, connection strings in source code
- Unvalidated user input used in security-critical operations
- Insecure deserialization of untrusted data

**Data loss or corruption risk**
- Database migration that drops a column without data preservation
- Write operation with no error handling that silently fails
- Race condition on shared mutable state that can corrupt data
- Missing transaction boundary on multi-step write operations

**Logic error causing incorrect behavior in the happy path**
- Off-by-one error that produces wrong results for normal inputs
- Reversed conditional that inverts the intended behavior
- Missing return statement that falls through to wrong code path
- Type coercion bug that silently produces wrong values

**Missing error handling that causes silent data loss**
- Catch block that swallows exceptions without logging or re-throwing
- Promise chain with no error handler that drops failures silently
- Write operation that does not check for success/failure

**Breaking change to public API without migration**
- Removing or renaming an endpoint that external consumers depend on
- Changing request/response shape without versioning
- Removing a field from a public type or schema

### P0 test: "If this code ships, will users or data be harmed within the first day?"

If yes, it is P0.

## P1 -- Important (Should Fix Before Commit)

A P1 finding means the code works for the happy path but has meaningful gaps that will cause problems soon.

### What qualifies as P1

**Missing edge case handling**
- No null/undefined check on a value that can be null
- No handling for empty arrays, empty strings, or zero values
- No boundary handling for numeric inputs (negative, overflow, NaN)
- No timeout on network requests or database operations

**Error handling that swallows errors without logging**
- Catch block that catches but does nothing meaningful
- Error response that returns a generic message with no logging
- Async operation that fails silently with no user feedback

**Suboptimal pattern that creates maintenance burden**
- Copy-pasted logic that should be extracted into a shared function
- Deeply nested conditionals that could be flattened
- God function that does too many things (over 50 lines of logic)
- Tight coupling between modules that should be independent

**Weak test assertions**
- `assertTrue(result)` instead of `assertEquals(expected, result)`
- Testing that a function runs without asserting its output
- Snapshot test used where specific assertions would be more reliable
- Test that passes for wrong reasons (assertion on wrong value)

**Missing test for a planned acceptance criterion**
- Acceptance criterion exists in `docs/spec/02-plan.md` but no test covers it
- Test file exists but does not test the specified behavior
- Edge case identified in the plan but not tested

### P1 test: "Will this cause a bug report or maintenance headache within the first month?"

If yes, it is P1.

## P2 -- Minor (Nice to Have)

A P2 finding means the code works and is maintainable but could be cleaner. These are not urgent but improve quality.

### What qualifies as P2

**Naming could be clearer**
- Variable name `data` when `userProfile` would be more descriptive
- Function name `process` when `validateAndSaveOrder` would be more specific
- Boolean variable without `is`/`has`/`should` prefix when conventions expect it
- Abbreviation that is not universally understood in the team

**Minor code duplication (under 5 lines)**
- Two functions with identical 3-line blocks that could share a helper
- Repeated string literals that could be a named constant
- Similar but not identical logic that could be parameterized

**Missing code comment for non-obvious logic**
- Regex pattern with no explanation of what it matches
- Business rule encoded in a conditional with no comment about why
- Workaround for a known bug with no reference to the issue

**Slightly more complex than necessary**
- Ternary expression that would be clearer as an if/else
- Unnecessary abstraction layer for something used in one place
- Over-generic type parameter when a concrete type would suffice

### P2 test: "Would a new team member ask 'why is it done this way?' without a clear answer?"

If yes, it is P2.

## P3 -- Suggestion (FYI)

A P3 finding is an observation, not a defect. The code is correct, readable, and maintainable. The reviewer is offering an alternative perspective.

### What qualifies as P3

**Alternative approach worth considering**
- "This works well with a for loop, but Array.reduce would express the intent more concisely"
- "This inline function is fine here, but if it grows, consider extracting it"

**Style preference not violating conventions**
- Preferring early returns vs. else blocks (when the project has no convention)
- Suggestion to reorder function parameters for readability
- Recommending a utility library function over a hand-rolled equivalent

**Future improvement opportunity**
- "If this pattern appears in more places, consider a generic version"
- "This is fine for now, but if traffic grows, consider caching this query"
- "The test coverage is adequate, but adding a property-based test would strengthen confidence"

### P3 test: "Would I mention this in a casual code review but not block the PR?"

If yes, it is P3.

## Severity Promotion Rules

When deduplicating findings from multiple reviewers:

1. If two reviewers flag the same issue at different severities, use the HIGHER severity.
2. If a P2 finding appears in three or more files, promote it to P1 (pattern indicates systemic issue).
3. If a P3 suggestion addresses a known project pain point from `CLAUDE.md` or `AGENTS.md`, promote to P2.
4. Never demote a finding during deduplication. Severity only moves up.
