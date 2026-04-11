#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/session-start.sh"

fail() {
  echo "test-session-start.sh: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    fail "expected output not to contain: $needle"
  fi
}

assert_json_field() {
  local json="$1"
  local expr="$2"
  local expected="$3"
  local actual

  actual="$(JSON_INPUT="$json" python3 -c "import json, os; data=json.loads(os.environ['JSON_INPUT']); value=$expr; print(value if value is not None else '')")"
  if [[ "$actual" != "$expected" ]]; then
    fail "expected JSON field $expr to equal '$expected', got '$actual'"
  fi
}

assert_valid_json() {
  local json="$1"
  JSON_INPUT="$json" python3 -c "import json, os; json.loads(os.environ['JSON_INPUT'])" >/dev/null \
    || fail "output is not valid JSON"
}

run_case() {
  local name="$1"
  local setup_fn="$2"
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  (
    cd "$tmpdir"
    "$setup_fn" "$tmpdir"
    bash "$HOOK"
  )
}

setup_none() {
  :
}

setup_draft() {
  local root="$1"
  mkdir -p "$root/docs/2026-04-11-sample"
  cat >"$root/docs/2026-04-11-sample/01-brainstorm.md" <<'EOF'
---
status: draft
---
EOF
}

setup_approved() {
  local root="$1"
  mkdir -p "$root/docs/2026-04-11-sample"
  cat >"$root/docs/2026-04-11-sample/01-brainstorm.md" <<'EOF'
---
status: approved
---
EOF
}

setup_resolve_approved() {
  local root="$1"
  mkdir -p "$root/docs/2026-04-11-sample"
  cat >"$root/docs/2026-04-11-sample/01-diagnosis.md" <<'EOF'
---
status: approved
---
EOF
}

setup_completed() {
  local root="$1"
  setup_approved "$root"
  touch "$root/docs/2026-04-11-sample/05-code-review.md"
}

setup_legacy_completed() {
  local root="$1"
  setup_resolve_approved "$root"
  touch "$root/docs/2026-04-11-sample/04-code-review.md"
}

out="$(run_case none setup_none)"
assert_valid_json "$out"
assert_json_field "$out" "data['priority']" "IMPORTANT"
assert_json_field "$out" "data.get('stalledPipeline')" ""

out="$(run_case draft setup_draft)"
assert_valid_json "$out"
assert_json_field "$out" "data.get('stalledPipeline')" ""

out="$(run_case approved setup_approved)"
assert_valid_json "$out"
assert_contains "$out" "STALLED PIPELINE DETECTED"
assert_json_field "$out" "'STALLED PIPELINE DETECTED' in data.get('stalledPipeline', '')" "True"

out="$(run_case resolve_approved setup_resolve_approved)"
assert_valid_json "$out"
assert_json_field "$out" "'resolve pipeline' in data.get('stalledPipeline', '')" "True"

out="$(run_case completed setup_completed)"
assert_valid_json "$out"
assert_json_field "$out" "data.get('stalledPipeline')" ""

out="$(run_case legacy_completed setup_legacy_completed)"
assert_valid_json "$out"
assert_json_field "$out" "data.get('stalledPipeline')" ""

echo "test-session-start.sh: ok"
