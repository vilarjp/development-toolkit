# development-toolkit

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that enforces spec-driven development through structured pipelines.

Three tiers serve different work types. The **dev pipeline** runs exploration, planning, TDD implementation, and multi-axis code review with structured findings before it reaches a commit. The **resolve pipeline** runs structured diagnosis, prove-it TDD, and code review for bug fixes. The **trivial pipeline** goes straight to TDD and commit for small, isolated changes. Human approval gates ensure nothing ships without your sign-off.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated

## Installation

### Option 1: Shell alias (recommended)

```bash
git clone https://github.com/vilarjp/development-toolkit.git ~/development-toolkit
```

Add to your `~/.zshrc` (or `~/.bashrc`):

```bash
alias claude='claude --plugin-dir ~/development-toolkit'
```

Reload: `source ~/.zshrc`

### Option 2: One-off loading

```bash
claude --plugin-dir /path/to/development-toolkit
```

## Quick Start

```
/dev add user authentication with JWT tokens    # Full feature pipeline
/resolve fix the race condition in payment       # Bug fix pipeline
/quick fix the typo in the shipping label        # Trivial pipeline

# Individual phases
/brainstorm    /diagnose    /plan    /revise
/execute       /review      /commit  /pr-feedback
```

## Pipelines

### Dev Pipeline (`/dev`)

```
Context -> Brainstorm -> Plan -> Revision -> [APPROVAL] -> Execute -> [TESTS] -> Review -> Fix Loop -> Commit -> Solutions
```

| Phase | Artifact | What Happens |
|-------|----------|--------------|
| 0 | (in-memory) | Scans project structure, config, conventions |
| 1 | `01-brainstorm.md` | Socratic exploration + self-review + visual companion offer |
| 2 | `02-plan.md` | Research sub-agents + architecture + confidence check + mandatory test paths |
| 3 | `03-revision.md` | Cross-check + scope creep detection + adversarial review + plan update |
| | | **Human approval gate** |
| 4 | `04-execution-log.md` | Parallel subagents, TDD, incremental commits per wave |
| | | **Test gate** |
| 5 | `05-code-review.md` | Two-stage review (spec compliance gate, then code quality), structured JSON findings, confidence gating, dedup |
| 5.5 | (appended to 05) | Auto-fix safe_auto, human triage, bounded re-review (max 3 rounds) |
| 6 | git history | Conventional commits, lint gate, PR description |
| 7 | `06-solutions.md` | Problem summary, approach, key decisions, gotchas |

### Resolve Pipeline (`/resolve`)

| Phase | Artifact | What Happens |
|-------|----------|--------------|
| 0 | (in-memory) | Context scan |
| 1R | `01-diagnosis.md` | Opus/high investigator: root-cause tracing, hypothesis testing |
| | | **Human approval gate** |
| 4 | `04-execution-log.md` | Prove-it TDD: reproduction test first, then minimal fix |
| | | **Test gate** |
| 5 | `05-code-review.md` | Same review system as dev pipeline |
| 5.5 | (appended to 05) | Fix loop |
| 6 | git history | Commit and push |
| 7 | `06-solutions.md` | Learnings capture |

### Trivial Pipeline (`/quick`)

```
TDD/Verification -> Lint check -> Commit
```

No spec directory. No artifacts. Agent assesses, user confirms.

## Structured Code Review

The review system uses structured JSON findings with a full processing pipeline:

### Findings Schema

Every reviewer returns JSON with fields: `title`, `severity` (P0-P3), `file`, `line`, `impact`, `intent` (file/line-independent description), `autofix` (safe_auto/gated_auto/manual/advisory), `confidence` (0.0-1.0), `evidence[]`, `pre_existing`, `suggested_fix`, `needs_verification`.

### Confidence Gating

| Tier | Range | Action |
|------|-------|--------|
| Suppress | Below 0.60 | Dropped (except P0 at 0.50+) |
| Flag | 0.60-0.69 | Include only when clearly actionable |
| Confident | 0.70-0.84 | Real and important |
| Certain | 0.85-1.00 | Verifiable from code alone |

Cross-reviewer agreement boosts confidence by +0.10 per additional reviewer (cap 1.0).

### Fix Loop

After review: safe_auto fixes applied automatically, gated_auto/manual presented for human triage, approved fixes via TDD, bounded re-review (max 3 rounds).

