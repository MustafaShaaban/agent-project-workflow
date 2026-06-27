[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

& npx -y skills remove project-workflow --global --agent claude-code --agent codex
if ($LASTEXITCODE -ne 0) { throw "Global skill removal failed with exit code $LASTEXITCODE." }

& npx -y skills ls -g
if ($LASTEXITCODE -ne 0) { throw "Global skill listing failed with exit code $LASTEXITCODE." }

