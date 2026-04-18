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

Describe 'Read-PromptUri' -Tag 'Unit' {

    Context 'valid absolute URI' {

        It 'returns the URI when user enters a valid absolute URI' {
            InModuleScope 'Anvil' {
                Mock Read-Host { 'https://github.com/user/repo' }
                $Result = Read-PromptUri -Prompt '  Project URI'
                $Result | Should -Be 'https://github.com/user/repo'
            }
        }
    }

    Context 'empty input with default' {

        It 'returns default when user enters nothing' {
            InModuleScope 'Anvil' {
                Mock Read-Host { '' }
                $Result = Read-PromptUri -Prompt '  Project URI' -Default 'https://example.com'
                $Result | Should -Be 'https://example.com'
            }
        }
    }

    Context 'empty input without default' {

        It 'returns empty string when user enters nothing and no default' {
            InModuleScope 'Anvil' {
                Mock Read-Host { '' }
                $Result = Read-PromptUri -Prompt '  Project URI' -Default ''
                $Result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'invalid then valid URI' {

        It 'reprompts on invalid input then returns the valid URI' {
            InModuleScope 'Anvil' {
                $Script:CallCount = 0
                Mock Read-Host {
                    $Script:CallCount++
                    if ($Script:CallCount -eq 1) { 'not-a-uri' }
                    else { 'https://github.com/user/repo' }
                }
                Mock Write-Host {}

                $Result = Read-PromptUri -Prompt '  Project URI'
                $Result | Should -Be 'https://github.com/user/repo'
                Should -Invoke Write-Host -Times 1 -ParameterFilter {
                    $Object -like '*Must be a valid absolute URI*'
                }
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Read-PromptUri'
    }
}
