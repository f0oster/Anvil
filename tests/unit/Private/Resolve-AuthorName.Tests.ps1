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

Describe 'Resolve-AuthorName' -Tag 'Unit' {

    It 'returns a string when git user.name is configured' {
        InModuleScope 'Anvil' {
            Mock Get-Command { [PSCustomObject]@{ Name = 'git' } } -ParameterFilter { $Name -eq 'git' }
            Mock git { 'Test User' }

            $Result = Resolve-AuthorName
            $Result | Should -Be 'Test User'
        }
    }

    It 'returns nothing when git is not installed' {
        InModuleScope 'Anvil' {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'git' }

            $Result = Resolve-AuthorName
            $Result | Should -BeNullOrEmpty
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Resolve-AuthorName'
    }
}
