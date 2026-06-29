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
$pass = 0
$warn = 0
$fail = 0

function Write-Pass {
    param([string]$Message)

    Write-Host "  [PASS] $Message" -ForegroundColor Green
    $script:pass++
}

function Write-Fail {
    param([string]$Message)

    Write-Host "  [FAIL] $Message" -ForegroundColor Red
    $script:fail++
}

function Write-Warn {
    param([string]$Message)

    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
    $script:warn++
}

function Write-Info {
    param([string]$Message)

    Write-Host "  [INFO] $Message" -ForegroundColor Gray
}

function Write-Section {
    param([string]$Title)

    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

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

# ─── 6. Project Workflow CLI smoke tests ──────────────────────────────────
Write-Section "6. Project Workflow CLI Smoke Tests"

$cliScript = Join-Path $repoRoot 'scripts\project-workflow.ps1'
$cliSmokeRoot = Join-Path ([System.IO.Path]::GetTempPath()) "apw-cli-smoke-$([guid]::NewGuid().ToString('N'))"
try {
    if (Test-Path $cliScript) {
        Write-Pass 'scripts\project-workflow.ps1 exists'
    } else {
        Write-Fail 'scripts\project-workflow.ps1 not found'
    }

    New-Item -ItemType Directory -Path $cliSmokeRoot -Force | Out-Null
    Push-Location $cliSmokeRoot
    git init 2>$null | Out-Null
    Pop-Location

    if (Test-Path $cliScript) {
        $dryRunOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            init -TargetPath $cliSmokeRoot -Type wordpress-site -Profile standard -SpecKit `
            -Agents codex,claude-code -DryRun 2>&1
        if (($dryRunOutput -match 'DRY-RUN') -and -not (Test-Path (Join-Path $cliSmokeRoot 'AGENTS.md'))) {
            Write-Pass 'init dry-run reports safely without writing AGENTS.md'
        } else {
            Write-Fail 'init dry-run must report DRY-RUN and avoid writing workflow files'
        }

        $applyOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            init -TargetPath $cliSmokeRoot -Type wordpress-site -Profile standard -SpecKit `
            -Agents codex,claude-code -Apply 2>&1
        $lockPath = Join-Path $cliSmokeRoot '.agent-workflow.lock.json'
        $agentsPath = Join-Path $cliSmokeRoot 'AGENTS.md'
        if ((Test-Path $lockPath) -and (Test-Path $agentsPath)) {
            $lock = Get-Content $lockPath -Raw | ConvertFrom-Json
            $agentsText = Get-Content $agentsPath -Raw
            if (($lock.archetype -eq 'wordpress-site') -and ($lock.spec_kit.enabled -eq $true) -and
                ($agentsText -match 'automatically follow the project-workflow startup sequence')) {
                Write-Pass 'init apply creates lock file and automatic activation instructions'
            } else {
                Write-Fail 'init apply created files but lock/automatic activation content is incomplete'
            }
        } else {
            Write-Fail 'init apply must create AGENTS.md and .agent-workflow.lock.json'
        }

        $doctorOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            doctor -TargetPath $cliSmokeRoot 2>&1
        if (($doctorOutput -match 'Workflow readiness:') -and ($doctorOutput -match 'Recommended next:')) {
            Write-Pass 'doctor reports readiness score and recommended next step'
        } else {
            Write-Fail 'doctor output must include readiness score and recommended next step'
        }
    }
} catch {
    Write-Fail "project-workflow CLI smoke failed: $_"
} finally {
    if (Test-Path $cliSmokeRoot) {
        Remove-Item -LiteralPath $cliSmokeRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ─── 7. CLI safety and archetype tests ────────────────────────────────────
Write-Section "7. CLI Safety and Archetype Tests"

$cliBehaviorRoot = Join-Path ([System.IO.Path]::GetTempPath()) "apw-cli-behavior-$([guid]::NewGuid().ToString('N'))"
try {
    New-Item -ItemType Directory -Path $cliBehaviorRoot -Force | Out-Null

    $conflictRoot = Join-Path $cliBehaviorRoot 'conflict'
    New-Item -ItemType Directory -Path $conflictRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $conflictRoot 'AGENTS.md') -Value '# Owner instructions' -Encoding UTF8
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $conflictRoot -Type generic -Apply 2>&1 | Out-Null
    $ownerText = Get-Content (Join-Path $conflictRoot 'AGENTS.md') -Raw
    if (($ownerText -match 'Owner instructions') -and (Test-Path (Join-Path $conflictRoot 'AGENTS.md.suggested.md'))) {
        Write-Pass 'init preserves unmanaged files and creates .suggested.md proposals'
    } else {
        Write-Fail 'init must preserve unmanaged files and create .suggested.md proposals'
    }

    $upgradeRoot = Join-Path $cliBehaviorRoot 'upgrade'
    New-Item -ItemType Directory -Path $upgradeRoot -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $upgradeRoot -Type generic -Apply 2>&1 | Out-Null
    Add-Content -LiteralPath (Join-Path $upgradeRoot 'AGENTS.md') -Value "`nOwner upgrade note."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        upgrade -TargetPath $upgradeRoot -Type generic -Apply 2>&1 | Out-Null
    if ((Get-Content (Join-Path $upgradeRoot 'AGENTS.md') -Raw) -match 'Owner upgrade note') {
        Write-Pass 'upgrade preserves content outside managed blocks'
    } else {
        Write-Fail 'upgrade must preserve content outside managed blocks'
    }

    $archetypes = @(
        @{ name = 'wordpress-plugin'; file = 'sample-plugin.php'; content = "<?php`n/*`nPlugin Name: Sample`n*/" }
        @{ name = 'wordpress-theme'; file = 'style.css'; content = "/*`nTheme Name: Sample`n*/" }
        @{ name = 'wordpress-block'; file = 'block.json'; content = '{"apiVersion":3,"name":"sample/block"}' }
        @{ name = 'wordpress-bedrock'; file = 'composer.json'; content = '{"require":{"roots/bedrock":"*"}}' }
        @{ name = 'wordpress-woocommerce'; file = 'sample.php'; content = "<?php`n/* WooCommerce extension */`nWC_Order::class;" }
    )
    foreach ($case in $archetypes) {
        $caseRoot = Join-Path $cliBehaviorRoot $case.name
        New-Item -ItemType Directory -Path $caseRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $caseRoot $case.file) -Value $case.content -Encoding UTF8
        & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            init -TargetPath $caseRoot -Type auto -Apply 2>&1 | Out-Null
        $caseLock = Get-Content (Join-Path $caseRoot '.agent-workflow.lock.json') -Raw | ConvertFrom-Json
        if ($caseLock.archetype -eq $case.name) {
            Write-Pass "auto detection: $($case.name)"
        } else {
            Write-Fail "auto detection: expected $($case.name), got $($caseLock.archetype)"
        }
        $caseAudit = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            audit -TargetPath $caseRoot -Json 2>$null | ConvertFrom-Json
        if ($caseAudit.archetype -eq $case.name) {
            Write-Pass "audit archetype: $($case.name)"
        } else {
            Write-Fail "audit archetype: expected $($case.name), got $($caseAudit.archetype)"
        }
    }

    $doctorJson = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        doctor -TargetPath $upgradeRoot -Json 2>$null | ConvertFrom-Json
    if (($doctorJson.score -is [int]) -and $doctorJson.recommended_next) {
        Write-Pass 'doctor JSON exposes score and recommended_next'
    } else {
        Write-Fail 'doctor JSON must expose score and recommended_next'
    }

    $wooRoot = Join-Path $cliBehaviorRoot 'wordpress-woocommerce'
    $wooSkillsPath = Join-Path $wooRoot '.ai-skills.json'
    $wooSkills = Get-Content $wooSkillsPath -Raw | ConvertFrom-Json
    $wooSkills.skills.required = @($wooSkills.skills.required | Where-Object { $_.name -ne 'woo-guard' })
    $wooSkills | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $wooSkillsPath -Encoding UTF8
    $wooDoctor = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        doctor -TargetPath $wooRoot -Json 2>$null | ConvertFrom-Json
    if (($wooDoctor.blocking -join ' ') -match 'woo-guard') {
        Write-Pass 'doctor blocks WooCommerce projects missing woo-guard'
    } else {
        Write-Fail 'doctor must block WooCommerce projects missing woo-guard'
    }

    $existingSpecRoot = Join-Path $cliBehaviorRoot 'existing-spec-kit'
    New-Item -ItemType Directory -Path (Join-Path $existingSpecRoot '.specify') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $existingSpecRoot '.specify\owner.txt') -Value 'preserve me'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $existingSpecRoot -Type generic -SpecKit -Apply 2>&1 | Out-Null
    $existingSpecLock = Get-Content (Join-Path $existingSpecRoot '.agent-workflow.lock.json') -Raw | ConvertFrom-Json
    if (($existingSpecLock.spec_kit.status -eq 'existing-preserved') -and
        ((Get-Content (Join-Path $existingSpecRoot '.specify\owner.txt') -Raw) -match 'preserve me')) {
        Write-Pass 'Spec Kit init preserves existing .specify state'
    } else {
        Write-Fail 'Spec Kit init must preserve existing .specify state'
    }

    if (-not (Get-Command specify -ErrorAction SilentlyContinue)) {
        $missingSpecRoot = Join-Path $cliBehaviorRoot 'missing-spec-kit'
        New-Item -ItemType Directory -Path $missingSpecRoot -Force | Out-Null
        & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            init -TargetPath $missingSpecRoot -Type generic -SpecKit -Apply 2>&1 | Out-Null
        $missingSpecLock = Get-Content (Join-Path $missingSpecRoot '.agent-workflow.lock.json') -Raw | ConvertFrom-Json
        if ($missingSpecLock.spec_kit.status -eq 'requested-unavailable') {
            Write-Pass 'Spec Kit requested-unavailable state is recorded'
        } else {
            Write-Fail "Expected Spec Kit requested-unavailable, got $($missingSpecLock.spec_kit.status)"
        }
    } else {
        $availableSpecRoot = Join-Path $cliBehaviorRoot 'available-spec-kit'
        New-Item -ItemType Directory -Path $availableSpecRoot -Force | Out-Null
        & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            init -TargetPath $availableSpecRoot -Type generic -SpecKit -Agents codex -Apply 2>&1 | Out-Null
        $availableSpecLock = Get-Content (Join-Path $availableSpecRoot '.agent-workflow.lock.json') -Raw | ConvertFrom-Json
        if ((Test-Path (Join-Path $availableSpecRoot '.specify')) -and
            ($availableSpecLock.spec_kit.status -eq 'initialized') -and
            (($availableSpecLock.spec_kit.commands -join ' ') -match 'integration list') -and
            (($availableSpecLock.spec_kit.commands -join ' ') -match 'specify init')) {
            Write-Pass 'Spec Kit available state initializes and records commands'
        } else {
            Write-Fail "Spec Kit available state failed: status=$($availableSpecLock.spec_kit.status)"
        }
    }

    $questionRoot = Join-Path $cliBehaviorRoot 'question-engine'
    New-Item -ItemType Directory -Path $questionRoot -Force | Out-Null
    $questionOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $questionRoot -Type auto -DryRun 2>&1
    $questionText = $questionOutput | Out-String
    $questionFields = @('Detected:', 'Recommended:', 'Why:', 'Alternatives:', 'Impact:', 'Question:', 'Default if you approve:')
    $missingQuestionFields = @($questionFields | Where-Object { $questionText -notmatch [regex]::Escape($_) })
    if (($missingQuestionFields.Count -eq 0) -and -not (Test-Path (Join-Path $questionRoot 'AGENTS.md'))) {
        Write-Pass 'unknown project type emits recommendation-first question without writing'
    } else {
        Write-Fail "unknown project question missing fields: $($missingQuestionFields -join ', ')"
    }

    $installRoot = Join-Path $cliBehaviorRoot 'install-skills'
    $shimRoot = Join-Path $installRoot 'bin'
    New-Item -ItemType Directory -Path $shimRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $shimRoot 'npx.cmd') -Value '@echo installed>%CD%\installed.txt' -Encoding Ascii
    [ordered]@{
        version = '1.0'
        install_mode = 'auto-approved-only'
        skills = [ordered]@{
            required = @(
                [ordered]@{
                    name = 'approved-skill'
                    install_approved = $true
                    install_command = 'npx -y skills add . --skill approved-skill --global --agent codex --copy'
                }
                [ordered]@{
                    name = 'manual-skill'
                    install_approved = $false
                    install_command = 'npx -y skills add . --skill manual-skill --global --agent codex --copy'
                }
            )
        }
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $installRoot '.ai-skills.json') -Encoding UTF8
    $oldPath = $env:PATH
    try {
        $env:PATH = "$shimRoot;$oldPath"
        & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            install-skills -TargetPath $installRoot -ApprovedOnly 2>&1 | Out-Null
    } finally {
        $env:PATH = $oldPath
    }
    if ((Test-Path (Join-Path $installRoot 'installed.txt')) -and
        -not (Test-Path (Join-Path $installRoot 'manual-installed.txt'))) {
        Write-Pass 'install-skills executes only approved safe commands'
    } else {
        Write-Fail 'install-skills must execute approved safe commands'
    }
} catch {
    Write-Fail "CLI safety/archetype tests failed: $_"
} finally {
    if (Test-Path $cliBehaviorRoot) {
        Remove-Item -LiteralPath $cliBehaviorRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ─── 8. Template path sanity ──────────────────────────────────────────────
Write-Section "8. Template Path Sanity"

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

# ─── 9. Preset payload sanity ──────────────────────────────────────────────
Write-Section "9. Preset Payload Sanity"

$presetNames = @(
    'generic',
    'wordpress',
    'wordpress-site',
    'wordpress-plugin',
    'wordpress-theme',
    'wordpress-block',
    'wordpress-woocommerce',
    'wordpress-bedrock'
)
$presetFiles = @(
    '.ai-workflow.yml',
    '.ai-skills.json',
    'AGENTS.md',
    'CLAUDE.md',
    'PROJECT-WORKING-GUIDE.md',
    'PROGRESS.md',
    'DECISIONS.md',
    'specs\constitution.md',
    'README.md'
)
foreach ($preset in $presetNames) {
    $missingPresetFiles = @()
    foreach ($presetFile in $presetFiles) {
        if (-not (Test-Path (Join-Path $repoRoot "presets\$preset\$presetFile"))) {
            $missingPresetFiles += $presetFile
        }
    }
    if ($missingPresetFiles.Count -eq 0) {
        Write-Pass "preset/$preset has full payload"
    } else {
        Write-Fail "preset/$preset missing: $($missingPresetFiles -join ', ')"
    }
}

# ─── 10. Doc file sanity ───────────────────────────────────────────────────
Write-Section "10. Documentation File Sanity"

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
    'docs\cli.md'
    'docs\presets.md'
    'docs\bundles.md'
    'docs\wordpress-preset.md'
    'docs\question-engine.md'
    'docs\automatic-activation.md'
    'docs\ci-enforcement.md'
    'docs\skills-policy.md'
)
foreach ($d in $expectedDocs) {
    $path = Join-Path $repoRoot $d
    if (Test-Path $path) { Write-Pass $d } else { Write-Fail "$d not found" }
}

# ─── 11. Format / line-count sanity ───────────────────────────────────────
Write-Section "11. Format / Line-Count Sanity"

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
