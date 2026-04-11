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

Describe 'ConvertTo-RequiredModuleEntry' -Tag 'Unit' {

    It 'returns bare module name for latest' {
        InModuleScope 'Anvil' {
            $Result = ConvertTo-RequiredModuleEntry -Name 'Pester' -VersionSpec 'latest'
            $Result | Should -Be 'Pester'
            $Result | Should -BeOfType [string]
        }
    }

    It 'returns hashtable with ModuleVersion for >= spec' {
        InModuleScope 'Anvil' {
            $Result = ConvertTo-RequiredModuleEntry -Name 'Pester' -VersionSpec '>=5.0.0'
            $Result | Should -BeOfType [hashtable]
            $Result.ModuleName | Should -Be 'Pester'
            $Result.ModuleVersion | Should -Be '5.0.0'
            $Result.Keys | Should -Not -Contain 'RequiredVersion'
        }
    }

    It 'returns hashtable with RequiredVersion for exact version' {
        InModuleScope 'Anvil' {
            $Result = ConvertTo-RequiredModuleEntry -Name 'PSScriptAnalyzer' -VersionSpec '5.7.1'
            $Result | Should -BeOfType [hashtable]
            $Result.ModuleName | Should -Be 'PSScriptAnalyzer'
            $Result.RequiredVersion | Should -Be '5.7.1'
            $Result.Keys | Should -Not -Contain 'ModuleVersion'
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'ConvertTo-RequiredModuleEntry'
    }
}
