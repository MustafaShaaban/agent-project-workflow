#Requires -Version 5.1
<#
.SYNOPSIS
    Audits a project directory for AI workflow readiness and compliance.

.DESCRIPTION
    Inspects a target project and reports on Git status, platform, CI, project type,
    branch strategy, workflow files, skill configs, and risks. Makes no modifications.

.PARAMETER TargetPath
    Path to the project root to audit. Defaults to the current directory.

.PARAMETER OutputFormat
    Output format: Text (default, human-readable) or Json (machine-readable for CI use).

.EXAMPLE
    .\audit-project-workflow.ps1
    .\audit-project-workflow.ps1 -TargetPath C:\path\to\project
    .\audit-project-workflow.ps1 -TargetPath C:\path\to\project -OutputFormat Json
#>
[CmdletBinding()]
param(
    [string]$TargetPath = (Get-Location).Path,
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)
$jsonMode = $OutputFormat -eq 'Json'

$ErrorActionPreference = 'Stop'
$target = [System.IO.Path]::GetFullPath($TargetPath)

# Collected audit data for JSON output
$auditData = @{
    status               = 'pass'
    project_root         = $target
    platform             = 'unknown'
    project_type         = 'unknown'
    branch               = ''
    profile              = 'standard'
    branching_strategy   = 'unknown'
    skills_required      = @('project-workflow')
    skills_missing       = @()
    risks                = @()
    recommended_next_step = ''
}

function Write-Section { param([string]$Title) if (-not $jsonMode) { Write-Host "`n=== $Title ===" -ForegroundColor Cyan } }
function Write-Ok    { param([string]$Msg) if (-not $jsonMode) { Write-Host "  [OK]      $Msg" -ForegroundColor Green } }
function Write-Warn  { param([string]$Msg) if (-not $jsonMode) { Write-Host "  [WARN]    $Msg" -ForegroundColor Yellow } }
function Write-Miss  { param([string]$Msg) if (-not $jsonMode) { Write-Host "  [MISSING] $Msg" -ForegroundColor DarkYellow } }
function Write-Info  { param([string]$Msg) if (-not $jsonMode) { Write-Host "  [INFO]    $Msg" -ForegroundColor Gray } }
function Write-Risk  { param([string]$Msg) if (-not $jsonMode) { Write-Host "  [RISK]    $Msg" -ForegroundColor Red } }

$risks = [System.Collections.Generic.List[string]]::new()
$nextStep = $null

if (-not $jsonMode) {
    Write-Host "`n=====================================" -ForegroundColor Cyan
    Write-Host " AI Workflow Audit" -ForegroundColor Cyan
    Write-Host " Target: $target" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
}

# ─── Git ───────────────────────────────────────────────────────────────────
Write-Section "GIT"

$gitInit = Test-Path (Join-Path $target '.git')
if ($gitInit) {
    Write-Ok "Git initialized"
} else {
    Write-Risk "Git not initialized"
    $risks.Add("Git is not initialized. Branching safety, worktree checks, and most guards will not function.")
    $nextStep = "Run 'git init' and make an initial commit before bootstrapping the workflow."
}

$gitRoot = $null
if ($gitInit) {
    try {
        Push-Location $target
        $gitRoot = (git rev-parse --show-toplevel 2>$null).Trim()
        $currentBranch = (git branch --show-current 2>$null).Trim()
        $remotes = git remote -v 2>$null
        $worktrees = git worktree list 2>$null
        Pop-Location

        Write-Info "Git root:       $gitRoot"
        Write-Info "Current branch: $(if ($currentBranch) { $currentBranch } else { '(detached HEAD)' })"

        if ($remotes) {
            foreach ($r in $remotes) { Write-Info "Remote: $r" }
        } else {
            Write-Warn "No remotes configured"
        }

        if ($worktrees.Count -gt 1) {
            Write-Warn "Multiple worktrees detected:"
            foreach ($wt in $worktrees) { Write-Info "  $wt" }
        } else {
            Write-Ok "Single worktree"
        }
    } catch {
        Write-Risk "Git command failed: $_"
        $risks.Add("Git commands failed. Repository may be incomplete or corrupt.")
    }
}

