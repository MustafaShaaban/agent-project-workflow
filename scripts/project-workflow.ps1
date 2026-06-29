#Requires -Version 5.1
<#
.SYNOPSIS
    First-class project-workflow command router.

.DESCRIPTION
    PowerShell MVP for the project-workflow CLI. Supports safe init, audit,
    doctor, upgrade, new, and install-skills commands while preserving existing
    user files and using managed blocks for workflow-owned content.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('init', 'new', 'audit', 'doctor', 'upgrade', 'install-skills', 'help')]
    [string]$Command = 'help',

    [string]$TargetPath = (Get-Location).Path,
    [string]$ProjectName,
    [ValidateSet('auto', 'generic', 'wordpress', 'wordpress-site', 'wordpress-plugin', 'wordpress-theme', 'wordpress-block', 'wordpress-woocommerce', 'wordpress-bedrock', 'php', 'laravel', 'js-ts', 'react', 'vue', 'nextjs', 'python', 'dotnet', 'unknown')]
    [string]$Type = 'auto',
    [ValidateSet('minimal', 'standard', 'strict', 'enterprise')]
    [string]$Profile = 'standard',
    [string]$Bundle = '',
    [switch]$SpecKit,
    [string[]]$Agents = @('codex', 'claude-code'),
    [switch]$DryRun,
    [switch]$Apply,
    [switch]$Json,
    [switch]$Ci,
    [switch]$ApprovedOnly
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib\WorkflowDetection.ps1')

$ManagedStart = '<!-- agent-project-workflow:start -->'
$ManagedEnd = '<!-- agent-project-workflow:end -->'
$WorkflowVersion = '0.3.0'

function Write-InfoLine { param([string]$Message) Write-Host $Message }

function Resolve-TargetRoot {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    return [System.IO.Path]::GetFullPath($Path)
}

function Get-CiStatus {
    param([string]$Root)
    $items = [System.Collections.Generic.List[string]]::new()
    if (Test-Path (Join-Path $Root '.github\workflows')) { $items.Add('github-actions') }
    if ((Test-Path (Join-Path $Root 'azure-pipelines.yml')) -or (Test-Path (Join-Path $Root '.azure\pipelines'))) { $items.Add('azure-pipelines') }
    if (Test-Path (Join-Path $Root 'Jenkinsfile')) { $items.Add('jenkins') }
    if (Test-Path (Join-Path $Root '.circleci')) { $items.Add('circleci') }
    if (Test-Path (Join-Path $Root '.travis.yml')) { $items.Add('travis') }
    if ($items.Count -eq 0) { $items.Add('none') }
    return $items.ToArray()
}

function Get-Archetype {
    param([string]$Root, [string]$RequestedType)
    if ($RequestedType -ne 'auto') { return $RequestedType }
    return Get-WfArchetype -ProjectRoot $Root
}

function Get-ProjectTypeFromArchetype {
    param([string]$Archetype)
    if ($Archetype -match '^wordpress') { return 'wordpress' }
    return $Archetype
}

function Get-RequiredSkills {
    param([string]$Archetype, [string]$Profile)
    $required = [System.Collections.Generic.List[string]]::new()
    $optional = [System.Collections.Generic.List[string]]::new()
    $required.Add('project-workflow')
    if ($Profile -in @('standard', 'strict', 'enterprise')) {
        $required.Add('clean-code-guard')
        $required.Add('test-guard')
        $required.Add('docs-guard')
    }
    if ($Archetype -match '^wordpress') {
        $required.Add('wp-guard')
        $optional.Add('wp-plugin-development')
        $optional.Add('wp-block-development')
        $optional.Add('wp-performance')
        $optional.Add('wp-phpstan')
        $optional.Add('wp-playground')
    }
    if ($Archetype -eq 'wordpress-woocommerce') {
        $required.Add('woo-guard')
    }
    return @{
        required = $required.ToArray()
        optional = $optional.ToArray()
    }
}

