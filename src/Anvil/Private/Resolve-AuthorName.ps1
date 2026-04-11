function Resolve-AuthorName {
    <#
    .SYNOPSIS
        Attempts to resolve an author name from git config.

    .DESCRIPTION
        Returns the git user.name if git is available and configured.
        Returns $null otherwise.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $GitCmd = Get-Command -Name git -ErrorAction SilentlyContinue
    if ($GitCmd) {
        $AuthorName = & git config user.name 2>$null
        if ($AuthorName) { return $AuthorName }
    }
}
