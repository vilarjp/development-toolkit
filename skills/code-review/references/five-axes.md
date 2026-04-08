# The Five Review Axes

Every code change is evaluated across five axes. Each axis focuses on a different aspect of quality. A change can be excellent on one axis and poor on another -- all five matter.

## Axis 1: Correctness

Does the code do what it is supposed to do?

### What to look for

- **Logic errors:** Reversed conditionals, wrong operator (< vs <=), incorrect boolean logic, missing negation.
- **Edge cases:** Null, undefined, empty string, empty array, zero, negative numbers, NaN, Infinity, very large values, Unicode, special characters.
- **Off-by-one errors:** Loop bounds, array indexing, string slicing, pagination offsets.
- **Null handling:** Dereferencing potentially null values, missing null checks before property access, optional chaining where required chaining is needed.
- **State management bugs:** State updated in the wrong order, stale closures, race conditions between concurrent operations, missing state initialization.
- **Race conditions:** Two async operations that can interleave and produce incorrect results, shared mutable state without synchronization, read-modify-write without atomicity.
- **Error propagation:** Errors caught but not re-thrown or logged, error states not communicated to callers, async errors that vanish into the void.
- **Type safety:** Implicit type coercion that changes behavior, any/unknown used where a specific type is needed, type assertion (as X) hiding a real type mismatch.

### Common failures

- Function works for the primary input but crashes on empty input.
- Async function awaits one call but not another.
- Error in a nested callback is caught by the wrong handler.
- Integer arithmetic produces unexpected results due to floating point.
- String comparison fails for locale-specific characters.

### Severity mapping

- Logic error in happy path: **P0**
- Missing edge case that crashes: **P0**
- Missing edge case that produces wrong data: **P1**
- Missing edge case that degrades gracefully: **P2**
- Potential race condition under high load: **P1**
- Type safety weakness caught by compiler: **P3**

## Axis 2: Readability

Can another developer understand this code without asking the author?

### What to look for

- **Naming clarity:** Does every variable, function, class, and file name communicate its purpose? Can you understand the name without reading the implementation?
- **Function length:** Can each function be understood in one screen (roughly 30 lines of logic)? If not, can it be split without artificial fragmentation?
- **Nesting depth:** Are conditionals nested more than 3 levels deep? Can early returns, guard clauses, or extracted functions reduce nesting?
- **Comments on non-obvious logic:** Is there a comment explaining WHY for any logic that is not immediately obvious? Comments explaining WHAT the code does are usually a sign the code is not clear enough.
- **Consistent formatting:** Does the new code match the formatting of the surrounding code? Tabs vs spaces, brace placement, line length, blank line usage.
- **Dead code:** Is there commented-out code, unreachable branches, or unused imports? Dead code creates confusion about what is active.
- **Cognitive load:** How many concepts must a reader hold in their head simultaneously to understand a function? More than 3-4 is too many.

### Common failures

- Variable named `data` when it holds a specific domain object.
- Function named `handleClick` that also validates, transforms, and saves data.
- Deeply nested if/else/try/catch that could be flattened with guard clauses.
- Magic numbers or strings with no named constant or comment.
- Function that is 100+ lines with multiple responsibilities interleaved.

### Severity mapping

- Misleading name that causes incorrect usage: **P1**
- Function over 50 lines: **P2**
- Missing comment on complex business logic: **P2**
- Minor naming improvement: **P3**
- Commented-out code: **P2**
- Magic number without explanation: **P2**

## Axis 3: Architecture

Does the code fit the system's structure and the plan's design?

### What to look for

- **Plan alignment:** Does the implementation match the architecture described in `docs/spec/02-plan.md`? Are components, modules, and boundaries where the plan says they should be?
- **Separation of concerns:** Does each module, class, or function have a single responsibility? Is business logic separated from presentation, I/O, and framework code?
- **Dependency direction:** Do dependencies flow from outer layers (UI, API) inward (domain, core)? Does core logic depend on framework specifics?
- **Abstraction appropriateness:** Are abstractions at the right level? An abstraction used in one place is premature. An abstraction used in five places is justified. A missing abstraction duplicated across files is a gap.
- **Pattern compliance:** Does the new code follow the patterns established in the existing codebase? If it introduces a new pattern, is the deviation justified?
- **Coupling:** Are modules tightly coupled (change in one requires change in another) or properly decoupled (clear interfaces, dependency injection, events)?

### Common failures

- Business logic embedded in a UI component.
- API route handler that directly queries the database without a service layer (when the project uses service layers).
- New utility function placed in a random file instead of the project's utility directory.
- Circular dependency between two modules.
- Abstraction created for a single use case "just in case" it is needed later.

