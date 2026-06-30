#Requires -Version 5.1
<#
.SYNOPSIS
    Verifies GitHub-raw readability and hidden-character safety.

.DESCRIPTION
    Reads repository files as strict UTF-8 bytes. It rejects collapsed Markdown,
    embedded Markdown headings, collapsed workflow YAML keys, compact policy JSON,
    and Unicode format/control characters that can trigger hidden-text warnings.

    The -Files parameter exists for isolated regression tests. Without it, the
    script checks every user-facing documentation, template, preset, workflow
    skill, CI YAML, and PowerShell generator or verifier in the repository.
#>
[CmdletBinding()]
param(
    [string]$TargetPath,
    [string[]]$Files
)

$ErrorActionPreference = 'Stop'
if (-not $TargetPath) { $TargetPath = Split-Path -Parent $PSScriptRoot }
$root = [System.IO.Path]::GetFullPath($TargetPath)
$strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
$failures = [System.Collections.Generic.List[string]]::new()
$hiddenCount = 0

function Add-Failure {
    param([string]$Message)

    $script:failures.Add($Message)
}

function Get-DisplayPath {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if ($fullPath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($root.Length).TrimStart([char]'\', [char]'/')
    }
    return $fullPath
}

function Get-LineCount {
    param([string]$NormalizedText)

    $count = @($NormalizedText -split "`n").Count
    if ($NormalizedText.EndsWith("`n", [System.StringComparison]::Ordinal)) {
        $count--
    }
    return $count
}

if (-not $Files) {
    $scope = @(
        Get-Item (Join-Path $root 'README.md')
        Get-ChildItem (Join-Path $root 'docs') -File -Filter '*.md'
        Get-ChildItem (Join-Path $root 'templates') -File -Recurse |
            Where-Object { $_.Extension -in @('.md', '.yml', '.yaml', '.json') }
        Get-ChildItem (Join-Path $root 'presets') -File -Recurse |
            Where-Object { $_.Extension -in @('.md', '.yml', '.yaml', '.json') }
        Get-Item (Join-Path $root 'skills\project-workflow\SKILL.md')
        Get-ChildItem (Join-Path $root 'scripts') -File -Recurse -Filter '*.ps1'
        Get-ChildItem (Join-Path $root '.github') -File -Recurse |
            Where-Object { $_.Extension -in @('.yml', '.yaml') }
    )
    $Files = @($scope | Select-Object -ExpandProperty FullName -Unique)
}

foreach ($file in $Files) {
    $fullPath = if ([System.IO.Path]::IsPathRooted($file)) {
        [System.IO.Path]::GetFullPath($file)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $root $file))
    }
    $display = Get-DisplayPath $fullPath

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure "$display`: file not found"
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    try {
        $text = $strictUtf8.GetString($bytes)
    } catch {
        Add-Failure "$display`: not valid UTF-8"
        continue
    }

    $normalized = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $lines = @($normalized -split "`n")
    $lineCount = Get-LineCount $normalized
    $extension = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
    $name = [System.IO.Path]::GetFileName($fullPath)

    if (($bytes.Length -ge 3) -and
        ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)) {
        Add-Failure "$display`: UTF-8 BOM is not allowed"
    }

    if (($lineCount -gt 1) -and -not ($bytes -contains 0x0A)) {
        Add-Failure "$display`: multiple logical lines do not use real LF bytes"
    }

    for ($index = 0; $index -lt $text.Length; $index++) {
        $codePoint = [char]::ConvertToUtf32($text, $index)
        $category = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($text, $index)
        $allowedWhitespace = $codePoint -in @(9, 10, 13)
        $hidden = (($category -eq [System.Globalization.UnicodeCategory]::Format) -or
            ($category -eq [System.Globalization.UnicodeCategory]::Control) -or
            ($category -eq [System.Globalization.UnicodeCategory]::LineSeparator) -or
            ($category -eq [System.Globalization.UnicodeCategory]::ParagraphSeparator)) -and
            -not $allowedWhitespace
        if ($hidden) {
            $hiddenCount++
            Add-Failure ('{0}: hidden/bidi character U+{1:X} ({2}) at character {3}' -f
                $display, $codePoint, $category, $index)
        }
        if ([char]::IsHighSurrogate($text[$index])) { $index++ }
    }

    if ($extension -eq '.md') {
        $minimumLines = if ($name -eq 'README.md' -and
            $fullPath.Equals((Join-Path $root 'README.md'), [System.StringComparison]::OrdinalIgnoreCase)) {
            100
        } elseif ($fullPath.StartsWith((Join-Path $root 'docs'), [System.StringComparison]::OrdinalIgnoreCase)) {
            10
        } else {
            2
        }
        if ($lineCount -lt $minimumLines) {
            Add-Failure "$display`: only $lineCount lines; expected at least $minimumLines"
        }

        $insideFence = $false
        $fenceMarker = $null
        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
            $line = $lines[$lineIndex]
            if ($line -match '^\s*(```|~~~)') {
                $marker = $Matches[1]
                if (-not $insideFence) {
                    $insideFence = $true
                    $fenceMarker = $marker
                } elseif ($marker -eq $fenceMarker) {
                    $insideFence = $false
                    $fenceMarker = $null
                }
                continue
            }
            if (-not $insideFence -and $line -match '\S[ \t]+#{1,6}[ \t]+\S') {
                Add-Failure "$display`:$($lineIndex + 1): Markdown heading marker appears in the middle of a line"
            }
        }
    }

    if ($name -eq '.ai-workflow.yml') {
        if ($lineCount -lt 20) {
            Add-Failure "$display`: workflow YAML has only $lineCount lines"
        }
        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
            $candidate = ($lines[$lineIndex] -split '\s+#', 2)[0]
            if ($candidate -match '^\s*[A-Za-z_][\w.-]*:\s+[^#]*\s+[A-Za-z_][\w.-]*:\s+\S') {
                Add-Failure "$display`:$($lineIndex + 1): multiple YAML keys appear collapsed on one line"
            }
        }
    }

    if ($name -eq '.ai-skills.json') {
        try {
            $null = $text | ConvertFrom-Json
        } catch {
            Add-Failure "$display`: invalid JSON - $($_.Exception.Message)"
            continue
        }

        if (($lineCount -lt 20) -or ($lines[0] -ne '{') -or
            ($lines[$lineCount - 1] -ne '}') -or ($text.Contains("`t"))) {
            Add-Failure "$display`: policy JSON is not readable multi-line, space-indented JSON"
        }

        for ($lineIndex = 0; $lineIndex -lt $lineCount; $lineIndex++) {
            $line = $lines[$lineIndex]
            if (-not $line.Trim()) { continue }
            $leadingSpaces = $line.Length - $line.TrimStart(' ').Length
            if (($leadingSpaces % 2) -ne 0) {
                Add-Failure "$display`:$($lineIndex + 1): JSON indentation is not a multiple of two spaces"
            }
            if ([regex]::Matches($line, '"[^"\r\n]+"\s*:').Count -gt 1) {
                Add-Failure "$display`:$($lineIndex + 1): multiple JSON properties appear collapsed on one line"
            }
        }
    }
}

$reportCounts = @(
    'README.md',
    'docs\spec-kit.md',
    'templates\.ai-workflow.yml',
    'templates\.ai-skills.json'
)

foreach ($relativePath in $reportCounts) {
    $path = Join-Path $root $relativePath
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $content = $strictUtf8.GetString([System.IO.File]::ReadAllBytes($path))
        $normalized = $content.Replace("`r`n", "`n").Replace("`r", "`n")
        Write-Host ('RAW_READABILITY_COUNT {0}={1}' -f
            ($relativePath -replace '\\', '/'), (Get-LineCount $normalized))
    }
}

Write-Host "HIDDEN_BIDI_COUNT=$hiddenCount"
Write-Host "RAW_READABILITY_FILES=$($Files.Count)"

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Host "[FAIL] $failure" -ForegroundColor Red }
    exit 1
}

Write-Host '[PASS] Raw readability and hidden/bidi checks passed.' -ForegroundColor Green
exit 0
