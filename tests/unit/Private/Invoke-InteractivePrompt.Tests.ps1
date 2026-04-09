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

Describe 'Invoke-InteractivePrompt' -Tag 'Unit' {

    Context 'All values pre-bound' {
        It 'returns bound values without prompting' {
            InModuleScope 'Anvil' {
                Mock Read-Host { throw 'Read-Host should not be called' }
                Mock Write-Host {}
                Mock Get-Command { $null } -ParameterFilter { $Name -eq 'git' }

                $Params = @{
                    Name                  = 'TestMod'
                    DestinationPath       = 'C:\temp'
                    Author                = 'Tester'
                    Description           = 'A test module'
                    CompanyName           = 'TestCo'
                    MinPowerShellVersion  = '7.2'
                    CompatiblePSEditions  = @('Core')
                    CIProvider            = 'GitHub'
                    License               = 'MIT'
                    CoverageThreshold     = 90
                    IncludeDocs           = $true
                    Tags                  = @('Test')
                    ProjectUri            = 'https://example.com'
                    LicenseUri            = 'https://example.com/license'
                    GitInit               = $false
                    Force                 = $false
                    PassThru              = $true
                }

                $Result = Invoke-InteractivePrompt -BoundParams $Params
                $Result.Name | Should -Be 'TestMod'
                $Result.Author | Should -Be 'Tester'
                $Result.CIProvider | Should -Be 'GitHub'
                $Result.PassThru | Should -BeTrue
                $Result.GitInit | Should -BeFalse
                Should -Invoke Read-Host -Times 0 -Exactly
            }
        }
    }

    Context 'No values pre-bound' {
        It 'prompts for all values and returns a complete hashtable' {
            InModuleScope 'Anvil' {
                $Script:PromptResponses = @{
                    '  Module name'                                    = 'PromptMod'
                    '  Destination path [.]'                           = ''
                    '  Author [GitUser]'                               = ''
                    '  Description [A PowerShell module scaffolded by Anvil.]' = ''
                    '  Company name []'                                = ''
                    '  Minimum PowerShell version [5.1]'               = ''
                    '  Compatible PS editions (Desktop,Core / Core) [Desktop,Core]' = ''
                    '  CI provider (GitHub, AzurePipelines, GitLab, None) [GitHub]' = ''
                    '  License (MIT, Apache2, None) [MIT]'             = ''
                    '  Code coverage threshold (0-100) [80]'           = ''
                    '  Include PlatyPS docs generation? (y/n) [n]'     = ''
                    '  Tags (comma-separated) []'                      = ''
                    '  Project URI []'                                 = ''
                    '  License URI []'                                 = ''
                    '  Initialize git repository? (y/n) [y]'           = ''
                }
                Mock Read-Host { param($Prompt) return 'PromptMod' }
                Mock Write-Host {}
                Mock Get-Command { $null } -ParameterFilter { $Name -eq 'git' }

                # Read-PromptValue and Read-PromptChoice call Read-Host internally.
                # Mock the leaf helpers to avoid prompt-string sensitivity.
                Mock Read-PromptValue { param($Prompt, $Default, [switch]$Required)
                    if ($Required -and -not $Default) { return 'PromptMod' }
                    return $Default
                }
                Mock Read-PromptChoice { param($Prompt, $Choices, $Default) return $Default }

                $Result = Invoke-InteractivePrompt -BoundParams @{}

                $Result.Name | Should -Be 'PromptMod'
                $Result.CIProvider | Should -Be 'GitHub'
                $Result.License | Should -Be 'MIT'
                $Result.CoverageThreshold | Should -Be 80
                $Result.Force | Should -BeFalse
                $Result.PassThru | Should -BeFalse
            }
        }
    }

    Context 'Partial values pre-bound' {
        It 'prompts only for missing values' {
            InModuleScope 'Anvil' {
                Mock Write-Host {}
                Mock Get-Command { $null } -ParameterFilter { $Name -eq 'git' }
                Mock Read-PromptValue { param($Prompt, $Default, [switch]$Required)
                    if ($Required -and -not $Default) { return 'Prompted' }
                    return $Default
                }
                Mock Read-PromptChoice { param($Prompt, $Choices, $Default) return $Default }

                $Params = @{
                    Name   = 'PreBound'
                    Author = 'KnownAuthor'
                }

                $Result = Invoke-InteractivePrompt -BoundParams $Params
                $Result.Name | Should -Be 'PreBound'
                $Result.Author | Should -Be 'KnownAuthor'
                $Result.CIProvider | Should -Be 'GitHub'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Invoke-InteractivePrompt'
    }
}
