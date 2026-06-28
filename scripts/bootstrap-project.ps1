#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstraps AI workflow files into a target project directory.

.DESCRIPTION
    Copies missing workflow files from the templates directory into the target project.
    Supports three modes:
      observe-only    - Audit and report without writing any files
      safe-bootstrap  - Add missing files only, skip existing (default)
      force           - Overwrite existing files (use with caution)

    Also copies .ai-workflow.yml and .ai-skills.json templates when not present.

.PARAMETER TargetPath
    Path to the target project. Required.

.PARAMETER Mode
    observe-only | safe-bootstrap (default)

.PARAMETER Force
    Overwrite existing workflow files.

.PARAMETER IncludeConfig
    Also copy .ai-workflow.yml and .ai-skills.json templates.

.EXAMPLE
    .\bootstrap-project.ps1 -TargetPath C:\path\to\project
    .\bootstrap-project.ps1 -TargetPath C:\path\to\project -Mode observe-only
    .\bootstrap-project.ps1 -TargetPath C:\path\to\project -IncludeConfig
    .\bootstrap-project.ps1 -TargetPath C:\path\to\project -Force
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetPath,

    [ValidateSet('observe-only', 'safe-bootstrap')]
    [string]$Mode = 'safe-bootstrap',

    [switch]$Force,

    [switch]$IncludeConfig
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$TemplateRoot = Join-Path $RepoRoot 'templates'
$ResolvedTarget = [System.IO.Path]::GetFullPath($TargetPath)

$observeOnly = $Mode -eq 'observe-only'
if ($observeOnly) {
    Write-Host "`n[MODE] observe-only - no files will be written`n" -ForegroundColor Cyan
} else {
    Write-Host "`n[MODE] safe-bootstrap - missing files will be added$( if ($Force) { ', existing files will be overwritten (-Force)' })`n" -ForegroundColor Cyan
}

if (-not (Test-Path -LiteralPath $ResolvedTarget)) {
    if ($observeOnly) {
        Write-Host "Target directory does not exist: $ResolvedTarget" -ForegroundColor Red
        exit 1
    }
    New-Item -ItemType Directory -Path $ResolvedTarget -Force | Out-Null
    Write-Host "Created target directory: $ResolvedTarget" -ForegroundColor Green
}

$WorkflowFiles = @(
    'AGENTS.md',
    'CLAUDE.md',
    'PROJECT-WORKING-GUIDE.md',
    'PROGRESS.md',
    'DECISIONS.md',
    'specs\constitution.md'
)

$ConfigFiles = @()
if ($IncludeConfig) {
    $ConfigFiles = @('.ai-workflow.yml', '.ai-skills.json')
}

$allFiles = $WorkflowFiles + $ConfigFiles

$added   = [System.Collections.Generic.List[string]]::new()
$skipped = [System.Collections.Generic.List[string]]::new()
$overwrote = [System.Collections.Generic.List[string]]::new()
$missing = [System.Collections.Generic.List[string]]::new()

foreach ($RelativePath in $allFiles) {
    $Source = Join-Path $TemplateRoot $RelativePath
    $Destination = Join-Path $ResolvedTarget $RelativePath
    $DestinationDirectory = Split-Path -Parent $Destination

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "SOURCE MISSING: $RelativePath (template not found at $Source)" -ForegroundColor Red
        continue
    }

    $exists = Test-Path -LiteralPath $Destination

    if ($observeOnly) {
        if ($exists) {
            Write-Host "EXISTS:   $RelativePath" -ForegroundColor Gray
        } else {
            Write-Host "MISSING:  $RelativePath (would be created)" -ForegroundColor Yellow
            $missing.Add($RelativePath)
        }
        continue
    }

    if (-not (Test-Path -LiteralPath $DestinationDirectory)) {
        New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null
    }

    if ($exists -and -not $Force) {
        Write-Host "SKIPPED:  $RelativePath (already exists; use -Force to overwrite)" -ForegroundColor Yellow
        $skipped.Add($RelativePath)
        continue
    }

    $action = if ($exists) { 'OVERWROTE' } else { 'CREATED  ' }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "${action}: $RelativePath" -ForegroundColor Green

    if ($exists) { $overwrote.Add($RelativePath) } else { $added.Add($RelativePath) }
}

Write-Host ""

if ($observeOnly) {
    Write-Host "Audit complete." -ForegroundColor Cyan
    if ($missing.Count -gt 0) {
        Write-Host "Files that would be created ($($missing.Count)):" -ForegroundColor Yellow
        foreach ($f in $missing) { Write-Host "  - $f" -ForegroundColor Yellow }
        Write-Host "`nRun without -Mode observe-only to apply these changes." -ForegroundColor Cyan
    } else {
        Write-Host "All workflow files are present. No changes needed." -ForegroundColor Green
    }
} else {
    if ($added.Count -gt 0) {
        Write-Host "Added $($added.Count) file(s)." -ForegroundColor Green
    }
    if ($skipped.Count -gt 0) {
        Write-Host "Skipped $($skipped.Count) existing file(s). Use -Force to overwrite." -ForegroundColor Yellow
    }
    if ($overwrote.Count -gt 0) {
        Write-Host "Overwrote $($overwrote.Count) file(s)." -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host 'Spec Kit was not installed or initialized.' -ForegroundColor Gray
    Write-Host 'Recommended next commands (after owner approval):' -ForegroundColor Gray
    Write-Host '  specify integration list' -ForegroundColor Gray
    Write-Host '  specify init . --integration claude' -ForegroundColor Gray
    Write-Host '  specify init . --integration codex' -ForegroundColor Gray
}
