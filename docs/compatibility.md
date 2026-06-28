# Compatibility

## Script environment

All scripts in this repository (`scripts/*.ps1`) target **Windows PowerShell 5.1**
as the minimum supported version. They are also compatible with **PowerShell 7**
(tested on Windows; cross-platform behavior on Linux/macOS is not guaranteed for
every script — see notes below).

## Requirements

| Requirement | Purpose | Required for |
|-------------|---------|-------------|
| Windows PowerShell 5.1+ or PowerShell 7 | Running all `.ps1` scripts | All scripts |
| Git (any recent version) | Git root, branch, worktree detection | All guard/audit scripts |
| Node.js + `npx` | Skill install/remove/verify via `skills` CLI | `install-global.ps1`, `remove-global.ps1`, `verify-install.ps1` only |

Node.js is **not** required to use the skill itself or to run the guard/audit scripts.
It is only needed for the `scripts/install-global.ps1` (and equivalent) install flow.

## Agent compatibility

| Agent | Status |
|-------|--------|
| Claude Code (claude-code) | Supported (primary) |
| Codex | Supported |
| Other AI agents | The skill content is plain Markdown and can be read by any agent; platform-specific tool names may differ |

## Platform / hosting compatibility

| Platform | Status | Notes |
|----------|--------|-------|
| GitHub | Supported | Platform detection, PR templates, Actions CI examples |
| Azure DevOps | Supported | Platform detection, PR templates, Pipelines CI examples |
| Generic Git | Supported | Default when no specific platform is detected |
| Bitbucket | Partial | Detected as generic-git; no Bitbucket-specific templates |
| GitLab | Partial | Detected as generic-git; no GitLab-specific templates |
| Self-hosted Gitea/Forgejo | Partial | Detected as generic-git |

## Cross-platform (Linux/macOS) notes

The guard and audit scripts use:
- `[System.IO.Path]::GetFullPath()` — cross-platform
- `Push-Location` / `Pop-Location` — cross-platform
- `git` CLI commands — cross-platform (requires Git in PATH)
- Path separators: scripts use `Join-Path` which adapts to the OS, but some
  string patterns use `\` (backslash) which may not match on Linux/macOS paths

If you need to run these scripts on Linux/macOS via PowerShell 7:
- Test each script in your environment
- Report issues at the project repository

## Tested environments

- Windows 11 with Windows PowerShell 5.1
- Windows 11 with PowerShell 7

Linux/macOS PowerShell 7 and CI runner compatibility: not formally tested.
PRs and issue reports welcome.
