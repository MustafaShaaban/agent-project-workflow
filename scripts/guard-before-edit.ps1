#Requires -Version 5.1
<#
.SYNOPSIS
    Pre-edit safety guard for AI agents.

.DESCRIPTION
    Verifies Git root, branch, worktree, workflow files, and skills config
    before any file edits. Makes no modifications.

.PARAMETER ProjectPath
    Path to the project root. Defaults to current directory.

.EXAMPLE
    .\guard-before-edit.ps1
    .\guard-before-edit.ps1 -ProjectPath C:\path\to\project
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
Write-Host " Pre-Edit Guard" -ForegroundColor Cyan
Write-Host " Project: $root" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# ─── Git root ──────────────────────────────────────────────────────────────
Write-Host "`n--- Git Root ---" -ForegroundColor Cyan

if (-not (Test-Path (Join-Path $root '.git'))) {
    Write-Fail "Not a Git repository at $root"
    Write-Host "`n[RESULT] BLOCKED" -ForegroundColor Red
    exit 1
}

Push-Location $root
$gitRoot = (git rev-parse --show-toplevel 2>$null).Trim() -replace '/', '\'
Pop-Location
$resolvedRoot = [System.IO.Path]::GetFullPath($root) -replace '/', '\'

if ($gitRoot -ne $resolvedRoot) {
    Write-Warn "Working directory $resolvedRoot is not the Git root $gitRoot. Working from Git root recommended."
} else {
    Write-Pass "Working directory matches Git root"
}

# ─── Branch ────────────────────────────────────────────────────────────────
Write-Host "`n--- Branch ---" -ForegroundColor Cyan

Push-Location $root
$currentBranch = (git branch --show-current 2>$null).Trim()
Pop-Location

Write-Info "Current branch: $currentBranch"

if (-not $currentBranch) {
    Write-Fail "Detached HEAD. Checkout a named branch before editing."
}

$productionBranch = 'main'
$configPath = Join-Path $root '.ai-workflow.yml'
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw
    if ($config -match 'production_branch:\s*(\S+)') { $productionBranch = $Matches[1] }
}

$protectedBranches = @($productionBranch, 'master', 'main', 'trunk') | Select-Object -Unique
if ($currentBranch -in $protectedBranches) {
    Write-Fail "Current branch '$currentBranch' is a protected branch. Create a feature/fix/chore branch before editing."
} else {
    Write-Pass "Branch '$currentBranch' is not a protected production branch"
}

# ─── Worktree ──────────────────────────────────────────────────────────────
Write-Host "`n--- Worktree ---" -ForegroundColor Cyan

Push-Location $root
$worktrees = @(git worktree list 2>$null)
Pop-Location

if ($worktrees.Count -gt 1) {
    Write-Warn "Multiple worktrees detected ($($worktrees.Count)). Confirm you are in the intended one:"
    foreach ($wt in $worktrees) { Write-Info "  $wt" }
} else {
    Write-Pass "Single worktree - no conflict risk"
}

$unexpectedWorktrees = $worktrees | Where-Object { $_ -match '\.worktrees/' }
if ($unexpectedWorktrees) {
    Write-Fail "Hidden worktrees detected (.worktrees/). These require explicit owner approval."
}

# ─── Worktree cleanliness ──────────────────────────────────────────────────
Write-Host "`n--- Worktree Status ---" -ForegroundColor Cyan

$requireClean = $false
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw
    if ($config -match 'require_clean_worktree:\s*(true|false)') {
        $requireClean = ($Matches[1] -eq 'true')
    }
}

Push-Location $root
$status = git status --short 2>$null
Pop-Location

if ($status) {
    if ($requireClean) {
        Write-Fail "Worktree is dirty and require_clean_worktree is true:`n$($status -join "`n")"
    } else {
        Write-Warn "Worktree has uncommitted changes. Preserve existing work; do not discard."
        foreach ($s in $status) { Write-Info "  $s" }
    }
} else {
    Write-Pass "Worktree is clean"
}

# ─── Required workflow files ────────────────────────────────────────────────
Write-Host "`n--- Required Workflow Files ---" -ForegroundColor Cyan

$profile = 'standard'
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw
    if ($config -match 'profile:\s*(\S+)') { $profile = $Matches[1] }
}

$requiredFiles = @()
$optionalFiles = @('AGENTS.md', 'CLAUDE.md', 'PROJECT-WORKING-GUIDE.md', 'specs/constitution.md')

if ($profile -in @('standard', 'strict', 'enterprise')) {
    $requiredFiles = @('PROGRESS.md', 'DECISIONS.md')
}
if ($profile -in @('strict', 'enterprise')) {
    $requiredFiles += 'AGENTS.md'
}

foreach ($f in $requiredFiles) {
    if (Test-Path (Join-Path $root $f)) {
        Write-Pass "$f exists"
    } else {
        Write-Fail "$f is required by the '$profile' profile but is missing. Run bootstrap-project.ps1 to create it."
    }
}
foreach ($f in $optionalFiles) {
    if ($f -notin $requiredFiles) {
        if (Test-Path (Join-Path $root $f)) {
            Write-Ok "$f exists (optional)"
        } else {
            Write-Info "$f missing (optional)"
        }
    }
}

# ─── Skills config ─────────────────────────────────────────────────────────
Write-Host "`n--- Skills Config ---" -ForegroundColor Cyan

if (Test-Path (Join-Path $root '.ai-skills.json')) {
    Write-Pass ".ai-skills.json found"
} else {
    Write-Info ".ai-skills.json not present (optional but recommended)"
}

# ─── Result ────────────────────────────────────────────────────────────────
Write-Host "`n====================================`n" -ForegroundColor Cyan

if ($failures.Count -gt 0) {
    Write-Host "[RESULT] BLOCKED - Resolve failures before editing" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
    Write-Host ""
    exit 1
} elseif ($warnings.Count -gt 0) {
    Write-Host "[RESULT] PROCEED WITH CAUTION" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
    Write-Host ""
    exit 0
} else {
    Write-Host "[RESULT] CLEAR - Safe to proceed with edits" -ForegroundColor Green
    Write-Host ""
    exit 0
}
