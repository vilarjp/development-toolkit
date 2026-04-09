# AGENTS.md — development-toolkit

Instructions for AI agents working in this repository.

## What this is

This is a Claude Code plugin toolkit that provides a structured development pipeline: brainstorm, plan, revise, execute (TDD), review, and commit. It is designed to be installed into any project and invoked via slash commands.

## Repository layout

```
skills/            Skill definitions (SKILL.md + references/)
  dev-pipeline/      Feature pipeline orchestrator
  resolve-pipeline/  Resolve pipeline orchestrator (bug fixes)
  diagnosis/         Phase 1R: structured bug investigation
  brainstorm/        Phase 1: problem exploration
  plan/              Phase 2: technical planning
  revision/          Phase 3: cross-document review
  execute/           Phase 4: TDD implementation
  code-review/       Phase 5: multi-axis review
  commit-push/       Phase 6: safe git operations
  tdd/               Cross-cutting TDD enforcement
  context-loader/    Phase 0: project scanning
  using-toolkit/     Meta-skill: discovery + operating behaviors
agents/            Agent personas for parallel reviewer subagents
commands/          Slash command definitions (thin markdown files)
hooks/             Session and pre-tool hooks
templates/         Document templates for spec artifacts
```

## Rules for modifying skills

- Each skill lives in `skills/<name>/SKILL.md` with optional `references/` subdirectory.
- Keep `SKILL.md` under 500 lines. If a skill grows beyond that, extract late-sequence content (examples, reference tables, detailed instructions for sub-steps) into `references/` files.
- Reference files are loaded by the skill only when needed — they are not injected into context automatically.
- The `SKILL.md` is the entry point. It must be self-contained enough to understand the skill's purpose and flow without reading references.

## Rules for modifying templates

- Templates live in `templates/` and are used by skills to create spec artifacts in per-session directories under `docs/` (format: `docs/YYYY-MM-DD-short-description/`).
- Never modify a template without updating the corresponding skill that uses it.
- Templates use `{{placeholder}}` syntax for dynamic content.
- YAML frontmatter in templates defines metadata fields that skills must populate.

## Rules for modifying agents

- Agent personas live in `agents/` as markdown files with YAML frontmatter.
- Each agent must specify `name`, `description`, and `model: inherit`.
- Agent instructions define the reviewer's scope, methodology, and output format.
- All agents must include the iron rule: read actual code, do not trust self-reported claims.

## Rules for modifying commands

- Commands live in `commands/` as thin markdown files.
- Each command describes what it does and its usage pattern.
- Commands map to skill invocations — they do not contain logic themselves.

## Spec directory convention

Pipeline artifacts are stored in per-session directories under `docs/`:

```
docs/YYYY-MM-DD-short-description/
```

- Use today's date and a kebab-case short description derived from the topic (e.g., `docs/2026-04-08-user-auth-flow/`)
- Artifacts within: `01-brainstorm.md` or `01-diagnosis.md`, `02-plan.md`, `03-revision.md`, `04-code-review.md`
- To detect an active pipeline, search for `docs/YYYY-MM-DD-*/` directories and check which artifacts exist within.

## Rules for modifying hooks

- Hook configuration is in `hooks/hooks.json`.
- Hook scripts are in `hooks/` and must be executable bash scripts.
- The git-safety hook blocks writes to master/main. Do not weaken this protection.

## Testing changes

Test any skill changes by running the skill in a sample project:

1. Install the plugin in a test project
2. Run the relevant slash command
3. Verify the skill produces correct output
4. Verify hooks fire correctly