# ─── Platform detection ────────────────────────────────────────────────────
Write-Section "PLATFORM"

$platform = "generic-git"
$remoteUrl = if ($gitInit) { git -C $target remote get-url origin 2>$null } else { "" }

if ($remoteUrl -match "github\.com") {
    $platform = "github"
    Write-Ok "Detected: GitHub (remote URL)"
} elseif ($remoteUrl -match "dev\.azure\.com|visualstudio\.com") {
    $platform = "azure-devops"
    Write-Ok "Detected: Azure DevOps (remote URL)"
} elseif (Test-Path (Join-Path $target '.github')) {
    $platform = "github"
    Write-Ok "Detected: GitHub (.github/ directory)"
} elseif ((Test-Path (Join-Path $target 'azure-pipelines.yml')) -or (Test-Path (Join-Path $target '.azure'))) {
    $platform = "azure-devops"
    Write-Ok "Detected: Azure DevOps (azure-pipelines.yml or .azure/)"
} else {
    Write-Info "Detected: Generic Git (no GitHub/Azure DevOps indicators)"
}

# ─── CI detection ──────────────────────────────────────────────────────────
Write-Section "CI"

$ciDetected = $false
if (Test-Path (Join-Path $target '.github\workflows')) {
    Write-Ok "GitHub Actions (.github/workflows/)"
    $ciDetected = $true
}
if ((Test-Path (Join-Path $target 'azure-pipelines.yml')) -or (Test-Path (Join-Path $target '.azure\pipelines'))) {
    Write-Ok "Azure Pipelines"
    $ciDetected = $true
}
if (Test-Path (Join-Path $target 'Jenkinsfile')) {
    Write-Ok "Jenkins (Jenkinsfile)"
    $ciDetected = $true
}
if (Test-Path (Join-Path $target '.circleci')) {
    Write-Ok "CircleCI (.circleci/)"
    $ciDetected = $true
}
if (Test-Path (Join-Path $target '.travis.yml')) {
    Write-Ok "Travis CI"
    $ciDetected = $true
}
if (-not $ciDetected) {
    Write-Warn "No CI configuration detected"
}

# ─── Project type detection ────────────────────────────────────────────────
Write-Section "PROJECT TYPE"

$projectType = "unknown"
$isWordPress = $false

$wpIndicators = @(
    'wp-config.php', 'wp-config-sample.php', 'wp-login.php',
    'wp-blog-header.php', 'wp-content'
)
foreach ($indicator in $wpIndicators) {
    if (Test-Path (Join-Path $target $indicator)) {
        $isWordPress = $true
        break
    }
}
if (-not $isWordPress -and (Test-Path (Join-Path $target 'composer.json'))) {
    $composer = Get-Content (Join-Path $target 'composer.json') -Raw -ErrorAction SilentlyContinue
    if ($composer -match 'johnpbloch/wordpress|roots/bedrock|wpackagist') {
        $isWordPress = $true
    }
}
if (-not $isWordPress -and (Test-Path (Join-Path $target 'package.json'))) {
    $pkg = Get-Content (Join-Path $target 'package.json') -Raw -ErrorAction SilentlyContinue
    if ($pkg -match '"@wordpress/') {
        $isWordPress = $true
    }
}