function Get-StartupSequenceText {
@"
For every project request, even if the user does not mention `project-workflow`, automatically follow the project-workflow startup sequence before planning, editing, writing code, changing docs, running commands, committing, pushing, or merging.

Startup sequence:

1. Resolve the real Git root with `git rev-parse --show-toplevel`.
2. Confirm the current directory is the root or move to the root.
3. Check `git status --short --branch`.
4. Check the current branch.
5. Check remotes.
6. Check worktrees.
7. Detect platform.
8. Detect CI/CD.
9. Detect project type/archetype.
10. Read `.ai-workflow.yml`.
11. Read `.ai-skills.json`.
12. Read `.agent-workflow.lock.json` if present.
13. Read `AGENTS.md`.
14. Read `CLAUDE.md` if present.
15. Read `PROJECT-WORKING-GUIDE.md`.
16. Read `PROGRESS.md`.
17. Read `DECISIONS.md`.
18. Read `specs/constitution.md` or `.specify/memory/constitution.md`.
19. Read the active spec if present.
20. State detected mode and recommended next step before implementation.

Question rule: ask only useful questions that cannot be safely detected. Every question must include Detected, Recommended, Why, Alternatives, Impact, Question, and Default if you approve.
"@
}

function New-ManagedDocument {
    param([string]$Title, [string]$Body, [string]$ProjectNotes = 'Project-specific notes belong here and are preserved during upgrades.')
@"
# $Title

$ManagedStart
$Body
$ManagedEnd

## Project-specific notes

$ProjectNotes
"@
}

function Set-WorkflowFile {
    param(
        [string]$Root,
        [string]$RelativePath,
        [string]$Content,
        [bool]$ApplyChanges,
        [System.Collections.Generic.List[string]]$Generated,
        [System.Collections.Generic.List[string]]$Suggested,
        [System.Collections.Generic.List[string]]$Skipped
    )

    $path = Join-Path $Root $RelativePath
    $dir = Split-Path -Parent $path
    if (-not $ApplyChanges) {
        Write-InfoLine "DRY-RUN: would create/update $RelativePath"
        return
    }
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if (-not (Test-Path -LiteralPath $path)) {
        Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
        $Generated.Add($RelativePath)
        Write-InfoLine "CREATED: $RelativePath"
        return
    }

    $existing = Get-Content -LiteralPath $path -Raw
    if ($existing -match [regex]::Escape($ManagedStart) -and $existing -match [regex]::Escape($ManagedEnd)) {
        $pattern = "(?s)$([regex]::Escape($ManagedStart)).*?$([regex]::Escape($ManagedEnd))"
        $replacement = ($Content -replace "(?s)^.*?$([regex]::Escape($ManagedStart))", $ManagedStart) -replace "(?s)$([regex]::Escape($ManagedEnd)).*$", $ManagedEnd
        $updated = [regex]::Replace($existing, $pattern, $replacement)
        Set-Content -LiteralPath $path -Value $updated -Encoding UTF8
        $Generated.Add($RelativePath)
        Write-InfoLine "UPDATED MANAGED BLOCK: $RelativePath"
        return
    }

    $suggestedPath = "$path.suggested.md"
    Set-Content -LiteralPath $suggestedPath -Value $Content -Encoding UTF8
    $Suggested.Add("$RelativePath.suggested.md")
    $Skipped.Add($RelativePath)
    Write-InfoLine "SUGGESTED: $RelativePath.suggested.md (existing file has no managed block)"
}

