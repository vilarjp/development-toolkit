#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() {
  echo "validate-contracts.sh: $*" >&2
  exit 1
}

cd "$REPO_ROOT"

grep -q 'For \*\*resolve\*\*: `01-diagnosis.md` MUST exist and be `approved`' skills/execute/SKILL.md \
  || fail "execute skill does not define resolve-mode prerequisites"

grep -q 'Use the diagnosis as the execution source of truth. Do NOT invent a synthetic plan.' skills/execute/SKILL.md \
  || fail "execute skill does not protect against synthetic resolve plans"

grep -q 'STATUS" = "approved"' hooks/session-start.sh \
  || fail "session-start stalled detection is not approval-gated"

grep -q '"positives"' findings-schema.json \
  || fail "findings schema is missing positives[]"

grep -q 'provably behavior-preserving' findings-schema.json \
  || fail "findings schema safe_auto contract is not tightened"

grep -q 'raw checkout' README.md \
  || fail "README does not explain the raw-checkout packaging boundary"

grep -q 'dispatch` (string)' AGENTS.md \
  || fail "AGENTS frontmatter contract still assumes only always/conditional"

grep -Fq '04-execution-log.md` becomes `approved`' AGENTS.md \
  || fail "AGENTS artifact lifecycle is missing execution log ownership"

grep -Fq '04-execution-log.md` → `approved`' skills/using-toolkit/SKILL.md \
  || fail "meta-skill artifact lifecycle is missing execution log ownership"

grep -Fq '`status: approved`' skills/execute/SKILL.md \
  || fail "execute skill does not finalize execution log status"

if grep -q '### Dev Pipeline (`/dev`)' skills/using-toolkit/SKILL.md; then
  fail "meta-skill still presents dev as a literal slash command"
fi

echo "validate-contracts.sh: ok"