if ($isWordPress) {
    $projectType = "wordpress"
    Write-Ok "WordPress project detected"
} elseif (Test-Path (Join-Path $target 'artisan')) {
    $projectType = "laravel"
    Write-Ok "Laravel project detected (artisan)"
} elseif (Test-Path (Join-Path $target 'package.json')) {
    $pkg = Get-Content (Join-Path $target 'package.json') -Raw -ErrorAction SilentlyContinue
    if ($pkg -match '"react"') { $projectType = "react"; Write-Ok "React project (package.json)" }
    elseif ($pkg -match '"vue"') { $projectType = "vue"; Write-Ok "Vue project (package.json)" }
    elseif ($pkg -match '"svelte"') { $projectType = "svelte"; Write-Ok "Svelte project (package.json)" }
    elseif ($pkg -match '"next"') { $projectType = "nextjs"; Write-Ok "Next.js project (package.json)" }
    else { $projectType = "js/ts"; Write-Ok "JavaScript/TypeScript project (package.json)" }
} elseif (Test-Path (Join-Path $target 'composer.json')) {
    $projectType = "php"
    Write-Ok "PHP project (composer.json)"
} elseif ((Test-Path (Join-Path $target '*.sln')) -or (Test-Path (Join-Path $target '*.csproj'))) {
    $projectType = "dotnet"
    Write-Ok ".NET project"
} elseif (Test-Path (Join-Path $target 'requirements.txt')) {
    $projectType = "python"
    Write-Ok "Python project (requirements.txt)"
} else {
    Write-Info "Project type: unknown (no recognizable indicators)"
}

# ─── Branch strategy detection ─────────────────────────────────────────────
Write-Section "BRANCH STRATEGY"

$branchStrategy = "unknown"
if ($gitInit) {
    try {
        Push-Location $target
        $allBranches = git branch -a 2>$null
        Pop-Location

        $hasDevelop = $allBranches -match '\bdevelop\b'
        $hasRelease = $allBranches -match 'release/'
        $hasHotfix  = $allBranches -match 'hotfix/'

        if ($hasDevelop -and ($hasRelease -or $hasHotfix)) {
            $branchStrategy = "git-flow"
            Write-Ok "Git Flow detected (develop + release/hotfix branches)"
        } elseif ($hasDevelop) {
            $branchStrategy = "git-flow-partial"
            Write-Warn "Partial Git Flow (develop exists but no release/hotfix branches yet)"
        } else {
            $branchStrategy = "github-flow"
            Write-Info "Likely GitHub Flow (no develop branch)"
        }
    } catch {
        Write-Warn "Could not inspect branches: $_"
    }
}

# ─── Production/integration branches ──────────────────────────────────────
Write-Section "KEY BRANCHES"

if ($gitInit) {
    Push-Location $target
    $allBranches = git branch -a 2>$null
    Pop-Location

    foreach ($pb in @('main', 'master', 'trunk')) {
        if ($allBranches -match "\b$pb\b") {
            Write-Ok "Production branch '$pb' exists"
        }
    }
    if ($allBranches -match '\bdevelop\b') {
        Write-Ok "Integration branch 'develop' exists"
    } else {
        Write-Info "No 'develop' branch (expected for Git Flow, not needed for GitHub Flow)"
    }

    if ($currentBranch -match '^(main|master|trunk|develop)$') {
        Write-Warn "Current branch is '$currentBranch' - implement on a feature/fix/chore branch"
        $risks.Add("Agent is on branch '$currentBranch'. Implementing directly on this branch is unsafe.")
    } else {
        Write-Ok "Current branch '$currentBranch' appears to be a work branch"
    }
}

# ─── Workflow files ────────────────────────────────────────────────────────
Write-Section "WORKFLOW FILES"

$workflowFiles = @{
    'AGENTS.md'                 = 'Agent instructions'
    'CLAUDE.md'                 = 'Claude Code entry point'
    'PROJECT-WORKING-GUIDE.md'  = 'Working guide'
    'PROGRESS.md'               = 'Progress tracking'
    'DECISIONS.md'              = 'Decision log'
    'specs/constitution.md'     = 'Project constitution'
}
foreach ($file in $workflowFiles.Keys) {
    $path = Join-Path $target $file
    if (Test-Path $path) {
        Write-Ok "$file ($($workflowFiles[$file]))"
    } else {
        Write-Miss "$file ($($workflowFiles[$file]))"
    }
}

