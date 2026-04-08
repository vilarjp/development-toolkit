#!/usr/bin/env bash
set -uo pipefail

# Stop guard hook — prevents premature session termination during active pipelines.
# Fires as a Stop hook. Checks for incomplete pipeline state and blocks if found.
#
# Cooldown: If this hook fired within the last 60 seconds, allow stop to prevent
# infinite loops at approval gates (where the assistant pauses for user input but
# the pipeline appears incomplete to the hook).

COOLDOWN_FILE="/tmp/development-toolkit-stop-guard-last-fire"
COOLDOWN_SECONDS=60

if [ -f "$COOLDOWN_FILE" ]; then
  LAST_FIRE=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  ELAPSED=$(( NOW - LAST_FIRE ))
  if [ "$ELAPSED" -lt "$COOLDOWN_SECONDS" ]; then
    # Within cooldown window — allow stop to prevent loop at approval gates
    exit 0
  fi
fi

# Search for active spec directories
SPEC_DIR=""

# Check new per-session folder convention
if [ -d "docs" ]; then
  LATEST_SPEC_DIR=$(find docs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
  if [ -n "$LATEST_SPEC_DIR" ]; then
    SPEC_DIR="$LATEST_SPEC_DIR"
  fi
fi

# Check legacy docs/spec/ location
if [ -z "$SPEC_DIR" ] && [ -d "docs/spec" ]; then
  SPEC_DIR="docs/spec"
fi

# No spec directory — no active pipeline — allow stop
if [ -z "$SPEC_DIR" ]; then
  exit 0
fi

# Check pipeline state
HAS_BRAINSTORM=false
HAS_REVIEW=false
HAS_COMMITS=false

[ -f "$SPEC_DIR/01-brainstorm.md" ] || [ -f "$SPEC_DIR/01-diagnosis.md" ] && HAS_BRAINSTORM=true
[ -f "$SPEC_DIR/04-code-review.md" ] && HAS_REVIEW=true

# Check if there are uncommitted changes from implementation
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CHANGED_FILES=$(git status --porcelain 2>/dev/null | grep -v "docs/" | wc -l | tr -d ' ')
  if [ "$CHANGED_FILES" -gt 0 ]; then
    HAS_COMMITS=false
  else
    HAS_COMMITS=true
  fi
fi

# Pipeline is active and incomplete if:
# - Brainstorm/diagnosis exists but code review does not
# - OR code review exists but there are uncommitted changes
if [ "$HAS_BRAINSTORM" = true ] && [ "$HAS_REVIEW" = false ]; then
  date +%s > "$COOLDOWN_FILE"
  echo "STOP BLOCKED by development-toolkit stop-guard:"
  echo "  Active pipeline detected in $SPEC_DIR."
  echo "  Pipeline has not completed code review."
  echo "  Run /review to complete the review, or /commit to finalize."
  echo "  If you want to abandon the pipeline, delete the spec directory first."
  exit 2
fi

if [ "$HAS_REVIEW" = true ] && [ "$HAS_COMMITS" = false ]; then
  date +%s > "$COOLDOWN_FILE"
  echo "STOP BLOCKED by development-toolkit stop-guard:"
  echo "  Code review is complete but changes are not committed."
  echo "  Run /commit to commit and push changes."
  exit 2
fi

# Pipeline complete or not active — allow stop
exit 0
