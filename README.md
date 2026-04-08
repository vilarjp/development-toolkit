# joao-toolkit

A Claude Code plugin that enforces spec-driven development through a structured pipeline: brainstorm, plan, revise, execute, review, commit.

## Installation

Add a shell alias that loads the plugin on every session. In your `~/.zshrc` (or `~/.bashrc`):

```bash
alias claude='claude --plugin-dir ~/dev/joao-toolkit'
```

If you use a custom alias (e.g. `claudio`), it inherits automatically since the base `claude` command now includes the flag.

Reload your shell:

```bash
source ~/.zshrc
```

Validate the plugin:

```bash
claude plugin validate ~/dev/joao-toolkit
# Should show: ✔ Validation passed
```

Since `--plugin-dir` points to the source directory, any edits to the toolkit take effect immediately — no reinstall needed.

## Pipeline overview

### Feature mode

| Phase | Command | Artifact | Model | Thinking Budget |
|-------|---------|----------|-------|-----------------|
| 0 | `/context` | (in-memory) | claude-sonnet-4-6 | none |
| 1 | `/brainstorm` | `01-brainstorm.md` | claude-opus-4-6 | 10,000 tokens |
| 2 | `/plan` | `02-plan.md` | claude-opus-4-6 | 10,000 tokens |
| 3 | `/revise` | `03-revision.md` | claude-opus-4-6 | 10,000 tokens |
| | **HUMAN APPROVAL GATES** (complexity-based) | | | |
| 4 | `/execute` | source code + tests | claude-sonnet-4-6 | 5,000 tokens |
| | **TEST GATE** | | | |
| 5 | `/review` | `04-code-review.md` | claude-sonnet-4-6 | 5,000 tokens |
| | **HUMAN APPROVAL GATE** (if P0 issues from BLOCKING reviewers) | | | |
| 6 | `/commit` | git history | claude-sonnet-4-6 | 5,000 tokens |

### Resolve mode (bug fixes)

| Phase | Artifact | Model | Thinking Budget |
|-------|----------|-------|-----------------|
| 0 | (in-memory) | claude-sonnet-4-6 | none |
| 1R | `01-diagnosis.md` | claude-opus-4-6 | 10,000 tokens |
| | **HUMAN APPROVAL GATE** (diagnosis review) | | |
| 4R | source code + tests (prove-it TDD) | claude-sonnet-4-6 | 5,000 tokens |
| | **TEST GATE** | | |
| 5 | `04-code-review.md` | claude-sonnet-4-6 | 5,000 tokens |
| 6 | git history | claude-sonnet-4-6 | 5,000 tokens |

All artifacts are saved in a per-session folder: `docs/YYYY-MM-DD-short-description/`.

Run `/dev` to execute the full pipeline end-to-end. Bug-related requests automatically enter resolve mode.

## Available commands

| Command | Description |
|---------|-------------|
| `/dev <description>` | Full pipeline from brainstorm through commit |
| `/brainstorm <topic>` | Explore a problem before committing to a direction |
| `/plan [path]` | Create implementation plan from brainstorm |
| `/revise` | Cross-check brainstorm and plan for gaps |
| `/execute [path]` | Execute plan using TDD with parallel subagents |
| `/review` | Structured code review with five reviewer agents |
| `/commit [message]` | Safe git commit and push (never to main/master) |
| `/tdd <description>` | Enter TDD mode: RED, GREEN, REFACTOR |
| `/context` | Load and display current project context |

## How it works

Each phase produces a markdown artifact in `docs/spec/`. Each subsequent phase reads the previous artifacts, creating a durable chain of accountability:

1. **Context** scans the project structure, config files, conventions, and existing specs
2. **Brainstorm** explores options through Socratic questioning and selects a direction
3. **Plan** decomposes the direction into implementation steps with `[PARALLEL]`/`[SEQUENTIAL]` classification, acceptance criteria, and test strategies
4. **Revise** cross-references brainstorm against plan to catch gaps, validates the dependency graph, and checks feasibility against the project context
5. **Execute** dispatches parallel subagents per the plan's Execution Waves table, enforcing TDD (RED, GREEN, REFACTOR) for every change
6. **Review** launches five specialized reviewer agents in parallel to evaluate correctness, readability, architecture, security, and performance
7. **Commit** creates conventional commits on a feature branch with branch protection enforced by hooks

