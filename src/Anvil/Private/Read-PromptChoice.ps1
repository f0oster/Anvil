function Read-PromptChoice {
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
