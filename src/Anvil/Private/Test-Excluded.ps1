function Test-Excluded {
    <#
    .SYNOPSIS
        Tests whether a relative path matches any exclusion pattern.

    .DESCRIPTION
        Returns $true if the relative path matches at least one of the
        supplied wildcard patterns, $false otherwise.  Used by
        Invoke-TemplateEngine to skip files and directories during
        scaffolding.

    .PARAMETER RelativePath
        The relative path to test against the patterns.

    .PARAMETER Patterns
        Array of wildcard patterns.  Uses the PowerShell -like operator
        (supports *, ?, []).  Does not support recursive glob syntax
        such as **/docs/**.

    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [string[]]$Patterns = @()
    )

    foreach ($Pattern in $Patterns) {
        if ($RelativePath -like $Pattern) {
            return $true
        }
    }
    return $false
}