## Agents

### Reviewer Agents (Phase 5)

| Agent | Dispatch | Blocking | Model |
|-------|----------|----------|-------|
| code-quality-reviewer | Always | Yes | Sonnet/medium |
| test-reviewer | Always | Yes | Sonnet/medium |
| plan-alignment-reviewer | Conditional: plan exists | Yes | Sonnet/medium |
| security-reviewer | Conditional: auth/input/API/payment/data | Yes | Sonnet/medium |
| convention-reviewer | Conditional: area has 3+ files | No | Sonnet/medium |

### Adversarial Agent (Phase 3)

| Agent | Dispatch | Model |
|-------|----------|-------|
| adversarial-reviewer | Always during revision | Sonnet/medium |

### Investigation Agent

| Agent | Dispatch | Model |
|-------|----------|-------|
| resolve-investigator | Diagnosis phase | Opus/high |

### Research Agents (Phase 2)

| Agent | Dispatch | Model |
|-------|----------|-------|
| Repo patterns | Always during planning | Opus/high |
| Solutions history | Always during planning | Opus/high |
| Ecosystem practices | Conditional: new lib/security area | Opus/high |

## Model Tiering

| Phase | Sub-agent Model | Effort |
|-------|----------------|--------|
| Diagnosis | Latest Opus | High |
| Plan (research + confidence) | Latest Opus | High |
| Execute (wave agents) | Latest Sonnet | Medium |
| Code Review (reviewers) | Latest Sonnet | Medium |
| Fix Loop (re-review) | Latest Sonnet | Medium |
| PR Feedback (fixers) | Latest Sonnet | Medium |

Orchestrator always runs on the user's configured model.

## Operating Behaviors

**Always-on:** Enforce Simplicity, Verify Don't Assume, Maintain Scope Discipline, Surface Assumptions, Manage Confusion Actively.

**Phase-injected:** Push Back When Warranted (brainstorm + planning), Seek Forgiveness Strategically (execution).

## Git Safety

- Never commits to master/main (enforced by PreToolUse hook)
- Conventional Commits format
- Lint gate before every commit
- Logical commit splitting
- Rebase before push

## Project Structure

```
development-toolkit/
  findings-schema.json              # Structured output contract for reviewers
  hooks/
    hooks.json                      # Hook configuration
    session-start.sh                # Meta-skill injection + stalled pipeline detection
    git-safety.sh                   # Blocks writes to master/main
    stop-guard.sh                   # Blocks stop during active pipelines
  skills/
    using-toolkit/SKILL.md          # Meta-skill: tier classification + operating behaviors
    context-loader/SKILL.md         # Phase 0: project scanning
    brainstorm/SKILL.md             # Phase 1: Socratic exploration + self-review + council debate
      references/council-debate.md  # Multi-perspective debate protocol for architectural decisions
    diagnosis/SKILL.md              # Phase 1R: structured bug investigation
    plan/SKILL.md                   # Phase 2: research + architecture + confidence check
    revision/SKILL.md               # Phase 3: cross-check + scope creep + plan update
    execute/SKILL.md                # Phase 4: TDD + incremental commits + execution log
    tdd/SKILL.md                    # Cross-cutting: RED-GREEN-REFACTOR + verification mode
    code-review/SKILL.md            # Phase 5: structured findings + conditional reviewers
    fix-loop/SKILL.md               # Phase 5.5: autofix routing + bounded re-review
    commit-push/SKILL.md            # Phase 6: lint gate + PR description
    pr-feedback/SKILL.md            # Post-pipeline: PR thread resolution
    solutions/SKILL.md              # Phase 7: learnings capture
  agents/
    code-quality-reviewer.md        # Always-on, blocking
    test-reviewer.md                # Always-on, blocking
    plan-alignment-reviewer.md      # Conditional, blocking
    security-reviewer.md            # Conditional, blocking
    convention-reviewer.md          # Conditional, non-blocking
    adversarial-reviewer.md         # Revision phase: stress-tests premises and assumptions
    resolve-investigator.md         # Diagnosis phase only
  templates/
    01-brainstorm.md
    01-diagnosis.md
    02-plan.md
    03-revision.md
    04-execution-log.md
    05-code-review.md
    06-solutions.md
```

## License

MIT
