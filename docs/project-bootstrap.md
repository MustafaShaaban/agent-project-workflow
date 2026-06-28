# Bootstrap a project

The templates establish project-owned rules without selecting a language or framework.

## Automated bootstrap (safe mode — skips existing files)

From this repository:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project
```

The script creates missing directories and copies:

- `AGENTS.md`
- `CLAUDE.md`
- `PROJECT-WORKING-GUIDE.md`
- `PROGRESS.md`
- `DECISIONS.md`
- `specs\constitution.md`

Existing files are always skipped in default mode. Add `-IncludeConfig` to also copy `.ai-workflow.yml` and `.ai-skills.json`:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -IncludeConfig
```

Use `-Force` only after reviewing existing files and deciding replacement is correct:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -Force
```

## Audit mode (observe-only — no file changes)

See what the bootstrap would do without actually doing it:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -Mode observe-only
```

For a full project audit, use the dedicated audit script:

```powershell
.\scripts\audit-project-workflow.ps1 -TargetPath C:\path\to\project
```

## Manual bootstrap

1. Copy `templates\AGENTS.md` to the project root and replace the project-purpose placeholder.
2. Copy `templates\CLAUDE.md` when the project uses Claude Code.
3. Copy and adapt `templates\PROJECT-WORKING-GUIDE.md`.
4. Create `PROGRESS.md` from the starter and record the actual branch and status.
5. Create `DECISIONS.md` from the starter.
6. Create `specs\constitution.md` from the generic constitution.
7. Copy `templates\.ai-workflow.yml` and adjust profile, platform, and branching strategy.
8. Copy `templates\.ai-skills.json` if you want machine-readable skill requirements.
9. Commit the workflow files as project-owned documentation.

## After bootstrap

Open each generated file and replace placeholder text (e.g. `[Describe the project's purpose]`)
with project-specific content before committing. Key files to edit:

- `AGENTS.md` — fill in the project purpose section
- `PROGRESS.md` — set the actual branch and initial status
- `.ai-workflow.yml` — set profile, branching strategy, and production branch

## Spec Kit

Bootstrap does not run Spec Kit. First inspect for `.specify`, existing specs, or spec commands.
Ask the owner before installation or initialization, then run `specify integration list`
to learn currently supported integration IDs.

## Platform-specific templates

After bootstrap, copy any needed platform templates manually:

```powershell
# GitHub
Copy-Item templates\github\pull_request_template.md .github\pull_request_template.md
Copy-Item templates\github\CODEOWNERS .github\CODEOWNERS

# Azure DevOps
New-Item -ItemType Directory -Force .azuredevops
Copy-Item templates\azure-devops\pull_request_template.md .azuredevops\pull_request_template.md
```

See [docs/github.md](github.md) and [docs/azure-devops.md](azure-devops.md) for platform-specific setup.