function New-WorkflowLock {
    param(
        [string]$Root,
        [string]$Archetype,
        [string]$Profile,
        [bool]$SpecKitEnabled,
        [string[]]$Agents,
        [string[]]$GeneratedFiles,
        [string]$SpecKitStatus,
        [string[]]$SpecKitCommands
    )
    $platform = Get-WfPlatform -ProjectRoot $Root
    $ci = Get-CiStatus -Root $Root
    $skills = Get-RequiredSkills -Archetype $Archetype -Profile $Profile
    return [ordered]@{
        workflow_version = $WorkflowVersion
        init_timestamp = (Get-Date).ToUniversalTime().ToString('o')
        project_type = Get-ProjectTypeFromArchetype -Archetype $Archetype
        archetype = $Archetype
        profile = $Profile
        branching = [ordered]@{
            strategy = 'github-flow'
            production_branch = 'main'
            integration_branch = $null
        }
        detected_platform = $platform
        detected_ci = $ci
        spec_kit = [ordered]@{
            enabled = $SpecKitEnabled
            integrations = $Agents
            skills_mode = $true
            status = $SpecKitStatus
            commands = $SpecKitCommands
        }
        skills = [ordered]@{
            install_mode = 'ask'
            required = $skills.required
            optional = $skills.optional
        }
        generated_files = [ordered]@{
            'AGENTS.md' = 'managed-block'
            'CLAUDE.md' = 'managed-block'
            'PROJECT-WORKING-GUIDE.md' = 'managed-block'
            'PROGRESS.md' = 'user-owned'
            'DECISIONS.md' = 'user-owned'
            'specs/constitution.md' = 'managed-block'
        }
        managed_files = $GeneratedFiles
        user_owned_files = @('PROGRESS.md', 'DECISIONS.md')
        preset_bundle_version = $WorkflowVersion
    }
}

