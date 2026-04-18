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

Describe 'Resolve-DefaultFrom' -Tag 'Unit' {

    Context 'GitUserName' {

        It 'returns git user name when available' {
            InModuleScope 'Anvil' {
                Mock Resolve-AuthorName { 'GitUser' }
                $Result = Resolve-DefaultFrom -ResolverName 'GitUserName'
                $Result | Should -Be 'GitUser'
            }
        }

        It 'returns null when git user name is not configured' {
            InModuleScope 'Anvil' {
                Mock Resolve-AuthorName { $null }
                $Result = Resolve-DefaultFrom -ResolverName 'GitUserName'
                $Result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'CurrentDirectory' {

        It 'returns the current working directory' {
            InModuleScope 'Anvil' {
                $Result = Resolve-DefaultFrom -ResolverName 'CurrentDirectory'
                $Result | Should -Be $PWD.Path
            }
        }
    }

    Context 'unknown resolver' {

        It 'returns null for an unrecognized resolver name' {
            InModuleScope 'Anvil' {
                $Result = Resolve-DefaultFrom -ResolverName 'Nonexistent'
                $Result | Should -BeNullOrEmpty
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Resolve-DefaultFrom'
    }
}
