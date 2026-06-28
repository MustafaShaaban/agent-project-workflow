# GitHub Branch Protection Guide

Apply these protections to your production and integration branches via
**Settings → Branches → Branch protection rules** (classic) or
**Settings → Rules → Rulesets** (new ruleset system).

## Recommended rules for `main` / `master`

| Setting | Value |
|---------|-------|
| Require a pull request before merging | ✅ |
| Required approvals | 1–2 (based on team size) |
| Dismiss stale reviews when new commits pushed | ✅ |
| Require review from Code Owners | ✅ (if CODEOWNERS is present) |
| Require status checks to pass before merging | ✅ |
| Require branches to be up to date | ✅ |
| Restrict who can push to this branch | ✅ (leads/owners only) |
| Allow force pushes | ❌ |
| Allow deletions | ❌ |

## Recommended rules for `develop`

| Setting | Value |
|---------|-------|
| Require a pull request before merging | ✅ |
| Required approvals | 1 |
| Require status checks to pass | ✅ |
| Allow force pushes | ❌ |
| Allow deletions | ❌ |

## Required status checks

Add the names of your CI jobs that must pass before merge:
- `build`
- `test`
- `lint`

## GitHub Actions example placeholder

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          # Add your test command here
          echo "No tests configured yet"
```
