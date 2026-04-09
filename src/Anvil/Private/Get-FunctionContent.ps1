function Get-FunctionContent {
    param(
        [string]$FunctionName,

        [ValidateSet('Public', 'Private')]
        [string]$Scope
    )

    if ($Scope -eq 'Public') {
        @"
function $FunctionName {
    <#
    .SYNOPSIS
        TODO: Brief description of what $FunctionName does.

    .DESCRIPTION
        TODO: Detailed description.

    .EXAMPLE
        $FunctionName
    #>
    [CmdletBinding()]
    param(
    )

    # TODO: Implement
}
"@
    } else {
        @"
function $FunctionName {
    [CmdletBinding()]
    param(
    )

    # TODO: Implement
}
"@
    }
}