### Severity mapping

- Architecture contradicts the plan: **P1**
- Business logic in wrong layer: **P1**
- Circular dependency: **P1**
- New pattern without justification: **P2**
- Minor file placement deviation: **P2**
- Premature abstraction: **P3**

## Axis 4: Security

Is the code safe from exploitation?

### What to look for

- **Input validation:** Is every external input (user input, query parameters, request bodies, file uploads, environment variables from external sources) validated before use? Validation means checking type, format, range, and length.
- **Output encoding:** Is output escaped appropriately for its context? HTML output must be HTML-escaped. SQL must use parameterized queries. Shell commands must escape arguments. URLs must encode parameters.
- **Auth/authz:** Are authentication checks present on protected endpoints? Are authorization checks verifying the requesting user has permission for the specific resource? Are there IDOR (Insecure Direct Object Reference) vulnerabilities?
- **SQL/command injection:** Are database queries constructed with parameterized queries or an ORM? Is any user input interpolated into SQL strings, shell commands, or eval statements?
- **XSS (Cross-Site Scripting):** Is user-provided content rendered in HTML without escaping? Is `dangerouslySetInnerHTML`, `v-html`, or equivalent used with unsanitized input?
- **CSRF (Cross-Site Request Forgery):** Do state-changing endpoints verify CSRF tokens? Are cookies set with SameSite attributes?
- **Secrets in code:** Are any API keys, tokens, passwords, connection strings, or private keys hardcoded in source files? Are `.env` files committed?
- **CORS configuration:** Are CORS headers appropriately restrictive? Is `Access-Control-Allow-Origin: *` used in production?

### Common failures

- User input passed directly into a database query string.
- JWT verification that checks signature but not expiration.
- API endpoint that checks authentication but not authorization (any logged-in user can access any other user's data).
- Password stored in plaintext or hashed with MD5/SHA without salt.
- Error message that reveals internal system details (stack traces, database schema, file paths) to the client.

### Severity mapping

- Exploitable injection or XSS: **P0**
- Exposed secret in source code: **P0**
- Authentication bypass: **P0**
- Missing authorization check on sensitive endpoint: **P0**
- Missing input validation on non-critical field: **P1**
- Overly permissive CORS in non-production: **P1**
- Missing rate limiting on auth endpoint: **P1**
- HTTPS not enforced: **P1**
- Verbose error messages in production: **P2**
- Missing security headers (CSP, HSTS): **P2**

## Axis 5: Performance

Will the code perform acceptably under expected load?

### What to look for

- **N+1 queries:** Is a database query executed inside a loop where a single batch query would suffice? This is the single most common performance bug in web applications.
- **Unbounded operations:** Is there a query, loop, or data fetch with no limit? What happens when the dataset grows to 10x its current size? 100x?
- **Missing pagination:** Does an API endpoint return all records instead of a paginated subset? Does a UI component render all items instead of virtualizing?
- **Redundant computations:** Is the same expensive calculation performed multiple times when it could be computed once and reused? Are derived values recomputed on every render?
- **Unnecessary re-renders:** In React/Vue/Svelte, are components re-rendering when their props have not changed? Are objects or functions recreated on every render, breaking memoization?
- **Large bundle imports:** Is an entire library imported when only a single function is needed? Does `import _ from 'lodash'` appear when `import debounce from 'lodash/debounce'` would suffice?
- **Missing indexes:** Are database queries filtering or sorting on columns that lack indexes? This matters for tables expected to grow.
- **Synchronous blocking:** Is a long-running operation blocking the main thread or event loop? Are CPU-intensive tasks run synchronously in a request handler?
- **Memory leaks:** Are event listeners, subscriptions, timers, or connections cleaned up when components unmount or requests complete?

### Common failures

- Fetching all records to count them instead of using COUNT.
- Loading a 2MB library for a single utility function.
- Creating a new database connection per request instead of using a pool.
- Rendering 10,000 list items without virtualization.
- Running a regex with catastrophic backtracking potential on user input.
- Missing cleanup in useEffect (React) or onUnmounted (Vue).

### Severity mapping

- N+1 query in a hot path: **P1**
- Unbounded query with no limit: **P1**
- Missing pagination on an endpoint returning user data: **P1**
- Memory leak (uncleaned listener/subscription): **P1**
- Synchronous blocking in request handler: **P1**
- Redundant computation (fixable with memoization): **P2**
- Large bundle import: **P2**
- Missing database index (table currently small): **P2**
- Unnecessary re-render (no user-visible impact): **P3**
- Micro-optimization opportunity: **P3**
