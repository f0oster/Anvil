function Test-FileCondition {
    <#
    .SYNOPSIS
        Determines whether a template file should be included based on
        manifest conditions.

    .DESCRIPTION
        Evaluates a resolved file path against IncludeWhen and ExcludeWhen
        condition tables from a template manifest.

        Matching rules:
          - Condition table keys are wildcard patterns tested against the
            file path with the -like operator.
          - ExcludeWhen is evaluated first.  If a matching pattern's
            condition is satisfied, the file is excluded.
          - IncludeWhen is evaluated second.  If a matching pattern's
            condition is satisfied, the file is included.  If the
            condition is NOT satisfied, the file is excluded.
          - Files not matched by any pattern are included by default.

    .PARAMETER RelativePath
        The resolved relative file path (after path-token replacement,
        before .tmpl stripping).

    .PARAMETER IncludeWhen
        Hashtable mapping wildcard path patterns to condition hashtables.
        A file matching a pattern is included only when the condition is
        satisfied.

    .PARAMETER ExcludeWhen
        Hashtable mapping wildcard path patterns to condition hashtables.
        A file matching a pattern is excluded when the condition is
        satisfied.

    .PARAMETER Tokens
        Hashtable of resolved token values used to evaluate conditions.

    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [hashtable]$IncludeWhen = @{},

        [hashtable]$ExcludeWhen = @{},

        [Parameter(Mandatory)]
        [hashtable]$Tokens
    )

    $NormalizedPath = $RelativePath -replace '\\', '/'

    foreach ($Pattern in $ExcludeWhen.Keys) {
        if ($NormalizedPath -like $Pattern) {
            if (Test-ManifestCondition -Condition $ExcludeWhen[$Pattern] -Tokens $Tokens) {
                return $false
            }
        }
    }

    foreach ($Pattern in $IncludeWhen.Keys) {
        if ($NormalizedPath -like $Pattern) {
            return (Test-ManifestCondition -Condition $IncludeWhen[$Pattern] -Tokens $Tokens)
        }
    }

    return $true
}
