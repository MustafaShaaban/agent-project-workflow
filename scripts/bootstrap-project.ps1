[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetPath,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$TemplateRoot = Join-Path $RepoRoot 'templates'
$ResolvedTarget = [System.IO.Path]::GetFullPath($TargetPath)

if (-not (Test-Path -LiteralPath $ResolvedTarget)) {
    New-Item -ItemType Directory -Path $ResolvedTarget -Force | Out-Null
    Write-Host "Created target directory: $ResolvedTarget"
}

$Files = @(
    'AGENTS.md',
    'CLAUDE.md',
    'PROJECT-WORKING-GUIDE.md',
    'PROGRESS.md',
    'DECISIONS.md',
    'specs\constitution.md'
)

foreach ($RelativePath in $Files) {
    $Source = Join-Path $TemplateRoot $RelativePath
    $Destination = Join-Path $ResolvedTarget $RelativePath
    $DestinationDirectory = Split-Path -Parent $Destination

    if (-not (Test-Path -LiteralPath $DestinationDirectory)) {
        New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Write-Host "SKIPPED: $RelativePath (already exists; use -Force to overwrite)" -ForegroundColor Yellow
        continue
    }

    $Action = if (Test-Path -LiteralPath $Destination) { 'OVERWROTE' } else { 'CREATED' }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force:$Force
    Write-Host "${Action}: $RelativePath" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Spec Kit was not installed or initialized.'
Write-Host 'Recommended next commands (after owner approval):'
Write-Host '  specify integration list'
Write-Host '  specify init . --integration claude'
Write-Host '  specify init . --integration codex'
