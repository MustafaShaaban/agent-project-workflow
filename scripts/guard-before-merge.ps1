#Requires -Version 5.1
<#
.SYNOPSIS
    Pre-merge / pre-release safety guard for AI agents.

.DESCRIPTION
    Validates branch, workflow files, required docs, verification status,
    and progress tracking before a merge or release. Makes no modifications.

.PARAMETER ProjectPath
    Path to the project root. Defaults to current directory.

.EXAMPLE
    .\guard-before-merge.ps1
    .\guard-before-merge.ps1 -ProjectPath C:\path\to\project
#>
[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath($ProjectPath)
$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Write-Pass { param([string]$Msg) Write-Host "  [PASS] $Msg" -ForegroundColor Green }
function Write-Fail { param([string]$Msg) Write-Host "  [FAIL] $Msg" -ForegroundColor Red; $script:failures.Add($Msg) }
function Write-Warn { param([string]$Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow; $script:warnings.Add($Msg) }
function Write-Info { param([string]$Msg) Write-Host "  [INFO] $Msg" -ForegroundColor Gray }

Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host " Pre-Merge / Pre-Release Guard" -ForegroundColor Cyan
Write-Host " Project: $root" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# ─── Read config ───────────────────────────────────────────────────────────
$configPath = Join-Path $root '.ai-workflow.yml'
$profile = 'standard'
$strategy = 'github-flow'
$productionBranch = 'main'
$integrationBranch = 'develop'
$requireVerification = $true

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw
    if ($config -match 'profile:\s*(\S+)') { $profile = $Matches[1] }
    if ($config -match 'strategy:\s*(\S+)') { $strategy = $Matches[1] }
    if ($config -match 'production_branch:\s*(\S+)') { $productionBranch = $Matches[1] }
    if ($config -match 'integration_branch:\s*(\S+)') { $integrationBranch = $Matches[1] }
    if ($config -match 'require_verification_before_handoff:\s*(true|false)') {
        $requireVerification = ($Matches[1] -eq 'true')
    }
    Write-Info "Profile: $profile | Strategy: $strategy"
}

# ─── Git state ─────────────────────────────────────────────────────────────
Write-Host "`n--- Git State ---" -ForegroundColor Cyan

if (-not (Test-Path (Join-Path $root '.git'))) {
    Write-Fail "Not a Git repository"
    Write-Host "`n[RESULT] BLOCKED" -ForegroundColor Red
    exit 1
}

Push-Location $root
$currentBranch = (git branch --show-current 2>$null).Trim()
$status = git status --short 2>$null
Pop-Location

Write-Info "Current branch: $currentBranch"

# ─── Branch must be a work branch, not production ──────────────────────────
Write-Host "`n--- Source Branch ---" -ForegroundColor Cyan

$protectedBranches = @($productionBranch, 'master', 'main', 'trunk') | Select-Object -Unique
if ($currentBranch -in $protectedBranches) {
    Write-Warn "Merging FROM a protected branch ($currentBranch). Ensure this is a hotfix merge-back or deliberate release step."
} else {
    Write-Pass "Source branch '$currentBranch' is a work branch"
}

# ─── Worktree clean ────────────────────────────────────────────────────────
Write-Host "`n--- Worktree Cleanliness ---" -ForegroundColor Cyan

if ($status) {
    Write-Fail "Worktree is dirty. Commit, stash, or discard all changes before merging:`n$($status -join "`n")"
} else {
    Write-Pass "Worktree is clean"
}

# ─── Hidden worktrees ──────────────────────────────────────────────────────
Write-Host "`n--- Worktrees ---" -ForegroundColor Cyan

Push-Location $root
$worktrees = @(git worktree list 2>$null)
Pop-Location

if ($worktrees | Where-Object { $_ -match '\.worktrees/' }) {
    Write-Warn "Hidden worktrees detected. Confirm all work is on the intended worktree before merging."
} else {
    Write-Pass "No hidden worktrees"
}

# ─── Required docs ─────────────────────────────────────────────────────────
Write-Host "`n--- Required Documentation ---" -ForegroundColor Cyan

$docsRequired = @()
if ($profile -in @('standard', 'strict', 'enterprise')) {
    $docsRequired = @('PROGRESS.md', 'DECISIONS.md')
}
if ($profile -in @('strict', 'enterprise')) {
    $docsRequired += 'AGENTS.md'
}

foreach ($doc in $docsRequired) {
    $path = Join-Path $root $doc
    if (Test-Path $path) {
        $content = Get-Content $path -Raw -ErrorAction SilentlyContinue
        if ($content -match 'Not started|YYYY-MM-DD|\[branch-name\]') {
            Write-Warn "$doc exists but appears to contain placeholder content - update before merging"
        } else {
            Write-Pass "$doc present and appears updated"
        }
    } else {
        if ($profile -in @('strict', 'enterprise')) {
            Write-Fail "$doc missing (required by $profile profile)"
        } else {
            Write-Warn "$doc missing - consider adding it before merging"
        }
    }
}

# ─── Verification ──────────────────────────────────────────────────────────
Write-Host "`n--- Verification ---" -ForegroundColor Cyan

if ($requireVerification) {
    Write-Warn "Verification required before merge. Confirm that:"
    Write-Info "  - Relevant tests were run and passed"
    Write-Info "  - Guard scripts ran clean (guard-before-edit.ps1, guard-git-flow.ps1)"
    Write-Info "  - PROGRESS.md reflects current state"
    Write-Info "  (This guard cannot auto-run your tests; confirm manually)"
} else {
    Write-Info "Verification not enforced by config"
}

# ─── Git Flow merge-back reminder ──────────────────────────────────────────
Write-Host "`n--- Git Flow Merge-Back ---" -ForegroundColor Cyan

if ($strategy -eq 'git-flow') {
    if ($currentBranch -match '^release/') {
        Write-Warn "Release branch - remember to merge into BOTH '$productionBranch' AND '$integrationBranch' after release"
    } elseif ($currentBranch -match '^hotfix/') {
        Write-Warn "Hotfix branch - remember to merge into BOTH '$productionBranch' AND '$integrationBranch' after fix"
    } else {
        Write-Pass "No special merge-back requirements for this branch type"
    }
} else {
    Write-Info "Not using Git Flow - merge-back check skipped"
}

# ─── Result ────────────────────────────────────────────────────────────────
Write-Host "`n====================================`n" -ForegroundColor Cyan

if ($failures.Count -gt 0) {
    Write-Host "[RESULT] BLOCKED - Resolve before merging" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
    Write-Host ""
    exit 1
} elseif ($warnings.Count -gt 0) {
    Write-Host "[RESULT] PROCEED WITH CAUTION" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
    Write-Host ""
    exit 0
} else {
    Write-Host "[RESULT] CLEAR - Safe to merge/release" -ForegroundColor Green
    Write-Host ""
    exit 0
}
