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
agents/                Agent definitions for reviewer and investigator subagents
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
- Required frontmatter: `name`, `description`, `model` (sonnet/opus), `effort` (medium/high), `dispatch` (always/conditional), `blocking` (true/false).
- All reviewer agents must return JSON matching `findings-schema.json`.
- All agents must include confidence calibration guidelines.
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

## Rules for Modifying Hooks

- Configuration in `hooks/hooks.json`.
- Scripts must be executable bash.
- Git-safety protection is non-negotiable — do not weaken.
- Stop-guard must check both v2.1.0 (05) and legacy (04) numbering.

## Findings Schema

Reviewers produce structured JSON per `findings-schema.json`. The code-review orchestrator adds: `id` (fingerprint), `reviewers[]`, `reviewer_agreement`, `original_confidence`. Confidence below 0.60 is suppressed (P0 exception at 0.50+).
