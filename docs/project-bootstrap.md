# Bootstrap and initialization

Bootstrap prepares a folder or repository so future agents follow durable,
repository-local workflow rules. It does not build the application.

## Command meanings

| Command | Use it for | Writes by default? |
|---|---|---|
| `bootstrap-project.ps1` | Legacy safe copy of missing workflow files | Yes, but skips existing files |
| `init` | Initialize workflow files in the current target | No; use `-Apply` |
| `new` | Create a named starter, initialize Git, and apply workflow after type is explicit | Yes |
| `audit` | Inspect Git, platform, type, config, and skill readiness | No |
| `doctor` | Validate generated files, managed blocks, lock state, and next action | No |
| `upgrade` | Refresh workflow-owned managed blocks | No; use `-Apply` |
| `install-skills` | Review or install policy-approved skills | No unless `-ApprovedOnly` executes approved commands |

Use `new` when the directory itself does not exist and you want the tool to
create a named starter. Use `init` when you are already inside the intended
folder or repository.

## Safe bootstrap behavior

The default workflow is recommendation-first:

1. Detect the real root, Git state, project indicators, platform, and CI.
2. Preview with `-DryRun`.
3. Preserve every unmanaged owner file.
4. Write `.suggested.md` when an existing file has no valid managed block.
5. Ask before Spec Kit initialization or skill installation.
6. Run `doctor` and stop with the next setup or planning action.

Managed files use exact start/end markers. Upgrade changes only that block;
project-specific notes before or after it remain untouched.

## Empty folder without Git

`init -Type auto -DryRun` reports `Empty directory: Yes` and
`Git initialized: No`, asks whether to initialize Git, and writes nothing.
After Git approval, initialize it and rerun the preview. An explicit full
bootstrap may create workflow files without Git, but implementation still waits
until project type and required Spec Kit decisions are resolved.

## Empty Git repository

The workflow recognizes `.git` while still reporting the project directory as
empty. It asks for the archetype because no project files exist. Choose `generic`
when no framework has been selected.

## Unknown project type

Auto-detection never guesses. It reports the detected state, recommends
`generic`, lists alternatives, and provides the exact next command. Choose an
explicit type only after deciding what the project will be.

## Existing repository

The workflow detects the Git root, branch, remotes, worktrees, provider, CI,
project type, workflow files, skills, and Spec Kit status. Existing files are
preserved. Use `upgrade -DryRun` when managed files need refresh. If setup is
incomplete, the agent stops before application implementation.

## Examples

```powershell
# Preview the current folder.
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -DryRun

# Apply after reviewing the preview.
.\scripts\project-workflow.ps1 init -Type generic -Profile standard -Apply

# Read-only checks.
.\scripts\project-workflow.ps1 audit
.\scripts\project-workflow.ps1 doctor -Json

# Refresh only managed blocks.
.\scripts\project-workflow.ps1 upgrade -DryRun
.\scripts\project-workflow.ps1 upgrade -Apply

# Create a named starter.
.\scripts\project-workflow.ps1 new -ProjectName my-app -Type react -Profile standard
```
