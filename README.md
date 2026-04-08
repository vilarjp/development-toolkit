# development-toolkit

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that enforces spec-driven development through structured pipelines.

Two pipelines serve different work types. The **feature pipeline** runs exploration, planning, TDD implementation, and multi-axis code review before it reaches a commit. The **resolve pipeline** runs structured diagnosis, prove-it TDD, and code review for bug fixes. Human approval gates ensure nothing ships without your sign-off.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated

## Installation

### Option 1: Shell alias (recommended)

Clone the repo and add a shell alias so the plugin loads on every Claude Code session:

```bash
git clone https://github.com/vilarjp/development-toolkit.git ~/development-toolkit
```

Add to your `~/.zshrc` (or `~/.bashrc`):

```bash
alias claude='claude --plugin-dir ~/development-toolkit'
```

Reload your shell:

```bash
source ~/.zshrc
```

### Option 2: One-off loading

Load the plugin for a single session without installing:

```bash
claude --plugin-dir /path/to/development-toolkit
```

### Verify installation

Start a Claude Code session and run:

```
/context
```

You should see a project context scan output. If the toolkit loaded correctly, the `/dev`, `/resolve`, `/brainstorm`, `/diagnose`, `/plan`, `/revise`, `/execute`, `/review`, and `/commit` slash commands will be available.

## Quick start

```
# Start a full feature pipeline
/dev add user authentication with JWT tokens

# Just brainstorm an idea
/brainstorm how should we structure the caching layer

# Fix a bug (resolve pipeline)
/resolve fix the race condition in the payment handler

# Just diagnose a bug (without full pipeline)
/diagnose why are checkout totals rounding incorrectly

# Run individual phases
/context          # scan project structure
/brainstorm       # explore options
/diagnose         # investigate a bug
/plan             # create implementation plan
/revise           # cross-check for gaps
/execute          # implement with TDD
/review           # multi-axis code review
/commit           # safe commit and push
```

## How it works

The toolkit runs a structured pipeline where each phase produces a markdown artifact. Each subsequent phase reads the previous artifacts, creating a durable chain of accountability.

### Feature pipeline (`/dev`)

```
Context -> Brainstorm -> Plan -> Revise -> [APPROVAL] -> Execute -> [TESTS] -> Review -> [APPROVAL] -> Commit
```

| Phase | Command | Artifact | What happens |
|-------|---------|----------|--------------|
| 0 | `/context` | (in-memory) | Scans project structure, config, conventions |
| 1 | `/brainstorm` | `01-brainstorm.md` | Explores options via Socratic questioning, selects a direction |
| 2 | `/plan` | `02-plan.md` | Decomposes into implementation steps with parallel/sequential classification |
| 3 | `/revise` | `03-revision.md` | Cross-references brainstorm against plan to catch gaps |
| | | | **Human approval gate** |
| 4 | `/execute` | source code + tests | Dispatches parallel subagents, enforces TDD (RED-GREEN-REFACTOR) |
| | | | **Test gate** (all tests must pass) |
| 5 | `/review` | `04-code-review.md` | Five specialized reviewer agents evaluate the diff |
| | | | **Human approval gate** (only if critical issues found) |
| 6 | `/commit` | git history | Conventional commits on a feature branch |

All artifacts are saved in a per-session folder: `docs/YYYY-MM-DD-short-description/`.

### Resolve pipeline (`/resolve`)

Bug-related requests use a dedicated resolve pipeline optimized for diagnosis and targeted fixes:

| Phase | Command | Artifact | What happens |
|-------|---------|----------|--------------|
| 0 | `/context` | (in-memory) | Context scan |
| 1R | `/diagnose` | `01-diagnosis.md` | Structured bug investigation with root-cause tracing |
| | | | **Human approval gate** (diagnosis review) |
| 4R | `/execute` | source code + tests | Prove-it TDD: reproduction test first, then minimal fix |
| | | | **Test gate** |
| 5 | `/review` | `04-code-review.md` | Same review process as feature pipeline |
| 6 | `/commit` | git history | Commit and push |

Trivial bugs get an escape hatch: if the diagnosis classifies the fix as trivial, you can skip execution and review phases entirely.

