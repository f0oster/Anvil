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

Describe 'Read-PromptValue' -Tag 'Unit' {

    Context 'User provides input' {
        It 'returns the user input' {
            InModuleScope 'Anvil' {
                Mock Read-Host { return 'MyValue' }
                $Result = Read-PromptValue -Prompt 'Enter value'
                $Result | Should -Be 'MyValue'
            }
        }
    }

    Context 'User provides empty input with a default' {
        It 'returns the default value' {
            InModuleScope 'Anvil' {
                Mock Read-Host { return '' }
                $Result = Read-PromptValue -Prompt 'Enter value' -Default 'Fallback'
                $Result | Should -Be 'Fallback'
            }
        }
    }

    Context 'Required field' {
        It 'returns the value once provided' {
            InModuleScope 'Anvil' {
                $Script:CallCount = 0
                Mock Read-Host {
                    $Script:CallCount++
                    if ($Script:CallCount -eq 1) { return '' }
                    return 'Finally'
                }
                Mock Write-Host {}
                $Result = Read-PromptValue -Prompt 'Enter value' -Required
                $Result | Should -Be 'Finally'
                Should -Invoke Read-Host -Times 2 -Exactly
            }
        }
    }

    Context 'Required field with default' {
        It 'returns the default when input is empty' {
            InModuleScope 'Anvil' {
                Mock Read-Host { return '' }
                $Result = Read-PromptValue -Prompt 'Enter value' -Default 'Safe' -Required
                $Result | Should -Be 'Safe'
                Should -Invoke Read-Host -Times 1 -Exactly
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Read-PromptValue'
    }
}
