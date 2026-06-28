# WorkflowDetection.ps1
# Shared detection helpers for workflow scripts.
# Dot-source this file: . (Join-Path $PSScriptRoot 'lib\WorkflowDetection.ps1')

function Get-WfConfig {
    <#
    .SYNOPSIS Returns a hashtable of .ai-workflow.yml values, with safe defaults.
    #>
    param([string]$ProjectRoot)
    $defaults = @{
        profile                     = 'standard'
        strategy                    = 'github-flow'
        production_branch           = 'main'
        integration_branch          = 'develop'
        never_implement_on_production  = $true
        never_implement_on_integration = $true
        require_clean_worktree      = $false
        require_verification        = $true
        install_mode                = 'ask'
        wordpress_guard_required    = $true
        mode                        = 'normal'
    }
    $configPath = Join-Path $ProjectRoot '.ai-workflow.yml'
    if (-not (Test-Path $configPath)) { return $defaults }
    try {
        $raw = Get-Content $configPath -Raw
        if ($raw -match 'profile:\s*(\S+)')              { $defaults.profile = $Matches[1] }
        if ($raw -match 'strategy:\s*(\S+)')             { $defaults.strategy = $Matches[1] }
        if ($raw -match 'production_branch:\s*(\S+)')    { $defaults.production_branch = $Matches[1] }
        if ($raw -match 'integration_branch:\s*(\S+)')   { $defaults.integration_branch = $Matches[1] }
        if ($raw -match 'never_implement_on_integration:\s*(true|false)') {
            $defaults.never_implement_on_integration = ($Matches[1] -eq 'true')
        }
        if ($raw -match 'require_clean_worktree:\s*(true|false)') {
            $defaults.require_clean_worktree = ($Matches[1] -eq 'true')
        }
        if ($raw -match 'require_verification_before_handoff:\s*(true|false)') {
            $defaults.require_verification = ($Matches[1] -eq 'true')
        }
        if ($raw -match 'install_mode:\s*(\S+)')         { $defaults.install_mode = $Matches[1] }
        if ($raw -match 'guard_required:\s*(true|false)') {
            $defaults.wordpress_guard_required = ($Matches[1] -eq 'true')
        }
        if ($raw -match 'mode:\s*(\S+)')                 { $defaults.mode = $Matches[1] }
    } catch {}
    return $defaults
}

function Get-WfPlatform {
    <#
    .SYNOPSIS Detects the Git hosting platform. Returns: github | azure-devops | generic-git
    #>
    param([string]$ProjectRoot)
    $remoteUrl = ''
    try {
        Push-Location $ProjectRoot
        $remoteUrl = (git remote get-url origin 2>$null).Trim()
    } catch {} finally { Pop-Location }

    if ($remoteUrl -match 'github\.com')                             { return 'github' }
    if ($remoteUrl -match 'dev\.azure\.com|visualstudio\.com')       { return 'azure-devops' }
    if (Test-Path (Join-Path $ProjectRoot '.github'))                 { return 'github' }
    if ((Test-Path (Join-Path $ProjectRoot 'azure-pipelines.yml')) -or
        (Test-Path (Join-Path $ProjectRoot '.azure')))                { return 'azure-devops' }
    return 'generic-git'
}

function Get-WfProjectType {
    <#
    .SYNOPSIS Detects the project type. Returns: wordpress | laravel | react | vue | nextjs | svelte | js/ts | php | dotnet | python | unknown
    #>
    param([string]$ProjectRoot)

    $wpIndicators = @('wp-config.php','wp-config-sample.php','wp-login.php','wp-blog-header.php','wp-content')
    foreach ($i in $wpIndicators) {
        if (Test-Path (Join-Path $ProjectRoot $i)) { return 'wordpress' }
    }
    if (Test-Path (Join-Path $ProjectRoot 'composer.json')) {
        $c = Get-Content (Join-Path $ProjectRoot 'composer.json') -Raw -ErrorAction SilentlyContinue
        if ($c -match 'johnpbloch/wordpress|roots/bedrock|wpackagist') { return 'wordpress' }
    }
    if (Test-Path (Join-Path $ProjectRoot 'package.json')) {
        $p = Get-Content (Join-Path $ProjectRoot 'package.json') -Raw -ErrorAction SilentlyContinue
        if ($p -match '"@wordpress/') { return 'wordpress' }
    }
    if (Test-Path (Join-Path $ProjectRoot 'artisan')) { return 'laravel' }
    if (Test-Path (Join-Path $ProjectRoot 'package.json')) {
        $p = Get-Content (Join-Path $ProjectRoot 'package.json') -Raw -ErrorAction SilentlyContinue
        if ($p -match '"next"')   { return 'nextjs' }
        if ($p -match '"react"')  { return 'react' }
        if ($p -match '"vue"')    { return 'vue' }
        if ($p -match '"svelte"') { return 'svelte' }
        return 'js/ts'
    }
    if (Test-Path (Join-Path $ProjectRoot 'composer.json')) { return 'php' }
    if ((Get-ChildItem $ProjectRoot -Filter '*.sln' -ErrorAction SilentlyContinue) -or
        (Get-ChildItem $ProjectRoot -Filter '*.csproj' -ErrorAction SilentlyContinue)) { return 'dotnet' }
    if ((Test-Path (Join-Path $ProjectRoot 'requirements.txt')) -or
        (Test-Path (Join-Path $ProjectRoot 'pyproject.toml')))  { return 'python' }
    return 'unknown'
}

function Get-WfBranchStrategy {
    <#
    .SYNOPSIS Detects likely branching strategy from existing branches.
    Returns: git-flow | git-flow-partial | github-flow | unknown
    #>
    param([string]$ProjectRoot)
    try {
        Push-Location $ProjectRoot
        $branches = @(git branch -a 2>$null)
        Pop-Location
        $hasDevelop = $branches -match '\bdevelop\b'
        $hasRelease = $branches -match 'release/'
        $hasHotfix  = $branches -match 'hotfix/'
        if ($hasDevelop -and ($hasRelease -or $hasHotfix)) { return 'git-flow' }
        if ($hasDevelop) { return 'git-flow-partial' }
        return 'github-flow'
    } catch { return 'unknown' }
}

function Test-WfWordPress {
    <#
    .SYNOPSIS Returns $true if WordPress indicators are detected.
    #>
    param([string]$ProjectRoot)
    $indicators = @('wp-config.php','wp-config-sample.php','wp-login.php','wp-blog-header.php','wp-content')
    foreach ($i in $indicators) {
        if (Test-Path (Join-Path $ProjectRoot $i)) { return $true }
    }
    try {
        $c = Get-Content (Join-Path $ProjectRoot 'composer.json') -Raw -ErrorAction SilentlyContinue
        if ($c -match 'johnpbloch/wordpress|roots/bedrock') { return $true }
        $p = Get-Content (Join-Path $ProjectRoot 'package.json') -Raw -ErrorAction SilentlyContinue
        if ($p -match '"@wordpress/') { return $true }
    } catch {}
    return $false
}
