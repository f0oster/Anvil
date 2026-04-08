function Assert-ValidConfiguration {
    <#
    .SYNOPSIS
        Validates the scaffolding configuration hashtable.  Throws on any
        invalid or missing required values.

    .DESCRIPTION
        Checks the configuration hashtable built from New-ModuleProject
        parameters against known constraints:

          - Required keys: ModuleName, Author, Description (non-empty).
          - ModuleName format: starts with a letter, alphanumeric plus
            dots/hyphens/underscores, max 128 characters.
          - CIProvider and License must be from their allowed sets.
          - CoverageThreshold must be an integer 0-100.
          - MinPowerShellVersion must parse as a .NET Version.

        All violations are collected and thrown as a single error message
        so the caller sees every problem at once.

    .PARAMETER Configuration
        Hashtable of scaffolding options to validate.

    .OUTPUTS
        None.  Throws on validation failure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $Errors = [System.Collections.Generic.List[string]]::new()

    # Required keys
    $RequiredKeys = @('ModuleName', 'Author', 'Description')
    foreach ($Key in $RequiredKeys) {
        if (-not $Configuration.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Configuration[$Key])) {
            $Errors.Add("'$Key' is required and must not be empty.")
        }
    }

    # ModuleName format
    if ($Configuration.ContainsKey('ModuleName') -and -not [string]::IsNullOrWhiteSpace($Configuration['ModuleName'])) {
        $Name = $Configuration['ModuleName']
        if ($Name -notmatch '^[A-Za-z][A-Za-z0-9._-]*$') {
            $Errors.Add("ModuleName '$Name' contains invalid characters. Use letters, digits, dots, hyphens, or underscores, starting with a letter.")
        }
        if ($Name.Length -gt 128) {
            $Errors.Add("ModuleName must be 128 characters or fewer.")
        }
    }

    # CIProvider
    $ValidProviders = @('GitHub', 'AzurePipelines', 'GitLab', 'None')
    if ($Configuration.ContainsKey('CIProvider')) {
        if ($Configuration['CIProvider'] -notin $ValidProviders) {
            $Errors.Add("CIProvider '$($Configuration['CIProvider'])' is not valid. Choose from: $($ValidProviders -join ', ').")
        }
    }

    # License
    $ValidLicenses = @('MIT', 'Apache2', 'None')
    if ($Configuration.ContainsKey('License')) {
        if ($Configuration['License'] -notin $ValidLicenses) {
            $Errors.Add("License '$($Configuration['License'])' is not valid. Choose from: $($ValidLicenses -join ', ').")
        }
    }

    # Numeric thresholds
    if ($Configuration.ContainsKey('CoverageThreshold')) {
        $Ct = $Configuration['CoverageThreshold']
        if ($Ct -isnot [int] -or $Ct -lt 0 -or $Ct -gt 100) {
            $Errors.Add("CoverageThreshold must be an integer between 0 and 100.")
        }
    }

    # PowerShell version
    if ($Configuration.ContainsKey('MinPowerShellVersion')) {
        try {
            [void][Version]::new($Configuration['MinPowerShellVersion'])
        }
        catch {
            $Errors.Add("MinPowerShellVersion '$($Configuration['MinPowerShellVersion'])' is not a valid version string.")
        }
    }

    if ($Errors.Count -gt 0) {
        $Message = "Configuration validation failed:`n  - " + ($Errors -join "`n  - ")
        throw $Message
    }
}
