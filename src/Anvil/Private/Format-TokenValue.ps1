function Format-TokenValue {
    <#
    .SYNOPSIS
        Formats a parameter value for embedding in a template file using
        a named formatter.

    .DESCRIPTION
        Transforms a resolved parameter value into a string suitable for
        token replacement in template content.  The formatter name
        determines the transformation applied.

        Supported formatters:
          raw          Returns the value as a string via .ToString().
                       This is the default.
          psd1-array   Formats a string array as a PowerShell data
                       literal: @('a', 'b') or @() for empty.
          lower-string Converts a boolean to its lowercase string
                       representation: 'true' or 'false'.
          quoted       Wraps the value in single quotes.

    .PARAMETER Value
        The value to format.  May be a string, string array, boolean,
        integer, or $null.

    .PARAMETER Formatter
        The name of the formatter to apply.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        $Value,

        [Parameter(Mandatory)]
        [string]$Formatter
    )

    switch ($Formatter) {
        'raw' {
            if ($null -eq $Value) { return '' }
            return $Value.ToString()
        }
        'psd1-array' {
            $Items = @($Value | Where-Object { $_ })
            if ($Items.Count -eq 0) {
                return '@()'
            }
            $Quoted = $Items | ForEach-Object { "'$_'" }
            return "@($($Quoted -join ', '))"
        }
        'lower-string' {
            if ($Value -is [bool]) {
                return $Value.ToString().ToLower()
            }
            return "$Value".ToLower()
        }
        'quoted' {
            return "'$Value'"
        }
        default {
            throw "Unknown formatter '$Formatter'. Valid formatters: raw, psd1-array, lower-string, quoted."
        }
    }
}