function Get-NormalizedAgents {
    param([string[]]$AgentValues)
    return @($AgentValues | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
}

function Write-InitQuestion {
    param([string]$Root)
    Write-InfoLine 'Detected: No reliable project type or archetype indicators were found.'
    Write-InfoLine 'Recommended: Select `generic` unless this directory is intended for a known framework or WordPress archetype.'
    Write-InfoLine 'Why: Explicit selection prevents the workflow from generating the wrong constitution and required-skill policy.'
    Write-InfoLine 'Alternatives: wordpress-site, wordpress-plugin, wordpress-theme, wordpress-block, wordpress-woocommerce, wordpress-bedrock, php, laravel, js-ts, react, vue, nextjs, python, dotnet, or unknown.'
    Write-InfoLine 'Impact: The selected type controls generated rules, required guards, presets, and lock metadata.'
    Write-InfoLine 'Question: Which project type should be initialized?'
    Write-InfoLine 'Default if you approve: generic'
    Write-InfoLine "Recommended next command: .\scripts\project-workflow.ps1 init -TargetPath `"$Root`" -Type generic -Profile standard -DryRun"
}

function Invoke-SpecKitSetup {
    param([string]$Root, [bool]$ApplyChanges, [string[]]$RequestedAgents)
    $result = [ordered]@{
        status = 'disabled'
        commands = @()
    }
    if (-not $SpecKit) { return $result }

    if (Test-Path (Join-Path $Root '.specify')) {
        Write-InfoLine 'Spec Kit already present: preserving existing .specify/ state.'
        $result.status = 'existing-preserved'
        return $result
    }

    $specify = Get-Command specify -ErrorAction SilentlyContinue
    if (-not $specify) {
        Write-InfoLine 'Spec Kit requested but `specify` was not found.'
        $result.status = 'requested-unavailable'
        return $result
    }

    $listCommand = 'specify integration list'
    $result.commands += $listCommand
    $integrationOutput = & specify integration list 2>&1 | Out-String
    $listExitCode = $LASTEXITCODE
    Write-InfoLine $listCommand
    if ($listExitCode -ne 0) {
        $checkCommand = 'specify check'
        $result.commands += $checkCommand
        $integrationOutput = & specify check 2>&1 | Out-String
        Write-InfoLine "$listCommand was unavailable before initialization; used $checkCommand for tool availability."
    }

    if (-not $ApplyChanges) {
        foreach ($agent in $RequestedAgents) {
            $candidate = if ($agent -eq 'claude-code') { 'claude' } else { $agent }
            $result.commands += "specify init --here --force --integration $candidate"
        }
        $result.status = 'available-dry-run'
        return $result
    }

    Push-Location $Root
    try {
        $initialized = [System.Collections.Generic.List[string]]::new()
        $resolvedIntegrations = @($RequestedAgents | ForEach-Object {
            if ($_ -eq 'claude-code') { 'claude' } else { $_ }
        } | Select-Object -Unique)
        for ($index = 0; $index -lt $resolvedIntegrations.Count; $index++) {
            $integration = $resolvedIntegrations[$index]
            if ($integrationOutput -notmatch "(?im)\b$([regex]::Escape($integration))\b") {
                Write-InfoLine "Spec Kit did not report integration '$integration'; using the explicit requested identifier."
            }
            $commandText = if ($index -eq 0) {
                "specify init --here --force --integration $integration"
            } else {
                "specify integration install --force $integration"
            }
            $result.commands += $commandText
            Write-InfoLine $commandText
            if ($index -eq 0) {
                & specify init --here --force --integration $integration
            } else {
                & specify integration install --force $integration
            }
            if ($LASTEXITCODE -ne 0) { throw "Spec Kit initialization failed for integration '$integration'." }
            $initialized.Add($integration)
        }
        $result.status = if ($initialized.Count -gt 0) { 'initialized' } else { 'available-no-matching-integration' }
    } finally {
        Pop-Location
    }
    return $result
}

function Invoke-Init {
    $root = Resolve-TargetRoot -Path $TargetPath
    $applyChanges = $Apply.IsPresent
    if (-not $applyChanges) { $DryRun = $true }
    $archetype = if ($Bundle) { ($Bundle -replace '-standard$','' -replace '-strict$','') } else { Get-Archetype -Root $root -RequestedType $Type }
    if ($Bundle -match 'strict') { $script:Profile = 'strict' }
    if (($Type -eq 'auto') -and ($archetype -eq 'unknown')) {
        Write-InitQuestion -Root $root
        return
    }

    Write-InfoLine "project-workflow init"
    Write-InfoLine "Target: $root"
    Write-InfoLine "Mode: $(if ($applyChanges) { 'APPLY' } else { 'DRY-RUN' })"
    Write-InfoLine "Archetype: $archetype"
    Write-InfoLine "Profile: $Profile"

    $generated = [System.Collections.Generic.List[string]]::new()
    $suggested = [System.Collections.Generic.List[string]]::new()
    $skipped = [System.Collections.Generic.List[string]]::new()
    $normalizedAgents = Get-NormalizedAgents -AgentValues $Agents
    $startup = Get-StartupSequenceText
    $constitutionBody = Get-ConstitutionBody -Archetype $archetype

    $agentsBody = @"
## Automatic activation

$startup

## Safety rules

- Work from the real Git root only.
- Preserve user changes and never rewrite history.
- Do not edit generated, vendor, build, cache, or upload directories unless the owner explicitly requires it.
- Use Spec Kit for non-trivial, multi-file, security, API, database, CI/CD, WordPress production, and WooCommerce work.
- Keep `PROGRESS.md` and `DECISIONS.md` current when progress or durable decisions change.
"@
    Set-WorkflowFile -Root $root -RelativePath 'AGENTS.md' -Content (New-ManagedDocument -Title 'Agent Instructions' -Body $agentsBody) -ApplyChanges $applyChanges -Generated $generated -Suggested $suggested -Skipped $skipped
    Set-WorkflowFile -Root $root -RelativePath 'CLAUDE.md' -Content (New-ManagedDocument -Title 'Claude Code Entry Point' -Body "Read `AGENTS.md`, `.ai-workflow.yml`, `.ai-skills.json`, `.agent-workflow.lock.json`, and `PROJECT-WORKING-GUIDE.md`. $startup") -ApplyChanges $applyChanges -Generated $generated -Suggested $suggested -Skipped $skipped
    Set-WorkflowFile -Root $root -RelativePath 'PROJECT-WORKING-GUIDE.md' -Content (New-ManagedDocument -Title 'Project Working Guide' -Body (Get-WorkingGuideBody)) -ApplyChanges $applyChanges -Generated $generated -Suggested $suggested -Skipped $skipped
    Set-WorkflowFile -Root $root -RelativePath 'specs\constitution.md' -Content (New-ManagedDocument -Title 'Project Constitution' -Body $constitutionBody) -ApplyChanges $applyChanges -Generated $generated -Suggested $suggested -Skipped $skipped
    Set-WorkflowFile -Root $root -RelativePath '.ai-workflow.yml' -Content (Get-WorkflowConfigTemplate -Archetype $archetype -Profile $Profile) -ApplyChanges $applyChanges -Generated $generated -Suggested $suggested -Skipped $skipped
    Set-WorkflowFile -Root $root -RelativePath '.ai-skills.json' -Content (Get-SkillsJson -Archetype $archetype -Profile $Profile) -ApplyChanges $applyChanges -Generated $generated -Suggested $suggested -Skipped $skipped

    $specKitResult = Invoke-SpecKitSetup -Root $root -ApplyChanges $applyChanges -RequestedAgents $normalizedAgents

    if ($applyChanges) {
        Set-UserOwnedFile -Root $root -RelativePath 'PROGRESS.md' -Content (Get-ProgressTemplate)
        Set-UserOwnedFile -Root $root -RelativePath 'DECISIONS.md' -Content (Get-DecisionsTemplate -Archetype $archetype -Profile $Profile)
        $lock = New-WorkflowLock -Root $root -Archetype $archetype -Profile $Profile -SpecKitEnabled $SpecKit.IsPresent -Agents $normalizedAgents -GeneratedFiles $generated.ToArray() -SpecKitStatus $specKitResult.status -SpecKitCommands $specKitResult.commands
        $lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root '.agent-workflow.lock.json') -Encoding UTF8
        Write-InfoLine 'CREATED: .agent-workflow.lock.json'
    } else {
        Write-InfoLine 'DRY-RUN: would create/update .agent-workflow.lock.json'
    }

    Write-InfoLine "Recommended next command: .\scripts\project-workflow.ps1 doctor -TargetPath `"$root`""
}

function Set-UserOwnedFile {
    param([string]$Root, [string]$RelativePath, [string]$Content)
    $path = Join-Path $Root $RelativePath
    if (Test-Path -LiteralPath $path) {
        Write-InfoLine "PRESERVED: $RelativePath"
        return
    }
    Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
    Write-InfoLine "CREATED: $RelativePath"
}

function Get-WorkflowConfigTemplate {
    param([string]$Archetype, [string]$Profile)
@"
workflow:
  version: "$WorkflowVersion"
  profile: $Profile
  mode: normal
  archetype: $Archetype
  automatic_activation: true

branching:
  strategy: github-flow
  production_branch: main
  integration_branch: null

spec_kit:
  enabled: $($SpecKit.IsPresent.ToString().ToLowerInvariant())
  use_for_non_trivial_work: true

skills:
  install_mode: ask
  approved_only_command: ".\scripts\project-workflow.ps1 install-skills -ApprovedOnly"

safety:
  dry_run_default: true
  managed_blocks: true
  preserve_user_files: true
  protect_generated_vendor_build_cache_uploads: true
"@
}

function Get-SkillsJson {
    param([string]$Archetype, [string]$Profile)
    $skills = Get-RequiredSkills -Archetype $Archetype -Profile $Profile
    $required = @()
    foreach ($skill in $skills.required) {
        $required += [ordered]@{
            name = $skill
            install_approved = ($skill -eq 'project-workflow')
            install_command = if ($skill -eq 'project-workflow') { 'npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy' } else { $null }
            reason = "Required by $Profile profile for $Archetype projects."
        }
    }
    $optional = @()
    foreach ($skill in $skills.optional) {
        $optional += [ordered]@{
            name = $skill
            install_approved = $false
            install_command = $null
            reason = "Recommended for WordPress build work when relevant."
        }
    }
    ([ordered]@{
        version = '1.0'
        install_mode = 'ask'
        skills = [ordered]@{
            required = $required
            optional = $optional
        }
    } | ConvertTo-Json -Depth 8)
}

function Get-ConstitutionBody {
    param([string]$Archetype)
    $generic = @"
## Source of truth

Latest owner instruction wins, then repo instructions, this constitution, active specs, progress/decisions, docs, and implementation code.

## Required workflow

- Use one real Git root.
- Preserve user work.
- Use Spec Kit before code for non-trivial work.
- Run tests and guards before completion.
- Keep docs synchronized with code.
- Protect secrets and never expose credentials.
- Do not edit generated/vendor/build/cache/upload outputs as source.
- End with verification, recommended options, and mandatory NEXT STEP.
- Ask recommendation-first questions only when detection cannot answer safely.
"@
    if ($Archetype -notmatch '^wordpress') { return $generic }
    return @"
$generic

## WordPress rules

- Never edit WordPress core.
- Never treat uploads, cache, vendor, or build output as source.
- Use WordPress APIs.
- Sanitize input and escape output.
- Use nonces for state-changing requests.
- Use capabilities for authorization.
- Prepare database queries.
- Keep strings translation-ready.
- Keep business logic out of themes unless the project is theme-only and the logic is presentation-only.
- Plugin work belongs in plugin mode; theme work belongs in theme mode; block work belongs in block mode.
- WooCommerce checkout, order, payment, shipping, and tax work requires WooCommerce mode and `woo-guard`.
- Load frontend, admin, and block assets conditionally.
- Avoid global asset bloat and prefer progressive enhancement.
- Respect WordPress coding standards where applicable.
- Add tests where the repository supports tests.
- Use Spec Kit for non-trivial WordPress work.
"@
}

function Get-WorkingGuideBody {
@"
## Start

Run the startup sequence from `AGENTS.md`, classify the task as Tiny, Normal, or High-risk, and state the mode before implementation.

## Task risk

- Tiny: typo, small docs edit, obvious comment update, simple config cleanup. Proceed with a documented safe assumption.
- Normal: feature, behavior, API, integration, tests, docs plus code. Ask only missing implementation questions.
- High-risk: auth, authorization, payments, PII, security, database migration, deployment, CI/CD, production configuration, or WooCommerce checkout/order/payment/shipping/tax. Require Spec Kit and clarifying questions before implementation.

## Handoff

Finish with SUMMARY, WORKSPACE, MODE, SPEC KIT STATUS, VERIFICATION, BLOCKERS / DECISIONS NEEDED, RECOMMENDED OPTIONS, and NEXT STEP.
"@
}

function Get-ProgressTemplate {
@"
# Progress

## Done

- Project workflow initialized.

## In progress

- First project task is not selected yet.

## Next

- Run `project-workflow doctor` and choose the first project outcome.

## Open decisions

- None.

## Last session summary

- Workflow files, lock file, and local instructions were generated.
"@
}

function Get-DecisionsTemplate {
    param([string]$Archetype, [string]$Profile)
    $today = Get-Date -Format 'yyyy-MM-dd'
@"
# Decisions

## Decision log

### $today - Initial workflow defaults

- **Decision:** Use `$Archetype` archetype with `$Profile` profile, GitHub Flow branching, detected platform/CI, ask-mode skill installation, and Spec Kit status from the init command.
- **Reason:** These defaults are safe for existing repositories and preserve owner control.
- **Impact:** Agents follow repo-local startup instructions automatically and use managed blocks for workflow-owned content.
- **Revisit trigger:** Project type, branching model, CI provider, or risk profile changes.
"@
}

function Invoke-Audit {
    $audit = Join-Path $PSScriptRoot 'audit-project-workflow.ps1'
    if ($Json) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $audit -TargetPath $TargetPath -OutputFormat Json
    } else {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $audit -TargetPath $TargetPath
    }
}

