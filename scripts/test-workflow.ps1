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

function Test-OrderedTokens {
    param([string]$Content, [string[]]$Tokens)

    $searchFrom = 0
    foreach ($token in $Tokens) {
        $tokenIndex = $Content.IndexOf($token, $searchFrom, [System.StringComparison]::Ordinal)
        if ($tokenIndex -lt 0) { return $false }
        $searchFrom = $tokenIndex + $token.Length
    }
    return $true
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
$jsonFiles += @(Get-ChildItem (Join-Path $repoRoot 'presets') -Filter '.ai-skills.json' -Recurse |
    ForEach-Object { $_.FullName.Substring($repoRoot.Length + 1) })
foreach ($rel in $jsonFiles) {
    $path = Join-Path $repoRoot $rel
    if (-not (Test-Path $path)) { Write-Warn "$rel not found"; continue }
    try {
        $null = Get-Content $path -Raw | ConvertFrom-Json
        if (($rel -like '*\.ai-skills.json') -and (@(Get-Content $path).Count -lt 20)) {
            Write-Fail "$rel`: valid JSON but not readable pretty-printed policy"
        } else {
            Write-Pass "$rel"
        }
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
if (-not $yamlParser) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand) {
        $previousErrorPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & $pythonCommand.Source -c "import yaml" 2>$null
            if ($LASTEXITCODE -eq 0) { $yamlParser = 'python-pyyaml' }
        } finally {
            $ErrorActionPreference = $previousErrorPreference
        }
    }
}
if ($yamlParser) {
    Write-Info "Using YAML parser: $yamlParser"
} else {
    Write-Fail 'No real YAML parser is available for user-facing workflow files.'
}

