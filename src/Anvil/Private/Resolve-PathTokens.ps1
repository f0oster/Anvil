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
