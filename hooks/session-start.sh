#!/usr/bin/env bash
set -euo pipefail

# Session start hook — injects the meta-skill and detects stalled pipelines.
# Uses status field in YAML frontmatter and updated artifact numbering (05-code-review.md).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL_FILE="$PLUGIN_DIR/skills/using-toolkit/SKILL.md"

if [[ ! -f "$SKILL_FILE" ]]; then
  cat <<'WARN_EOF'
{
  "priority": "IMPORTANT",
  "message": "[development-toolkit] Warning: skills/using-toolkit/SKILL.md not found. The toolkit is installed but the meta-skill could not be loaded."
}
WARN_EOF
  exit 0
fi

# Read skill content and JSON-encode it
ESCAPED="$(python3 -c "
import json, sys
with open(sys.argv[1], 'r') as f:
    content = f.read()
print(json.dumps(content))
" "$SKILL_FILE")"

# Check for stalled pipeline artifacts
STALLED_MSG=""

if [ -d "docs" ]; then
  LATEST_SPEC=$(find docs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
  if [ -n "$LATEST_SPEC" ]; then
    HAS_START=false
    HAS_REVIEW=false
    IS_RESOLVE=false

    # Check for pipeline start artifacts
    [ -f "$LATEST_SPEC/01-brainstorm.md" ] && HAS_START=true
    [ -f "$LATEST_SPEC/01-diagnosis.md" ] && HAS_START=true && IS_RESOLVE=true

    # Check for review artifact (v2.1.0 numbering: 05-code-review.md)
    [ -f "$LATEST_SPEC/05-code-review.md" ] && HAS_REVIEW=true
    # Also check legacy numbering for backwards compatibility
    [ -f "$LATEST_SPEC/04-code-review.md" ] && HAS_REVIEW=true

    if [ "$HAS_START" = true ] && [ "$HAS_REVIEW" = false ]; then
      # Check if the start artifact has status: approved (not just draft)
      START_FILE=""
      [ -f "$LATEST_SPEC/01-brainstorm.md" ] && START_FILE="$LATEST_SPEC/01-brainstorm.md"
      [ -f "$LATEST_SPEC/01-diagnosis.md" ] && START_FILE="$LATEST_SPEC/01-diagnosis.md"

      if [ -n "$START_FILE" ]; then
        # Check status field — stalled if approved but no review
        STATUS=$(grep -m1 "^status:" "$START_FILE" 2>/dev/null | sed 's/status:\s*//' | tr -d '"' | tr -d "'" | xargs)
        if [ "$STATUS" = "approved" ] || [ "$STATUS" = "draft" ]; then
          PIPELINE_TYPE="dev"
          [ "$IS_RESOLVE" = true ] && PIPELINE_TYPE="resolve"
          STALLED_MSG="STALLED PIPELINE DETECTED in $LATEST_SPEC ($PIPELINE_TYPE pipeline). Resume or start fresh."
        fi
      fi
    fi
  fi
fi

# Build output
if [ -n "$STALLED_MSG" ]; then
  STALLED_ESCAPED="$(python3 -c "import json, sys; print(json.dumps(sys.argv[1]))" "$STALLED_MSG")"
  cat <<EOF
{
  "priority": "IMPORTANT",
  "message": $ESCAPED,
  "stalledPipeline": $STALLED_ESCAPED
}
EOF
else
  cat <<EOF
{
  "priority": "IMPORTANT",
  "message": $ESCAPED
}
EOF
fi
