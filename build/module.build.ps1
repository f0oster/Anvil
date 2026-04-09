#Requires -Version 5.1
<#
.SYNOPSIS
    InvokeBuild build script for Anvil.

.DESCRIPTION
    Task graph:
        . (default)  ->  Clean, Validate, Format, Lint, Test, Docs, Build, IntegrationTest, Package
        Release      ->  Version + . + Publish
        DevCC        ->  generate Coverage Gutters output for VS Code

    Invoke with:
        Invoke-Build                                    # full default pipeline
        Invoke-Build -Task Lint                         # single task
        Invoke-Build -Task Release                      # full + publish
        Invoke-Build -Task DevCC                        # local coverage for VS Code
        Invoke-Build -Task Version -NewVersion 1.2.0    # bump version
        Invoke-Build -Task Version -Prerelease beta1   # set prerelease label
        Invoke-Build -Task Version -Prerelease ''      # clear prerelease label
#>
param(
    [string]$NewVersion,
    [string]$Prerelease
)

# Settings (user-editable in build.settings.psd1)
$script:Settings       = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'build.settings.psd1')
$script:ModuleName     = $script:Settings.ModuleName
$script:CoverageThreshold = $script:Settings.CoverageThreshold

# Project paths
$script:ProjectRoot    = Split-Path -Path $BuildFile -Parent | Split-Path -Parent
$script:SrcDir         = Join-Path -Path $script:ProjectRoot -ChildPath 'src'
$script:ModuleDir      = Join-Path -Path $script:SrcDir      -ChildPath $script:ModuleName
$script:ManifestPath   = Join-Path -Path $script:ModuleDir   -ChildPath "$($script:ModuleName).psd1"
$script:ModuleFilePath = Join-Path -Path $script:ModuleDir   -ChildPath "$($script:ModuleName).psm1"
$script:TestsDir       = Join-Path -Path $script:ProjectRoot -ChildPath 'tests'
$script:UnitTestDir    = Join-Path -Path $script:TestsDir    -ChildPath 'unit'
$script:IntTestDir     = Join-Path -Path $script:TestsDir    -ChildPath 'integration'
$script:DocsDir        = Join-Path -Path $script:ProjectRoot -ChildPath 'docs'
$script:ArtifactsDir   = Join-Path -Path $script:ProjectRoot -ChildPath 'artifacts'
$script:PackageDir     = Join-Path -Path $script:ArtifactsDir -ChildPath 'package'
$script:TestResultsDir = Join-Path -Path $script:ArtifactsDir -ChildPath 'testResults'
$script:ArchiveDir     = Join-Path -Path $script:ArtifactsDir -ChildPath 'archive'

# Helpers
function Write-BuildHeader ([string]$Message) {
    $D = '=' * 72
    Write-Build Cyan "`n$D`n  $Message`n$D`n"
}

function Write-BuildFooter ([string]$Message) {
    Write-Build Green "  [ok] $Message`n"
}

function Assert-FileExists ([string]$Path, [string]$Description) {
    if (-not (Test-Path -Path $Path)) { throw "$Description not found: $Path" }
}

# Tasks

