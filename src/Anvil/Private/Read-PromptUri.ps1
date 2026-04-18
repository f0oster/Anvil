function Read-PromptUri {
    <#
    .SYNOPSIS
        Prompts the user for an absolute URI with validation and retry.

    .DESCRIPTION
        Displays a prompt for a URI value.  If the user enters a non-empty
        string that is not a valid absolute URI, a warning is shown and
        the prompt repeats.  An empty response returns the default value.

    .PARAMETER Prompt
        The prompt text displayed to the user.

    .PARAMETER Default
        The value returned when the user presses Enter without typing.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter()]
        [string]$Default
    )

    do {
        $UriInput = Read-PromptValue -Prompt $Prompt -Default $Default
        if ([string]::IsNullOrWhiteSpace($UriInput)) {
            return $UriInput
        }
        $Parsed = $UriInput -as [System.Uri]
        if ($Parsed -and $Parsed.IsAbsoluteUri) {
            return $UriInput
        }
        Write-Host '  Must be a valid absolute URI (e.g. https://github.com/user/repo).' -ForegroundColor Yellow
    } while ($true)
}
