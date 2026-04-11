#!/usr/bin/env bash
set -uo pipefail

# Git safety hook — blocks write operations on protected branches
# and blocks pushes targeting protected remote branches from any branch.
#
# Receives the Bash tool input (the command string) as $1.
# Exit 0 = allow, Exit 1 = block.

TOOL_INPUT="${1:-}"
PROTECTED_BRANCH_REGEX='^(main|master|production|prod|stable|live|trunk)$'

is_protected_branch() {
  local branch="${1:-}"
  [[ -n "$branch" && "$branch" =~ $PROTECTED_BRANCH_REGEX ]]
}

strip_ref_prefix() {
  local ref="${1:-}"
  ref="${ref#refs/heads/}"
  ref="${ref#remotes/}"
  ref="${ref#origin/}"
  printf '%s\n' "$ref"
}

# If no input provided, allow
if [[ -z "$TOOL_INPUT" ]]; then
  exit 0
fi

# Only inspect commands that start with "git "
if [[ "$TOOL_INPUT" != git\ * && "$TOOL_INPUT" != *\|*git\ * && "$TOOL_INPUT" != *\;*git\ * && "$TOOL_INPUT" != *&&*git\ * ]]; then
  exit 0
fi

# --- Check 1: Block pushes targeting protected branches from ANY branch ---
#
# Examples that should be blocked:
# - git push origin main
# - git push origin HEAD:main
# - git push upstream feature:production
# - git push --force-with-lease origin refs/heads/topic:refs/heads/live
if [[ "$TOOL_INPUT" =~ git[[:space:]]+push([[:space:]]|$) ]]; then
  TARGET_REFS="$(printf '%s\n' "$TOOL_INPUT" | grep -oE '([[:alnum:]_./-]+:)?(refs/heads/)?(main|master|production|prod|stable|live|trunk)([[:space:]]|$)' || true)"
  if [[ -n "$TARGET_REFS" ]]; then
    echo "BLOCKED by development-toolkit git-safety hook:"
    echo "  Pushing to a protected branch is not allowed."
    echo "  Protected branch names include: main, master, production, prod, stable, live, trunk."
    echo "  Push to a feature branch instead: git push -u <remote> <branch-name>"
    exit 1
  fi
fi

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
if ! is_protected_branch "$CURRENT_BRANCH"; then
  if [[ "$TOOL_INPUT" =~ git[[:space:]]+push([[:space:]]|$) ]]; then
    UPSTREAM_BRANCH="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")"
    UPSTREAM_BRANCH="$(strip_ref_prefix "$UPSTREAM_BRANCH")"
    if is_protected_branch "$UPSTREAM_BRANCH"; then
      echo "BLOCKED by development-toolkit git-safety hook:"
      echo "  This branch pushes to protected upstream '$UPSTREAM_BRANCH'."
      echo "  Repoint the upstream or push to a non-protected branch explicitly."
      exit 1
    fi
  fi
  exit 0
fi

# Define write operations that are blocked on protected branches
# commit, push, merge, rebase (but not: status, log, diff, branch, checkout, fetch, pull)
WRITE_OPS="commit|push|merge|rebase"

if echo "$TOOL_INPUT" | grep -qE "git\s+($WRITE_OPS)(\s|$)"; then
  echo "BLOCKED by development-toolkit git-safety hook:"
  echo "  You are on the protected branch '$CURRENT_BRANCH'."
  echo "  Git write operations (commit, push, merge, rebase) are not allowed on protected branches."
  echo "  Create a feature branch first: git checkout -b <branch-name>"
  exit 1
fi

# All other commands are allowed
exit 0
