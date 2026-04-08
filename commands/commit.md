---
description: Safe git commit and push with branch protection
---

Safe git commit and push. Verifies branch is not master/main, runs pre-commit checks, creates conventional commits with logical splitting, rebases from main, and pushes. Never commits to protected branches.

Usage: /commit [optional commit message override]
