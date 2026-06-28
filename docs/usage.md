# Usage

The global skill provides a universal startup, safety, and handoff routine.
Project-owned `AGENTS.md`, `CLAUDE.md`, `.ai-workflow.yml`, and specs remain authoritative.

## Claude Code

```text
Use the project-workflow skill. Start safely in this repo, read its rules, detect the platform and project type, and report the current mode before editing.
```

## Codex

```text
Use project-workflow to continue from PROGRESS.md. Verify the real root, branch, worktree, platform, skills status, and active spec first.
```

---

## Example prompts

### Start safely

```text
Use project-workflow and start safely in this repo. Do not edit until you have
checked the real root, status, branch, remotes, worktrees, platform, project type,
required skills, and project rules.
```

### Audit only (observe-only mode)

```text
Use project-workflow in observe-only mode. Audit this repository and report its
Git state, detected platform, project type, branch strategy, workflow files,
required skills, and any risks. Do not modify anything.
```

### Initialize a repository

```text
Use project-workflow to bootstrap this repo with the standard workflow.
Preserve existing files and ask before Spec Kit init.
Copy .ai-workflow.yml and .ai-skills.json templates and ask me to review them.
```

### Continue durable work

```text
Use project-workflow to continue from PROGRESS.md and the active spec.
Preserve unrelated changes and update durable state after meaningful progress.
```

### Review status

```text
Use project-workflow to review current project status, active specs, progress,
decisions, blockers, and the recommended next step. Make no file changes.
```

### Close a session

```text
Use project-workflow to verify the work, update PROGRESS.md and any durable
decisions, then close with the full structured handoff and NEXT STEP block.
```

### Create a Spec Kit plan

```text
Use project-workflow to detect the existing Spec Kit setup, clarify the
requested feature, and create its plan and tasks. Ask before installing or
initializing anything missing.
```

### Check Git Flow compliance

```text
Use project-workflow to verify that the current branch and workspace comply
with our Git Flow policy. Run guard-git-flow.ps1 and report the result.
```

### WordPress project start

```text
Use project-workflow to start safely in this WordPress project.
Detect whether wp-guard is installed and report before proceeding.
```

---

## Guard scripts (run directly)

```powershell
# Full project audit (no modifications)
.\scripts\audit-project-workflow.ps1

# Validate Git Flow branch rules
.\scripts\guard-git-flow.ps1

# Pre-edit safety check
.\scripts\guard-before-edit.ps1

# Pre-merge / pre-release check
.\scripts\guard-before-merge.ps1
```

---

## Bootstrap scripts

```powershell
# Bootstrap missing workflow files (safe, skips existing)
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project

# Audit only — no changes
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -Mode observe-only

# Include .ai-workflow.yml and .ai-skills.json templates
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -IncludeConfig

# Overwrite existing files (use with caution)
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -Force
```
