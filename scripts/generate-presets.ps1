#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$presetRoot = Join-Path $repoRoot 'presets'
. (Join-Path $PSScriptRoot 'lib\JsonFormatting.ps1')
$managedStart = '<!-- agent-project-workflow:start -->'
$managedEnd = '<!-- agent-project-workflow:end -->'
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
$specKitOrderText = @'
Production commands:

/speckit.constitution
/speckit.specify
/speckit.clarify
/speckit.plan
/speckit.checklist
/speckit.tasks
/speckit.analyze
/speckit.implement
/speckit.converge

Codex skills mode:

$speckit-constitution
$speckit-specify
$speckit-clarify
$speckit-plan
$speckit-checklist
$speckit-tasks
$speckit-analyze
$speckit-implement
$speckit-converge

Do not skip or reorder steps. Run converge when available and needed; otherwise record why it was not applicable.
'@

$presets = @(
    @{ name = 'generic'; wordpress = $false; woo = $false; description = 'Generic software project workflow.' }
    @{ name = 'wordpress'; wordpress = $true; woo = $false; description = 'Base WordPress workflow.' }
    @{ name = 'wordpress-site'; wordpress = $true; woo = $false; description = 'Whole-site WordPress workflow.' }
    @{ name = 'wordpress-plugin'; wordpress = $true; woo = $false; description = 'Standalone WordPress plugin workflow.' }
    @{ name = 'wordpress-theme'; wordpress = $true; woo = $false; description = 'Standalone WordPress theme workflow.' }
    @{ name = 'wordpress-block'; wordpress = $true; woo = $false; description = 'WordPress block workflow.' }
    @{ name = 'wordpress-woocommerce'; wordpress = $true; woo = $true; description = 'WooCommerce workflow with high-risk commerce guards.' }
    @{ name = 'wordpress-bedrock'; wordpress = $true; woo = $false; description = 'Bedrock-based WordPress workflow.' }
)

function Set-GeneratedFile {
    param([string]$Path, [string]$Content)
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $normalizedContent = (($Content -replace "`r`n", "`n") -replace "`r", "`n").TrimEnd("`n") + "`n"
    [System.IO.File]::WriteAllText($Path, $normalizedContent, $utf8NoBom)
}

function Get-InstallCommand {
    param([string]$SkillName)

    if ($SkillName -eq 'project-workflow') {
        return 'npx -y skills add MustafaShaaban/agent-project-workflow --skill project-workflow --global --agent claude-code --agent codex --copy'
    }
    if ($SkillName -in @('clean-code-guard', 'test-guard', 'docs-guard', 'wp-guard', 'woo-guard')) {
        return "npx -y skills add amElnagdy/guard-skills --skill $SkillName --global --agent claude-code --agent codex --copy"
    }
    return $null
}

