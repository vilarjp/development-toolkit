#!/usr/bin/env bash
set -uo pipefail

# Continuity enforcement hook — prevents LLM narration between skill transitions
# during active pipeline execution. Fires as a PostToolUse hook after Skill calls.
#
# When a skill returns during an active pipeline, the only permitted next action
# is another tool call. No summarizing, no narrating, no explaining.

# Check if we are in an active pipeline by looking for spec artifacts
SPEC_DIR=""

# Search for active spec directories (the new per-session folder convention)
if [ -d "docs" ]; then
  # Find the most recent spec folder matching the YYYY-MM-DD pattern
  LATEST_SPEC_DIR=$(find docs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
  if [ -n "$LATEST_SPEC_DIR" ]; then
    SPEC_DIR="$LATEST_SPEC_DIR"
  fi
fi

# Also check legacy docs/spec/ location
if [ -z "$SPEC_DIR" ] && [ -d "docs/spec" ]; then
  SPEC_DIR="docs/spec"
fi

# If no spec directory found, pipeline is not active — allow normal behavior
if [ -z "$SPEC_DIR" ]; then
  exit 0
fi

# Check if there are artifacts indicating an active pipeline
HAS_BRAINSTORM=false
HAS_PLAN=false
HAS_REVIEW=false

[ -f "$SPEC_DIR/01-brainstorm.md" ] || [ -f "$SPEC_DIR/01-diagnosis.md" ] && HAS_BRAINSTORM=true
[ -f "$SPEC_DIR/02-plan.md" ] && HAS_PLAN=true
[ -f "$SPEC_DIR/04-code-review.md" ] && HAS_REVIEW=true

# Pipeline is active if we have artifacts but the review is not yet complete
if [ "$HAS_BRAINSTORM" = true ] && [ "$HAS_REVIEW" = false ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "CONTINUITY ENFORCEMENT: You are in an active pipeline. Your ONLY next action must be a tool call to execute the next pipeline phase. Do NOT output text to the user between phases. Do NOT summarize what just happened. Execute the next phase immediately."
  }
}
EOF
fi

exit 0
