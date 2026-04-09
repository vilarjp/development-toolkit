#!/usr/bin/env bash
set -euo pipefail

# Detect plugin directory from this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL_FILE="$PLUGIN_DIR/skills/using-toolkit/SKILL.md"

if [[ ! -f "$SKILL_FILE" ]]; then
  # Skill file not found — emit a warning but do not fail
  cat <<'WARN_EOF'
{
  "priority": "IMPORTANT",
  "message": "[development-toolkit] Warning: skills/using-toolkit/SKILL.md not found. The toolkit is installed but the meta-skill could not be loaded. Run /context to verify your installation."
}
WARN_EOF
  exit 0
fi

# Read skill content and escape it for JSON embedding
SKILL_CONTENT="$(cat "$SKILL_FILE")"

# Use python3 (available on macOS) to safely JSON-encode the content
ESCAPED="$(python3 -c "
import json, sys
with open(sys.argv[1], 'r') as f:
    content = f.read()
print(json.dumps(content))
" "$SKILL_FILE")"

# Check for stalled pipeline artifacts
STALLED_MSG=""

# Check new per-session folder convention
if [ -d "docs" ]; then
  LATEST_SPEC=$(find docs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
  if [ -n "$LATEST_SPEC" ]; then
    if [ ! -f "$LATEST_SPEC/04-code-review.md" ]; then
      STALLED_MSG="STALLED PIPELINE DETECTED in $LATEST_SPEC. Resume the pipeline or start fresh."
    fi
  fi
fi

# Check legacy docs/spec/ location
if [ -z "$STALLED_MSG" ] && [ -d "docs/spec" ]; then
  LATEST_ARTIFACT=$(ls -t docs/spec/*.md 2>/dev/null | head -1)
  if [ -n "$LATEST_ARTIFACT" ] && [ ! -f "docs/spec/04-code-review.md" ]; then
    STALLED_MSG="STALLED PIPELINE DETECTED in docs/spec/. Resume the pipeline or start fresh."
  fi
fi

# Build the message with optional stalled pipeline warning
if [ -n "$STALLED_MSG" ]; then
  STALLED_ESCAPED="$(python3 -c "import json; print(json.dumps('$STALLED_MSG'))")"
  cat <<EOF
{
  "priority": "IMPORTANT",
  "message": $ESCAPED,
  "stalledPipeline": $STALLED_ESCAPED
}
EOF
else
  # Output the injection payload
  cat <<EOF
{
  "priority": "IMPORTANT",
  "message": $ESCAPED
}
EOF
fi
