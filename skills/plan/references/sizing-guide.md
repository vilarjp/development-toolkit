# Task Sizing Guide

Use this reference when estimating the scope of implementation steps during the planning phase.

## Size Definitions

| Size | Files | Scope | Time Signal |
|------|-------|-------|-------------|
| XS | 1 | Single function or config change | Minutes |
| S | 1-2 | One component or endpoint | Short session |
| M | 3-5 | One feature slice (vertical) | One session |
| L | 5-8 | MUST be broken down | -- |
| XL | 8+ | MUST be broken down | -- |

## Rules

- Plan steps must be sized XS, S, or M.
- L and XL steps are not allowed in a plan. They must be decomposed into smaller steps.
- If you cannot size a step, it is too vague. Add specificity until you can size it.

## When to Break a Step Down Further

A step needs further decomposition when ANY of the following are true:

### The "and" test

The step title contains "and" -- this means it is doing two things. Split it.
- Bad: "Create user model and add validation"
- Good: Step A: "Create user model" (XS), Step B: "Add user validation rules" (XS)

### The acceptance criteria test

You cannot describe acceptance criteria in 3 bullets or fewer. If the step needs 5 acceptance criteria, it is doing too much.
- Bad: "Build the dashboard page" (needs 8 criteria for layout, data fetching, filtering, sorting, pagination, error states, loading states, empty states)
- Good: Step A: "Build dashboard layout with loading skeleton" (S), Step B: "Add data fetching with error handling" (S), Step C: "Add filtering and sorting" (M), Step D: "Add pagination" (S)

### The subsystem test

The step touches two independent subsystems. Each subsystem should be its own step.
- Bad: "Update the API and the notification service" (two systems, likely independent)
- Good: Step A: "Update API response format" (S), Step B: "Update notification service templates" (S)

### The session test

The step would take more than one focused session to complete. If you cannot finish it in one sitting, it is too large.

## Sizing Examples by Stack

### XS -- Single function or config change (1 file, minutes)

| Stack | Example |
|-------|---------|
| React/TS | Add a `formatCurrency(amount: number, locale: string): string` utility function |
| Node API | Add a new validation schema for an existing endpoint's query params |
| Python | Add a dataclass for a configuration object |
| Ruby/Rails | Add a scope to an existing model |
| Go | Add a helper function to an existing package |

### S -- One component or endpoint (1-2 files, short session)

| Stack | Example |
|-------|---------|
| React/TS | Create a `<Badge>` component with variants (success, warning, error) + its test file |
| Node API | Add a new GET endpoint with request validation, handler, and response serialization |
| Python | Create a new service class with 2-3 methods + its test file |
| Ruby/Rails | Add a new controller action with its view + controller test |
| Go | Add a new handler function with its test |

### M -- One feature slice (3-5 files, one session)

| Stack | Example |
|-------|---------|
| React/TS | Add a user profile form: component + hook + API call + validation + tests |
| Node API | Add user registration: route + controller + service + validation + tests |
| Python | Add a CLI command: parser + handler + output formatter + tests |
| Ruby/Rails | Add a CRUD resource: model + controller + views + routes + tests |
| Go | Add a new gRPC service method: proto + handler + repository + tests |

### L -- MUST be broken down (5-8 files)

| L Task | Decomposition |
|--------|--------------|
| "Add authentication system" | M1: User model + migration. M2: Login endpoint + JWT. M3: Auth middleware. S4: Logout endpoint. S5: Token refresh. |
| "Build dashboard page" | M1: Dashboard layout + routing. M2: Stats widget + API. M3: Activity feed + API. S4: Empty states. |
| "Add payment processing" | M1: Payment model + Stripe integration. M2: Checkout flow UI. M3: Webhook handler. S4: Receipt email. S5: Error handling. |

### XL -- MUST be broken down (8+ files)

| XL Task | Decomposition Strategy |
|---------|----------------------|
| "Add multi-tenant support" | Break by boundary: tenant model, tenant middleware, tenant-scoped queries, tenant admin UI, tenant switching |
| "Migrate from REST to GraphQL" | Break by resource: schema setup, user queries, user mutations, post queries, post mutations |
| "Add real-time collaboration" | Break by interaction: WebSocket setup, presence, cursor sharing, text sync, conflict resolution |

## Common Sizing Mistakes

### 1. Underestimating Integration Work

Sizing a step based on the code you write, not the code you touch. Adding a new API endpoint might seem like an S (one route file). But if it requires updating the router configuration, adding middleware, updating API documentation, and updating a client SDK, it is an M. Count ALL files you will touch, not just the ones you create.

### 2. Forgetting Test Setup

Not counting test infrastructure as part of the step. If your step requires setting up a test database, creating fixtures, configuring a test runner, or adding mock servers, the setup is part of the step's scope.

### 3. Overlooking Configuration Changes

Changes to `package.json`, `tsconfig.json`, `.env.example`, migration files, CI/CD config, Docker files, or route configuration files are never free. Each config change adds risk. Factor it into the size.

### 4. Treating "and" as One Step

"Create the form and add validation and submit to API" is three steps: create the form (S), add validation (S), add API submission (S). If the title contains "and," split it. Each piece should be independently testable.

### 5. Horizontal Layers Disguised as Vertical Slices

"Create all the database models" looks like one step, but it is a horizontal layer that touches every feature. Break it into vertical slices: "Create user model + user API + user tests," "Create post model + post API + post tests."

## The 5-File Rule

If a step touches more than 5 files, it is almost certainly too big:
1. List every file the step creates or modifies
2. If the count exceeds 5, identify which files are logically independent
3. Split along the independence boundary
