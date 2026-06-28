# Generic Git Platform Support

When no specific platform is detected, `project-workflow` operates in
generic Git mode. This covers self-hosted GitLab, Gitea, Bitbucket, Forgejo,
local-only repos, and any other Git host.

## What generic Git mode provides

- Safe workspace detection (Git root, branch, worktree)
- Branch naming and protection rules
- Guard scripts that work with any Git repo
- PR/merge request checklist template
- Release process checklist
- All workflow docs and templates

## Templates available

| Template | Path | Usage |
|----------|------|-------|
| PR/MR checklist | `templates/generic-git/pr-checklist.md` | Paste into your MR tool or review email |
| Release process | `templates/generic-git/release-process.md` | Follow for releases without a platform release tool |

## Manual PR process

If your platform does not have native PR templates, use the checklist from
`templates/generic-git/pr-checklist.md` as a structured code review guide.
Paste it into your merge request description, Jira ticket, or email thread.

## Branch naming without platform enforcement

Since there is no platform branch policy, use guard scripts to enforce locally:

```powershell
.\scripts\guard-git-flow.ps1 -ProjectPath C:\path\to\project
.\scripts\guard-before-edit.ps1 -ProjectPath C:\path\to\project
```

## Commit message convention

Without a platform enforcing linked work items, adopt a convention in `AGENTS.md`:

```
<type>(<scope>): <subject>

Types: feat | fix | chore | docs | refactor | test | style
```

## Release tagging

Tag releases manually following `templates/generic-git/release-process.md`.
Push tags explicitly:

```powershell
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```

## Agent behavior on generic Git projects

- Handoff includes `DETECTED PLATFORM: Generic Git`
- No platform-specific review requirements are enforced
- Guard scripts and workflow docs work as-is
- PR template guidance references the generic checklist
