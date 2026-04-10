function Read-PromptChoice {
    <#
    .SYNOPSIS
        Prompts the user to select from a list of valid choices.

    .PARAMETER Prompt
        The prompt text displayed to the user.

    .PARAMETER Choices
        The set of valid choices. Input is reprompted until a valid choice is entered.

    .PARAMETER Default
        The value returned when the user presses Enter without typing anything.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [string[]]$Choices,

        [Parameter()]
        [string]$Default
    )

    $ChoiceList = $Choices -join ', '
    $DisplayDefault = if ($Default) { " [$Default]" } else { '' }
    do {
        $Response = Read-Host -Prompt "$Prompt ($ChoiceList)$DisplayDefault"
        if ([string]::IsNullOrWhiteSpace($Response)) {
            $Response = $Default
        }
        if ($Response -notin $Choices) {
            Write-Host "  Choose from: $ChoiceList" -ForegroundColor Yellow
            $Response = $null
        }
    } while (-not $Response)

    return $Response
}
