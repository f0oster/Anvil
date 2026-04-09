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

Describe 'Get-FunctionContent' -Tag 'Unit' {

    Context 'Public scope' {
        It 'includes the function name' {
            InModuleScope 'Anvil' {
                $Result = Get-FunctionContent -FunctionName 'Get-Widget' -Scope Public
                $Result | Should -Match 'function Get-Widget'
            }
        }

        It 'includes comment-based help' {
            InModuleScope 'Anvil' {
                $Result = Get-FunctionContent -FunctionName 'Get-Widget' -Scope Public
                $Result | Should -Match '\.SYNOPSIS'
                $Result | Should -Match '\.DESCRIPTION'
                $Result | Should -Match '\.EXAMPLE'
            }
        }

        It 'includes CmdletBinding' {
            InModuleScope 'Anvil' {
                $Result = Get-FunctionContent -FunctionName 'Get-Widget' -Scope Public
                $Result | Should -Match '\[CmdletBinding\(\)\]'
            }
        }
    }

    Context 'Private scope' {
        It 'includes the function name' {
            InModuleScope 'Anvil' {
                $Result = Get-FunctionContent -FunctionName 'Format-Internal' -Scope Private
                $Result | Should -Match 'function Format-Internal'
            }
        }

        It 'does not include comment-based help' {
            InModuleScope 'Anvil' {
                $Result = Get-FunctionContent -FunctionName 'Format-Internal' -Scope Private
                $Result | Should -Not -Match '\.SYNOPSIS'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Get-FunctionContent'
    }
}
