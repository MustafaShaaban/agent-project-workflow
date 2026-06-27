# agent-project-workflow

`agent-project-workflow` is a reusable, safe-by-default workflow for software-project agents. It provides the global `project-workflow` skill, project starter templates, and Windows PowerShell helpers for installation and bootstrap.

The skill makes Claude Code and Codex detect the real Git root, read repository rules first, avoid unapproved worktrees, use Spec Kit when the project has adopted it, preserve durable progress, verify changes, and close real work with a useful handoff and `NEXT STEP`.

## Who should use it

Use this repository if you work with agents across multiple software projects and want consistent startup, planning, verification, and handoff behavior. The templates remain project-owned: once copied, repository instructions outrank the generic global routine.

## What it does not do

- It does not impose a framework, language, branching convention, or release process.
- It does not install or initialize Spec Kit without approval.
- It does not overwrite existing workflow files by default.
- It does not create hidden worktrees or discard local changes.

## Quick install

From Windows PowerShell in this repository:

```powershell
.\scripts\install-global.ps1
```

Equivalent command:

```powershell
npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy
```

## Quick usage

In Claude Code or Codex, ask:

```text
Use project-workflow and start safely in this repo. Review current status before editing.
```

To initialize project-owned files safely:

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project
```

Or prompt the agent:

```text
Use project-workflow to initialize this repo with the standard workflow. Preserve existing files and ask before initializing Spec Kit.
```

See [installation](docs/install.md), [usage](docs/usage.md), and [project bootstrap](docs/project-bootstrap.md).

## Uninstall

```powershell
.\scripts\remove-global.ps1
```