task Clean {
    Write-BuildHeader 'Clean'
    if (Test-Path -Path $script:ArtifactsDir) {
        Remove-Item -Path $script:ArtifactsDir -Recurse -Force
    }
    @($script:ArtifactsDir, $script:PackageDir, $script:TestResultsDir, $script:ArchiveDir) | ForEach-Object {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
    Write-BuildFooter 'Clean complete'
}

task Validate {
    Write-BuildHeader 'Validate'
    Write-Build White "  PowerShell $($PSVersionTable.PSVersion)"
    Assert-FileExists -Path $script:ManifestPath -Description 'Module manifest'
    $Manifest = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
    Write-Build White "  Manifest OK: $($Manifest.Name) v$($Manifest.Version)"
    Assert-FileExists -Path $script:ModuleFilePath -Description 'Module .psm1'
    Write-BuildFooter 'Validation complete'
}

task Format {
    Write-BuildHeader 'Format (Invoke-Formatter)'
    $SettingsPath = Join-Path -Path $script:ProjectRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
    $FormatterParams = @{}
    if (Test-Path -Path $SettingsPath) { $FormatterParams['Settings'] = $SettingsPath }
    $Files = Get-ChildItem -Path $script:ModuleDir -Filter '*.ps1' -Recurse
    foreach ($File in $Files) {
        $Original = Get-Content -Path $File.FullName -Raw
        if ([string]::IsNullOrWhiteSpace($Original)) { continue }
        try {
            $Formatted = Invoke-Formatter -ScriptDefinition $Original @FormatterParams
        } catch {
            Write-Build Yellow "  Skipped (formatter error): $($File.Name)"
            continue
        }
        if ([string]::IsNullOrWhiteSpace($Formatted)) {
            Write-Build Yellow "  Skipped (empty result): $($File.Name)"
            continue
        }
        if ($Formatted -ne $Original) {
            Set-Content -Path $File.FullName -Value $Formatted -NoNewline
            Write-Build DarkGray "  Formatted: $($File.Name)"
        }
    }
    Write-BuildFooter 'Formatting complete'
}

task Lint {
    Write-BuildHeader 'Lint (PSScriptAnalyzer)'
    $Params = @{
        Path    = $script:ModuleDir
        Recurse = $true
    }
    $SettingsPath = Join-Path -Path $script:ProjectRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
    if (Test-Path -Path $SettingsPath) { $Params['Settings'] = $SettingsPath }
    $AnalyzersDir = Join-Path -Path $PSScriptRoot -ChildPath 'analyzers'
    if (Test-Path -Path $AnalyzersDir) {
        $RuleFiles = (Get-ChildItem -Path $AnalyzersDir -Filter '*.psm1').FullName
        if ($RuleFiles) {
            $Params['CustomRulePath'] = $RuleFiles
            $Params['IncludeDefaultRules'] = $true
        }
    }
    $Results = Invoke-ScriptAnalyzer @Params
    if ($Results) {
        $Results | Format-Table -AutoSize
        $Failures = $Results | Where-Object { $_.Severity -in 'Error', 'Warning' }
        if ($Failures) {
            throw "PSScriptAnalyzer found $($Failures.Count) issue(s)."
        }
    }
    Write-BuildFooter 'No lint issues'
}

task Test {
    Write-BuildHeader 'Unit Tests (Pester 5)'
    Assert-FileExists -Path $script:UnitTestDir -Description 'Unit test directory'

    $Cfg = New-PesterConfiguration
    $Cfg.Run.Path                           = $script:UnitTestDir
    $Cfg.Run.Exit                           = $true
    $Cfg.Output.Verbosity                   = 'Detailed'
    $Cfg.TestResult.Enabled                 = $true
    $Cfg.TestResult.OutputFormat             = if ($env:PESTER_OUTPUT_FORMAT) { $env:PESTER_OUTPUT_FORMAT } else { 'NUnitXml' }
    $Cfg.TestResult.OutputPath               = Join-Path -Path $script:TestResultsDir -ChildPath 'unit-results.xml'
    $Cfg.CodeCoverage.Enabled               = $true
    $Cfg.CodeCoverage.Path                  = @(
        (Join-Path -Path $script:ModuleDir -ChildPath 'PrivateClasses')
        (Join-Path -Path $script:ModuleDir -ChildPath 'Public')
        (Join-Path -Path $script:ModuleDir -ChildPath 'Private')
    )
    $Cfg.CodeCoverage.OutputFormat           = 'JaCoCo'
    $Cfg.CodeCoverage.OutputPath             = Join-Path -Path $script:TestResultsDir -ChildPath 'coverage.xml'
    $Cfg.CodeCoverage.CoveragePercentTarget  = $script:CoverageThreshold

    Invoke-Pester -Configuration $Cfg
    Write-BuildFooter 'Unit tests complete'
}

task Docs {
    Write-BuildHeader 'Documentation (platyPS)'

    if (-not (Get-Module -ListAvailable -Name 'platyPS' -ErrorAction SilentlyContinue)) {
        Write-Build Yellow '  platyPS not installed -- skipping docs generation'
        return
    }
    Import-Module platyPS -ErrorAction Stop
    Import-Module $script:ManifestPath -Force -ErrorAction Stop

    $MdDir = Join-Path -Path $script:DocsDir -ChildPath 'commands'
    $ExistingDocs = Get-ChildItem -Path $MdDir -Filter '*.md' -Recurse -ErrorAction SilentlyContinue

    if ($ExistingDocs) {
        Update-MarkdownHelp -Path $MdDir | Out-Null
        Write-Build White "  Updated $($ExistingDocs.Count) existing doc(s)"
    } else {
        if (-not (Test-Path -Path $MdDir)) {
            New-Item -Path $MdDir -ItemType Directory -Force | Out-Null
        }
        New-MarkdownHelp -Module $script:ModuleName -OutputFolder $MdDir -Force | Out-Null
        Write-Build White '  Generated initial documentation'
    }

    Write-BuildFooter 'Docs generation complete'
}

task Build {
    Write-BuildHeader 'Build (compile module)'
    $Staging = Join-Path -Path $script:PackageDir -ChildPath $script:ModuleName
    if (Test-Path -Path $Staging) { Remove-Item -Path $Staging -Recurse -Force }
    New-Item -Path $Staging -ItemType Directory -Force | Out-Null

    # Copy static assets
    foreach ($AssetDir in @('Types', 'Formats', 'Assemblies', 'Templates')) {
        $AssetPath = Join-Path -Path $script:ModuleDir -ChildPath $AssetDir
        if (Test-Path -Path $AssetPath) {
            Copy-Item -Path $AssetPath -Destination (Join-Path -Path $Staging -ChildPath $AssetDir) -Recurse
        }
    }

    # Compile .psm1
    $Sb = [System.Text.StringBuilder]::new()

    $ImportsPath = Join-Path -Path $script:ModuleDir -ChildPath 'Imports.ps1'
    if (Test-Path -Path $ImportsPath) {
        [void]$Sb.AppendLine('# --- Imports ---')
        [void]$Sb.AppendLine((Get-Content -Path $ImportsPath -Raw))
        [void]$Sb.AppendLine('')
    }

    $PrivateClassesPath = Join-Path -Path $script:ModuleDir -ChildPath 'PrivateClasses'
    $PrivatePath = Join-Path -Path $script:ModuleDir -ChildPath 'Private'
    $PublicPath  = Join-Path -Path $script:ModuleDir -ChildPath 'Public'

    foreach ($Dir in @($PrivateClassesPath, $PrivatePath, $PublicPath)) {
        if (Test-Path -Path $Dir) {
            foreach ($File in (Get-ChildItem -Path $Dir -Filter '*.ps1' -Recurse | Sort-Object FullName)) {
                [void]$Sb.AppendLine("# --- $($File.Name) ---")
                [void]$Sb.AppendLine((Get-Content -Path $File.FullName -Raw))
                [void]$Sb.AppendLine('')
            }
        }
    }

    $CompiledPsm1 = Join-Path -Path $Staging -ChildPath "$($script:ModuleName).psm1"
    Set-Content -Path $CompiledPsm1 -Value $Sb.ToString() -NoNewline

    # Generate a clean manifest
    $PublicFunctions = @()
    if (Test-Path -Path $PublicPath) {
        $PublicFunctions = @((Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse).BaseName | Sort-Object)
    }

    $SourceManifest = Import-PowerShellDataFile -Path $script:ManifestPath
    $PSData = $SourceManifest.PrivateData.PSData

    $ManifestParams = @{
        Path              = Join-Path -Path $Staging -ChildPath "$($script:ModuleName).psd1"
        RootModule        = "$($script:ModuleName).psm1"
        ModuleVersion     = if ($NewVersion) { $NewVersion } else { $SourceManifest.ModuleVersion }
        Guid              = $SourceManifest.GUID
        Author            = $SourceManifest.Author
        CompanyName       = $SourceManifest.CompanyName
        Copyright         = $SourceManifest.Copyright
        Description       = $SourceManifest.Description
        PowerShellVersion = $SourceManifest.PowerShellVersion
        FunctionsToExport = $PublicFunctions
        CmdletsToExport   = @()
        VariablesToExport  = @()
        AliasesToExport    = @()
    }

    # Carry through optional manifest properties
    if ($SourceManifest.CompatiblePSEditions)  { $ManifestParams.CompatiblePSEditions = $SourceManifest.CompatiblePSEditions }
    if ($SourceManifest.RequiredModules)        { $ManifestParams.RequiredModules = $SourceManifest.RequiredModules }
    if ($SourceManifest.RequiredAssemblies)     { $ManifestParams.RequiredAssemblies = $SourceManifest.RequiredAssemblies }
    if ($SourceManifest.NestedModules)          { $ManifestParams.NestedModules = $SourceManifest.NestedModules }
    if ($SourceManifest.ScriptsToProcess)       { $ManifestParams.ScriptsToProcess = $SourceManifest.ScriptsToProcess }
    if ($SourceManifest.TypesToProcess)         { $ManifestParams.TypesToProcess = $SourceManifest.TypesToProcess }
    if ($SourceManifest.FormatsToProcess)       { $ManifestParams.FormatsToProcess = $SourceManifest.FormatsToProcess }

    # Carry through PSData metadata
    if ($PSData.Tags)                          { $ManifestParams.Tags = $PSData.Tags }
    if ($PSData.LicenseUri)                    { $ManifestParams.LicenseUri = $PSData.LicenseUri }
    if ($PSData.ProjectUri)                    { $ManifestParams.ProjectUri = $PSData.ProjectUri }
    if ($PSData.ReleaseNotes)                  { $ManifestParams.ReleaseNotes = $PSData.ReleaseNotes }
    if ($Prerelease) {
        $ManifestParams.Prerelease = $Prerelease
    } elseif ($PSData.Prerelease) {
        $ManifestParams.Prerelease = $PSData.Prerelease
    }
    if ($PSData.ExternalModuleDependencies)    { $ManifestParams.ExternalModuleDependencies = $PSData.ExternalModuleDependencies }

    New-ModuleManifest @ManifestParams

    # Generate MAML help from markdown docs
    $MdDir = Join-Path -Path $script:DocsDir -ChildPath 'commands'
    if ((Test-Path -Path $MdDir) -and (Get-Module -ListAvailable -Name 'platyPS' -ErrorAction SilentlyContinue)) {
        Import-Module platyPS -ErrorAction Stop
        $HelpDir = Join-Path -Path $Staging -ChildPath 'en-US'
        New-ExternalHelp -Path $MdDir -OutputPath $HelpDir -Force | Out-Null
        Write-Build White '  Generated MAML help'
    }

    Write-Build White "  Compiled $($PublicFunctions.Count) public + private functions into .psm1"
    Write-BuildFooter 'Build complete'
}

task IntegrationTest {
    Write-BuildHeader 'Integration Tests'
    if (-not (Test-Path -Path $script:IntTestDir)) {
        Write-Build Yellow '  No integration tests found -- skipping'
        return
    }
    $Cfg = New-PesterConfiguration
    $Cfg.Run.Path                 = $script:IntTestDir
    $Cfg.Run.Exit                 = $true
    $Cfg.Output.Verbosity         = 'Detailed'
    $Cfg.TestResult.Enabled       = $true
    $Cfg.TestResult.OutputFormat   = 'NUnitXml'
    $Cfg.TestResult.OutputPath     = Join-Path -Path $script:TestResultsDir -ChildPath 'integration-results.xml'
    Invoke-Pester -Configuration $Cfg
    Write-BuildFooter 'Integration tests complete'
}

task Package {
    Write-BuildHeader 'Package'
    $Staging = Join-Path -Path $script:PackageDir -ChildPath $script:ModuleName
    Assert-FileExists -Path $Staging -Description 'Staged module (run Build first)'

    $Manifest    = Test-ModuleManifest -Path (Join-Path -Path $Staging -ChildPath "$($script:ModuleName).psd1") -ErrorAction Stop
    $ArchiveName = "$($script:ModuleName)-$($Manifest.Version).zip"
    $ArchivePath = Join-Path -Path $script:ArchiveDir -ChildPath $ArchiveName
    Compress-Archive -Path $Staging -DestinationPath $ArchivePath -Force

    Write-Build White "  Archive: $ArchivePath"
    Write-BuildFooter 'Packaging complete'
}

task Version {
    Write-BuildHeader 'Version'
    $Manifest = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
    Write-Build White "  Source: $($Manifest.Version)"
    if ($NewVersion) {
        Write-Build Green "  Build will use: $NewVersion"
    }
    if ($Prerelease) {
        Write-Build Green "  Prerelease: $Prerelease"
    }
    if (-not $NewVersion -and -not $Prerelease) {
        Write-Build DarkGray '  No -NewVersion or -Prerelease provided. Build will use source version.'
    }
    Write-BuildFooter 'Version task complete'
}

task Publish {
    Write-BuildHeader 'Publish to PowerShell Gallery'
    $ApiKey = $env:PSGALLERY_API_KEY
    if (-not $ApiKey) { throw 'PSGALLERY_API_KEY not set.' }
    $Staging = Join-Path -Path $script:PackageDir -ChildPath $script:ModuleName
    Assert-FileExists -Path $Staging -Description 'Staged module'
    $StagedManifest = Join-Path -Path $Staging -ChildPath "$($script:ModuleName).psd1"
    $ManifestInfo = Test-ModuleManifest -Path $StagedManifest -ErrorAction Stop
    if ($ManifestInfo.Version -eq [Version]'0.0.0') {
        throw "Cannot publish placeholder version 0.0.0. Pass -NewVersion to inject a release version: Invoke-Build -Task Release -NewVersion 1.0.0"
    }
    Publish-Module -Path $Staging -NuGetApiKey $ApiKey -ErrorAction Stop
    Write-BuildFooter "Published v$($ManifestInfo.Version)"
}

task DevCC {
    Write-BuildHeader 'Dev Code Coverage'
    Assert-FileExists -Path $script:UnitTestDir -Description 'Unit test directory'

    $Cfg = New-PesterConfiguration
    $Cfg.Run.Path              = $script:UnitTestDir
    $Cfg.Run.Exit              = $false
    $Cfg.Output.Verbosity      = 'Normal'
    $Cfg.CodeCoverage.Enabled  = $true
    $Cfg.CodeCoverage.Path     = @(
        (Join-Path -Path $script:ModuleDir -ChildPath 'Public')
        (Join-Path -Path $script:ModuleDir -ChildPath 'Private')
    )
    $Cfg.CodeCoverage.OutputFormat = 'CoverageGutters'
    $Cfg.CodeCoverage.OutputPath   = Join-Path -Path $script:ProjectRoot -ChildPath 'coverage.xml'

    Invoke-Pester -Configuration $Cfg

    Write-Build White "  Coverage file: $(Join-Path -Path $script:ProjectRoot -ChildPath 'coverage.xml')"
    Write-BuildFooter 'Dev coverage complete -- open Coverage Gutters in VS Code'
}

# Composite tasks
task . Clean, Validate, Format, Lint, Test, Docs, Build, IntegrationTest, Package
task Release Version, ., Publish
