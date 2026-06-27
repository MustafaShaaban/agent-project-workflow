[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Output = & npx -y skills ls -g 2>&1
$ExitCode = $LASTEXITCODE
$Output | ForEach-Object { Write-Host $_ }

if ($ExitCode -ne 0) {
    Write-Error "Could not list global skills (exit code $ExitCode)."
    exit $ExitCode
}

if (($Output | Out-String) -match '(?im)project-workflow') {
    Write-Host 'SUCCESS: project-workflow is installed globally.' -ForegroundColor Green
    exit 0
}

Write-Error 'FAILURE: project-workflow was not found in the global skill list.'
exit 1

