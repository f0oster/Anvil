function New-AnvilModule {
    <#
    .SYNOPSIS
        Scaffolds a new PowerShell module project with build, test, lint, docs,
        and CI/CD pipelines.

    .DESCRIPTION
        Generates a complete, opinionated module project structure including:

          - Module source (manifest, .psm1 entry point, Public/Private/PrivateClasses layout)
          - InvokeBuild pipeline (Validate, Format, Lint, Test, Build, IntegrationTest, Package, Publish)
          - Dependency manifest with pinned tool versions (installed via ModuleFast)
          - Pester 5 unit tests and post-build integration tests
          - PSScriptAnalyzer settings with formatting rules and custom analyzers
          - CI/CD workflows for the chosen provider (GitHub, Azure Pipelines, GitLab)
          - README, CONTRIBUTING, LICENSE, .editorconfig, VS Code config

        Use -Interactive to launch a guided wizard that prompts for each value.
        Without -Interactive, parameters are required and defaults are applied
        silently for any optional values not specified.

    .PARAMETER Name
        The name of the new module. Must start with a letter and contain only
        letters, digits, dots, hyphens, or underscores (max 128 characters).

    .PARAMETER DestinationPath
        Parent directory where the project folder will be created. A child
        directory named after -Name is created inside this path.
        Interactive default: current directory.

    .PARAMETER Author
        Author name written into the module manifest, LICENSE, and copyright.
        Interactive default: git config user.name (if available).

    .PARAMETER Description
        Short description for the module manifest.
        Default: 'A PowerShell module scaffolded by Anvil.'

    .PARAMETER CompanyName
        Company name written into the module manifest.
        Default: empty string.

    .PARAMETER MinPowerShellVersion
        Minimum PowerShell version declared in the generated module manifest.
        Must be a valid .NET version string (e.g. '5.1', '7.2').
        Default: '5.1'.

    .PARAMETER CompatiblePSEditions
        PowerShell editions the module supports.
        Default: @('Desktop', 'Core').

    .PARAMETER CIProvider
        CI/CD platform to scaffold workflows for.
        Valid values: GitHub, AzurePipelines, GitLab, None.
        Default: GitHub.

    .PARAMETER License
        License type to include. Valid values: MIT, Apache2, None.
        Default: MIT.

    .PARAMETER IncludeDocs
        When set, the build pipeline adds a Docs task that generates markdown
        and MAML help via platyPS.

    .PARAMETER CoverageThreshold
        Minimum code coverage percentage enforced by Pester during the Test
        task. Valid range: 0-100. Default: 80.

    .PARAMETER Tags
        Tags for PSGallery discoverability. Default: empty array.

    .PARAMETER ProjectUri
        Project URI for the module manifest (e.g. GitHub repo URL).
        Default: empty string.

    .PARAMETER LicenseUri
        License URI for the module manifest.
        Default: empty string.

    .PARAMETER Force
        Removes and re-creates the destination directory if it already exists.

    .PARAMETER GitInit
        Initialises a git repository in the scaffolded project and creates an
        initial commit. Requires git to be available on PATH.

    .PARAMETER Interactive
        Launches the guided wizard, prompting for any values not already
        provided via parameters. Pre-filled parameters are skipped.

    .PARAMETER PassThru
        Returns the full path of the generated project directory as a string.

    .INPUTS
        None

    .OUTPUTS
        System.String

    .EXAMPLE
        New-AnvilModule -Interactive

        Launches the guided wizard, prompting for all values.

    .EXAMPLE
        New-AnvilModule -Name 'NetworkTools' -DestinationPath '~/Projects' -Author 'Jane Doe'

        Scaffolds a GitHub CI project at ~/Projects/NetworkTools/ with MIT
        license and default settings.

    .EXAMPLE
        $Params = @{
            Name            = 'VaultHelper'
            DestinationPath = '~/src'
            Author          = 'Team'
            CompanyName     = 'Contoso'
            CIProvider      = 'GitLab'
            License         = 'Apache2'
            Tags            = @('Vault', 'Security')
            IncludeDocs     = $true
            GitInit         = $true
        }
        New-AnvilModule @Params

        Scaffolds a GitLab CI project with Apache 2.0 license, platyPS
        documentation, and an initialised git repository.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Author,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$CompanyName,

        [Parameter()]
        [string]$MinPowerShellVersion,

        [Parameter()]
        [ValidateSet('Desktop', 'Core')]
        [string[]]$CompatiblePSEditions,

        [Parameter()]
        [ValidateSet('GitHub', 'AzurePipelines', 'GitLab', 'None')]
        [string]$CIProvider,

        [Parameter()]
        [ValidateSet('MIT', 'Apache2', 'None')]
        [string]$License,

        [Parameter()]
        [switch]$IncludeDocs,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$CoverageThreshold,

        [Parameter()]
        [string[]]$Tags,

        [Parameter()]
        [ValidateScript({
                if ([string]::IsNullOrWhiteSpace($_)) { return $true }
                $uri = $_ -as [System.Uri]
                if (-not $uri -or -not $uri.IsAbsoluteUri) {
                    throw "'$_' is not a valid absolute URI."
                }
                $true
            })]
        [string]$ProjectUri,

        [Parameter()]
        [ValidateScript({
                if ([string]::IsNullOrWhiteSpace($_)) { return $true }
                $uri = $_ -as [System.Uri]
                if (-not $uri -or -not $uri.IsAbsoluteUri) {
                    throw "'$_' is not a valid absolute URI."
                }
                $true
            })]
        [string]$LicenseUri,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$GitInit,

        [Parameter()]
        [switch]$Interactive,

        [Parameter()]
        [switch]$PassThru
    )

    $Defaults = @{
        Description          = 'A PowerShell module scaffolded by Anvil.'
        CompanyName          = ''
        MinPowerShellVersion = '5.1'
        CompatiblePSEditions = @('Desktop', 'Core')
        CIProvider           = 'GitHub'
        License              = 'MIT'
        CoverageThreshold    = 80
        IncludeDocs          = $false
        Tags                 = @()
        ProjectUri           = ''
        LicenseUri           = ''
        GitInit              = $false
    }

    $PromptParams = @{
        BoundParams = $PSBoundParameters
        Defaults    = $Defaults
        Interactive = [bool]$Interactive
    }
    $Resolved = Invoke-InteractivePrompt @PromptParams

    $Config = @{
        ModuleName           = $Resolved.Name
        Author               = $Resolved.Author
        Description          = $Resolved.Description
        CIProvider           = $Resolved.CIProvider
        License              = $Resolved.License
        CoverageThreshold    = $Resolved.CoverageThreshold
        MinPowerShellVersion = $Resolved.MinPowerShellVersion
    }

    Assert-ValidConfiguration -Configuration $Config

    $ProjectRoot = Join-Path -Path $Resolved.DestinationPath -ChildPath $Resolved.Name

    if (Test-Path -Path $ProjectRoot) {
        if ($Resolved.Force) {
            Remove-Item -Path $ProjectRoot -Recurse -Force
        } else {
            throw "Destination already exists: $ProjectRoot -- remove it first, choose a different name, or use -Force."
        }
    }

    $ModuleGuid = [guid]::NewGuid().ToString()
    $Year = (Get-Date).Year.ToString()
    $DocsEnabled = if ($Resolved.IncludeDocs) { 'true' } else { 'false' }

    # Format array values for .psd1 embedding
    $EditionsString = "@('" + ($Resolved.CompatiblePSEditions -join "', '") + "')"
    $TagsString = if ($Resolved.Tags.Count -gt 0) {
        "@('" + ($Resolved.Tags -join "', '") + "')"
    } else {
        "@()"
    }

    $Tokens = @{
        ModuleName           = $Resolved.Name
        Author               = $Resolved.Author
        Description          = $Resolved.Description
        CompanyName          = $Resolved.CompanyName
        ModuleGuid           = $ModuleGuid
        Year                 = $Year
        CoverageThreshold    = $Resolved.CoverageThreshold.ToString()
        MinPowerShellVersion = $Resolved.MinPowerShellVersion
        CompatiblePSEditions = $EditionsString
        License              = $Resolved.License
        CIProvider           = $Resolved.CIProvider
        IncludeDocs          = $DocsEnabled
        Tags                 = $TagsString
        ProjectUri           = $Resolved.ProjectUri
        LicenseUri           = $Resolved.LicenseUri
    }

    if ($PSCmdlet.ShouldProcess($ProjectRoot, "Scaffold module project '$($Resolved.Name)'")) {

        Write-Host "[Anvil] Creating project: $($Resolved.Name)" -ForegroundColor Cyan
        Write-Host "[Anvil] Destination: $ProjectRoot" -ForegroundColor White

        # 1. Expand base module template
        $BaseTemplatePath = Join-Path -Path $script:TemplateRoot -ChildPath 'Module'
        $FileCount = Invoke-TemplateEngine -SourcePath $BaseTemplatePath -DestinationPath $ProjectRoot -Tokens $Tokens

        Write-Host "[Anvil] Base template: $FileCount files" -ForegroundColor DarkGray

        # 2. Layer CI-specific templates
        if ($Resolved.CIProvider -ne 'None') {
            $CiCount = Copy-CITemplates -Provider $Resolved.CIProvider -DestinationPath $ProjectRoot -Tokens $Tokens
            Write-Host "[Anvil] CI ($($Resolved.CIProvider)): $CiCount files" -ForegroundColor DarkGray
        }

        # 3. Remove license file if 'None'
        if ($Resolved.License -eq 'None') {
            $LicPath = Join-Path -Path $ProjectRoot -ChildPath 'LICENSE'
            if (Test-Path -Path $LicPath) {
                Remove-Item -Path $LicPath -Force
            }
        }

        # 4. Remove docs template files if docs not requested
        if (-not $Resolved.IncludeDocs) {
            $DocsDir = Join-Path -Path $ProjectRoot -ChildPath 'docs'
            if (Test-Path -Path $DocsDir) {
                Get-ChildItem -Path $DocsDir -File -Recurse -ErrorAction SilentlyContinue |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }

        Write-Host ''
        Write-Host "[Anvil] Project '$($Resolved.Name)' scaffolded successfully!" -ForegroundColor Green
        Write-Host "[Anvil] Next steps:" -ForegroundColor White
        Write-Host "  cd $ProjectRoot" -ForegroundColor White
        Write-Host "  ./build/bootstrap.ps1" -ForegroundColor White
        Write-Host "  Invoke-Build -File ./build/module.build.ps1" -ForegroundColor White
        Write-Host ''

        # 5. Optionally initialise a git repository
        if ($Resolved.GitInit) {
            $GitCmd = Get-Command -Name git -ErrorAction SilentlyContinue
            if ($GitCmd) {
                Push-Location -Path $ProjectRoot
                try {
                    & git init --quiet
                    & git add -A
                    & git commit --quiet -m 'Initial scaffold via Anvil'
                    Write-Host "[Anvil] Git repository initialised with initial commit." -ForegroundColor DarkGray
                } finally {
                    Pop-Location
                }
            } else {
                Write-Warning 'git not found on PATH -- skipping git init.'
            }
        }

        if ($Resolved.PassThru) {
            return $ProjectRoot
        }
    }
}
