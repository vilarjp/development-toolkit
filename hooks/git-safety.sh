#!/usr/bin/env bash
set -uo pipefail

# Git safety hook — blocks write operations on protected branches (master/main)
# and blocks pushes targeting protected remote branches from any branch.
#
# Receives the Bash tool input (the command string) as $1.
# Exit 0 = allow, Exit 1 = block.

TOOL_INPUT="${1:-}"

# If no input provided, allow
if [[ -z "$TOOL_INPUT" ]]; then
  exit 0
fi

# Only inspect commands that start with "git "
if [[ "$TOOL_INPUT" != git\ * && "$TOOL_INPUT" != *\|*git\ * && "$TOOL_INPUT" != *\;*git\ * && "$TOOL_INPUT" != *&&*git\ * ]]; then
  exit 0
fi

# --- Check 1: Block pushes targeting origin main/master from ANY branch ---
# Matches: git push origin main, git push origin master, git push --force origin main, etc.
if echo "$TOOL_INPUT" | grep -qE 'git\s+push\s+.*origin\s+(main|master)(\s|$)'; then
  echo "BLOCKED by development-toolkit git-safety hook:"
  echo "  Pushing to origin main/master is not allowed."
  echo "  Push to a feature branch instead: git push -u origin <branch-name>"
  exit 1
fi

# Also catch: git push (with upstream set to main/master)
# We check this further below when we know the branch.

# --- Check 2: Block git write operations when on a protected branch ---

# Are we in a git repo?
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Not a git repo — nothing to protect
  exit 0
fi

# Get current branch name
CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"

# Detached HEAD or unable to determine branch — allow
if [[ -z "$CURRENT_BRANCH" ]]; then
  exit 0
fi

# Only enforce on protected branches
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
  exit 0
fi

# Define write operations that are blocked on protected branches
# commit, push, merge, rebase (but not: status, log, diff, branch, checkout, fetch, pull)
WRITE_OPS="commit|push|merge|rebase"

if echo "$TOOL_INPUT" | grep -qE "git\s+($WRITE_OPS)(\s|$)"; then
  echo "BLOCKED by development-toolkit git-safety hook:"
  echo "  You are on the protected branch '$CURRENT_BRANCH'."
  echo "  Git write operations (commit, push, merge, rebase) are not allowed on main/master."
  echo "  Create a feature branch first: git checkout -b <branch-name>"
  exit 1
fi

# All other commands are allowed
exit 0
