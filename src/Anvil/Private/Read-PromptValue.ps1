function Read-PromptValue {
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
