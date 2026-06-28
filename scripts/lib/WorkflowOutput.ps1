# WorkflowOutput.ps1
# Shared output formatting helpers for workflow scripts.
# Dot-source this file in other scripts: . (Join-Path $PSScriptRoot 'lib\WorkflowOutput.ps1')

function Write-WfPass   { param([string]$Msg) Write-Host "  [PASS] $Msg" -ForegroundColor Green }
function Write-WfFail   { param([string]$Msg) Write-Host "  [FAIL] $Msg" -ForegroundColor Red }
function Write-WfWarn   { param([string]$Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow }
function Write-WfInfo   { param([string]$Msg) Write-Host "  [INFO] $Msg" -ForegroundColor Gray }
function Write-WfMiss   { param([string]$Msg) Write-Host "  [MISSING] $Msg" -ForegroundColor DarkYellow }
function Write-WfRisk   { param([string]$Msg) Write-Host "  [RISK] $Msg" -ForegroundColor Red }
function Write-WfSection { param([string]$Title) Write-Host "`n=== $Title ===" -ForegroundColor Cyan }
function Write-WfHeader {
    param([string]$Title, [string]$Subtitle = '')
    Write-Host "`n$('=' * 38)" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    if ($Subtitle) { Write-Host " $Subtitle" -ForegroundColor Cyan }
    Write-Host "$('=' * 38)" -ForegroundColor Cyan
}

function Write-WfResult {
    param(
        [int]$FailCount,
        [int]$WarnCount,
        [string]$PassMessage = 'All checks passed',
        [string]$BlockedMessage = 'Resolve failures before proceeding'
    )
    Write-Host "`n$('=' * 38)`n" -ForegroundColor Cyan
    if ($FailCount -gt 0) {
        Write-Host "[RESULT] BLOCKED - $BlockedMessage" -ForegroundColor Red
    } elseif ($WarnCount -gt 0) {
        Write-Host "[RESULT] PROCEED WITH CAUTION" -ForegroundColor Yellow
    } else {
        Write-Host "[RESULT] PASS - $PassMessage" -ForegroundColor Green
    }
    Write-Host ""
}
