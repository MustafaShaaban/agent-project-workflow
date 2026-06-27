# Bootstrap a project

The templates establish project-owned rules without selecting a language or framework.

## Automated bootstrap

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

Existing files are skipped. Use `-Force` only after reviewing them and deciding replacement is correct:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -Force
```

## Manual bootstrap

1. Copy `templates\AGENTS.md` to the project root and replace the project-purpose placeholder.
2. Copy `templates\CLAUDE.md` when the project uses Claude Code.
3. Copy and adapt `templates\PROJECT-WORKING-GUIDE.md`.
4. Create `PROGRESS.md` from the starter and record the actual branch and status.
5. Create `DECISIONS.md` from the starter.
6. Create `specs\constitution.md` from the generic constitution.
7. Commit the workflow files as project-owned documentation.

## Spec Kit

Bootstrap does not run Spec Kit. First inspect for `.specify`, existing specs, or spec commands. Ask the owner before installation or initialization, then run `specify integration list` to learn currently supported integration IDs.
