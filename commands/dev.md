---
description: Run the feature development pipeline from brainstorm through commit
---

Run the feature development pipeline from brainstorm through commit. Invokes the `dev-pipeline` skill which orchestrates all phases: context loading -> brainstorm -> plan -> revision -> execution (TDD with parallel subagents) -> code review -> commit/push. For bug fixes, use `/resolve` instead.

Usage: /dev <description of what to build>
