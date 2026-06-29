#Requires -Version 5.1
<#
.SYNOPSIS
    Validates Git Flow branch rules for AI agent safety.

.DESCRIPTION
    Reads .ai-workflow.yml (if present) for profile and branching config.
    Validates current branch, develop existence (when Git Flow), and branch naming.
    Produces clear PASS/FAIL output. Makes no modifications.

.PARAMETER ProjectPath
    Path to the project root. Defaults to current directory.

.PARAMETER OutputFormat
    Text (default) for human-readable output, or Json for machine-readable output.
    Json emits: status, project_root, platform, project_type, current_branch,
    profile, branching_strategy, risks, failures, warnings, recommended_next_step.

.EXAMPLE
    .\guard-git-flow.ps1
    .\guard-git-flow.ps1 -ProjectPath C:\path\to\project
    .\guard-git-flow.ps1 -ProjectPath C:\path\to\project -OutputFormat Json
#>
[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

$ErrorActionPreference = 'Stop'
$jsonMode = $OutputFormat -eq 'Json'
$root = [System.IO.Path]::GetFullPath($ProjectPath)
$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

# Shared detection helpers (platform / project type for JSON output).
. (Join-Path $PSScriptRoot 'lib\WorkflowDetection.ps1')

function Write-Pass { param([string]$Msg) if (-not $script:jsonMode) { Write-Host "  [PASS] $Msg" -ForegroundColor Green } }
function Write-Fail { param([string]$Msg) if (-not $script:jsonMode) { Write-Host "  [FAIL] $Msg" -ForegroundColor Red }; $script:failures.Add($Msg) }
function Write-Warn { param([string]$Msg) if (-not $script:jsonMode) { Write-Host "  [WARN] $Msg" -ForegroundColor Yellow }; $script:warnings.Add($Msg) }
function Write-Info { param([string]$Msg) if (-not $script:jsonMode) { Write-Host "  [INFO] $Msg" -ForegroundColor Gray } }
function Write-Head { param([string]$Msg) if (-not $script:jsonMode) { Write-Host $Msg -ForegroundColor Cyan } }

Write-Head "`n===================================="
Write-Head " Git Flow / Branch Guard"
Write-Head " Project: $root"
Write-Head "===================================="

# ─── Read .ai-workflow.yml ─────────────────────────────────────────────────
$configPath = Join-Path $root '.ai-workflow.yml'
$profile = 'standard'
$strategy = 'github-flow'
$productionBranch = 'main'
$integrationBranch = 'develop'
$allowedPatterns = @('feature/*', 'fix/*', 'chore/*', 'hotfix/*', 'release/*')
$neverImplementOnProduction = $true
$neverImplementOnIntegration = $true

if (Test-Path $configPath) {
    Write-Info "Reading .ai-workflow.yml"
    $config = Get-Content $configPath -Raw

    if ($config -match 'profile:\s*(\S+)') { $profile = $Matches[1] }
    if ($config -match 'strategy:\s*(\S+)') { $strategy = $Matches[1] }
    if ($config -match 'production_branch:\s*(\S+)') { $productionBranch = $Matches[1] }
    if ($config -match 'integration_branch:\s*(\S+)') { $integrationBranch = $Matches[1] }
    if ($config -match 'never_implement_on_integration:\s*(true|false)') {
        $neverImplementOnIntegration = ($Matches[1] -eq 'true')
    }

    Write-Info "Profile:            $profile"
    Write-Info "Branching strategy: $strategy"
    Write-Info "Production branch:  $productionBranch"
    if ($strategy -eq 'git-flow') {
        Write-Info "Integration branch: $integrationBranch"
    }
} else {
    Write-Info "No .ai-workflow.yml found - using default standard/github-flow settings"
}

# ─── Git checks ────────────────────────────────────────────────────────────
Write-Head "`n--- Git State ---"

if (-not (Test-Path (Join-Path $root '.git'))) {
    Write-Fail "Not a Git repository"
    if ($jsonMode) {
        [ordered]@{
            status                = 'blocked'
            project_root          = $root
            platform              = 'unknown'
            project_type          = 'unknown'
            current_branch        = ''
            profile               = $profile
            branching_strategy    = $strategy
            risks                 = @('Not a Git repository')
            failures              = $failures.ToArray()
            warnings              = $warnings.ToArray()
            recommended_next_step = 'Initialize a Git repository before running branch guards.'
        } | ConvertTo-Json -Depth 5
    } else {
        Write-Host "`n[RESULT] BLOCKED - Not a Git repository" -ForegroundColor Red
    }
    exit 1
}

Push-Location $root
try {
    $currentBranch = (git branch --show-current 2>$null).Trim()
    $allBranches = git branch -a 2>$null

    Write-Info "Current branch: $currentBranch"
} catch {
    Write-Fail "Git command failed: $_"
    Pop-Location
    exit 1
}
Pop-Location

# Detect platform and project type for machine-readable output.
$platform = Get-WfPlatform -ProjectRoot $root
$projectType = Get-WfProjectType -ProjectRoot $root

# ─── Production branch guard ───────────────────────────────────────────────
Write-Head "`n--- Production Branch Guard ---"

if ($currentBranch -eq $productionBranch) {
    if ($neverImplementOnProduction) {
        Write-Fail "Current branch is '$productionBranch' (production). Implementation is not allowed here. Create a feature/fix/hotfix branch."
    } else {
        Write-Warn "Current branch is '$productionBranch'. Confirm this is intentional."
    }
} else {
    Write-Pass "Not on production branch '$productionBranch'"
}

# ─── Integration branch guard (Git Flow only) ──────────────────────────────
Write-Head "`n--- Integration Branch Guard ---"

if ($strategy -eq 'git-flow') {
    if ($currentBranch -eq $integrationBranch) {
        if ($neverImplementOnIntegration) {
            Write-Fail "Current branch is '$integrationBranch' (integration). Feature work must start from '$integrationBranch' on a new branch, not directly on it."
        } else {
            Write-Warn "Current branch is '$integrationBranch'. Only small docs/workflow changes allowed. Confirm this is intentional."
        }
    } else {
        Write-Pass "Not on integration branch '$integrationBranch'"
    }
} else {
    Write-Info "Not using Git Flow - integration branch guard skipped"
}

# ─── Develop branch existence (Git Flow only) ──────────────────────────────
Write-Head "`n--- Develop Branch Existence ---"

if ($strategy -eq 'git-flow') {
    if ($allBranches -match "\b$integrationBranch\b") {
        Write-Pass "Integration branch '$integrationBranch' exists"
    } else {
        Write-Fail "Git Flow is configured but '$integrationBranch' branch does not exist. Create it from '$productionBranch' before starting work."
    }
} else {
    Write-Info "Not using Git Flow - develop existence check skipped"
}

# ─── Branch naming ─────────────────────────────────────────────────────────
Write-Head "`n--- Branch Naming ---"

$protectedBranches = @($productionBranch, 'master', 'main', 'trunk', $integrationBranch) | Select-Object -Unique

if ($currentBranch -notin $protectedBranches) {
    $matched = $false
    foreach ($pattern in $allowedPatterns) {
        $regex = '^' + ($pattern -replace '\*', '[^/]+') + '$'
        if ($currentBranch -match $regex) {
            $matched = $true
            break
        }
    }
    if ($matched) {
        Write-Pass "Branch '$currentBranch' matches allowed patterns"
    } else {
        if ($profile -in @('strict', 'enterprise')) {
            Write-Fail "Branch '$currentBranch' does not match any allowed pattern ($($allowedPatterns -join ', ')). Rename or recreate it following the naming convention."
        } else {
            Write-Warn "Branch '$currentBranch' does not match allowed patterns ($($allowedPatterns -join ', ')). Consider renaming."
        }
    }
} else {
    Write-Info "Branch '$currentBranch' is a protected/base branch - naming check skipped"
}

# ─── Git Flow source/target rules (Git Flow only) ──────────────────────────
Write-Head "`n--- Git Flow Source Rules ---"

if ($strategy -eq 'git-flow') {
    if ($currentBranch -match '^(feature|fix|chore)/') {
        Write-Info "Work branch '$currentBranch' should have been created from '$integrationBranch'"
        Write-Info "Verify with: git log --oneline $integrationBranch..$currentBranch"
    } elseif ($currentBranch -match '^release/') {
        Write-Info "Release branch should come from '$integrationBranch' and merge into '$productionBranch' and back into '$integrationBranch'"
    } elseif ($currentBranch -match '^hotfix/') {
        Write-Info "Hotfix branch should come from '$productionBranch' and merge into '$productionBranch' and back into '$integrationBranch'"
    }
    Write-Pass "Source/target rules noted (manual verification required)"
} else {
    Write-Info "Not using Git Flow - source/target check skipped"
}

# ─── Result ────────────────────────────────────────────────────────────────
if ($failures.Count -gt 0) {
    $status = 'blocked'
    $nextStep = "Resolve the $($failures.Count) failure(s) above before implementing on this branch."
} elseif ($warnings.Count -gt 0) {
    $status = 'warn'
    $nextStep = 'Review the warnings, then proceed if the branch state is intentional.'
} else {
    $status = 'pass'
    $nextStep = 'Branch rules satisfied. Safe to continue work on this branch.'
}

if ($jsonMode) {
    [ordered]@{
        status                = $status
        project_root          = $root
        platform              = $platform
        project_type          = $projectType
        current_branch        = if ($currentBranch) { $currentBranch } else { '' }
        profile               = $profile
        branching_strategy    = $strategy
        risks                 = $failures.ToArray()
        failures              = $failures.ToArray()
        warnings              = $warnings.ToArray()
        recommended_next_step = $nextStep
    } | ConvertTo-Json -Depth 5
    if ($status -eq 'blocked') { exit 1 } else { exit 0 }
}

Write-Host "`n====================================`n" -ForegroundColor Cyan

if ($status -eq 'blocked') {
    Write-Host "[RESULT] BLOCKED" -ForegroundColor Red
    Write-Host "Failures ($($failures.Count)):" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
    if ($warnings.Count -gt 0) {
        Write-Host "Warnings ($($warnings.Count)):" -ForegroundColor Yellow
        foreach ($w in $warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
    }
    Write-Host ""
    exit 1
} elseif ($status -eq 'warn') {
    Write-Host "[RESULT] PASS with warnings" -ForegroundColor Yellow
    Write-Host "Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
    Write-Host ""
    exit 0
} else {
    Write-Host "[RESULT] PASS - All branch checks passed" -ForegroundColor Green
    Write-Host ""
    exit 0
}