foreach ($preset in $presets) {
    $root = Join-Path $presetRoot $preset.name
    if (-not (Test-Path $root)) { New-Item -ItemType Directory -Path $root -Force | Out-Null }

    $requiredSkills = @('project-workflow', 'clean-code-guard', 'test-guard', 'docs-guard')
    if ($preset.wordpress) { $requiredSkills += 'wp-guard' }
    if ($preset.woo) { $requiredSkills += 'woo-guard' }
    $skillsPolicy = [ordered]@{
        version = '1.0'
        install_mode = 'ask'
        authority = [ordered]@{
            startup = 'project-workflow'
            planning = 'spec-kit'
            safety = 'conditional-guard-skills'
            implementation = 'after-speckit-analyze'
            optional_executor_skills_may_replace_planning = $false
            owner_override_required = $true
        }
        spec_kit = [ordered]@{
            enforced_order = $specKitCommandOrder
            codex_skills_mode_order = $specKitSkillOrder
            converge = 'when-available-and-needed'
        }
        skills = [ordered]@{
            required = @($requiredSkills | ForEach-Object {
                [ordered]@{
                    name = $_
                    install_approved = ($_ -eq 'project-workflow')
                    install_command = Get-InstallCommand -SkillName $_
                }
            })
            conditional_required = @(
                [ordered]@{ name = 'wp-guard'; condition = 'wordpress_detected'; install_approved = $false }
                [ordered]@{ name = 'woo-guard'; condition = 'woocommerce_detected'; install_approved = $false }
            )
            optional = if ($preset.wordpress) { @('wp-plugin-development', 'wp-block-development', 'wp-performance', 'wp-phpstan', 'wp-playground') } else { @() }
        }
    }
    $skillsJson = ConvertTo-ReadableJson -InputObject $skillsPolicy -Depth 8

    $workflowYaml = @"
workflow:
  version: "0.3.0"
  profile: standard
  archetype: $($preset.name)
  automatic_activation: true
workflow_authority:
  startup: project-workflow
  planning: spec-kit
  implementation: after-speckit-analyze
  verification: project-workflow
  optional_executor_skills_may_replace_planning: false
branching:
  strategy: github-flow
  production_branch: main
spec_kit:
  enabled: true
  mode: ask-to-initialize
  use_for_non_trivial_work: true
  enforce_for_non_trivial_work: true
  require_before_implementation: true
  enforced_order:
    - "/speckit.constitution"
    - "/speckit.specify"
    - "/speckit.clarify"
    - "/speckit.plan"
    - "/speckit.checklist"
    - "/speckit.tasks"
    - "/speckit.analyze"
    - "/speckit.implement"
    - "/speckit.converge"
  codex_skills_mode_order:
    - "`$speckit-constitution"
    - "`$speckit-specify"
    - "`$speckit-clarify"
    - "`$speckit-plan"
    - "`$speckit-checklist"
    - "`$speckit-tasks"
    - "`$speckit-analyze"
    - "`$speckit-implement"
    - "`$speckit-converge"
  converge: when-available-and-needed
skills:
  install_mode: ask
safety:
  dry_run_default: true
  managed_blocks: true
  preserve_user_files: true
"@

    $agents = @"
# Agent Instructions

$managedStart
For every project request, even if the user does not mention `project-workflow`, automatically follow the startup sequence in `PROJECT-WORKING-GUIDE.md` before planning, editing, running commands, committing, pushing, or merging.

Use one real Git root, preserve user work, protect generated/vendor/build/cache/upload paths, use Spec Kit for non-trivial work, update progress/decisions, run guards, and end with mandatory NEXT STEP.

Project-workflow owns startup and verification. Spec Kit owns the exact enforced
stages. Guard skills own conditional safety. Optional skills must not replace Spec
Kit unless the owner explicitly overrides this policy. Implement only after analyze.

$specKitOrderText
$managedEnd

## Project-specific notes
"@

    $claude = @"
# Claude Code Entry Point

$managedStart
Read `AGENTS.md`, `.ai-workflow.yml`, `.ai-skills.json`, `.agent-workflow.lock.json`, and `PROJECT-WORKING-GUIDE.md`. Automatically follow project-workflow for every request. Use Spec Kit as the non-trivial planning authority; optional skills must not replace it.

$specKitOrderText
$managedEnd

## Project-specific notes
"@

    $guide = @"
# Project Working Guide

$managedStart
Resolve the real root; inspect status, branch, remotes, and worktrees; detect platform, CI, and archetype; read workflow, lock, instruction, progress, decision, constitution, and active-spec files; state mode and recommended next step.

Classify tasks as Tiny, Normal, or High-risk. Non-trivial work requires every
enforced Spec Kit stage through analyze before implementation. Optional executor
skills may help only after analyze passes.

$specKitOrderText
$managedEnd

## Project-specific notes
"@

    $progress = @"
# Progress

## Done

- Project workflow initialized from the $($preset.name) preset.

## In progress

- None.

## Next

- Run project-workflow doctor.

## Open decisions

- None.

## Last session summary

- Preset installed.
"@

    $decisions = @"
# Decisions

## Decision log

### YYYY-MM-DD - Initial workflow defaults

- **Decision:** Use the $($preset.name) archetype and standard profile.
- **Reason:** Selected during project-workflow initialization.
- **Impact:** Repo-local automatic activation and guard rules apply.
- **Revisit trigger:** Project archetype or risk profile changes.
"@

    $wordpressRules = if ($preset.wordpress) {
@"

## WordPress rules

Never edit WordPress core. Use WordPress APIs, sanitize input, escape output, use nonces and capabilities, prepare queries, keep strings translation-ready, load assets conditionally, and keep business logic in the correct plugin/theme/block mode.
"@
    } else { '' }
    $wooRules = if ($preset.woo) {
@"

## WooCommerce rules

Checkout, orders, payments, shipping, tax, customer data, and PII are high-risk. Require WooCommerce mode, `woo-guard`, and Spec Kit.
"@
    } else { '' }
    $constitution = @"
# Project Constitution

$managedStart
Use the source-of-truth hierarchy, durable progress/decisions, Spec Kit before non-trivial code, tests/guards before completion, docs with code, CI awareness, branch safety, one real root, recommendation-first questions, and mandatory handoff/NEXT STEP.

$specKitOrderText
$wordpressRules$wooRules
$managedEnd

## Project-specific notes
"@

    Set-GeneratedFile -Path (Join-Path $root '.ai-workflow.yml') -Content $workflowYaml
    Set-GeneratedFile -Path (Join-Path $root '.ai-skills.json') -Content $skillsJson
    Set-GeneratedFile -Path (Join-Path $root 'AGENTS.md') -Content $agents
    Set-GeneratedFile -Path (Join-Path $root 'CLAUDE.md') -Content $claude
    Set-GeneratedFile -Path (Join-Path $root 'PROJECT-WORKING-GUIDE.md') -Content $guide
    Set-GeneratedFile -Path (Join-Path $root 'PROGRESS.md') -Content $progress
    Set-GeneratedFile -Path (Join-Path $root 'DECISIONS.md') -Content $decisions
    Set-GeneratedFile -Path (Join-Path $root 'specs\constitution.md') -Content $constitution

    $readmePath = Join-Path $root 'README.md'
    if (-not (Test-Path $readmePath)) {
        Set-GeneratedFile -Path $readmePath -Content "# $($preset.name) Preset`n`n$($preset.description)"
    }
}

Write-Host "Generated $($presets.Count) preset payloads under $presetRoot"
