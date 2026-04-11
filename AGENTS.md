# AGENTS.md — development-toolkit

Instructions for AI agents working in this repository.

## What This Is

A Claude Code plugin toolkit providing spec-driven development through three pipeline tiers: dev (features), resolve (bugs), and trivial (small fixes). It uses structured JSON findings, confidence-gated code review, and TDD enforcement.

## Repository Layout

```
findings-schema.json   Structured output contract for reviewer agents
skills/                Skill definitions (SKILL.md per skill)
  using-toolkit/         Meta-skill: tier classification + operating behaviors
  context-loader/        Phase 0: project scanning (hard gate on CLAUDE.md)
  brainstorm/            Phase 1: Socratic exploration + self-review
  diagnosis/             Phase 1R: structured bug investigation (Opus/high)
  plan/                  Phase 2: research sub-agents + architecture (Opus/high)
  revision/              Phase 3: cross-check + scope creep + plan update
  execute/               Phase 4: TDD + incremental commits + execution log (Sonnet/medium)
  tdd/                   Cross-cutting TDD + verification mode
  code-review/           Phase 5: structured findings + conditional reviewers (Sonnet/medium)
  fix-loop/              Phase 5.5: autofix routing + bounded re-review
  commit-push/           Phase 6: lint gate + PR description
  pr-feedback/           Post-pipeline: PR thread resolution (Sonnet/medium)
  solutions/             Phase 7: learnings capture
agents/                Agent definitions for reviewer, investigator, and adversarial subagents
hooks/                 Session, pre-tool, and stop hooks
templates/             Document templates for spec artifacts (01 through 06)
```

## Rules for Modifying Skills

- Each skill lives in `skills/<name>/SKILL.md`.
- Keep `SKILL.md` under 500 lines. Extract detailed content to `references/`.
- SKILL.md is the entry point — self-contained enough to understand purpose and flow.

## Rules for Modifying Templates

- Templates live in `templates/` and are used to create artifacts in `docs/YYYY-MM-DD-topic/`.
- Use `{{placeholder}}` syntax for dynamic content.
- YAML frontmatter must include `status: draft | approved | superseded | archived`.
- Never modify a template without updating the skill that uses it.

## Rules for Modifying Agents

- Agent definitions live in `agents/` as markdown with YAML frontmatter.
- Required frontmatter: `name`, `description`, `model` (sonnet/opus), `effort` (medium/high), `dispatch` (string), `blocking` (true/false).
- Common `dispatch` values include `always`, `conditional`, and phase-scoped values such as `always-during-revision` or `diagnosis-phase-only`.
- All reviewer agents must return JSON matching `findings-schema.json`.
- All reviewer agents must include confidence calibration guidelines. For non-review agents, confidence guidance is recommended but not mandatory.
- Iron rule: read actual code, do not trust self-reported claims.

## Artifact Numbering

```
01-brainstorm.md or 01-diagnosis.md
02-plan.md
03-revision.md
04-execution-log.md
05-code-review.md
06-solutions.md
```

Pipeline detection: check for `docs/YYYY-MM-DD-*/` directories. Stalled if `01-*` exists with `status: approved` but `05-code-review.md` is missing.

## Artifact Lifecycle

- `draft` — artifact exists but has not passed its owning approval gate
- `approved` — artifact passed its owning gate and is now the source of truth
- `superseded` — replaced by a newer artifact
- `archived` — intentionally retired

Ownership:
- `01-brainstorm.md` becomes `approved` when the user confirms the recommended direction
- `01-diagnosis.md` becomes `approved` when the user accepts the diagnosis and proceeds
- `02-plan.md` and `03-revision.md` become `approved` together when the user says `go`
- `04-execution-log.md` becomes `approved` when execute completes its final test gate and writes the log
- `05-code-review.md` becomes `approved` when the final review round is complete
- `06-solutions.md` becomes `approved` when written

## Rules for Modifying Hooks

- Configuration in `hooks/hooks.json`.
- Scripts must be executable bash.
- Git-safety protection is non-negotiable — do not weaken.
- Stop-guard must check both current (05) and legacy (04) review numbering.

## Findings Schema

Reviewers produce structured JSON per `findings-schema.json`. Every finding requires an `intent` field — a file/line-independent description meaningful even after refactoring. The code-review orchestrator adds: `id` (fingerprint), `reviewers[]`, `reviewer_agreement`, `original_confidence`. Confidence below 0.60 is suppressed (P0 exception at 0.50+).
