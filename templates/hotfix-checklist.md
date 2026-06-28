# Hotfix Checklist

Use for urgent production fixes only. Scope must be minimal.

## Triage

- [ ] Confirmed production issue (not a staging/dev-only issue)
- [ ] Assessed impact and severity
- [ ] Fix is scoped to the minimum change needed
- [ ] Owner informed and approved the hotfix

## Create hotfix branch

- [ ] Branch from `main` / `master` (NOT from `develop`)
- [ ] Branch name: `hotfix/<short-description>` or `hotfix/<version>`
- [ ] Example: `git checkout -b hotfix/login-session-expiry origin/main`

## Implement fix

- [ ] Fix is minimal and scoped
- [ ] Fix does not introduce new features or unrelated cleanup
- [ ] No secrets or credentials committed
- [ ] Code reviewed (even informally) by at least one other developer

## Verification

- [ ] Relevant tests added or updated
- [ ] Tests pass
- [ ] Guard scripts ran clean:
  - [ ] `.\scripts\guard-before-edit.ps1`
  - [ ] `.\scripts\guard-git-flow.ps1`
  - [ ] `.\scripts\guard-before-merge.ps1`
- [ ] Smoke tested against production-equivalent environment

## Merge to production

- [ ] PR from `hotfix/<name>` → `main` / `master` opened
- [ ] Reviewed and approved
- [ ] All required CI checks passed
- [ ] Merged

## Tag

- [ ] `git tag -a v<patch-version> -m "Hotfix <description>"`
- [ ] `git push origin v<patch-version>`

## Merge back to develop (Git Flow only)

- [ ] Cherry-pick or merge `hotfix/<name>` into `develop`
- [ ] Confirm `develop` includes the fix
- [ ] Delete `hotfix/<name>` branch after both merges confirmed

## Post-fix notes

- [ ] Root cause documented in DECISIONS.md
- [ ] PROGRESS.md updated
- [ ] Monitoring confirms fix is effective
- [ ] Ticket / work item closed
- [ ] Post-mortem scheduled if severity was high
