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

Describe 'Get-TestContent' -Tag 'Unit' {

    Context 'Public scope' {
        It 'includes the function name in Describe' {
            InModuleScope 'Anvil' {
                $Result = Get-TestContent -Name 'Get-Widget' -ModuleName 'TestMod' -Scope Public
                $Result | Should -Match "Describe 'Get-Widget'"
            }
        }

        It 'does not use InModuleScope' {
            InModuleScope 'Anvil' {
                $Result = Get-TestContent -Name 'Get-Widget' -ModuleName 'TestMod' -Scope Public
                $Result | Should -Not -Match 'InModuleScope'
            }
        }

        It 'imports the module in BeforeAll' {
            InModuleScope 'Anvil' {
                $Result = Get-TestContent -Name 'Get-Widget' -ModuleName 'TestMod' -Scope Public
                $Result | Should -Match 'Import-Module'
                $Result | Should -Match 'TestMod'
            }
        }
    }

    Context 'Private scope' {
        It 'uses InModuleScope' {
            InModuleScope 'Anvil' {
                $Result = Get-TestContent -Name 'Format-Row' -ModuleName 'TestMod' -Scope Private
                $Result | Should -Match "InModuleScope 'TestMod'"
            }
        }

        It 'includes an is-not-exported test' {
            InModuleScope 'Anvil' {
                $Result = Get-TestContent -Name 'Format-Row' -ModuleName 'TestMod' -Scope Private
                $Result | Should -Match 'is not exported'
                $Result | Should -Match "Should -Not -Contain 'Format-Row'"
            }
        }
    }

    Context 'PrivateClasses scope' {
        It 'uses InModuleScope for instantiation' {
            InModuleScope 'Anvil' {
                $Result = Get-TestContent -Name 'MyClass' -ModuleName 'TestMod' -Scope PrivateClasses
                $Result | Should -Match "InModuleScope 'TestMod'"
                $Result | Should -Match '\[MyClass\]::new\(\)'
            }
        }

        It 'includes an is-not-accessible test' {
            InModuleScope 'Anvil' {
                $Result = Get-TestContent -Name 'MyClass' -ModuleName 'TestMod' -Scope PrivateClasses
                $Result | Should -Match 'is not accessible outside the module'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Get-TestContent'
    }
}
