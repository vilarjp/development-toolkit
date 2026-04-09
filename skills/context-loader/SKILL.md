---
name: context-loader
description: Use before any pipeline phase to scan and index the current project context. Reads CLAUDE.md, project structure, config files, and existing conventions.
---

# Context Loader (Phase 0)

This is Phase 0 -- the pre-flight scan that runs before any thinking begins. Every subsequent phase depends on accurate project context. This phase is fast and cheap. Do not skip it.

## When to Run

- Start of any new session
- Before any pipeline phase if context has not been loaded yet
- When switching to a different project or repository
- When another skill says "run context-loader first"

## Process

Execute these steps in order. Do not skip steps. Do not summarize without reading.

### Step 1: Read Project Instructions

Check for and read these files if they exist in the project root:
- `CLAUDE.md` -- project-specific instructions for AI agents
- `AGENTS.md` -- multi-agent coordination rules
- `.claude/CLAUDE.md` -- user-level overrides

If none exist, note this explicitly: "No project instruction files found. Proceeding with defaults."

Read each file fully. Do not skim. These files contain rules that override default behavior. Extract:
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
- `package.json` -- dependencies, scripts, module type
- `tsconfig.json` -- TypeScript configuration, module system, paths
- `.eslintrc*` or `eslint.config.*` -- linting rules
- `vite.config.*` -- build tool
- `next.config.*` -- framework (Next.js)
- `vitest.config.*` or `jest.config.*` -- test runner

**Python:**
- `pyproject.toml` -- dependencies, build system, tool config
- `setup.py` or `setup.cfg` -- legacy packaging
- `requirements.txt` -- dependencies
- `tox.ini` or `noxfile.py` -- test runner config
- `mypy.ini` or section in `pyproject.toml` -- type checking

**Ruby:**
- `Gemfile` -- dependencies
- `.rubocop.yml` -- linting rules
- `Rakefile` -- task runner

**Go:**
- `go.mod` -- module definition, dependencies
- `go.sum` -- dependency checksums

**General (any stack):**
- `.editorconfig` -- editor formatting rules
- `.prettierrc*` -- code formatting
- `docker-compose.yml` or `Dockerfile` -- containerization
- `Makefile` -- build commands
- `.github/workflows/` -- CI/CD configuration
- `.env.example` -- environment variables template

If a config file does not exist, skip it silently. Do not report its absence.

### Step 4: Read Configuration Files

For each detected config file, read it and extract:
- **Dependencies and versions** -- what libraries are in use, what versions are pinned
- **Build commands** -- how to build, test, lint, and run the project
- **Module system** -- ESM vs CJS, import style, path aliases
- **Test runner** -- what framework, what command to run tests
- **Lint/format rules** -- what style is enforced

YOU MUST READ `scripts` in `package.json`, `[tool.*]` sections in `pyproject.toml`, and `Makefile` targets. These tell you how the project is operated.

### Step 5: Scan Architectural Conventions

Look for patterns in the directory structure and existing code:

**Directory patterns:**
- `src/components/` -- component-based architecture
- `src/lib/` or `lib/` -- shared utilities
- `src/app/` or `app/` -- application routes or entry points
- `src/services/` -- service layer
- `src/hooks/` -- custom hooks (React)
- `src/stores/` or `src/state/` -- state management

**Test placement:**
- Co-located: `src/components/Button.tsx` + `src/components/Button.test.tsx`
- Separate: `src/components/Button.tsx` + `__tests__/components/Button.test.tsx`
- Top-level: `src/` + `test/`

**Import patterns:**
- Barrel files (`index.ts` re-exporting from a directory)
- Path aliases (`@/components/...`, `~/lib/...`)
- Relative imports vs absolute imports

**Naming conventions:**
- File naming: kebab-case, camelCase, PascalCase
- Component naming patterns
- Test file naming: `.test.ts`, `.spec.ts`, `_test.go`

Examine 3-5 representative source files and 2-3 test files to detect these patterns. You MUST only report conventions you can observe in actual code. Do NOT infer conventions from dependencies alone.

### Step 6: Check for Existing Specs

Look for pipeline artifacts in two locations:

1. **Per-session directories** under `docs/` matching the pattern `docs/YYYY-MM-DD-*/`. Check the most recent one (sorted by name, descending).
2. **Legacy location** at `docs/spec/`.

In either location, look for:
- `01-brainstorm.md` or `01-diagnosis.md` — has brainstorming or diagnosis been done?
- `02-plan.md` — has planning been done?
- `03-revision.md` — has revision been done?
- `04-code-review.md` — has code review been done?

If specs exist, read their frontmatter to check status (draft, approved, etc.). Note which phases have been completed and which are pending.

If no spec artifacts are found in either location, report "No active specs found."

### Step 7: Compile Project Context Block

Assemble all findings into a structured context block. This block stays in conversation context -- it is NOT written to a file.

## Output Format

Produce exactly this structure:

```
## Project Context

### Stack
- **Language:** [e.g., TypeScript 5.x]
- **Framework:** [e.g., Next.js 14 (App Router)]
- **Package Manager:** [e.g., pnpm]
- **Test Runner:** [e.g., Vitest]
- **Linter:** [e.g., ESLint with flat config]
- **Build Tool:** [e.g., Vite]

### Key Commands
- **Build:** [command]
- **Test:** [command]
- **Lint:** [command]
- **Dev:** [command]

### Conventions
- **Module System:** [ESM/CJS]
- **File Naming:** [pattern]
- **Test Placement:** [co-located/separate/top-level]
- **Import Style:** [path aliases/relative/barrel files]

### Architecture
- **Directory Structure:** [brief description of layout]
- **Key Directories:** [list with purposes]
- **State Management:** [if applicable]
- **API Layer:** [if applicable]

### Project Rules
[Summarize any rules from CLAUDE.md/AGENTS.md that affect implementation]

### Active Specs
- **Brainstorm:** [exists/missing, status if exists]
- **Plan:** [exists/missing, status if exists]
- **Revision:** [exists/missing, status if exists]
```

KEEP the total output under 2,000 tokens. ALWAYS prioritize information that affects implementation decisions.

## What This Phase Does NOT Do

- It does not make decisions about what to build
- It does not read application source code in depth (only config and structure)
- It does not produce spec artifacts
- It does not modify any files
- It does not execute any code, install dependencies, or run build commands

This is a read-only reconnaissance phase. Its only job is to produce accurate context for subsequent phases.

## Transition

WHEN this skill completes:
- RETURN the project context block to the calling pipeline.
- DO NOT ask the user what to do next.
- DO NOT summarize what you found unless the user explicitly asked for a context scan.
- The calling pipeline WILL invoke the next phase. Your job is done.
