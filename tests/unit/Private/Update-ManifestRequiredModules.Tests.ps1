#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

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
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'Update-ManifestRequiredModules' -Tag 'Unit' {

    BeforeEach {
        InModuleScope 'Anvil' {
            $script:TestManifest = Join-Path $TestDrive 'Test.psd1'
            @"
@{
    RootModule        = 'Test.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = '$([guid]::NewGuid())'
    Author            = 'Test'
    Description       = 'Test module'
    PowerShellVersion = '5.1'
    RequiredModules    = @()
    FunctionsToExport = @()
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
}
"@ | Set-Content -Path $script:TestManifest -NoNewline
        }
    }

    It 'writes an empty RequiredModules for empty requirements' {
        InModuleScope 'Anvil' {
            Update-ManifestRequiredModules -ManifestPath $script:TestManifest -Requirements @{}

            $Manifest = Import-PowerShellDataFile -Path $script:TestManifest
            $Manifest.RequiredModules.Count | Should -Be 0
        }
    }

    It 'writes minimum version entries for >= specs' {
        InModuleScope 'Anvil' {
            Update-ManifestRequiredModules -ManifestPath $script:TestManifest -Requirements @{
                'Az.Storage' = '>=5.0.0'
            }

            $Manifest = Import-PowerShellDataFile -Path $script:TestManifest
            $Entry = $Manifest.RequiredModules | Where-Object { $_.ModuleName -eq 'Az.Storage' }
            $Entry | Should -Not -BeNullOrEmpty
            $Entry.ModuleVersion | Should -Be '5.0.0'
        }
    }

    It 'writes exact version entries' {
        InModuleScope 'Anvil' {
            Update-ManifestRequiredModules -ManifestPath $script:TestManifest -Requirements @{
                'Pester' = '5.7.1'
            }

            $Manifest = Import-PowerShellDataFile -Path $script:TestManifest
            $Entry = $Manifest.RequiredModules | Where-Object { $_.ModuleName -eq 'Pester' }
            $Entry | Should -Not -BeNullOrEmpty
            $Entry.RequiredVersion | Should -Be '5.7.1'
        }
    }

    It 'writes bare string entries for latest' {
        InModuleScope 'Anvil' {
            Update-ManifestRequiredModules -ManifestPath $script:TestManifest -Requirements @{
                'ImportExcel' = 'latest'
            }

            $Manifest = Import-PowerShellDataFile -Path $script:TestManifest
            $Manifest.RequiredModules | Should -Contain 'ImportExcel'
        }
    }

    It 'handles multiple entries sorted by name' {
        InModuleScope 'Anvil' {
            Update-ManifestRequiredModules -ManifestPath $script:TestManifest -Requirements @{
                'Zebra'  = 'latest'
                'Alpha'  = '>=1.0.0'
            }

            $Manifest = Import-PowerShellDataFile -Path $script:TestManifest
            $Manifest.RequiredModules.Count | Should -Be 2
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Update-ManifestRequiredModules'
    }
}
