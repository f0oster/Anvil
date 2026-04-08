function Resolve-PathTokens {
    <#
    .SYNOPSIS
        Replaces __TokenName__ segments in a relative path string.

    .DESCRIPTION
        Iterates the token hashtable and performs literal string replacement
        of __Key__ patterns in the given path.  Used by Invoke-TemplateEngine
        to rename directories and files during scaffolding.

    .PARAMETER RelativePath
        The relative path containing __Token__ placeholders.

    .PARAMETER Tokens
        Hashtable mapping token names to replacement values.

    .OUTPUTS
        System.String
            The path with all matching tokens replaced.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [hashtable]$Tokens
    )

    $Result = $RelativePath
    foreach ($Key in $Tokens.Keys) {
        $Result = $Result.Replace("__${Key}__", $Tokens[$Key])
    }
    return $Result
}

function Resolve-ContentTokens {
    <#
    .SYNOPSIS
        Replaces <%TokenName%> placeholders in file content.

    .DESCRIPTION
        Iterates the token hashtable and performs literal string replacement
        of <%Key%> patterns in the given content.  Used by
        Invoke-TemplateEngine to expand .tmpl files during scaffolding.

    .PARAMETER Content
        The file content string containing <%Token%> placeholders.
        May be empty.

    .PARAMETER Tokens
        Hashtable mapping token names to replacement values.

    .OUTPUTS
        System.String
            The content with all matching tokens replaced.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory)]
        [hashtable]$Tokens
    )

    $Result = $Content
    foreach ($Key in $Tokens.Keys) {
        $Result = $Result.Replace("<%${Key}%>", $Tokens[$Key])
    }
    return $Result
}

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