$yamlRoots = @('templates', 'presets', 'tests\fixtures', '.github')
$yamlFiles = @($yamlRoots | ForEach-Object {
    Get-ChildItem (Join-Path $repoRoot $_) -File -Recurse -Include '*.yml', '*.yaml' |
        ForEach-Object { $_.FullName.Substring($repoRoot.Length + 1) }
} | Select-Object -Unique)
foreach ($rel in $yamlFiles) {
    $path = Join-Path $repoRoot $rel
    if (-not (Test-Path $path)) { Write-Warn "$rel not found"; continue }
    $content = Get-Content $path -Raw
    if ($yamlParser) {
        try {
            if ($yamlParser -eq 'python-pyyaml') {
                $parserOutput = & $pythonCommand.Source -c `
                    "import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding='utf-8'))" $path 2>&1
                if ($LASTEXITCODE -ne 0) { throw ($parserOutput | Out-String) }
            } else {
                $null = ConvertFrom-Yaml $content
            }
            Write-Pass "$rel (parsed with $yamlParser)"
        } catch {
            Write-Fail "$rel`: YAML parse error - $($_.Exception.Message)"
        }
    } else {
        Write-Fail "$rel`: not parsed because no real YAML parser is available"
    }
}

$specKitCommandOrder = @(
    '/speckit.constitution',
    '/speckit.specify',
    '/speckit.clarify',
    '/speckit.plan',
    '/speckit.checklist',
    '/speckit.tasks',
    '/speckit.analyze',
    '/speckit.implement',
    '/speckit.converge'
)
$specKitSkillOrder = @(
    '$speckit-constitution',
    '$speckit-specify',
    '$speckit-clarify',
    '$speckit-plan',
    '$speckit-checklist',
    '$speckit-tasks',
    '$speckit-analyze',
    '$speckit-implement',
    '$speckit-converge'
)
$specKitPolicyFiles = @(
    'README.md',
    'docs\usage.md',
    'docs\skills-policy.md',
    'docs\spec-kit.md',
    'templates\AGENTS.md',
    'templates\CLAUDE.md',
    'templates\PROJECT-WORKING-GUIDE.md',
    'templates\.ai-workflow.yml',
    'templates\.ai-skills.json'
)
foreach ($relativePath in $specKitPolicyFiles) {
    $policyContent = Get-Content (Join-Path $repoRoot $relativePath) -Raw
    if ((Test-OrderedTokens -Content $policyContent -Tokens $specKitCommandOrder) -and
        (Test-OrderedTokens -Content $policyContent -Tokens $specKitSkillOrder)) {
        Write-Pass "$relativePath contains both exact Spec Kit orders"
    } else {
        Write-Fail "$relativePath must contain command and Codex skills-mode Spec Kit orders"
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

        $initializedDoctor = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
            doctor -TargetPath $cliSmokeRoot -Json 2>$null | ConvertFrom-Json
        if ((($initializedDoctor.passing -join ' ') -match 'wp-guard skill documented') -and
            (($initializedDoctor.warnings -join ' ') -notmatch "differs from detected 'unknown'")) {
            Write-Pass 'doctor honors explicit lock archetype when filesystem detection is unknown'
        } else {
            Write-Fail 'doctor must use the lock archetype/profile for an explicitly initialized project'
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

    $cliSource = Get-Content -LiteralPath $cliScript -Raw
    $constantMarkerPattern = 'Set-Variable\s+-Name\s+Managed(Start|End)\s+-Value\s+''<!-- agent-project-workflow:(start|end) -->''\s+-Option\s+Constant\s+-Scope\s+Script'
    $constantMarkerMatches = [regex]::Matches($cliSource, $constantMarkerPattern)
    if ($constantMarkerMatches.Count -eq 2) {
        Write-Pass 'managed block markers are explicit non-empty script constants'
    } else {
        Write-Fail 'ManagedStart and ManagedEnd must be explicit non-empty script constants'
    }

    $conflictRoot = Join-Path $cliBehaviorRoot 'conflict'
    New-Item -ItemType Directory -Path $conflictRoot -Force | Out-Null
    $originalOwnerText = "# Owner instructions`n`nThis file belongs to the project owner."
    Set-Content -LiteralPath (Join-Path $conflictRoot 'AGENTS.md') -Value $originalOwnerText -Encoding UTF8 -NoNewline
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $conflictRoot -Type generic -Apply 2>&1 | Out-Null
    $ownerText = Get-Content (Join-Path $conflictRoot 'AGENTS.md') -Raw
    $suggestedPath = Join-Path $conflictRoot 'AGENTS.md.suggested.md'
    $suggestedText = if (Test-Path $suggestedPath) { Get-Content $suggestedPath -Raw } else { '' }
    if (($ownerText -ceq $originalOwnerText) -and
        ($suggestedText -match [regex]::Escape('<!-- agent-project-workflow:start -->')) -and
        ($suggestedText -match [regex]::Escape('<!-- agent-project-workflow:end -->'))) {
        Write-Pass 'init preserves unmanaged files and creates .suggested.md proposals'
    } else {
        Write-Fail 'init must preserve unmanaged files and create .suggested.md proposals'
    }

    $upgradeRoot = Join-Path $cliBehaviorRoot 'upgrade'
    New-Item -ItemType Directory -Path $upgradeRoot -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $upgradeRoot -Type generic -Apply 2>&1 | Out-Null
    $upgradeAgentsPath = Join-Path $upgradeRoot 'AGENTS.md'
    $managedAgents = Get-Content $upgradeAgentsPath -Raw
    $ownerPrefix = "Owner preface before workflow.`r`n`r`n"
    $ownerSuffix = "`r`n`r`nOwner appendix after workflow."
    Set-Content -LiteralPath $upgradeAgentsPath -Value ($ownerPrefix + $managedAgents.TrimEnd("`r", "`n") + $ownerSuffix) -Encoding UTF8 -NoNewline
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        upgrade -TargetPath $upgradeRoot -Type generic -Apply 2>&1 | Out-Null
    $upgradedAgents = Get-Content $upgradeAgentsPath -Raw
    if ($upgradedAgents.StartsWith($ownerPrefix) -and $upgradedAgents.EndsWith($ownerSuffix)) {
        Write-Pass 'upgrade preserves content outside managed blocks'
    } else {
        Write-Fail 'upgrade must preserve content outside managed blocks'
    }

    $managedFiles = @('AGENTS.md', 'CLAUDE.md', 'PROJECT-WORKING-GUIDE.md', 'specs\constitution.md')
    $markerFailures = [System.Collections.Generic.List[string]]::new()
    foreach ($managedFile in $managedFiles) {
        $managedText = Get-Content (Join-Path $upgradeRoot $managedFile) -Raw
        $startCount = ([regex]::Matches($managedText, [regex]::Escape('<!-- agent-project-workflow:start -->'))).Count
        $endCount = ([regex]::Matches($managedText, [regex]::Escape('<!-- agent-project-workflow:end -->'))).Count
        if (($startCount -ne 1) -or ($endCount -ne 1)) { $markerFailures.Add($managedFile) }
    }
    if ($markerFailures.Count -eq 0) {
        Write-Pass 'generated managed files contain one exact start and end marker'
    } else {
        Write-Fail "generated managed files have invalid marker pairs: $($markerFailures -join ', ')"
    }

    $brokenMarkerRoot = Join-Path $cliBehaviorRoot 'broken-marker'
    Copy-Item -LiteralPath $upgradeRoot -Destination $brokenMarkerRoot -Recurse
    $brokenConstitutionPath = Join-Path $brokenMarkerRoot 'specs\constitution.md'
    $brokenConstitution = (Get-Content $brokenConstitutionPath -Raw).Replace('<!-- agent-project-workflow:end -->', '')
    Set-Content -LiteralPath $brokenConstitutionPath -Value $brokenConstitution -Encoding UTF8 -NoNewline
    $brokenDoctor = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        doctor -TargetPath $brokenMarkerRoot -Json 2>$null | ConvertFrom-Json
    if (($brokenDoctor.warnings -join ' ') -match 'specs\\constitution.md does not have a valid managed block') {
        Write-Pass 'doctor rejects incomplete managed marker pairs'
    } else {
        Write-Fail 'doctor must reject a managed block with a missing end marker'
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

    $emptyFolderRoot = Join-Path $cliBehaviorRoot 'empty-folder'
    New-Item -ItemType Directory -Path $emptyFolderRoot -Force | Out-Null
    $emptyFolderOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $emptyFolderRoot -Type auto -DryRun 2>&1 | Out-String
    if (($emptyFolderOutput -match 'Empty directory: Yes') -and
        ($emptyFolderOutput -match 'Git initialized: No') -and
        ($emptyFolderOutput -match 'Question: Initialize Git in this directory before workflow setup\?') -and
        -not (Test-Path (Join-Path $emptyFolderRoot 'AGENTS.md'))) {
        Write-Pass 'empty non-Git folder reports state and asks about Git before setup'
    } else {
        Write-Fail 'empty non-Git folder must report state, ask about Git, and avoid writes'
    }

    $emptyGitRoot = Join-Path $cliBehaviorRoot 'empty-git-repo'
    New-Item -ItemType Directory -Path $emptyGitRoot -Force | Out-Null
    Push-Location $emptyGitRoot
    git init 2>$null | Out-Null
    Pop-Location
    $emptyGitOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $emptyGitRoot -Type auto -DryRun 2>&1 | Out-String
    if (($emptyGitOutput -match 'Empty directory: Yes') -and
        ($emptyGitOutput -match 'Git initialized: Yes') -and
        ($emptyGitOutput -match 'Question: Which project type should be initialized\?')) {
        Write-Pass 'empty Git repo reports state and asks only for project type'
    } else {
        Write-Fail 'empty Git repo must report state and request an explicit project type'
    }

    $emptyDoctor = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        doctor -TargetPath $emptyFolderRoot -Json 2>$null | ConvertFrom-Json
    if (($emptyDoctor.empty_directory -eq $true) -and
        ($emptyDoctor.git_initialized -eq $false) -and
        ($emptyDoctor.recommended_next -match 'Git')) {
        Write-Pass 'doctor JSON exposes empty-directory and Git state'
    } else {
        Write-Fail 'doctor JSON must expose empty-directory and Git state with a Git-first recommendation'
    }

    $genericPolicyRoot = Join-Path $cliBehaviorRoot 'generic-authority-policy'
    New-Item -ItemType Directory -Path $genericPolicyRoot -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $genericPolicyRoot -Type generic -Apply 2>&1 | Out-Null
    $generatedWorkflow = Get-Content (Join-Path $genericPolicyRoot '.ai-workflow.yml') -Raw
    $generatedSkillsText = Get-Content (Join-Path $genericPolicyRoot '.ai-skills.json') -Raw
    $generatedSkills = $generatedSkillsText | ConvertFrom-Json
    $generatedAgents = Get-Content (Join-Path $genericPolicyRoot 'AGENTS.md') -Raw
    $generatedClaude = Get-Content (Join-Path $genericPolicyRoot 'CLAUDE.md') -Raw
    $generatedGuide = Get-Content (Join-Path $genericPolicyRoot 'PROJECT-WORKING-GUIDE.md') -Raw
    $generatedOrderDocuments = @(
        $generatedWorkflow,
        $generatedSkillsText,
        $generatedAgents,
        $generatedClaude,
        $generatedGuide
    )
    $generatedOrdersValid = @($generatedOrderDocuments | Where-Object {
        -not (Test-OrderedTokens -Content $_ -Tokens $specKitCommandOrder) -or
        -not (Test-OrderedTokens -Content $_ -Tokens $specKitSkillOrder)
    }).Count -eq 0
    $generatedYamlValid = $false
    try {
        if ($yamlParser -eq 'python-pyyaml') {
            & $pythonCommand.Source -c `
                "import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding='utf-8'))" `
                (Join-Path $genericPolicyRoot '.ai-workflow.yml') 2>&1 | Out-Null
            $generatedYamlValid = $LASTEXITCODE -eq 0
        } else {
            $null = ConvertFrom-Yaml $generatedWorkflow
            $generatedYamlValid = $true
        }
    } catch {
        $generatedYamlValid = $false
    }
    if (($generatedWorkflow -match 'planning:\s+spec-kit') -and
        ($generatedWorkflow -match 'require_before_implementation:\s+true') -and
        ($generatedSkills.authority.planning -eq 'spec-kit') -and
        ($generatedSkills.authority.implementation -eq 'after-speckit-analyze') -and
        ($generatedSkills.authority.optional_executor_skills_may_replace_planning -eq $false) -and
        ($generatedAgents -match 'Do not use Superpowers or any similar planning workflow') -and
        ($generatedClaude -match 'must not replace Spec Kit') -and
        ($generatedGuide -match 'must not replace Spec Kit') -and
        $generatedOrdersValid -and
        $generatedYamlValid) {
        Write-Pass 'generated generic workflow enforces Spec Kit and skill precedence'
    } else {
        Write-Fail 'generated generic workflow must encode Spec Kit authority and anti-drift policy'
    }

    if (($generatedSkills.skills.conditional_required.name -contains 'wp-guard') -and
        -not ($generatedSkills.skills.required.name -contains 'wp-guard')) {
        Write-Pass 'generic policy keeps WordPress guards conditional'
    } else {
        Write-Fail 'generic policy must not require WordPress guards globally'
    }

    $workflowPolicyPath = Join-Path $genericPolicyRoot '.ai-workflow.yml'
    $driftedWorkflow = $generatedWorkflow.Replace('    - "/speckit.checklist"', '    - "/speckit.tasks"')
    Set-Content -LiteralPath $workflowPolicyPath -Value $driftedWorkflow -Encoding UTF8 -NoNewline
    $orderDriftDoctor = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        doctor -TargetPath $genericPolicyRoot -Json 2>$null | ConvertFrom-Json
    if (($orderDriftDoctor.blocking -join ' ') -match 'Spec Kit order') {
        Write-Pass 'doctor blocks missing or reordered Spec Kit policy steps'
    } else {
        Write-Fail 'doctor must block missing or reordered Spec Kit policy steps'
    }
    Set-Content -LiteralPath $workflowPolicyPath -Value $generatedWorkflow -Encoding UTF8 -NoNewline

    $generatedSkills.authority.optional_executor_skills_may_replace_planning = $true
    $generatedSkills | ConvertTo-Json -Depth 8 | Set-Content `
        -LiteralPath (Join-Path $genericPolicyRoot '.ai-skills.json') -Encoding UTF8
    $driftDoctor = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        doctor -TargetPath $genericPolicyRoot -Json 2>$null | ConvertFrom-Json
    if (($driftDoctor.blocking -join ' ') -match 'skill precedence') {
        Write-Pass 'doctor blocks policy that allows optional skills to replace planning'
    } else {
        Write-Fail 'doctor must block skill-precedence drift'
    }

    $jsAliasRoot = Join-Path $cliBehaviorRoot 'js-ts-alias'
    New-Item -ItemType Directory -Path $jsAliasRoot -Force | Out-Null
    $jsAliasOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $cliScript `
        init -TargetPath $jsAliasRoot -Type 'js/ts' -DryRun 2>&1 | Out-String
    if (($LASTEXITCODE -eq 0) -and ($jsAliasOutput -match 'Archetype: js-ts')) {
        Write-Pass 'CLI accepts js/ts as an alias for js-ts'
    } else {
        Write-Fail 'CLI must accept the documented js/ts type alias'
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

    $presetWorkflow = Get-Content (Join-Path $repoRoot "presets\$preset\.ai-workflow.yml") -Raw
    $presetSkillsText = Get-Content (Join-Path $repoRoot "presets\$preset\.ai-skills.json") -Raw
    $presetSkills = $presetSkillsText | ConvertFrom-Json
    $presetAgents = Get-Content (Join-Path $repoRoot "presets\$preset\AGENTS.md") -Raw
    $presetClaude = Get-Content (Join-Path $repoRoot "presets\$preset\CLAUDE.md") -Raw
    $presetGuide = Get-Content (Join-Path $repoRoot "presets\$preset\PROJECT-WORKING-GUIDE.md") -Raw
    $presetOrderDocuments = @($presetWorkflow, $presetSkillsText, $presetAgents, $presetClaude, $presetGuide)
    $presetOrdersValid = @($presetOrderDocuments | Where-Object {
        -not (Test-OrderedTokens -Content $_ -Tokens $specKitCommandOrder) -or
        -not (Test-OrderedTokens -Content $_ -Tokens $specKitSkillOrder)
    }).Count -eq 0
    if (($presetWorkflow -match 'planning:\s+spec-kit') -and
        ($presetWorkflow -match 'implementation:\s+after-speckit-analyze') -and
        ($presetWorkflow -match 'require_before_implementation:\s+true') -and
        ($presetSkills.authority.optional_executor_skills_may_replace_planning -eq $false) -and
        ($presetAgents -match 'must not replace Spec\s+Kit') -and
        $presetOrdersValid) {
        Write-Pass "preset/$preset enforces workflow authority"
    } else {
        Write-Fail "preset/$preset must enforce workflow authority"
    }

    $presetBomFiles = @($presetFiles | Where-Object {
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $repoRoot "presets\$preset\$_"))
        ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
    })
    if ($presetBomFiles.Count -eq 0) {
        Write-Pass "preset/$preset uses UTF-8 without BOM"
    } else {
        Write-Fail "preset/$preset contains UTF-8 BOM files: $($presetBomFiles -join ', ')"
    }

    $presetCrFiles = @($presetFiles | Where-Object {
        [System.IO.File]::ReadAllText((Join-Path $repoRoot "presets\$preset\$_")).Contains("`r")
    })
    if ($presetCrFiles.Count -eq 0) {
        Write-Pass "preset/$preset uses repository LF line endings"
    } else {
        Write-Fail "preset/$preset contains CR line endings: $($presetCrFiles -join ', ')"
    }
}

$genericPresetSkills = Get-Content (Join-Path $repoRoot 'presets\generic\.ai-skills.json') -Raw | ConvertFrom-Json
if (($genericPresetSkills.skills.conditional_required.name -contains 'wp-guard') -and
    -not ($genericPresetSkills.skills.required.name -contains 'wp-guard')) {
    Write-Pass 'generic preset keeps WordPress guards conditional'
} else {
    Write-Fail 'generic preset must not require WordPress guards globally'
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
    @{ rel = 'README.md';                  minLines = 100 }
    @{ rel = 'templates\AGENTS.md';        minLines = 20 }
    @{ rel = 'templates\CLAUDE.md';        minLines = 10 }
    @{ rel = 'templates\PROJECT-WORKING-GUIDE.md'; minLines = 20 }
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

$skillPolicy = Get-Content (Join-Path $repoRoot 'templates\.ai-skills.json') -Raw | ConvertFrom-Json
$workflowPolicy = Get-Content (Join-Path $repoRoot 'templates\.ai-workflow.yml') -Raw
if (($skillPolicy.authority.startup -eq 'project-workflow') -and
    ($skillPolicy.authority.planning -eq 'spec-kit') -and
    ($skillPolicy.authority.implementation -eq 'after-speckit-analyze') -and
    ($skillPolicy.authority.optional_executor_skills_may_replace_planning -eq $false) -and
    ($workflowPolicy -match 'workflow_authority:') -and
    ($workflowPolicy -match 'implementation:\s+after-speckit-analyze') -and
    ($workflowPolicy -match 'require_before_implementation:\s+true')) {
    Write-Pass 'templates encode workflow authority and Spec Kit enforcement'
} else {
    Write-Fail 'templates must encode workflow authority and Spec Kit enforcement'
}
$documentedSkills = @($skillPolicy.skills.required) + @($skillPolicy.skills.conditional_required)
$guardNames = @('clean-code-guard', 'test-guard', 'docs-guard', 'wp-guard', 'woo-guard')
$invalidGuardPolicies = [System.Collections.Generic.List[string]]::new()
foreach ($guardName in $guardNames) {
    $guard = @($documentedSkills | Where-Object { $_.name -eq $guardName }) | Select-Object -First 1
    if (-not $guard -or
        $guard.install_approved -ne $false -or
        $guard.install_command -ne "npx -y skills add amElnagdy/guard-skills --skill $guardName --global --agent claude-code --agent codex --copy") {
        $invalidGuardPolicies.Add($guardName)
    }
}
if ($invalidGuardPolicies.Count -eq 0) {
    Write-Pass 'companion guards have verified manual install commands'
} else {
    Write-Fail "companion guard install policy is incomplete: $($invalidGuardPolicies -join ', ')"
}

$formatScope = @(
    Get-Item (Join-Path $repoRoot 'README.md')
    Get-ChildItem (Join-Path $repoRoot 'docs') -File -Filter '*.md'
    Get-Item (Join-Path $repoRoot 'templates\AGENTS.md')
    Get-Item (Join-Path $repoRoot 'templates\CLAUDE.md')
    Get-Item (Join-Path $repoRoot 'templates\PROJECT-WORKING-GUIDE.md')
    Get-Item (Join-Path $repoRoot 'templates\.ai-workflow.yml')
    Get-Item (Join-Path $repoRoot 'templates\.ai-skills.json')
    Get-ChildItem (Join-Path $repoRoot 'presets') -File -Recurse
    Get-ChildItem (Join-Path $repoRoot 'scripts') -File -Recurse -Filter '*.ps1'
)
$collapsedFiles = [System.Collections.Generic.List[string]]::new()
foreach ($file in $formatScope) {
    $lines = @(Get-Content -LiteralPath $file.FullName)
    $maxLength = ($lines | Measure-Object -Property Length -Maximum).Maximum
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $hasLineFeed = $bytes -contains 0x0A
    if (($lines.Count -lt 2) -or (-not $hasLineFeed) -or ($maxLength -gt 500)) {
        $collapsedFiles.Add($file.FullName.Substring($repoRoot.Length + 1))
    }
}
if ($collapsedFiles.Count -eq 0) {
    Write-Pass "docs, presets, and scripts are not collapsed ($($formatScope.Count) files checked)"
} else {
    Write-Fail "collapsed files detected: $($collapsedFiles -join ', ')"
}

if (Test-Path (Join-Path $repoRoot '.gitattributes')) {
    Write-Pass '.gitattributes defines repository line-ending policy'
} else {
    Write-Fail '.gitattributes is required for deterministic line endings'
}

if (Test-Path (Join-Path $repoRoot '.github\workflows\verify.yml')) {
    Write-Pass 'repository self-verification CI workflow exists'
} else {
    Write-Fail '.github/workflows/verify.yml is required for repository self-validation'
}

# ─── Result ────────────────────────────────────────────────────────────────
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host " RESULTS: $pass passed | $warn warnings | $fail failed" -ForegroundColor $(
    if ($fail -gt 0) { 'Red' } elseif ($warn -gt 0) { 'Yellow' } else { 'Green' }
)
Write-Host "================================================`n" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
if ($warn -gt 0) { exit 1 }
exit 0
