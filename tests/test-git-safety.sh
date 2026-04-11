#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/git-safety.sh"

fail() {
  echo "test-git-safety.sh: $*" >&2
  exit 1
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

run_case() {
  local branch="$1"
  local command="$2"
  local expected="$3"
  local tmpdir
  local status

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  make_repo "$tmpdir"

  if [[ "$branch" != "main" ]]; then
    git -C "$tmpdir" checkout -q -b "$branch"
  fi

  set +e
  (
    cd "$tmpdir"
    bash "$HOOK" "$command"
  ) >/tmp/toolkit-git-safety.out 2>/tmp/toolkit-git-safety.err
  status=$?
  set -e

  if [[ "$status" -ne "$expected" ]]; then
    fail "command '$command' on branch '$branch' exited $status, expected $expected"
  fi
}

run_case feature "git status" 0
run_case main "git status" 0
run_case main "git commit -m test" 1
run_case production "git merge feature" 1
run_case feature "git push origin main" 1
run_case feature "git push origin production" 1
run_case feature "git push origin HEAD:main" 1
run_case feature "git push origin feature:production" 1
run_case feature "git push --force-with-lease upstream refs/heads/topic:refs/heads/live" 1
run_case feature "git push origin feature" 0

echo "test-git-safety.sh: ok"