function Invoke-Doctor {
    $root = Resolve-TargetRoot -Path $TargetPath
    $archetype = Get-WfArchetype -ProjectRoot $root
    $score = 100
    $passing = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $blocking = [System.Collections.Generic.List[string]]::new()

    foreach ($file in @('AGENTS.md','CLAUDE.md','PROJECT-WORKING-GUIDE.md','PROGRESS.md','DECISIONS.md','specs\constitution.md','.ai-workflow.yml','.ai-skills.json','.agent-workflow.lock.json')) {
        if (Test-Path (Join-Path $root $file)) { $passing.Add("$file exists") } else { $blocking.Add("$file missing"); $score -= 8 }
    }
    foreach ($file in @('AGENTS.md','CLAUDE.md','PROJECT-WORKING-GUIDE.md','specs\constitution.md')) {
        $path = Join-Path $root $file
        if ((Test-Path $path) -and ((Get-Content $path -Raw) -match [regex]::Escape($ManagedStart))) {
            $passing.Add("$file has managed block")
        } else {
            $warnings.Add("$file does not have a managed block")
            $score -= 3
        }
    }
    $agents = Join-Path $root 'AGENTS.md'
    if ((Test-Path $agents) -and ((Get-Content $agents -Raw) -match 'automatically follow the project-workflow startup sequence')) {
        $passing.Add('automatic activation rule present')
    } else {
        $blocking.Add('automatic activation rule missing')
        $score -= 12
    }
    $skillsPath = Join-Path $root '.ai-skills.json'
    if (Test-Path $skillsPath) {
        try {
            $skills = Get-Content $skillsPath -Raw | ConvertFrom-Json
            $documentedSkills = @($skills.skills.required | ForEach-Object { $_.name })
            foreach ($requiredSkill in (Get-RequiredSkills -Archetype $archetype -Profile 'standard').required) {
                if ($documentedSkills -contains $requiredSkill) {
                    $passing.Add("$requiredSkill skill documented")
                } else {
                    $blocking.Add("$requiredSkill skill missing for $archetype")
                    $score -= 8
                }
            }
        } catch {
            $blocking.Add('.ai-skills.json is not parseable')
            $score -= 10
        }
    }
    $lockPath = Join-Path $root '.agent-workflow.lock.json'
    if (Test-Path $lockPath) {
        try {
            $lock = Get-Content $lockPath -Raw | ConvertFrom-Json
            if ($lock.archetype -eq $archetype) {
                $passing.Add('lock file archetype matches detection')
            } else {
                $warnings.Add("lock archetype '$($lock.archetype)' differs from detected '$archetype'")
                $score -= 4
            }
        } catch {
            $blocking.Add('.agent-workflow.lock.json is not parseable')
            $score -= 10
        }
    }
    if ($score -lt 0) { $score = 0 }

    $recommendedNext = if ($blocking.Count -gt 0) { 'Run project-workflow init --apply or review suggested files.' } else { 'Run project-workflow audit before the next project task.' }
    if ($Json) {
        [ordered]@{
            score = $score
            status = if ($blocking.Count -gt 0) { 'blocking' } elseif ($warnings.Count -gt 0) { 'warning' } else { 'ready' }
            passing = $passing.ToArray()
            warnings = $warnings.ToArray()
            blocking = $blocking.ToArray()
            recommended_next = $recommendedNext
        } | ConvertTo-Json -Depth 5
        return
    }

    Write-InfoLine "Workflow readiness: $score/100"
    Write-InfoLine 'Passing:'
    foreach ($item in $passing) { Write-InfoLine "  - $item" }
    Write-InfoLine 'Warnings:'
    if ($warnings.Count -eq 0) { Write-InfoLine '  - None' } else { foreach ($item in $warnings) { Write-InfoLine "  - $item" } }
    Write-InfoLine 'Blocking:'
    if ($blocking.Count -eq 0) { Write-InfoLine '  - None' } else { foreach ($item in $blocking) { Write-InfoLine "  - $item" } }
    Write-InfoLine "Recommended next: $recommendedNext"
}