## Gates

The pipeline has built-in checkpoints that require your explicit approval:

- **Human Approval Gate #1** -- after revision, before any code is written. The number and placement of gates adapts to the complexity classification from the brainstorm phase.
- **Test Gate** -- after execution. All tests must pass before code review begins.
- **Human Approval Gate #2** -- after code review, only if critical (P0) issues are found.

No gate is bypassed automatically. Silence is not approval.

## Agents

### Reviewer agents (Phase 5)

| Agent | Focus | Blocking |
|-------|-------|----------|
| plan-alignment-reviewer | Code matches the plan's acceptance criteria | Yes |
| code-quality-reviewer | Correctness, readability, architecture, security, performance | Yes |
| convention-reviewer | Project convention adherence | No |
| test-reviewer | Test quality, coverage, anti-patterns | Yes |
| security-reviewer | OWASP Top 10, auth, input validation, PCI/e-commerce | Yes (conditional) |

The security reviewer is dispatched only when the diff touches auth, user input, APIs, data storage, or payment code.

### Investigation agent (Resolve pipeline)

| Agent | Focus | Blocking |
|-------|-------|----------|
| resolve-investigator | Root-cause tracing, hypothesis generation, reproduction tests | Yes |

## TDD enforcement

Every subagent follows the RED-GREEN-REFACTOR cycle:

1. **RED** -- write a failing test
2. **GREEN** -- write minimum code to pass
3. **REFACTOR** -- clean up while green

No production code without a failing test first. No exceptions.

## Parallelization

Tasks in the plan are classified as `[PARALLEL]` or `[SEQUENTIAL]`:

- **PARALLEL** -- no shared files, no data dependencies; dispatched as concurrent subagents
- **SEQUENTIAL** -- depends on another task's output or touches shared files

The plan's Execution Waves table groups tasks into waves. Within each wave, parallel tasks run concurrently. After each wave, the full test suite runs.

## Git safety

- **Never commits to master/main** -- enforced by a `PreToolUse` hook that blocks git write operations on protected branches
- **Conventional Commits** -- `feat(scope): description` format, adapted to the project's existing convention if different
- **Logical splitting** -- related changes in one commit, unrelated changes split
- **Rebase before push** -- always rebases from the default branch before pushing

## Project structure

```
development-toolkit/
  hooks/
    hooks.json                     # Hook configuration
    session-start.sh               # Meta-skill injection + stalled pipeline detection
    git-safety.sh                  # Blocks writes to master/main
    stop-guard.sh                  # Blocks stop during active pipelines
  skills/
    using-toolkit/SKILL.md         # Meta-skill: discovery + operating behaviors
    dev-pipeline/SKILL.md          # Feature pipeline orchestrator
    resolve-pipeline/SKILL.md      # Resolve pipeline orchestrator (bug fixes)
    context-loader/SKILL.md        # Phase 0: project context scanning
    brainstorm/SKILL.md            # Phase 1: problem exploration
    diagnosis/SKILL.md             # Phase 1R: structured bug investigation
    plan/SKILL.md                  # Phase 2: technical planning
    revision/SKILL.md              # Phase 3: cross-document review
    execute/SKILL.md               # Phase 4: TDD implementation + step-back protocol
    code-review/SKILL.md           # Phase 5: multi-axis review (BLOCKING/non-blocking)
    commit-push/SKILL.md           # Phase 6: safe git operations
    tdd/SKILL.md                   # Cross-cutting TDD enforcement
  agents/
    plan-alignment-reviewer.md     # BLOCKING -- code vs plan alignment
    code-quality-reviewer.md       # BLOCKING -- five-axis quality review
    convention-reviewer.md         # Non-blocking -- project convention adherence
    test-reviewer.md               # BLOCKING -- test quality and coverage
    security-reviewer.md           # BLOCKING -- OWASP + PCI/e-commerce
    resolve-investigator.md        # BLOCKING -- structured bug diagnosis
  commands/                        # Slash commands (/dev, /resolve, /brainstorm, etc.)
  templates/                       # Document templates for spec artifacts
```

## License

MIT
