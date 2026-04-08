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
  "message": "[joao-toolkit] Warning: skills/using-toolkit/SKILL.md not found. The toolkit is installed but the meta-skill could not be loaded. Run /context to verify your installation."
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

# Output the injection payload
cat <<EOF
{
  "priority": "IMPORTANT",
  "message": $ESCAPED
}
EOF
