function Test-ManifestCondition {
    <#
    .SYNOPSIS
        Tests whether a set of token values satisfies a manifest condition.

    .DESCRIPTION
        A condition is a hashtable mapping parameter names to allowed values.
        Each key must match for the condition to pass (AND logic across keys).
        Values may be a single string or an array of strings (OR logic within
        a key).

        Returns $true when every key in the condition has a matching token
        value, $false otherwise.  An empty condition always returns $true.

        This is the core evaluator used by Test-FileCondition and section
        processing to decide whether files or content blocks should be
        included or excluded during scaffolding.

    .PARAMETER Condition
        Hashtable of parameter-name-to-allowed-value(s) entries.

    .PARAMETER Tokens
        Hashtable of resolved token values to test against.

    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Condition,

        [Parameter(Mandatory)]
        [hashtable]$Tokens
    )

    foreach ($Key in $Condition.Keys) {
        if (-not $Tokens.ContainsKey($Key)) {
            return $false
        }

        $Allowed = @($Condition[$Key])
        if ($Tokens[$Key] -notin $Allowed) {
            return $false
        }
    }

    return $true
}
