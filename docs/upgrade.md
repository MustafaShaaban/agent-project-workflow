# Upgrade and Migration Guide

## Upgrading the global skill

If you already installed an older version of `project-workflow`, run the
install command again from a fresh clone or updated local copy:

```powershell
npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy
```

The `--copy` flag installs a standalone copy, so re-running it replaces the previous version.
Verify the new version is active:

```powershell
.\scripts\verify-install.ps1
```

Restart any running agent session so it reloads the updated skill.

## Adding `.ai-workflow.yml` to an existing bootstrapped project

If your project was bootstrapped with v0.1.0 (before `.ai-workflow.yml` existed),
copy the template and adjust:

```powershell
Copy-Item templates\.ai-workflow.yml C:\path\to\project\.ai-workflow.yml
```

Open the file and set:
- `project.name` and `project.type`
- `branching.strategy` (use `github-flow` if you're not sure — it's the safe default)
- `branching.production_branch` (change to `master` if your repo uses `master`)
- `workflow.profile` (start with `standard`)

Commit the file as project-owned documentation.

## Adding `.ai-skills.json` to an existing project

```powershell
Copy-Item templates\.ai-skills.json C:\path\to\project\.ai-skills.json
```

Edit the file to:
- Set `install_mode` to `ask` (safest default)
- Add any project-specific required skills
- Set `install_command` and `install_approved: true` only for skills you have
  verified and approved for auto-install

## Updating AGENTS.md, CLAUDE.md, PROGRESS.md, DECISIONS.md

The bootstrap script will never overwrite existing files by default:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project
```

If you want to see what would be added without changing anything:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -Mode observe-only
```

To update a specific file to the latest template while preserving others:

```powershell
Copy-Item templates\AGENTS.md C:\path\to\project\AGENTS.md -Force
```

Always review the diff before committing a template file update.

## Migrating from basic safe-branch workflow to strict Git Flow

If your project was using a basic workflow (no `develop` branch, GitHub Flow) and
you want to adopt strict Git Flow:

1. Tell the agent to use `strict-migration` mode:
   ```text
   Use project-workflow in strict-migration mode. Propose a migration plan
   to adopt Git Flow for this project and wait for my approval before making changes.
   ```
2. Review the proposed plan carefully
3. Approve each step explicitly
4. Create the `develop` branch from `main`:
   ```powershell
   git checkout main && git pull
   git checkout -b develop
   git push -u origin develop
   ```
5. Update `.ai-workflow.yml`:
   ```yaml
   branching:
     strategy: git-flow
     integration_branch: develop
   ```
6. Set up branch protection on `develop` (see `docs/github.md` or `docs/azure-devops.md`)
7. Communicate the new branching rules to your team

The migration never rewrites history, deletes branches, or makes changes automatically.
Each step requires explicit owner approval.

## What does NOT change during upgrade

- Your project's `AGENTS.md`, `CLAUDE.md`, `PROGRESS.md`, `DECISIONS.md` — never touched
- Your project's branching history or commit history — never modified
- Your existing `.ai-workflow.yml` if already present — never overwritten by install
- Your existing branch protection rules — unchanged

The global skill upgrade only replaces the copy in `~/.claude/skills/project-workflow/`.
Project-owned files in individual repos are untouched.
