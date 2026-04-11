#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/test-session-start.sh"
"$SCRIPT_DIR/test-stop-guard.sh"
"$SCRIPT_DIR/test-git-safety.sh"
"$SCRIPT_DIR/validate-contracts.sh"

echo "All development-toolkit checks passed."
