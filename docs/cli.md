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

`-DryRun` is the safe default for `init` and `upgrade`. Files are written only
when `-Apply` is passed. `new` creates its new project directory and applies the
workflow by design.

If `-Type auto` cannot detect a reliable type, `init` stops without writing and prints a recommendation-first question with detected state, recommendation, rationale, alternatives, impact, question, and default.

## Commands

- `init`: configures workflow files in an existing project.
- `new`: creates a new directory, initializes Git, and applies the workflow.
- `audit`: read-only project readiness report.
- `doctor`: validates workflow files, managed blocks, lock file, skills, and automatic activation.
- `upgrade`: previews managed-block and lock updates by default; `upgrade -Apply` writes them.
- `install-skills`: prints approved install commands from `.ai-skills.json`.
- `install-skills -ApprovedOnly`: executes only commands marked `install_approved: true` that match the safe `npx -y skills add ...` allowlist; unapproved or unsupported commands remain manual.

## Safety

Existing files without managed blocks are not overwritten. The CLI writes a `.suggested.md` proposal instead. Generated workflow-owned sections use:

```markdown
<!-- agent-project-workflow:start -->
<!-- agent-project-workflow:end -->
```

`ManagedStart` and `ManagedEnd` are immutable, non-empty script constants. A
file is managed only when it contains exactly one start marker followed by
exactly one end marker. Upgrade replaces that inclusive block and preserves all
owner text before and after it. Missing, reversed, or duplicate markers are
treated as unmanaged and produce a suggestion rather than an overwrite.

Recommended next command after initialization:

```powershell
.\scripts\project-workflow.ps1 doctor
```

Machine-readable doctor output:

```powershell
.\scripts\project-workflow.ps1 doctor -Json
```

When `-SpecKit` is requested, the CLI preserves existing `.specify/` state. For a new setup it attempts `specify integration list`, falls back to `specify check` when listing requires an initialized project, initializes the first requested integration, installs additional integrations, and records the exact commands/status in `.agent-workflow.lock.json`.

Generated companion guard commands point to `amElnagdy/guard-skills`, but they
remain `install_approved: false`. The owner must review and approve that source
before `install-skills -ApprovedOnly` can execute those commands.
