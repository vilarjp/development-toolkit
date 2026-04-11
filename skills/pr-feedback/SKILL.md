---
name: pr-feedback
description: Fetches unresolved PR review threads, clusters them by concern, dispatches parallel fixers (Sonnet/medium), commits, pushes, and resolves threads. Discussion replies require human approval.
---

# PR Feedback Resolution (Post-Pipeline)

Systematically process PR review comments from teammates. Fetch threads, classify them, fix what's actionable, reply to discussions, and mark threads as resolved.

## Invocation

- `/pr-feedback` — resolve all unresolved threads on current branch's PR
- `/pr-feedback 123` — resolve all threads on PR #123
- `/pr-feedback <comment-url>` — resolve a specific thread only

## Process

### Step 1 — Fetch Unresolved Threads

Use `gh` CLI to get PR data:

```bash
gh pr view [number] --json number,title,body,reviewThreads,comments
```

Extract all unresolved review threads and standalone PR comments.

### Step 2 — Triage

Classify each thread:

| Classification | Criteria | Action |
|----------------|----------|--------|
| `actionable` | Reviewer requests a code change, fix, or improvement | Fix via TDD |
| `discussion` | Reviewer asks a question, raises a concern, or disagrees | Draft reply for human approval |
| `resolved` | Already addressed by a recent commit (check diff) | Auto-reply with commit SHA + resolve |
| `stale` | Comment on code that no longer exists | Auto-reply noting the code changed + resolve |

### Step 3 — Cluster Actionable Threads

Group actionable threads by concern:
- Same file = same cluster
- Same issue pattern across files = same cluster
- Related files (e.g., component + its test) = same cluster

Standalone threads that don't cluster remain as individual items.

### Step 4 — Execute Fixes

For each cluster or standalone actionable thread:

1. DISPATCH a fixer subagent (model: latest Sonnet, effort: medium) with:
   - The review comment text
   - The relevant code context (file + surrounding lines)
   - TDD rules from `skills/tdd/SKILL.md`
   - Instruction: fix the issue following TDD, commit with reference to the PR

2. **Parallelism rules:**
   - Up to 4 fixers in parallel
   - If more than 4: batch in groups of 4
   - No two fixers touching the same file run in parallel

3. Each fixer reports: `fixed`, `fixed-differently` (with explanation), `needs-human`, or `not-addressing` (with reason).

4. For `needs-human`: surface to user with the fixer's analysis.

### Step 5 — Commit and Push

If any files were changed:
1. Stage files from fixer reports (specific files, not `git add .`).
2. Commit: `fix(pr-feedback): address review comments on PR #[number]`
3. Push to the existing branch.

### Step 6 — Reply and Resolve

**For actionable threads (fixed):**
- Reply with: what was fixed + commit SHA
- Mark as resolved

**For actionable threads (fixed-differently):**
- Reply with: what was done differently and why + commit SHA
- Mark as resolved

**For discussion threads:**
- Draft a reply based on the code context and the reviewer's question
- **PRESENT to user for approval before posting:**
  ```
  Thread: [reviewer's comment summary]
  Draft reply: [your proposed reply]
  
  Post this reply? (yes / edit / skip)
  ```
- Only post after explicit user approval
- Do NOT auto-resolve discussion threads — the reviewer decides

**For resolved/stale threads:**
- Auto-reply noting the code was already changed + commit SHA
- Mark as resolved

### Step 7 — Verify

Re-fetch unresolved threads:
```bash
gh pr view [number] --json reviewThreads
```

- If new threads appeared (reviewer responded): surface to user.
- If previously actionable threads are now resolved: report success.
- If threads remain unresolved after 2 cycles: surface to user, do not loop further.

### Step 8 — Summary

Report:
```
PR Feedback Resolution Complete

Fixed: [N] threads
  - [thread summary] — [commit SHA]
Replied: [N] threads (human-approved)
  - [thread summary]
Needs human: [N] threads
  - [thread summary] — [reason]
Not addressing: [N] threads
  - [thread summary] — [reason]
```

## Rules

- Discussion replies ALWAYS require human approval. Never auto-post explanations or disagreements.
- Fixes follow TDD — even PR feedback fixes get a test.
- Never force-push after fixing PR feedback. Always push new commits.
- If a fix requires changes beyond the scope of the review comment, flag it for human decision.
- Respect the reviewer's intent — if they ask for X, don't give them Y "because it's better."

## Transition

This skill is standalone (post-pipeline). When complete, report the summary and stop. Do not chain into other skills.
