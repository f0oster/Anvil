function Invoke-InteractivePrompt {
    <#
    .SYNOPSIS
        Resolves all New-AnvilModule parameters, prompting for missing values
        when running in interactive mode.

    .DESCRIPTION
        Collects all New-AnvilModule parameters from bound values, defaults,
        or interactive prompts.  Values already provided via bound parameters
        are used as-is and not prompted for.

        When Interactive is $false, missing values are filled from Defaults.
        Missing required values with no default cause a terminating error.

        Returns a hashtable of all resolved values.

    .PARAMETER BoundParams
        Hashtable of parameters already provided by the caller. Keys
        matching prompt fields are skipped.

    .PARAMETER Defaults
        Hashtable of default values for optional parameters. Used as prompt
        defaults in interactive mode and as silent fallbacks otherwise.

    .PARAMETER Interactive
        When $true, prompts the user for any missing values. When $false,
        applies defaults silently and throws on missing required values.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$BoundParams,

        [Parameter(Mandatory)]
        [hashtable]$Defaults,

        [Parameter()]
        [bool]$Interactive = $false
    )

    $GitAuthor = Resolve-AuthorName

    if ($Interactive) {
        Write-Host ''
        Write-Host '  Anvil - New Module Project' -ForegroundColor Cyan
        Write-Host '  Press Enter to accept defaults shown in [brackets].' -ForegroundColor DarkGray
        Write-Host ''
    }

    $Result = @{}

    # Required values (no defaults - must be bound or prompted)
    $Result.Name = if ($BoundParams.ContainsKey('Name')) {
        $BoundParams.Name
    } elseif ($Interactive) {
        Read-PromptValue -Prompt '  Module name' -Required
    } else {
        throw "'Name' is required. Use -Interactive for the guided wizard."
    }

    $Result.DestinationPath = if ($BoundParams.ContainsKey('DestinationPath')) {
        $BoundParams.DestinationPath
    } elseif ($Interactive) {
        Read-PromptValue -Prompt '  Destination path' -Default $PWD.Path
    } else {
        throw "'DestinationPath' is required. Use -Interactive for the guided wizard."
    }

    $AuthorDefault = if ($GitAuthor) { $GitAuthor } else { $null }
    $Result.Author = if ($BoundParams.ContainsKey('Author')) {
        $BoundParams.Author
    } elseif ($Interactive) {
        Read-PromptValue -Prompt '  Author' -Default $AuthorDefault -Required
    } elseif ($AuthorDefault) {
        $AuthorDefault
    } else {
        throw "'Author' is required. Use -Interactive for the guided wizard."
    }

    # Optional values - fall back to Defaults
    $Result.Description = if ($BoundParams.ContainsKey('Description')) {
        $BoundParams.Description
    } elseif ($Interactive) {
        Read-PromptValue -Prompt '  Description' -Default $Defaults.Description
    } else {
        $Defaults.Description
    }

    $Result.CompanyName = if ($BoundParams.ContainsKey('CompanyName')) {
        $BoundParams.CompanyName
    } elseif ($Interactive) {
        Read-PromptValue -Prompt '  Company name' -Default $Defaults.CompanyName
    } else {
        $Defaults.CompanyName
    }

    $Result.MinPowerShellVersion = if ($BoundParams.ContainsKey('MinPowerShellVersion')) {
        $BoundParams.MinPowerShellVersion
    } elseif ($Interactive) {
        Read-PromptValue -Prompt '  Minimum PowerShell version' -Default $Defaults.MinPowerShellVersion
    } else {
        $Defaults.MinPowerShellVersion
    }

    $Result.CompatiblePSEditions = if ($BoundParams.ContainsKey('CompatiblePSEditions')) {
        $BoundParams.CompatiblePSEditions
    } elseif ($Interactive) {
        $EditionInput = Read-PromptValue -Prompt '  Compatible PS editions (Desktop,Core / Core)' -Default ($Defaults.CompatiblePSEditions -join ',')
        @($EditionInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    } else {
        $Defaults.CompatiblePSEditions
    }

    $Result.CIProvider = if ($BoundParams.ContainsKey('CIProvider')) {
        $BoundParams.CIProvider
    } elseif ($Interactive) {
        Read-PromptChoice -Prompt '  CI provider' -Choices @('GitHub', 'AzurePipelines', 'GitLab', 'None') -Default $Defaults.CIProvider
    } else {
        $Defaults.CIProvider
    }

    $Result.License = if ($BoundParams.ContainsKey('License')) {
        $BoundParams.License
    } elseif ($Interactive) {
        Read-PromptChoice -Prompt '  License' -Choices @('MIT', 'Apache2', 'None') -Default $Defaults.License
    } else {
        $Defaults.License
    }

    $Result.CoverageThreshold = if ($BoundParams.ContainsKey('CoverageThreshold')) {
        $BoundParams.CoverageThreshold
    } elseif ($Interactive) {
        [int](Read-PromptValue -Prompt '  Code coverage threshold (0-100)' -Default $Defaults.CoverageThreshold.ToString())
    } else {
        $Defaults.CoverageThreshold
    }

    $Result.IncludeDocs = if ($BoundParams.ContainsKey('IncludeDocs')) {
        [bool]$BoundParams.IncludeDocs
    } elseif ($Interactive) {
        $DocsDefault = if ($Defaults.IncludeDocs) { 'y' } else { 'n' }
        $DocsInput = Read-PromptValue -Prompt '  Include PlatyPS docs generation? (y/n)' -Default $DocsDefault
        $DocsInput -match '^[Yy]'
    } else {
        $Defaults.IncludeDocs
    }

    $Result.Tags = if ($BoundParams.ContainsKey('Tags')) {
        $BoundParams.Tags
    } elseif ($Interactive) {
        $TagDefault = if ($Defaults.Tags.Count -gt 0) { $Defaults.Tags -join ',' } else { '' }
        $TagInput = Read-PromptValue -Prompt '  Tags (comma-separated)' -Default $TagDefault
        if ($TagInput) {
            @($TagInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        } else {
            @()
        }
    } else {
        $Defaults.Tags
    }

    $Result.ProjectUri = if ($BoundParams.ContainsKey('ProjectUri')) {
        $BoundParams.ProjectUri
    } elseif ($Interactive) {
        do {
            $UriInput = Read-PromptValue -Prompt '  Project URI' -Default $Defaults.ProjectUri
            if ([string]::IsNullOrWhiteSpace($UriInput)) { break }
            $Parsed = $UriInput -as [System.Uri]
            if ($Parsed -and $Parsed.IsAbsoluteUri) { break }
            Write-Host '  Must be a valid absolute URI (e.g. https://github.com/user/repo).' -ForegroundColor Yellow
        } while ($true)
        $UriInput
    } else {
        $Defaults.ProjectUri
    }

    $Result.LicenseUri = if ($BoundParams.ContainsKey('LicenseUri')) {
        $BoundParams.LicenseUri
    } elseif ($Interactive) {
        do {
            $UriInput = Read-PromptValue -Prompt '  License URI' -Default $Defaults.LicenseUri
            if ([string]::IsNullOrWhiteSpace($UriInput)) { break }
            $Parsed = $UriInput -as [System.Uri]
            if ($Parsed -and $Parsed.IsAbsoluteUri) { break }
            Write-Host '  Must be a valid absolute URI (e.g. https://github.com/user/repo/blob/main/LICENSE).' -ForegroundColor Yellow
        } while ($true)
        $UriInput
    } else {
        $Defaults.LicenseUri
    }

    $Result.GitInit = if ($BoundParams.ContainsKey('GitInit')) {
        [bool]$BoundParams.GitInit
    } elseif ($Interactive) {
        $GitDefault = if ($Defaults.GitInit) { 'y' } else { 'n' }
        $GitInput = Read-PromptValue -Prompt '  Initialize git repository? (y/n)' -Default $GitDefault
        $GitInput -match '^[Yy]'
    } else {
        $Defaults.GitInit
    }

    # Pass through flags
    $Result.Force = if ($BoundParams.ContainsKey('Force')) { [bool]$BoundParams.Force } else { $false }
    $Result.PassThru = if ($BoundParams.ContainsKey('PassThru')) { [bool]$BoundParams.PassThru } else { $false }

    if ($Interactive) {
        Write-Host ''
    }

    return $Result
}
