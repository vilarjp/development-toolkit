---
name: context-loader
description: Use before any pipeline phase to load project context.
---

# Context Loader (Phase 0)

This is Phase 0 — the pre-flight scan that runs before any thinking begins. Every subsequent phase depends on accurate project context. This phase is fast and cheap. Do not skip it.

## When to Run

- Start of any new session
- Before any pipeline phase if context has not been loaded yet
- When switching to a different project or repository
- When another skill says "run context-loader first"

## Process

Execute these steps in order. Do not skip steps. Do not summarize without reading.

### Step 1: Read Project Instructions [HARD GATE]

Check for and read these files if they exist:
- `CLAUDE.md` — project-specific instructions for AI agents
- `AGENTS.md` — multi-agent coordination rules
- `.claude/CLAUDE.md` — user-level overrides

**HARD GATE:** If any of these files exist, you MUST read them fully before proceeding. If you proceed without reading an existing CLAUDE.md or AGENTS.md, the entire pipeline is invalid. There is no exception to this rule.

If none exist, note this explicitly: "No project instruction files found. Proceeding with defaults."

Read each file fully. Do not skim. Extract:
- Explicit prohibitions ("NEVER do X", "do NOT do Y")
- Required patterns ("always use X", "must follow Y")
- Workflow rules ("before committing, run X")

You MUST NOT invent rules that are not explicitly stated in these files.

### Step 2: Map Project Structure

List the project structure 2-3 levels deep using Glob or `ls`. ALWAYS capture:
- Top-level directories and their purposes
- Source code location (src/, lib/, app/, etc.)
- Test location (test/, __tests__/, *.test.*, *.spec.*)
- Configuration files at root level
- Documentation directories (docs/, doc/)

Do NOT recurse into `node_modules/`, `.git/`, `vendor/`, `dist/`, `build/`, or other generated directories.

### Step 3: Detect Tech Stack

Scan the project root for configuration files to identify the tech stack:

**Node.js / TypeScript:**
- `package.json` — dependencies, scripts, module type
- `tsconfig.json` — TypeScript configuration, paths
- `.eslintrc*` or `eslint.config.*` — linting rules
- `vite.config.*` — build tool
- `vitest.config.*` or `jest.config.*` — test runner

**Python:**
- `pyproject.toml` — dependencies, build system
- `requirements.txt` — dependencies
- `mypy.ini` — type checking

**General (any stack):**
- `.editorconfig` — editor formatting rules
- `.prettierrc*` — code formatting
- `docker-compose.yml` or `Dockerfile` — containerization
- `Makefile` — build commands
- `.github/workflows/` — CI/CD configuration

If a config file does not exist, skip it silently.

### Step 4: Read Configuration Files

For each detected config file, read it and extract:
- **Dependencies and versions** — what libraries are in use
- **Build commands** — how to build, test, lint, and run the project
- **Module system** — ESM vs CJS, import style, path aliases
- **Test runner** — what framework, what command to run tests
- **Lint/format rules** — what style is enforced

YOU MUST READ `scripts` in `package.json`, `[tool.*]` sections in `pyproject.toml`, and `Makefile` targets.

### Step 5: Scan Architectural Conventions

Examine 3-5 representative source files and 2-3 test files to detect:
- File naming conventions (kebab-case, camelCase, PascalCase)
- Test placement (co-located vs separate)
- Import patterns (barrel files, path aliases, relative vs absolute)
- Component/module naming patterns

You MUST only report conventions you can observe in actual code. Do NOT infer conventions from dependencies alone.

### Step 6: Check for Existing Specs

Look for pipeline artifacts in `docs/` matching the pattern `docs/YYYY-MM-DD-*/`.

In each directory, check for:
- `01-brainstorm.md` or `01-diagnosis.md`
- `02-plan.md`
- `03-revision.md`
- `04-execution-log.md`
- `05-code-review.md`
- `06-solutions.md`

If specs exist, read their YAML frontmatter to check the `status` field (`draft`, `approved`, `superseded`, `archived`). Note which phases have been completed and which are pending.

**Stalled pipeline detection:** If a spec directory has `01-brainstorm.md` or `01-diagnosis.md` with `status: approved` but no `05-code-review.md`, this is a stalled pipeline. Draft specs are not stalled — they are in progress.

If no spec artifacts are found, report "No active specs found."

### Step 7: Compile Project Context Block

Assemble all findings into a structured context block. This block stays in conversation context — it is NOT written to a file.

## Output Format

Produce exactly this structure:

```
## Project Context

### Stack
- **Language:** [e.g., TypeScript 5.x]
- **Framework:** [e.g., React 18 + Vite 6]
- **Package Manager:** [e.g., yarn]
- **Test Runner:** [e.g., Vitest]
- **Linter:** [e.g., ESLint]
- **Formatter:** [e.g., Prettier]

### Key Commands
- **Build:** [command]
- **Test:** [command]
- **Lint:** [command]
- **Format:** [command]

### Conventions
- **Module System:** [ESM/CJS]
- **File Naming:** [pattern]
- **Test Placement:** [co-located/separate/top-level]
- **Import Style:** [path aliases/relative/barrel files]

### Architecture
- **Directory Structure:** [brief description]
- **Key Directories:** [list with purposes]

### Project Rules
[Summarize rules from CLAUDE.md/AGENTS.md that affect implementation]

### Active Specs
- **Directory:** [path or "none"]
- **Status:** [which phases complete, which pending, any stalled pipeline]
```

KEEP the total output under 2,000 tokens. Prioritize information that affects implementation decisions.

## What This Phase Does NOT Do

- Does not make decisions about what to build
- Does not read application source code in depth
- Does not produce spec artifacts
- Does not modify any files
- Does not execute code or install dependencies

This is a read-only reconnaissance phase.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I already read this project last session" | Sessions do not share state. You have zero project context right now. Read the files. |
| "CLAUDE.md is enough, I'll skip the structure scan" | CLAUDE.md tells you rules. Structure tells you where things live. Both are mandatory. |
| "This is a small change, context loading is overkill" | Context loading takes seconds. Guessing at conventions takes hours of rework. |
| "I can infer the tech stack from the code I'm about to read" | You will read the wrong files. The config files tell you which files matter. |

## Red Flags — Self-Check

- You are referencing a file you have not opened in this session
- You assumed a test runner or build tool without reading package.json / pyproject.toml
- You stated a convention ("this project uses X") without citing an actual file you read
- You skipped the structure scan and went straight to reading source code
- The project context block is missing from your conversation

## Transition

WHEN this skill completes:
- RETURN the project context block to the calling pipeline.
- DO NOT ask the user what to do next.
- The calling pipeline WILL invoke the next phase. Your job is done.
