# Install the global skill

## Requirements

- Windows PowerShell or PowerShell 7
- Node.js with `npx` available
- A local clone of this repository

## Install for Claude Code and Codex

Run from the repository root:

```powershell
npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy
```

Or use:

```powershell
.\scripts\install-global.ps1
```

If Windows PowerShell blocks unsigned local scripts, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-global.ps1
```

The `--copy` option installs a standalone copy rather than linking the clone.

## Verify

```powershell
npx -y skills ls -g
```

Or:

```powershell
.\scripts\verify-install.ps1
```

Confirm `project-workflow` is listed for both Claude Code and Codex. Restart an already-running agent session if it does not refresh its skill inventory.

## Remove

```powershell
npx -y skills remove project-workflow --global --agent claude-code --agent codex
```

Or:

```powershell
.\scripts\remove-global.ps1
```

## Manual Windows cleanup

Use the CLI removal command first. If a failed or old installation remains, inspect these common locations and remove only the `project-workflow` directory:

```powershell
Get-ChildItem -Force "$HOME\.claude\skills"
Get-ChildItem -Force "$HOME\.codex\skills"
```

Typical paths are `%USERPROFILE%\.claude\skills\project-workflow` and `%USERPROFILE%\.codex\skills\project-workflow`. Actual paths can vary by agent version; do not delete an entire skills directory.
