[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot
try {
    & npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy
    if ($LASTEXITCODE -ne 0) { throw "Global skill installation failed with exit code $LASTEXITCODE." }

    & npx -y skills ls -g
    if ($LASTEXITCODE -ne 0) { throw "Global skill listing failed with exit code $LASTEXITCODE." }
}
finally {
    Pop-Location
}

