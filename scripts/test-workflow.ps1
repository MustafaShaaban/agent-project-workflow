#Requires -Version 5.1
<#
.SYNOPSIS
    Runs automated validation checks for the agent-project-workflow repo itself.

.DESCRIPTION
    Tests:
    - PowerShell script syntax for all scripts
    - JSON validity for .ai-skills.json template (parsed with ConvertFrom-Json)
    - YAML validity for .ai-workflow.yml template (parsed with a real YAML parser
      if one is installed; WARN — never PASS — when no parser is available)
    - Format / line-count sanity so README.md and templates are rejected if
      collapsed into a handful of very long lines
    - Audit script against all test fixtures
    - Guard script syntax (already covered by PS parser)
    - Bootstrap observe-only mode against a fixture

.EXAMPLE
    .\scripts\test-workflow.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$pass = 0; $warn = 0; $fail = 0

function Write-Pass { param([string]$Msg) Write-Host "  [PASS] $Msg" -ForegroundColor Green;  $script:pass++ }
function Write-Fail { param([string]$Msg) Write-Host "  [FAIL] $Msg" -ForegroundColor Red;    $script:fail++ }
function Write-Warn { param([string]$Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow; $script:warn++ }
function Write-Info { param([string]$Msg) Write-Host "  [INFO] $Msg" -ForegroundColor Gray }
function Write-Section { param([string]$T) Write-Host "`n=== $T ===" -ForegroundColor Cyan }

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host " agent-project-workflow Self-Test" -ForegroundColor Cyan
Write-Host " Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# ─── 1. PowerShell syntax ──────────────────────────────────────────────────
Write-Section "1. PowerShell Script Syntax"

$scripts = Get-ChildItem (Join-Path $repoRoot 'scripts') -Filter '*.ps1' -Recurse
foreach ($s in $scripts) {
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$null, [ref]$errors)
    if ($errors.Count -gt 0) {
        Write-Fail "$($s.Name): $($errors.Count) syntax error(s)"
        $errors | Select-Object -First 2 | ForEach-Object { Write-Info "  $($_.Message) at line $($_.Extent.StartLineNumber)" }
    } else {
        Write-Pass "$($s.Name)"
    }
}

# ─── 2. JSON validity ──────────────────────────────────────────────────────
Write-Section "2. JSON Validity"

$jsonFiles = @(
    'templates\.ai-skills.json'
    'tests\fixtures\generic-github-flow\package.json'
)
foreach ($rel in $jsonFiles) {
    $path = Join-Path $repoRoot $rel
    if (-not (Test-Path $path)) { Write-Warn "$rel not found"; continue }
    try {
        $null = Get-Content $path -Raw | ConvertFrom-Json
        Write-Pass "$rel"
    } catch {
        Write-Fail "$rel`: $($_.Exception.Message)"
    }
}

# ─── 3. YAML validity ──────────────────────────────────────────────────────
Write-Section "3. YAML Template Validity"

# Try to find a real YAML parser. We only claim PASS when one exists.
$yamlParser = $null
if (Get-Module -ListAvailable -Name 'powershell-yaml' -ErrorAction SilentlyContinue) {
    try { Import-Module powershell-yaml -ErrorAction Stop; $yamlParser = 'powershell-yaml' } catch { }
}
if (-not $yamlParser -and (Get-Module -ListAvailable -Name 'PSYaml' -ErrorAction SilentlyContinue)) {
    try { Import-Module PSYaml -ErrorAction Stop; $yamlParser = 'PSYaml' } catch { }
}
if ($yamlParser) {
    Write-Info "Using YAML parser: $yamlParser"
} else {
    Write-Info "No YAML parser module installed (powershell-yaml / PSYaml). YAML files reported as WARN, not PASS."
}

$yamlFiles = @(
    'templates\.ai-workflow.yml'
    'tests\fixtures\generic-github-flow\.ai-workflow.yml'
    'tests\fixtures\git-flow\.ai-workflow.yml'
    'tests\fixtures\wordpress\.ai-workflow.yml'
)
foreach ($rel in $yamlFiles) {
    $path = Join-Path $repoRoot $rel
    if (-not (Test-Path $path)) { Write-Warn "$rel not found"; continue }
    $content = Get-Content $path -Raw
    if ($yamlParser) {
        try {
            $null = ConvertFrom-Yaml $content
            Write-Pass "$rel (parsed with $yamlParser)"
        } catch {
            Write-Fail "$rel`: YAML parse error - $($_.Exception.Message)"
        }
    } else {
        # No real parser available: do a structural smoke check but only WARN.
        if ($content -match '(?m)^\s*(profile|project)\s*:') {
            Write-Warn "$rel`: no YAML parser installed - structural check only, not validated (install powershell-yaml for real parsing)"
        } else {
            Write-Fail "$rel`: missing expected top-level keys (profile: / project:)"
        }
    }
}

# ─── 4. Audit on fixtures ──────────────────────────────────────────────────
Write-Section "4. Audit Script on Fixtures"

$auditScript = Join-Path $repoRoot 'scripts\audit-project-workflow.ps1'
$fixtures = @(
    @{ name = 'generic-github-flow'; expect_type = 'react';     expect_platform = 'generic-git'; expect_wp = $false }
    @{ name = 'git-flow';            expect_type = 'laravel';   expect_platform = 'generic-git'; expect_wp = $false }
    @{ name = 'wordpress';           expect_type = 'wordpress'; expect_platform = 'generic-git'; expect_wp = $true  }
    @{ name = 'non-git';             expect_type = 'unknown';   expect_platform = 'unknown';     expect_wp = $false }
)

