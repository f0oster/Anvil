function Resolve-DefaultFrom {
    <#
    .SYNOPSIS
        Resolves a named default-value resolver to its value.

    .DESCRIPTION
        Maps a DefaultFrom resolver name from a template manifest parameter
        to its resolved value.  Used by Invoke-ManifestPrompt to populate
        defaults for parameters that derive their value from the environment.

        Supported resolvers:
          GitUserName       Returns git config user.name via Resolve-AuthorName.
          CurrentDirectory  Returns the current working directory path.

    .PARAMETER ResolverName
        The name of the resolver to execute.

    .OUTPUTS
        System.String or $null
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ResolverName
    )

    switch ($ResolverName) {
        'GitUserName' { return Resolve-AuthorName }
        'CurrentDirectory' { return $PWD.Path }
        default { return $null }
    }
}
