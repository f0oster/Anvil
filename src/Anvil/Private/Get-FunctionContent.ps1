function Get-FunctionContent {
    <#
    .SYNOPSIS
        Returns the boilerplate content for a new function file.

    .PARAMETER FunctionName
        The name of the function to generate.

    .PARAMETER Scope
        Public functions include comment-based help. Private functions get a minimal template.
    #>
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

    .INPUTS
        None

    .OUTPUTS
        TODO
    #>
    [CmdletBinding()]
    [OutputType()]
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
