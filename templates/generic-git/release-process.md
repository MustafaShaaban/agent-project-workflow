# Generic Git Release Process

Use when your platform does not provide a built-in release workflow.

## Before releasing

- [ ] All planned work is merged to the integration branch (`develop` or equivalent)
- [ ] Tests pass on the integration branch
- [ ] Changelog or release notes are drafted
- [ ] Version number updated in relevant files (package.json, composer.json, etc.)
- [ ] No open blockers

## Release steps

1. Create a `release/<version>` branch from `develop` (Git Flow) or from `main` (GitHub Flow)
2. Make release-only changes: version bumps, changelog, last-minute fixes
3. Run full test suite and guards
4. Merge into `main` / `master` via PR/MR
5. Tag the release: `git tag -a v<version> -m "Release <version>"`
6. If using Git Flow: merge `release/<version>` back into `develop`
7. Delete the release branch after both merges are confirmed

## After releasing

- [ ] Tag pushed to remote: `git push origin v<version>`
- [ ] Release notes published (GitHub release, Azure DevOps release, etc.)
- [ ] PROGRESS.md updated
- [ ] Team notified
- [ ] Monitor for regressions
