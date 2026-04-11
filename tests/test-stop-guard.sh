#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/stop-guard.sh"

fail() {
  echo "test-stop-guard.sh: $*" >&2
  exit 1
}

run_guard() {
  local tmpdir="$1"
  shift
  (
    cd "$tmpdir"
    "$@"
  )
}

make_repo() {
  local root="$1"
  git init -q "$root"
  (
    cd "$root"
    git checkout -q -b main
    git config user.name "Toolkit Test"
    git config user.email "toolkit@example.com"
    echo "seed" > tracked.txt
    git add tracked.txt
    git commit -q -m "seed"
  )
}

write_status_file() {
  local path="$1"
  local status="$2"
  cat >"$path" <<EOF
---
status: $status
---
EOF
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
rm -f /tmp/development-toolkit-stop-guard-last-fire
make_repo "$tmpdir"

mkdir -p "$tmpdir/docs/2026-04-11-sample"
write_status_file "$tmpdir/docs/2026-04-11-sample/01-brainstorm.md" "draft"

if ! run_guard "$tmpdir" bash "$HOOK" >/dev/null 2>&1; then
  fail "draft spec should not block stop"
fi

write_status_file "$tmpdir/docs/2026-04-11-sample/01-brainstorm.md" "approved"

set +e
run_guard "$tmpdir" bash "$HOOK" >/tmp/toolkit-stop-guard.out 2>/tmp/toolkit-stop-guard.err
status=$?
set -e
if [[ "$status" -ne 2 ]]; then
  fail "approved unfinished pipeline should block stop"
fi
if ! grep -q "STOP BLOCKED" /tmp/toolkit-stop-guard.err; then
  fail "expected stop-guard to explain the block"
fi

touch "$tmpdir/docs/2026-04-11-sample/05-code-review.md"
echo "change" >>"$tmpdir/tracked.txt"
rm -f /tmp/development-toolkit-stop-guard-last-fire

set +e
run_guard "$tmpdir" bash "$HOOK" >/tmp/toolkit-stop-guard.out 2>/tmp/toolkit-stop-guard.err
status=$?
set -e
if [[ "$status" -ne 2 ]]; then
  fail "reviewed pipeline with uncommitted changes should block stop"
fi
if ! grep -q "not committed" /tmp/toolkit-stop-guard.err; then
  fail "expected uncommitted-change block message"
fi

rm -f /tmp/development-toolkit-stop-guard-last-fire
rm -rf "$tmpdir/docs/2026-04-11-sample"
mkdir -p "$tmpdir/docs/2026-04-11-sample"
write_status_file "$tmpdir/docs/2026-04-11-sample/01-diagnosis.md" "approved"
touch "$tmpdir/docs/2026-04-11-sample/04-code-review.md"
git -C "$tmpdir" checkout -q -- tracked.txt

if ! run_guard "$tmpdir" bash "$HOOK" >/dev/null 2>&1; then
  fail "legacy review numbering with approved diagnosis should allow stop"
fi

echo "test-stop-guard.sh: ok"
