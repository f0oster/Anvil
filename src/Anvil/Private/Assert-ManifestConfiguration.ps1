function Assert-ManifestConfiguration {
    <#
    .SYNOPSIS
        Validates resolved parameter values against manifest declarations.

    .DESCRIPTION
        Walks the manifest's Parameters array and validates each resolved
        value against the declared rules:

          - Required parameters must be non-empty.
          - String parameters with a Validate regex must match.
          - Choice parameters must be in the Choices array.
          - Int parameters with a Range must be within bounds.
          - Uri parameters must be valid absolute URIs (when non-empty).
          - Version-format strings are validated when a version regex
            is declared.

        All violations are collected and thrown as a single error so the
        caller sees every problem at once.

    .PARAMETER Manifest
        The template manifest hashtable (from Read-TemplateManifest).

    .PARAMETER Configuration
        Hashtable of resolved parameter values (from Invoke-ManifestPrompt).

    .OUTPUTS
        None.  Throws on validation failure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Manifest,

        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $Errors = [System.Collections.Generic.List[string]]::new()

    foreach ($Param in $Manifest.Parameters) {
        $Name = $Param.Name
        $Value = $Configuration[$Name]

        if ($Param.Required) {
            $IsEmpty = $false
            if ($null -eq $Value) { $IsEmpty = $true }
            elseif ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) { $IsEmpty = $true }
            if ($IsEmpty) {
                $Errors.Add("'$Name' is required and must not be empty.")
                continue
            }
        }

        if ($null -eq $Value -or ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value))) {
            continue
        }

        if ($Param.ContainsKey('Validate') -and -not [string]::IsNullOrWhiteSpace($Param.Validate)) {
            $StringValue = if ($Value -is [string]) { $Value } else { "$Value" }
            if ($StringValue -notmatch $Param.Validate) {
                $Message = if ($Param.ContainsKey('ValidateMessage')) {
                    $Param.ValidateMessage
                } else {
                    "'$Name' value '$StringValue' does not match required format."
                }
                $Errors.Add($Message)
            }
        }

        if ($Param.ContainsKey('Choices') -and $Param.Choices.Count -gt 0) {
            if ($Value -notin $Param.Choices) {
                $Errors.Add("'$Name' must be one of: $($Param.Choices -join ', '). Got '$Value'.")
            }
        }

        if ($Param.ContainsKey('Range')) {
            $Range = @($Param.Range)
            if ($Value -lt $Range[0] -or $Value -gt $Range[1]) {
                $Errors.Add("'$Name' must be between $($Range[0]) and $($Range[1]). Got $Value.")
            }
        }

        if ($Param.Type -eq 'uri' -and -not [string]::IsNullOrWhiteSpace($Value)) {
            $Parsed = $Value -as [System.Uri]
            if (-not $Parsed -or -not $Parsed.IsAbsoluteUri) {
                $Errors.Add("'$Name' must be a valid absolute URI. Got '$Value'.")
            }
        }
    }

    if ($Errors.Count -gt 0) {
        $Message = "Configuration validation failed:`n  - " + ($Errors -join "`n  - ")
        throw $Message
    }
}
