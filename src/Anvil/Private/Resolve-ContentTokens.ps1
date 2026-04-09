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
