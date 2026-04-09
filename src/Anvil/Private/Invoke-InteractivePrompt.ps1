function Invoke-InteractivePrompt {
    <#
    .SYNOPSIS
        Prompts the user for module project configuration interactively.

    .DESCRIPTION
        Collects all New-AnvilModule parameters via interactive prompts.
        Values already provided via bound parameters are used as-is and
        not prompted for. Returns a hashtable of all resolved values.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$BoundParams
    )

    # Try to detect author from git config
    $GitAuthor = $null
    $GitCmd = Get-Command -Name git -ErrorAction SilentlyContinue
    if ($GitCmd) {
        $GitAuthor = & git config user.name 2>$null
    }

    Write-Host ''
    Write-Host '  Anvil - New Module Project' -ForegroundColor Cyan
    Write-Host '  Press Enter to accept defaults shown in [brackets].' -ForegroundColor DarkGray
    Write-Host ''

    $Result = @{}

    # Required values
    $Result.Name = if ($BoundParams.ContainsKey('Name')) {
        $BoundParams.Name
    } else {
        Read-PromptValue -Prompt '  Module name' -Required
    }

    $Result.DestinationPath = if ($BoundParams.ContainsKey('DestinationPath')) {
        $BoundParams.DestinationPath
    } else {
        Read-PromptValue -Prompt '  Destination path' -Default $PWD.Path
    }

    $AuthorDefault = if ($GitAuthor) { $GitAuthor } else { $null }
    $Result.Author = if ($BoundParams.ContainsKey('Author')) {
        $BoundParams.Author
    } else {
        Read-PromptValue -Prompt '  Author' -Default $AuthorDefault -Required
    }

    $Result.Description = if ($BoundParams.ContainsKey('Description')) {
        $BoundParams.Description
    } else {
        Read-PromptValue -Prompt '  Description' -Default 'A PowerShell module scaffolded by Anvil.'
    }

    $Result.CompanyName = if ($BoundParams.ContainsKey('CompanyName')) {
        $BoundParams.CompanyName
    } else {
        Read-PromptValue -Prompt '  Company name' -Default ''
    }

    # PowerShell targeting
    $Result.MinPowerShellVersion = if ($BoundParams.ContainsKey('MinPowerShellVersion')) {
        $BoundParams.MinPowerShellVersion
    } else {
        Read-PromptValue -Prompt '  Minimum PowerShell version' -Default '5.1'
    }

    $Result.CompatiblePSEditions = if ($BoundParams.ContainsKey('CompatiblePSEditions')) {
        $BoundParams.CompatiblePSEditions
    } else {
        $EditionInput = Read-PromptValue -Prompt '  Compatible PS editions (Desktop,Core / Core)' -Default 'Desktop,Core'
        @($EditionInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }

    # Build and CI
    $Result.CIProvider = if ($BoundParams.ContainsKey('CIProvider')) {
        $BoundParams.CIProvider
    } else {
        Read-PromptChoice -Prompt '  CI provider' -Choices @('GitHub', 'AzurePipelines', 'GitLab', 'None') -Default 'GitHub'
    }

    $Result.License = if ($BoundParams.ContainsKey('License')) {
        $BoundParams.License
    } else {
        Read-PromptChoice -Prompt '  License' -Choices @('MIT', 'Apache2', 'None') -Default 'MIT'
    }

    $Result.CoverageThreshold = if ($BoundParams.ContainsKey('CoverageThreshold')) {
        $BoundParams.CoverageThreshold
    } else {
        [int](Read-PromptValue -Prompt '  Code coverage threshold (0-100)' -Default '80')
    }

    $Result.IncludeDocs = if ($BoundParams.ContainsKey('IncludeDocs')) {
        [bool]$BoundParams.IncludeDocs
    } else {
        $DocsInput = Read-PromptValue -Prompt '  Include PlatyPS docs generation? (y/n)' -Default 'n'
        $DocsInput -match '^[Yy]'
    }

    # PSGallery metadata
    $Result.Tags = if ($BoundParams.ContainsKey('Tags')) {
        $BoundParams.Tags
    } else {
        $TagInput = Read-PromptValue -Prompt '  Tags (comma-separated)' -Default ''
        if ($TagInput) {
            @($TagInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        } else {
            @()
        }
    }

    $Result.ProjectUri = if ($BoundParams.ContainsKey('ProjectUri')) {
        $BoundParams.ProjectUri
    } else {
        Read-PromptValue -Prompt '  Project URI' -Default ''
    }

    $Result.LicenseUri = if ($BoundParams.ContainsKey('LicenseUri')) {
        $BoundParams.LicenseUri
    } else {
        Read-PromptValue -Prompt '  License URI' -Default ''
    }

    # Git init
    $Result.GitInit = if ($BoundParams.ContainsKey('GitInit')) {
        [bool]$BoundParams.GitInit
    } else {
        $GitInput = Read-PromptValue -Prompt '  Initialize git repository? (y/n)' -Default 'y'
        $GitInput -match '^[Yy]'
    }

    # Pass through flags
    $Result.Force = if ($BoundParams.ContainsKey('Force')) { [bool]$BoundParams.Force } else { $false }
    $Result.PassThru = if ($BoundParams.ContainsKey('PassThru')) { [bool]$BoundParams.PassThru } else { $false }

    Write-Host ''

    return $Result
}
