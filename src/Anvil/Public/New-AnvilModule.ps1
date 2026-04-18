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

    .PARAMETER Template
        Template to scaffold from.  Accepts a template name (looked up
        under the bundled Templates directory) or an absolute path to a
        directory containing a template.psd1 manifest.
        Default: Module.

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
        [string]$Template = 'Module',

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$GitInit,

        [Parameter()]
        [switch]$Interactive,

        [Parameter()]
        [switch]$PassThru
    )

    # Resolve template path
    if (Test-Path -Path $Template -PathType Container) {
        $BaseTemplatePath = $Template
    } else {
        $BaseTemplatePath = Join-Path -Path $script:TemplateRoot -ChildPath $Template
    }

    $Manifest = Read-TemplateManifest -TemplatePath $BaseTemplatePath

    # Map cmdlet parameters to manifest parameter names
    $OperationalParams = @('DestinationPath', 'Force', 'GitInit', 'Interactive', 'PassThru', 'Template')
    $ManifestBound = @{}
    foreach ($Key in $PSBoundParameters.Keys) {
        if ($Key -notin $OperationalParams) {
            $ManifestBound[$Key] = $PSBoundParameters[$Key]
        }
    }

    # Resolve template parameters via manifest
    $Resolved = Invoke-ManifestPrompt -Manifest $Manifest -BoundParams $ManifestBound -Interactive ([bool]$Interactive)

    # Resolve operational parameters
    $ResolvedDestination = if ($PSBoundParameters.ContainsKey('DestinationPath')) {
        $DestinationPath
    } elseif ($Interactive) {
        Read-PromptValue -Prompt '  Destination path' -Default $PWD.Path
    } else {
        if (-not $DestinationPath) {
            throw "'DestinationPath' is required. Use -Interactive for the guided wizard."
        }
        $DestinationPath
    }

    $ResolvedGitInit = if ($PSBoundParameters.ContainsKey('GitInit')) {
        [bool]$GitInit
    } elseif ($Interactive) {
        $GitInput = Read-PromptValue -Prompt '  Initialize git repository? (y/n)' -Default 'n'
        $GitInput -match '^[Yy]'
    } else {
        $false
    }

    Assert-ManifestConfiguration -Manifest $Manifest -Configuration $Resolved

    $ProjectRoot = Join-Path -Path $ResolvedDestination -ChildPath $Resolved.Name

    if (Test-Path -Path $ProjectRoot) {
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($ProjectRoot, 'Remove existing project directory')) {
                Remove-Item -Path $ProjectRoot -Recurse -Force
            } else {
                return
            }
        } else {
            throw "Destination already exists: $ProjectRoot -- remove it first, choose a different name, or use -Force."
        }
    }

    # Build token table from manifest parameters
    $Tokens = @{}
    foreach ($Param in $Manifest.Parameters) {
        $ParamName = $Param.Name
        $Value = $Resolved[$ParamName]
        $Formatter = if ($Param.ContainsKey('Format')) { $Param.Format } else { 'raw' }
        $Tokens[$ParamName] = Format-TokenValue -Value $Value -Formatter $Formatter
    }

    # Resolve auto-tokens
    foreach ($Auto in $Manifest.AutoTokens) {
        $Tokens[$Auto.Name] = Resolve-AutoToken -Source $Auto.Source
    }

    # Extract conditions from manifest
    $IncludeWhen = if ($Manifest.ContainsKey('IncludeWhen')) { $Manifest.IncludeWhen } else { @{} }
    $ExcludeWhen = if ($Manifest.ContainsKey('ExcludeWhen')) { $Manifest.ExcludeWhen } else { @{} }
    $Sections = if ($Manifest.ContainsKey('Sections')) { $Manifest.Sections } else { @{} }

    if ($PSCmdlet.ShouldProcess($ProjectRoot, "Scaffold module project '$($Resolved.Name)'")) {

        Write-Host "[Anvil] Creating project: $($Resolved.Name)" -ForegroundColor Cyan
        Write-Host "[Anvil] Destination: $ProjectRoot" -ForegroundColor White

        # 1. Expand base module template with conditions
        $EngineParams = @{
            SourcePath      = $BaseTemplatePath
            DestinationPath = $ProjectRoot
            Tokens          = $Tokens
            ExcludePatterns = @('template.psd1')
            IncludeWhen     = $IncludeWhen
            ExcludeWhen     = $ExcludeWhen
            Sections        = $Sections
        }
        $FileCount = Invoke-TemplateEngine @EngineParams

        Write-Host "[Anvil] Base template: $FileCount files" -ForegroundColor DarkGray

        # 2. Process layers from manifest
        if ($Manifest.ContainsKey('Layers')) {
            foreach ($Layer in $Manifest.Layers) {
                $LayerValue = $Resolved[$Layer.PathKey]
                if ($Layer.ContainsKey('Skip') -and $LayerValue -eq $Layer.Skip) {
                    continue
                }
                $LayerRoot = Split-Path -Path $BaseTemplatePath -Parent
                $LayerPath = Join-Path -Path $LayerRoot -ChildPath $Layer.BasePath |
                    Join-Path -ChildPath $LayerValue
                if (Test-Path -Path $LayerPath) {
                    $LayerCount = Invoke-TemplateEngine -SourcePath $LayerPath -DestinationPath $ProjectRoot -Tokens $Tokens
                    Write-Host "[Anvil] Layer ($LayerValue): $LayerCount files" -ForegroundColor DarkGray
                }
            }
        }

        # 3. Write Anvil version stamp
        $AnvilVersion = (Get-Module -Name 'Anvil').Version.ToString()
        Set-Content -Path (Join-Path $ProjectRoot '.ANVIL_VERSION') -Value $AnvilVersion -NoNewline

        Write-Host ''
        Write-Host "[Anvil] Project '$($Resolved.Name)' scaffolded successfully!" -ForegroundColor Green
        Write-Host "[Anvil] Next steps:" -ForegroundColor White
        Write-Host "  cd $ProjectRoot" -ForegroundColor White
        Write-Host "  Invoke-AnvilBootstrapDeps" -ForegroundColor White
        Write-Host "  Invoke-AnvilBuild" -ForegroundColor White
        Write-Host ''

        # 4. Optionally initialise a git repository
        if ($ResolvedGitInit) {
            $GitCmd = Get-Command -Name git -ErrorAction SilentlyContinue
            if ($GitCmd) {
                Push-Location -Path $ProjectRoot
                try {
                    & git init --quiet
                    Write-Host "[Anvil] Git repository initialised." -ForegroundColor DarkGray
                } finally {
                    Pop-Location
                }
            } else {
                Write-Warning 'git not found on PATH -- skipping git init.'
            }
        }

        if ($PassThru) {
            return $ProjectRoot
        }
    }
}
