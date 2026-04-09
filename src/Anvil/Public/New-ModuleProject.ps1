function New-ModuleProject {
    <#
    .SYNOPSIS
        Scaffolds a new PowerShell module project with build, test, lint, docs,
        and CI/CD pipelines.

    .DESCRIPTION
        Generates a complete, opinionated module project structure including:

          - Module source (manifest, .psm1 entry point, Public/Private layout)
          - InvokeBuild pipeline (Validate, Lint, Test, Build, IntegrationTest, Package, Publish)
          - Dependency manifest with pinned tool versions (installed via ModuleFast)
          - Pester 5 unit tests and post-build integration tests
          - PSScriptAnalyzer settings with formatting rules
          - CI/CD workflows for the chosen provider (GitHub, Azure Pipelines, GitLab)
          - README, CONTRIBUTING, LICENSE, .editorconfig, VS Code config

        Parameters are validated before scaffolding begins.  A fresh token
        table is built internally — caller-provided objects are never mutated.

    .PARAMETER Name
        The name of the new module.  Must start with a letter and contain only
        letters, digits, dots, hyphens, or underscores (max 128 characters).

    .PARAMETER DestinationPath
        Parent directory where the project folder will be created.  A child
        directory named after -Name is created inside this path.

    .PARAMETER Author
        Author name written into the module manifest, LICENSE, and copyright.

    .PARAMETER Description
        Short description for the module manifest.  Defaults to a generic
        string if omitted.

    .PARAMETER CIProvider
        CI/CD platform to scaffold workflows for.
        Valid values: GitHub, AzurePipelines, GitLab, None.
        Default: GitHub.

    .PARAMETER License
        License type to include.  Valid values: MIT, Apache2, None.
        Default: MIT.

    .PARAMETER IncludeDocs
        When set, the build pipeline adds a Docs task that generates markdown
        and MAML help via Microsoft.PowerShell.PlatyPS.

    .PARAMETER CoverageThreshold
        Minimum code coverage percentage enforced by Pester during the Test
        task.  Valid range: 0-100.  Default: 80.

    .PARAMETER MinPowerShellVersion
        Minimum PowerShell version declared in the generated module manifest.
        Must be a valid .NET version string (e.g. '5.1', '7.2').
        Default: '5.1'.

    .PARAMETER Force
        Removes and re-creates the destination directory if it already exists.

    .PARAMETER GitInit
        Initialises a git repository in the scaffolded project and creates an
        initial commit.  Requires git to be available on PATH.

    .PARAMETER PassThru
        Returns the full path of the generated project directory as a string.

    .INPUTS
        None.  This command does not accept pipeline input.

    .OUTPUTS
        System.String
            The project directory path, returned only when -PassThru is used.

    .EXAMPLE
        New-ModuleProject -Name 'NetworkTools' -DestinationPath '~/Projects' -Author 'Jane Doe'

        Scaffolds a GitHub CI project at ~/Projects/NetworkTools/ with MIT
        license and default settings.

    .EXAMPLE
        $Params = @{
            Name            = 'VaultHelper'
            DestinationPath = '~/src'
            Author          = 'Team'
            CIProvider      = 'GitLab'
            License         = 'Apache2'
            IncludeDocs     = $true
            GitInit         = $true
        }
        New-ModuleProject @Params

        Scaffolds a GitLab CI project with Apache 2.0 license, platyPS
        documentation, and an initialised git repository.

    .EXAMPLE
        $Path = New-ModuleProject -Name 'Rebuild' -DestinationPath '~/src' -Author 'Dev' -Force -PassThru

        Overwrites any existing ~/src/Rebuild/ directory and returns the path.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Author,

        [Parameter()]
        [string]$Description = "A PowerShell module scaffolded by Anvil.",

        [Parameter()]
        [ValidateSet('GitHub', 'AzurePipelines', 'GitLab', 'None')]
        [string]$CIProvider = 'GitHub',

        [Parameter()]
        [ValidateSet('MIT', 'Apache2', 'None')]
        [string]$License = 'MIT',

        [Parameter()]
        [switch]$IncludeDocs,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$CoverageThreshold = 80,

        [Parameter()]
        [string]$MinPowerShellVersion = '5.1',

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$GitInit,

        [Parameter()]
        [switch]$PassThru
    )

    $Config = @{
        ModuleName          = $Name
        Author              = $Author
        Description         = $Description
        CIProvider          = $CIProvider
        License             = $License
        CoverageThreshold   = $CoverageThreshold
        MinPowerShellVersion = $MinPowerShellVersion
    }

    Assert-ValidConfiguration -Configuration $Config

    $ProjectRoot = Join-Path -Path $DestinationPath -ChildPath $Name

    if (Test-Path -Path $ProjectRoot) {
        if ($Force) {
            Remove-Item -Path $ProjectRoot -Recurse -Force
        } else {
            throw "Destination already exists: $ProjectRoot — remove it first, choose a different name, or use -Force."
        }
    }

    $ModuleGuid = [guid]::NewGuid().ToString()
    $Year = (Get-Date).Year.ToString()
    $DocsEnabled = if ($IncludeDocs) { 'true' } else { 'false' }

    $DefaultTasks = if ($IncludeDocs) {
        'Clean, Validate, Format, Lint, Test, Docs, Build, IntegrationTest, Package'
    } else {
        'Clean, Validate, Format, Lint, Test, Build, IntegrationTest, Package'
    }

    $Tokens = @{
        ModuleName          = $Name
        Author              = $Author
        Description         = $Description
        ModuleGuid          = $ModuleGuid
        Year                = $Year
        CoverageThreshold   = $CoverageThreshold.ToString()
        MinPowerShellVersion = $MinPowerShellVersion
        License             = $License
        CIProvider          = $CIProvider
        IncludeDocs         = $DocsEnabled
        DefaultTasks        = $DefaultTasks
    }

    if ($PSCmdlet.ShouldProcess($ProjectRoot, "Scaffold module project '$Name'")) {

        Write-Host "[Anvil] Creating project: $Name" -ForegroundColor Cyan
        Write-Host "[Anvil] Destination: $ProjectRoot" -ForegroundColor White

        # 1. Expand base module template
        $BaseTemplatePath = Join-Path -Path $script:TemplateRoot -ChildPath 'Module'
        $FileCount = Invoke-TemplateEngine -SourcePath $BaseTemplatePath -DestinationPath $ProjectRoot -Tokens $Tokens

        Write-Host "[Anvil] Base template: $FileCount files" -ForegroundColor DarkGray

        # 2. Layer CI-specific templates
        if ($CIProvider -ne 'None') {
            $CiCount = Copy-CITemplates -Provider $CIProvider -DestinationPath $ProjectRoot -Tokens $Tokens
            Write-Host "[Anvil] CI ($CIProvider): $CiCount files" -ForegroundColor DarkGray
        }

        # 3. Remove license file if 'None'
        if ($License -eq 'None') {
            $LicPath = Join-Path -Path $ProjectRoot -ChildPath 'LICENSE'
            if (Test-Path -Path $LicPath) {
                Remove-Item -Path $LicPath -Force
            }
        }

        # 4. Remove docs template files if docs not requested
        if (-not $IncludeDocs) {
            $DocsDir = Join-Path -Path $ProjectRoot -ChildPath 'docs'
            if (Test-Path -Path $DocsDir) {
                # Keep the directory but remove placeholder content
                Get-ChildItem -Path $DocsDir -File -Recurse -ErrorAction SilentlyContinue |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }

        Write-Host ''
        Write-Host "[Anvil] Project '$Name' scaffolded successfully!" -ForegroundColor Green
        Write-Host "[Anvil] Next steps:" -ForegroundColor White
        Write-Host "  cd $ProjectRoot" -ForegroundColor White
        Write-Host "  ./build/bootstrap.ps1" -ForegroundColor White
        Write-Host "  Invoke-Build -File ./build/module.build.ps1" -ForegroundColor White
        Write-Host ''

        # 5. Optionally initialise a git repository
        if ($GitInit) {
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
                Write-Warning 'git not found on PATH — skipping -GitInit.'
            }
        }

        if ($PassThru) {
            return $ProjectRoot
        }
    }
}