# ─── AI config files ───────────────────────────────────────────────────────
Write-Section "AI CONFIG FILES"

if (Test-Path (Join-Path $target '.ai-workflow.yml')) {
    Write-Ok ".ai-workflow.yml found"
    try {
        $config = Get-Content (Join-Path $target '.ai-workflow.yml') -Raw
        if ($config -match 'profile:\s*(\S+)') { Write-Info "  Profile: $($Matches[1])" }
        if ($config -match 'strategy:\s*(\S+)') { Write-Info "  Branching: $($Matches[1])" }
        if ($config -match 'provider:\s*(\S+)') { Write-Info "  Platform: $($Matches[1])" }
    } catch {}
} else {
    Write-Miss ".ai-workflow.yml (project AI config not set; defaults will be used)"
}

if (Test-Path (Join-Path $target '.ai-skills.json')) {
    Write-Ok ".ai-skills.json found"
} else {
    Write-Miss ".ai-skills.json (skills config not set)"
}

# ─── WordPress / wp-guard ──────────────────────────────────────────────────
Write-Section "WORDPRESS / WP-GUARD"

if ($isWordPress) {
    Write-Warn "WordPress project - wp-guard skill is required"
    $risks.Add("WordPress project detected. The 'wp-guard' skill must be installed before proceeding. wp-guard prevents unsafe modifications to WordPress core, plugins, and themes.")
    $nextStep = "Install the 'wp-guard' skill, then re-run this audit."
} else {
    Write-Ok "Not a WordPress project - wp-guard not required"
}

# ─── Required skills ───────────────────────────────────────────────────────
Write-Section "SKILL DOCUMENTATION"

if (Test-Path (Join-Path $target '.ai-skills.json')) {
    Write-Ok "Skill config documented in .ai-skills.json"
} else {
    Write-Info "No .ai-skills.json - skill requirements not formally documented"
}

# ─── Collect JSON data at detection completion ─────────────────────────────
$auditData.platform            = $platform
$auditData.project_type        = $projectType
$auditData.branch              = if ($currentBranch) { $currentBranch } else { '' }
$auditData.branching_strategy  = $branchStrategy
$auditData.risks               = $risks.ToArray()
if ($isWordPress) { $auditData.skills_missing = @('wp-guard') }

$resolvedNextStep = if ($nextStep) { $nextStep } `
    elseif (-not (Test-Path (Join-Path $target 'AGENTS.md'))) { 'Run bootstrap-project.ps1 to add missing workflow files.' } `
    elseif (-not (Test-Path (Join-Path $target '.ai-workflow.yml'))) { 'Copy templates/.ai-workflow.yml to the project root and adjust for this project.' } `
    elseif ($isWordPress) { "Install the 'wp-guard' skill before continuing work on this WordPress project." } `
    else { 'Audit complete. Project appears ready for AI workflow use.' }
$auditData.recommended_next_step = $resolvedNextStep
$auditData.status = if ($risks.Count -gt 0) { 'warn' } else { 'pass' }

# ─── Risks summary ─────────────────────────────────────────────────────────
Write-Section "RISKS"

if ($risks.Count -eq 0) {
    Write-Ok "No critical risks detected"
} else {
    foreach ($r in $risks) { Write-Risk $r }
}

# ─── Recommended next step ─────────────────────────────────────────────────
Write-Section "RECOMMENDED NEXT STEP"

if (-not $jsonMode) {
    if ($resolvedNextStep -eq 'Audit complete. Project appears ready for AI workflow use.') {
        Write-Host "  $resolvedNextStep" -ForegroundColor Green
    } else {
        Write-Host "  $resolvedNextStep" -ForegroundColor Yellow
    }
    Write-Host ""
}

# ─── JSON output ──────────────────────────────────────────────────────────
if ($jsonMode) {
    $auditData | ConvertTo-Json -Depth 5
}