function Invoke-Upgrade {
    $script:Apply = $true
    Invoke-Init
}

function Invoke-NewProject {
    if (-not $ProjectName) { throw 'new requires -ProjectName <name>' }
    $target = Join-Path (Resolve-TargetRoot -Path $TargetPath) $ProjectName
    if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
    if (-not (Test-Path (Join-Path $target '.git'))) {
        Push-Location $target
        git init 2>$null | Out-Null
        Pop-Location
    }
    $script:TargetPath = $target
    $script:Apply = $true
    Invoke-Init
}

function Invoke-InstallSkills {
    $root = Resolve-TargetRoot -Path $TargetPath
    $path = Join-Path $root '.ai-skills.json'
    if (-not (Test-Path $path)) { throw '.ai-skills.json not found. Run project-workflow init first.' }
    $skills = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($skill in $skills.skills.required) {
        if ($ApprovedOnly -and -not $skill.install_approved) {
            Write-InfoLine "MANUAL: $($skill.name) is not approved for automatic install."
            continue
        }
        if ($skill.install_command) {
            if ($ApprovedOnly) {
                Invoke-ApprovedSkillCommand -Root $root -SkillName $skill.name -CommandText $skill.install_command
            } else {
                Write-InfoLine "Detected: Missing or requested skill '$($skill.name)'."
                Write-InfoLine "Recommended: Run the documented command after approval: $($skill.install_command)"
                Write-InfoLine 'Why: Skill installation changes global or local agent tooling.'
                Write-InfoLine 'Alternatives: Mark the skill manual, set install_mode to never, or use -ApprovedOnly for approved commands.'
                Write-InfoLine 'Impact: Work requiring this skill may remain blocked or carry an explicit risk.'
                Write-InfoLine "Question: Approve installation of '$($skill.name)'?"
                Write-InfoLine 'Default if you approve: Run the documented command.'
            }
        } else {
            Write-InfoLine "MANUAL: $($skill.name) has no safe install command."
        }
    }
    Write-InfoLine 'Recommended next command: project-workflow doctor'
}

