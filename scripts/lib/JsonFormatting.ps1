# JsonFormatting.ps1
# Deterministic two-space JSON formatting for Windows PowerShell 5.1.

function ConvertTo-ReadableJson {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,
        [int]$Depth = 10
    )

    $compact = $InputObject | ConvertTo-Json -Depth $Depth -Compress
    $builder = New-Object System.Text.StringBuilder
    $indent = 0
    $insideString = $false
    $escaped = $false

    for ($index = 0; $index -lt $compact.Length; $index++) {
        $character = $compact[$index]

        if ($insideString) {
            [void]$builder.Append($character)
            if ($escaped) {
                $escaped = $false
            } elseif ($character -eq [char]'\') {
                $escaped = $true
            } elseif ($character -eq [char]'"') {
                $insideString = $false
            }
            continue
        }

        if ($character -eq [char]'"') {
            $insideString = $true
            [void]$builder.Append($character)
            continue
        }

        switch ($character) {
            { $_ -in @([char]'{', [char]'[') } {
                $closingCharacter = if ($character -eq [char]'{') { [char]'}' } else { [char]']' }
                [void]$builder.Append($character)
                if (($index + 1 -lt $compact.Length) -and ($compact[$index + 1] -eq $closingCharacter)) {
                    [void]$builder.Append($closingCharacter)
                    $index++
                } else {
                    $indent++
                    [void]$builder.Append("`n")
                    [void]$builder.Append('  ' * $indent)
                }
            }
            { $_ -in @([char]'}', [char]']') } {
                $indent--
                [void]$builder.Append("`n")
                [void]$builder.Append('  ' * $indent)
                [void]$builder.Append($character)
            }
            ([char]',') {
                [void]$builder.Append($character)
                [void]$builder.Append("`n")
                [void]$builder.Append('  ' * $indent)
            }
            ([char]':') {
                [void]$builder.Append(': ')
            }
            default {
                if (-not [char]::IsWhiteSpace($character)) {
                    [void]$builder.Append($character)
                }
            }
        }
    }

    return $builder.ToString()
}
