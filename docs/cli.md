# CLI

`project-workflow` is exposed first as a PowerShell MVP:

```powershell
.\scripts\project-workflow.ps1 init -Type wordpress-site -Profile standard -SpecKit -Agents codex,claude-code -DryRun
.\scripts\project-workflow.ps1 init -Type wordpress-site -Profile standard -SpecKit -Agents codex,claude-code -Apply
.\scripts\project-workflow.ps1 audit
.\scripts\project-workflow.ps1 doctor
.\scripts\project-workflow.ps1 upgrade -Apply
.\scripts\project-workflow.ps1 install-skills -ApprovedOnly
```

`-DryRun` is the safe default for `init`. Files are written only when `-Apply` is passed.

## Commands

- `init`: configures workflow files in an existing project.
- `new`: creates a new directory, initializes Git, and applies the workflow.
- `audit`: read-only project readiness report.
- `doctor`: validates workflow files, managed blocks, lock file, skills, and automatic activation.
- `upgrade`: refreshes managed blocks and lock metadata.
- `install-skills`: prints approved install commands from `.ai-skills.json`.

## Safety

Existing files without managed blocks are not overwritten. The CLI writes a `.suggested.md` proposal instead. Generated workflow-owned sections use:

```markdown
<!-- agent-project-workflow:start -->
<!-- agent-project-workflow:end -->
```

Recommended next command after initialization:

```powershell
.\scripts\project-workflow.ps1 doctor
```

Machine-readable doctor output:

```powershell
.\scripts\project-workflow.ps1 doctor -Json
```

When `-SpecKit` is requested, the CLI preserves existing `.specify/` state. For a new setup it attempts `specify integration list`, falls back to `specify check` when listing requires an initialized project, initializes the first requested integration, installs additional integrations, and records the exact commands/status in `.agent-workflow.lock.json`.
