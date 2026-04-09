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

Describe 'Read-PromptChoice' -Tag 'Unit' {

    Context 'User selects a valid choice' {
        It 'returns the selected value' {
            InModuleScope 'Anvil' {
                Mock Read-Host { return 'GitHub' }
                $Result = Read-PromptChoice -Prompt 'Pick CI' -Choices @('GitHub', 'GitLab', 'None')
                $Result | Should -Be 'GitHub'
            }
        }
    }

    Context 'User provides empty input with a default' {
        It 'returns the default value' {
            InModuleScope 'Anvil' {
                Mock Read-Host { return '' }
                $Result = Read-PromptChoice -Prompt 'Pick CI' -Choices @('GitHub', 'GitLab', 'None') -Default 'GitLab'
                $Result | Should -Be 'GitLab'
            }
        }
    }

    Context 'User provides an invalid choice then a valid one' {
        It 'reprompts and returns the valid choice' {
            InModuleScope 'Anvil' {
                $Script:CallCount = 0
                Mock Read-Host {
                    $Script:CallCount++
                    if ($Script:CallCount -eq 1) { return 'BadValue' }
                    return 'MIT'
                }
                Mock Write-Host {}
                $Result = Read-PromptChoice -Prompt 'Pick license' -Choices @('MIT', 'Apache2', 'None')
                $Result | Should -Be 'MIT'
                Should -Invoke Read-Host -Times 2 -Exactly
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Read-PromptChoice'
    }
}