### Gates

- **Human Approval Gate #1** — after revision, before any code is written. All three spec documents must be reviewed and approved.
- **Test Gate** — after execution. All tests must pass before code review begins.
- **Human Approval Gate #2** — after code review, only if critical (P0) issues are found.

### Parallelization

Tasks in the plan are classified as `[PARALLEL]` or `[SEQUENTIAL]`:
- `[PARALLEL]` — no shared files, no data dependencies, dispatched as concurrent subagents
- `[SEQUENTIAL]` — depends on another task's output or touches shared files

The plan's Execution Waves table groups tasks into waves. Within each wave, parallel tasks run concurrently. After each wave, the full test suite runs.

### TDD enforcement

Every subagent follows the RED-GREEN-REFACTOR cycle:
1. Write a failing test (RED)
2. Write minimum code to pass (GREEN)
3. Refactor while green (REFACTOR)

No production code without a failing test first. No exceptions.

## Agents

### Reviewer agents (Phase 5)

| Agent | Focus | Dispatched | Blocking |
|-------|-------|------------|----------|
| plan-alignment-reviewer | Code matches the plan's acceptance criteria | Always | **BLOCKING** |
| code-quality-reviewer | Correctness, readability, architecture, security, performance | Always | **BLOCKING** |
| convention-reviewer | Project convention adherence | Always | Non-blocking |
| test-reviewer | Test quality, coverage, anti-patterns | Always | **BLOCKING** |
| security-reviewer | OWASP Top 10, auth, input validation, PCI/e-commerce | When diff touches auth/input/APIs/payments | **BLOCKING** |

### Investigation agents (Resolve mode)

| Agent | Focus | Dispatched | Blocking |
|-------|-------|------------|----------|
| resolve-investigator | Root-cause tracing, hypothesis generation, reproduction tests | Resolve mode Phase 1R | **BLOCKING** |

## Git safety

- **Never commits to master/main** — enforced by a `PreToolUse` hook that blocks git write operations on protected branches
- **Conventional Commits** — `feat(scope): description` format, adapted to the project's existing convention if different
- **Logical splitting** — related changes in one commit, unrelated changes split
- **Rebase before push** — always rebases from the default branch before pushing

## File structure

```
joao-toolkit/
  .claude-plugin/
    plugin.json                    # Plugin manifest
    marketplace.json               # Local marketplace registration
  hooks/
    hooks.json                     # Hook configuration
    session-start.sh               # Injects meta-skill + stalled pipeline detection
    git-safety.sh                  # Blocks writes to master/main
    continuity-enforcement.sh      # Prevents narration between pipeline phases
    stop-guard.sh                  # Blocks stop during active pipelines
  skills/
    using-toolkit/SKILL.md         # Meta-skill: discovery + operating behaviors
    dev-pipeline/SKILL.md          # Pipeline orchestrator (feature + resolve modes)
    context-loader/SKILL.md        # Phase 0: project context scanning
    brainstorm/SKILL.md            # Phase 1: problem exploration + diagnosis mode
    plan/SKILL.md                  # Phase 2: technical planning
    revision/SKILL.md              # Phase 3: cross-document review
    execute/SKILL.md               # Phase 4: TDD implementation + step-back protocol
    code-review/SKILL.md           # Phase 5: multi-axis review (BLOCKING/non-blocking)
    commit-push/SKILL.md           # Phase 6: safe git operations + QA scenarios
    tdd/SKILL.md                   # Cross-cutting TDD enforcement + step-back
  agents/
    plan-alignment-reviewer.md     # BLOCKING — code vs plan alignment
    code-quality-reviewer.md       # BLOCKING — five-axis quality review
    convention-reviewer.md         # Non-blocking — project convention adherence
    test-reviewer.md               # BLOCKING — test quality and coverage
    security-reviewer.md           # BLOCKING — OWASP + PCI/e-commerce
    resolve-investigator.md        # BLOCKING — structured bug diagnosis
  commands/                        # Slash commands (/dev, /brainstorm, etc.)
  templates/
    01-brainstorm.md               # Template for brainstorm artifacts
    01-diagnosis.md                # Template for diagnosis artifacts (resolve mode)
    02-plan.md                     # Template for plan artifacts
    03-revision.md                 # Template for revision artifacts
    04-code-review.md              # Template for code review artifacts
```

## License

MIT
