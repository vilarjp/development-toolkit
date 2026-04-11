# development-toolkit

Spec-driven development scaffolding for Claude Code.

This repo is not an app or framework. It is a toolkit of:

- skills
- agent definitions
- artifact templates
- Claude hook configuration

Its job is to make agent-driven work more disciplined: clearer scope, explicit specs, tighter TDD, structured review, and fewer invented assumptions.

## What It Does

The toolkit organizes work into three paths:

- **Dev**: feature or architectural change
- **Resolve**: bug or regression investigation and fix
- **Trivial**: small isolated change

The heavier paths produce explicit artifacts under `docs/YYYY-MM-DD-topic/`:

1. `01-brainstorm.md` or `01-diagnosis.md`
2. `02-plan.md`
3. `03-revision.md`
4. `04-execution-log.md`
5. `05-code-review.md`
6. `06-solutions.md`

The aim is simple: make the agent show its work before, during, and after implementation.

## What A Raw Checkout Provides

A raw checkout of this repo currently ships:

- skills under [skills/](/Users/joao/dev/development-toolkit/skills)
- agent definitions under [agents/](/Users/joao/dev/development-toolkit/agents)
- templates under [templates/](/Users/joao/dev/development-toolkit/templates)
- hook configuration under [hooks/](/Users/joao/dev/development-toolkit/hooks)

It does **not** currently ship repo-local slash-command wrapper files for things like `/dev`, `/resolve`, or `/quick`.

In practice, that means:

- the toolkit can still work from a raw checkout
- the session-start meta-skill can still route work
- you can invoke the underlying skills directly
- you should not assume slash commands exist unless your Claude packaging layer adds them

## Installation

### Option 1: Shell Alias

```bash
git clone https://github.com/vilarjp/development-toolkit.git ~/development-toolkit
```

Add to your shell config:

```bash
alias claude='claude --plugin-dir ~/development-toolkit'
```

Reload your shell:

```bash
source ~/.zshrc
```

### Option 2: One-Off Loading

```bash
claude --plugin-dir /path/to/development-toolkit
```

## How To Use It

The normal entrypoint is the meta-skill in [skills/using-toolkit/SKILL.md](/Users/joao/dev/development-toolkit/skills/using-toolkit/SKILL.md). It classifies the task and routes to the right pipeline.

The main skills are:

- `using-toolkit`
- `context-loader`
- `brainstorm`
- `diagnosis`
- `plan`
- `revision`
- `execute`
- `code-review`
- `fix-loop`
- `commit-push`
- `pr-feedback`
- `solutions`

If your Claude environment exposes a separate command layer, it can map friendly commands onto these skills. This repo itself currently documents the skills as the source of truth.

## Pipeline Summary

### Dev

`Context -> Brainstorm -> Plan -> Revision -> Approval -> Execute -> Review -> Fix Loop -> Commit -> Solutions`

Use when the work changes behavior or architecture and needs explicit planning.

### Resolve

`Context -> Diagnosis -> Approval -> Execute minimal root-cause fix -> Review -> Fix Loop -> Commit -> Solutions`

Use when the work is a bug or regression. This path is diagnosis-driven, not plan-driven.

### Trivial

`TDD/Verification -> Lint -> Commit`

Use when the change is genuinely small and isolated.

## Review Model

The strongest part of the toolkit is the review path:

- reviewer agents return structured JSON
- findings are confidence-gated
- duplicate findings are merged
- only clearly behavior-preserving `safe_auto` fixes may apply automatically
- everything else goes through human triage and bounded re-review

Core contract: [findings-schema.json](/Users/joao/dev/development-toolkit/findings-schema.json)

Primary review orchestrator: [skills/code-review/SKILL.md](/Users/joao/dev/development-toolkit/skills/code-review/SKILL.md)

## Hooks

The hooks enforce the operational guardrails:

- [hooks/session-start.sh](/Users/joao/dev/development-toolkit/hooks/session-start.sh): injects the meta-skill and detects stalled approved specs
- [hooks/git-safety.sh](/Users/joao/dev/development-toolkit/hooks/git-safety.sh): blocks protected-branch git writes
- [hooks/stop-guard.sh](/Users/joao/dev/development-toolkit/hooks/stop-guard.sh): blocks stopping during active approved pipelines or with reviewed-but-uncommitted work

Hook config lives in [hooks/hooks.json](/Users/joao/dev/development-toolkit/hooks/hooks.json).

## Repo Layout

```text
development-toolkit/
  findings-schema.json
  hooks/
  skills/
  agents/
  templates/
```

If you are editing the toolkit itself, start with [AGENTS.md](/Users/joao/dev/development-toolkit/AGENTS.md).

## Current Scope

This repo is intentionally narrow.

It is trying to be:

- a disciplined spec-driven workflow toolkit
- a review and guardrail layer for Claude Code
- a source of reusable skills, agents, and templates

It is not currently trying to be:

- a cross-platform multi-agent distribution system
- a packaged slash-command product with built-in command wrappers
- a generic skill marketplace

## License

MIT