function Invoke-ApprovedSkillCommand {
    param([string]$Root, [string]$SkillName, [string]$CommandText)
    if ($CommandText -match '[;&|<>`]' -or $CommandText -notmatch '^npx\s+-y\s+skills\s+add\s+') {
        throw "Approved install command for '$SkillName' is outside the safe allowlist."
    }
    $tokens = @($CommandText -split '\s+' | Where-Object { $_ })
    if ($tokens.Count -lt 6 -or $tokens[0] -ne 'npx' -or $tokens[1] -ne '-y' -or $tokens[2] -ne 'skills' -or $tokens[3] -ne 'add') {
        throw "Approved install command for '$SkillName' is malformed."
    }
    $arguments = @($tokens[1..($tokens.Count - 1)])
    Write-InfoLine "INSTALLING: $SkillName"
    Write-InfoLine "COMMAND: $CommandText"
    Push-Location $Root
    try {
        & npx @arguments
        if ($LASTEXITCODE -ne 0) { throw "Installation failed for '$SkillName' with exit code $LASTEXITCODE." }
    } finally {
        Pop-Location
    }
}

switch ($Command) {
    'init' { Invoke-Init }
    'new' { Invoke-NewProject }
    'audit' { Invoke-Audit }
    'doctor' { Invoke-Doctor }
    'upgrade' { Invoke-Upgrade }
    'install-skills' { Invoke-InstallSkills }
    default {
        Write-InfoLine 'Usage: project-workflow init|new|audit|doctor|upgrade|install-skills [options]'
        Write-InfoLine 'Recommended next command: .\scripts\project-workflow.ps1 init -Type wordpress-site -Profile standard -SpecKit -Agents codex,claude-code -DryRun'
    }
}
