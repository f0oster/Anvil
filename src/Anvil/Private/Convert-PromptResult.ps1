function Convert-PromptResult {
    <#
    .SYNOPSIS
        Normalizes a parameter value to the expected type.

    .DESCRIPTION
        Converts a raw value (from bound parameters or manifest defaults)
        into the type expected by the manifest parameter declaration.
        Used by Invoke-ManifestPrompt to ensure consistent value types
        regardless of input source.

        Type conversions:
          csv   Splits a comma-separated string into a string array.
                Arrays pass through unchanged.  Empty/whitespace returns @().
          int   Casts to [int].
          bool  Converts booleans, 'y', 'true', '1' to $true; else $false.
                Actual [bool] values pass through unchanged.
          *     All other types return the value unchanged.

    .PARAMETER Value
        The value to convert.

    .PARAMETER Type
        The manifest parameter type name.

    .OUTPUTS
        The converted value (type varies by Type parameter).
    #>
    [CmdletBinding()]
    [OutputType([string], [int], [bool], [object[]])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        $Value,

        [Parameter(Mandatory)]
        [string]$Type
    )

    switch ($Type) {
        'csv' {
            if ($Value -is [array]) { return $Value }
            if ([string]::IsNullOrWhiteSpace($Value)) { return @() }
            return @($Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        'int' {
            return [int]$Value
        }
        'bool' {
            if ($Value -is [bool]) { return $Value }
            return $Value -match '^([Yy]|[Tt]rue|1)$'
        }
        default {
            return $Value
        }
    }
}
