#!/usr/bin/env bash
set -uo pipefail

# Stop guard hook — prevents premature session termination during active pipelines.
# Updated for v2.1.0 artifact numbering (05-code-review.md).
#
# Cooldown: If fired within last 60 seconds, allow stop to prevent infinite loops
# at approval gates.

COOLDOWN_FILE="/tmp/development-toolkit-stop-guard-last-fire"
COOLDOWN_SECONDS=60

if [ -f "$COOLDOWN_FILE" ]; then
  LAST_FIRE=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  ELAPSED=$(( NOW - LAST_FIRE ))
  if [ "$ELAPSED" -lt "$COOLDOWN_SECONDS" ]; then
    exit 0
  fi
fi

# Search for active spec directories
SPEC_DIR=""

if [ -d "docs" ]; then
  LATEST_SPEC_DIR=$(find docs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
  if [ -n "$LATEST_SPEC_DIR" ]; then
    SPEC_DIR="$LATEST_SPEC_DIR"
  fi
fi

# No spec directory — no active pipeline — allow stop
if [ -z "$SPEC_DIR" ]; then
  exit 0
fi

# Check pipeline state
HAS_BRAINSTORM=false
HAS_REVIEW=false
HAS_UNCOMMITTED=false

[ -f "$SPEC_DIR/01-brainstorm.md" ] || [ -f "$SPEC_DIR/01-diagnosis.md" ] && HAS_BRAINSTORM=true

# Check both v2.1.0 (05) and legacy (04) numbering
[ -f "$SPEC_DIR/05-code-review.md" ] || [ -f "$SPEC_DIR/04-code-review.md" ] && HAS_REVIEW=true

# Check for uncommitted changes (excluding docs/)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CHANGED_FILES=$(git status --porcelain 2>/dev/null | grep -v "docs/" | wc -l | tr -d ' ')
  if [ "$CHANGED_FILES" -gt 0 ]; then
    HAS_UNCOMMITTED=true
  fi
fi

# Pipeline active and incomplete: brainstorm/diagnosis exists but no review
if [ "$HAS_BRAINSTORM" = true ] && [ "$HAS_REVIEW" = false ]; then
  date +%s > "$COOLDOWN_FILE"
  echo "STOP BLOCKED by development-toolkit stop-guard:" >&2
  echo "  Active pipeline detected in $SPEC_DIR." >&2
  echo "  Pipeline has not completed code review." >&2
  echo "  Complete the review, or delete the spec directory to abandon." >&2
  exit 2
fi

# Review done but uncommitted changes
if [ "$HAS_REVIEW" = true ] && [ "$HAS_UNCOMMITTED" = true ]; then
  date +%s > "$COOLDOWN_FILE"
  echo "STOP BLOCKED by development-toolkit stop-guard:" >&2
  echo "  Code review complete but changes are not committed." >&2
  echo "  Commit and push to complete the pipeline." >&2
  exit 2
fi

# Pipeline complete or not active — allow stop
exit 0
