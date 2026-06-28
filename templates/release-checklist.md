# Release Checklist

Copy this into PROGRESS.md or a release PR description and check off each item.

## Pre-release

- [ ] All planned features and fixes are merged to `develop` (Git Flow) or `main` (GitHub Flow)
- [ ] No open high-priority blockers
- [ ] Version number decided: `v<major>.<minor>.<patch>`

## Create release branch (Git Flow only)

- [ ] Create `release/<version>` from `develop`
- [ ] Update version number in manifests (package.json, composer.json, pyproject.toml, etc.)
- [ ] Update CHANGELOG.md or release notes
- [ ] Commit: `chore: prepare release <version>`

## Verification

- [ ] Full test suite passed on release branch
- [ ] Linter / type check passed
- [ ] Guard scripts ran clean:
  - [ ] `.\scripts\guard-before-edit.ps1`
  - [ ] `.\scripts\guard-git-flow.ps1`
  - [ ] `.\scripts\guard-before-merge.ps1`
- [ ] Manual smoke test on staging / pre-prod environment
- [ ] No secrets or credentials in changed files

## Merge to production

- [ ] PR from `release/<version>` (or `feature/...`) → `main` / `master` opened
- [ ] At least one reviewer approved
- [ ] All required CI checks passed
- [ ] Merged (do NOT squash if you need the commit history)

## Tag release

- [ ] `git tag -a v<version> -m "Release <version>"`
- [ ] `git push origin v<version>`
- [ ] GitHub/Azure DevOps release created with release notes

## Merge back to develop (Git Flow only)

- [ ] Merge `release/<version>` back into `develop`
- [ ] Confirm `develop` is ahead of `main` by at least the merge commit
- [ ] Delete `release/<version>` branch after both merges confirmed

## Post-release

- [ ] PROGRESS.md updated with release status
- [ ] DECISIONS.md updated with any release decisions
- [ ] Team/stakeholders notified
- [ ] Monitoring confirms no regressions in production
- [ ] Next milestone / sprint started
