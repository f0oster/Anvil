function Read-PromptValue {
    <#
    .SYNOPSIS
        Prompts the user for a text value with optional default and required validation.

    .PARAMETER Prompt
        The prompt text displayed to the user.

    .PARAMETER Default
        The value returned when the user presses Enter without typing anything.

    .PARAMETER Required
        When set, reprompts until a non-empty value is provided.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter()]
        [string]$Default,

        [Parameter()]
        [switch]$Required
    )

    $DisplayDefault = if ($Default) { " [$Default]" } else { '' }
    do {
        $Response = Read-Host -Prompt "$Prompt$DisplayDefault"
        if ([string]::IsNullOrWhiteSpace($Response)) {
            $Response = $Default
        }
        if ($Required -and [string]::IsNullOrWhiteSpace($Response)) {
            Write-Host '  This field is required.' -ForegroundColor Yellow
        }
    } while ($Required -and [string]::IsNullOrWhiteSpace($Response))

    return $Response
}
