#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeDiscovery {
    $ProjectRoot = $PSScriptRoot
    while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
        $ProjectRoot = Split-Path $ProjectRoot -Parent
    }
    $ModuleName   = 'Anvil'
    $ModuleDir    = Join-Path -Path $ProjectRoot -ChildPath 'src' | Join-Path -ChildPath $ModuleName
    $ManifestPath = Join-Path -Path $ModuleDir -ChildPath "$ModuleName.psd1"

    $ManifestData      = Import-PowerShellDataFile -Path $ManifestPath
    $DeclaredFunctions = @($ManifestData.FunctionsToExport)
}

BeforeAll {
    $ProjectRoot = $PSScriptRoot
    while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
        $ProjectRoot = Split-Path $ProjectRoot -Parent
    }
    $ModuleName   = 'Anvil'
    $ModuleDir    = Join-Path -Path $ProjectRoot -ChildPath 'src' | Join-Path -ChildPath $ModuleName
    $ManifestPath = Join-Path -Path $ModuleDir -ChildPath "$ModuleName.psd1"

    Get-Module -Name $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $ManifestPath -Force -ErrorAction Stop

    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    $ExpectedFunctionCount = @($ManifestData.FunctionsToExport).Count
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'Module: Anvil' -Tag 'Unit' {

    Context 'Manifest' {
        It 'has a valid manifest' {
            { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
        }
        It 'has a non-empty description' {
            (Test-ModuleManifest -Path $ManifestPath).Description | Should -Not -BeNullOrEmpty
        }
        It 'targets PowerShell 5.1+' {
            (Test-ModuleManifest -Path $ManifestPath).PowerShellVersion | Should -BeGreaterOrEqual ([Version]'5.1')
        }
        It 'declares no runtime RequiredModules' {
            $Data = Import-PowerShellDataFile -Path $ManifestPath
            $Data.RequiredModules | Should -BeNullOrEmpty
        }
    }

    Context 'Import and exports' {
        It 'imports without error' {
            { Import-Module $ManifestPath -Force -ErrorAction Stop } | Should -Not -Throw
        }
        It 'exports <_>' -ForEach $DeclaredFunctions {
            (Get-Module -Name 'Anvil').ExportedFunctions.Keys | Should -Contain $_
        }
        It 'does not export private functions' {
            $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
            $Exported | Should -Not -Contain 'Invoke-TemplateEngine'
            $Exported | Should -Not -Contain 'Resolve-PathTokens'
            $Exported | Should -Not -Contain 'Resolve-ContentTokens'
            $Exported | Should -Not -Contain 'Assert-ValidConfiguration'
            $Exported | Should -Not -Contain 'Copy-CITemplates'
            $Exported | Should -Not -Contain 'Test-Excluded'
            $Exported | Should -Not -Contain 'Get-TestContent'
            $Exported | Should -Not -Contain 'Get-FunctionContent'
        }
    }

    Context 'Template root' {
        It 'ships a Templates directory' {
            $ModuleDir = (Get-Module -Name 'Anvil').ModuleBase
            Join-Path -Path $ModuleDir -ChildPath 'Templates' | Should -Exist
        }
        It 'contains the Module base template' {
            $ModuleDir = (Get-Module -Name 'Anvil').ModuleBase
            Join-Path -Path $ModuleDir -ChildPath 'Templates' |
                Join-Path -ChildPath 'Module' | Should -Exist
        }
    }
}
