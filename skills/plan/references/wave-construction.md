# Wave Construction Reference

How to organize implementation steps into execution waves for sequential and parallel dispatch.

## The Formal Rule

A step is **[PARALLEL]** if and only if:
1. It has no write-dependency on any in-flight step -- it does not need to read files that another step is currently writing
2. It does not depend on the output of any incomplete step -- no data flow dependency
3. It shares no mutable state with any concurrent step

Everything else is **[SEQUENTIAL]**.

When in doubt, mark it SEQUENTIAL. False parallelism causes merge conflicts, race conditions, and debugging nightmares. False sequentiality only costs time.

## Wave Construction Algorithm

### Step 1: Build the Dependency Graph

For each implementation step, list its dependencies (which prior steps must complete before it can start). This produces a directed acyclic graph (DAG).

```
Step 1: [] (no dependencies)
Step 2: [Step 1]
Step 3: [Step 1]
Step 4: [Step 2, Step 3]
```

If the graph has a cycle (step A depends on B, B depends on A), the plan is broken. Fix it before proceeding.

### Step 2: Assign Waves

- **Wave 1** = all steps with no dependencies (no incoming edges in the DAG)
- **Wave N** = all steps whose dependencies are entirely in waves 1 through N-1

A step cannot be in wave N if any of its dependencies are also in wave N. Dependencies must be in strictly earlier waves.

### Step 3: Classify Within Waves

Within each wave, check for file conflicts:
- If two steps in the same wave touch NO shared files, they are [PARALLEL]
- If two steps in the same wave touch ANY shared file, one must be marked [SEQUENTIAL] or moved to a later wave

### Step 4: Validate

Before finalizing:
- [ ] No two [PARALLEL] steps in the same wave touch the same file
- [ ] All dependencies point to earlier waves (never same wave or later)
- [ ] The wave assignments match the dependency graph
- [ ] SEQUENTIAL steps within a wave have a defined execution order

## Conflict Detection

Before dispatching parallel subagents, verify file sets do not overlap:

```
Step 2 files: [src/api/users.ts, src/types/user.ts]
Step 3 files: [src/api/orders.ts, src/types/order.ts]
Overlap: NONE -> safe to parallelize

Step 2 files: [src/api/users.ts, src/types/index.ts]
Step 3 files: [src/api/orders.ts, src/types/index.ts]
Overlap: src/types/index.ts -> NOT safe to parallelize
```

When overlap is detected, three options:
1. **Move one step to a later wave** -- simplest, always works
2. **Mark both as SEQUENTIAL within the same wave** -- define execution order explicitly
3. **Refactor the steps so they do not share files** -- e.g., each step writes to its own type file, and a later step combines them into index.ts (preferred when it does not add unnecessary complexity)

### Files That Are Almost Always Shared

Watch for these common conflict sources:

| File Type | Examples | Risk |
|-----------|----------|------|
| Route/router config | `routes.ts`, `urls.py`, `config/routes.rb` | Steps adding routes to the same router MUST be SEQUENTIAL |
| Dependency manifests | `package.json`, `Gemfile`, `requirements.txt` | Steps adding dependencies MUST be SEQUENTIAL |
| Type/interface barrels | `types/index.ts`, `models/__init__.py` | Steps exporting new types from same barrel MUST be SEQUENTIAL |
| Database schema | `schema.prisma`, `schema.rb` | Steps modifying schema MUST be SEQUENTIAL |
| Environment config | `.env.example`, `config/default.ts` | Steps adding env vars MUST be SEQUENTIAL |
| Test setup/fixtures | `conftest.py`, `testSetup.ts` | Steps modifying shared test setup MUST be SEQUENTIAL |

## Example: 4-Step Plan

Consider a feature that adds a user profile page:

**Steps:**
1. Create user profile API endpoint (`src/api/profile.ts`, `src/types/profile.ts`)
2. Create profile UI component (`src/components/ProfilePage.tsx`, `src/components/ProfileForm.tsx`)
3. Add profile route (`src/app/routes.ts`) -- depends on Steps 1 and 2
4. Add integration test (`test/integration/profile.test.ts`) -- depends on Steps 1, 2, and 3

**Dependencies:**
- Step 1: no dependencies
- Step 2: no dependencies (can use mocked data during development)
- Step 3: depends on Step 1 (needs the API) and Step 2 (needs the component)
- Step 4: depends on Steps 1, 2, and 3 (needs everything wired up)

**File conflict check:**
- Steps 1 and 2: no shared files -- safe to parallelize
- Step 3: touches `routes.ts` which neither Step 1 nor 2 touches -- no conflict with wave 1

**Wave Assignment:**

| Wave | Steps | Mode | Rationale |
|------|-------|------|-----------|
| 1 | Step 1, Step 2 | PARALLEL | No dependencies, no shared files. API and UI can be built independently. |
| 2 | Step 3 | SEQUENTIAL | Depends on both Steps 1 and 2. Wires the route to the API and component. |
| 3 | Step 4 | SEQUENTIAL | Depends on Steps 1, 2, and 3. Tests the fully assembled feature. |

**Execution flow:**
```
Wave 1: [Step 1] ----+
        [Step 2] ----+---> Wave 2: [Step 3] ---> Wave 3: [Step 4]
```

## Common Mistakes

### False Parallelism

Two steps that both modify a shared barrel file (`index.ts`), config file, or type definition file. They look independent but will produce merge conflicts.

**Fix:** Check file lists. If there is any overlap, they are not parallel.

### Over-Sequentialization

Steps that read from but do not write to the same file are marked SEQUENTIAL. Reading is safe to parallelize -- only concurrent writes cause conflicts.

**Fix:** Distinguish read-dependencies from write-dependencies. Two steps can both READ `src/config.ts` in parallel. They cannot both WRITE to it.

### Missing Dependency

A step uses a type or function defined in another step but does not declare the dependency. The parallel execution fails because the type does not exist yet.

**Fix:** For each step, ask: "What files must exist and have specific content before this step can run?" Each such file traces back to a dependency.

### Circular Dependencies

Step A depends on Step B, Step B depends on Step A. This makes the plan unexecutable.

**Fix:** Find the true direction of dependency. Usually one step can be restructured to use an interface or mock instead of the concrete implementation, breaking the cycle.