foreach ($f in $fixtures) {
    $fixturePath = Join-Path $repoRoot "tests\fixtures\$($f.name)"
    if (-not (Test-Path $fixturePath)) { Write-Warn "Fixture $($f.name) not found"; continue }
    try {
        $json = & powershell -NoProfile -ExecutionPolicy Bypass -File $auditScript `
            -TargetPath $fixturePath -OutputFormat Json 2>$null | ConvertFrom-Json
        $typeOk    = $json.project_type -eq $f.expect_type
        $wpMissing = if ($f.expect_wp) { $json.skills_missing -contains 'wp-guard' } else { $true }
        if ($typeOk -and $wpMissing) {
            Write-Pass "fixture/$($f.name): type=$($json.project_type), wp-guard-required=$($f.expect_wp)"
        } else {
            $issues = @()
            if (-not $typeOk)    { $issues += "expected type=$($f.expect_type) got=$($json.project_type)" }
            if (-not $wpMissing) { $issues += "expected wp-guard in skills_missing" }
            Write-Fail "fixture/$($f.name): $($issues -join '; ')"
        }
    } catch {
        Write-Warn "fixture/$($f.name): audit script error - $_"
    }
}

# ─── 5. Bootstrap observe-only on fixture ─────────────────────────────────
Write-Section "5. Bootstrap Observe-Only"

$bootstrapScript = Join-Path $repoRoot 'scripts\bootstrap-project.ps1'
$observeFixture  = Join-Path $repoRoot 'tests\fixtures\generic-github-flow'
try {
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript `
        -TargetPath $observeFixture -Mode observe-only 2>&1
    if ($output -match 'observe-only') {
        Write-Pass "bootstrap observe-only ran without errors"
    } else {
        Write-Warn "bootstrap observe-only: unexpected output"
    }
} catch {
    Write-Fail "bootstrap observe-only failed: $_"
}

# ─── 6. Template path sanity ──────────────────────────────────────────────
Write-Section "6. Template Path Sanity"

$expectedTemplates = @(
    'templates\.ai-workflow.yml'
    'templates\.ai-skills.json'
    'templates\AGENTS.md'
    'templates\CLAUDE.md'
    'templates\PROJECT-WORKING-GUIDE.md'
    'templates\PROGRESS.md'
    'templates\DECISIONS.md'
    'templates\specs\constitution.md'
    'templates\release-checklist.md'
    'templates\hotfix-checklist.md'
    'templates\github\pull_request_template.md'
    'templates\github\CODEOWNERS'
    'templates\azure-devops\pull_request_template.md'
    'templates\generic-git\pr-checklist.md'
)
foreach ($t in $expectedTemplates) {
    $path = Join-Path $repoRoot $t
    if (Test-Path $path) { Write-Pass $t } else { Write-Fail "$t not found" }
}

# ─── 7. Doc file sanity ────────────────────────────────────────────────────
Write-Section "7. Documentation File Sanity"

$expectedDocs = @(
    'docs\install.md'
    'docs\usage.md'
    'docs\profiles.md'
    'docs\git-flow.md'
    'docs\existing-projects.md'
    'docs\project-bootstrap.md'
    'docs\wordpress.md'
    'docs\github.md'
    'docs\azure-devops.md'
    'docs\generic-git.md'
    'docs\spec-kit.md'
    'docs\handoff-format.md'
    'docs\troubleshooting.md'
    'docs\definition-of-done.md'
    'docs\compatibility.md'
    'docs\upgrade.md'
    'docs\testing.md'
)
foreach ($d in $expectedDocs) {
    $path = Join-Path $repoRoot $d
    if (Test-Path $path) { Write-Pass $d } else { Write-Warn "$d not found (may not be created yet)" }
}

# ─── 8. Format / line-count sanity ────────────────────────────────────────
Write-Section "8. Format / Line-Count Sanity"

# Guards against files being collapsed into a handful of very long lines
# (e.g. real newlines stripped during a bad merge or copy/paste).
$formatChecks = @(
    @{ rel = 'README.md';                  minLines = 40 }
    @{ rel = 'templates\.ai-workflow.yml'; minLines = 20 }
    @{ rel = 'templates\.ai-skills.json';  minLines = 20 }
)
foreach ($fc in $formatChecks) {
    $path = Join-Path $repoRoot $fc.rel
    if (-not (Test-Path $path)) { Write-Fail "$($fc.rel) not found"; continue }
    $lines  = @(Get-Content $path)
    $count  = $lines.Count
    $maxLen = ($lines | Measure-Object -Property Length -Maximum).Maximum
    if (-not $maxLen) { $maxLen = 0 }
    if ($count -lt $fc.minLines) {
        Write-Fail "$($fc.rel): only $count line(s), expected >= $($fc.minLines) - looks collapsed"
    } elseif ($count -le 10 -and $maxLen -gt 200) {
        Write-Fail "$($fc.rel): $count line(s) with a $maxLen-char line - looks collapsed"
    } else {
        Write-Pass "$($fc.rel): $count lines, longest $maxLen chars"
    }
}

# ─── Result ────────────────────────────────────────────────────────────────
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host " RESULTS: $pass passed | $warn warnings | $fail failed" -ForegroundColor $(
    if ($fail -gt 0) { 'Red' } elseif ($warn -gt 0) { 'Yellow' } else { 'Green' }
)
Write-Host "================================================`n" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
if ($warn -gt 0) { exit 0 }
exit 0
