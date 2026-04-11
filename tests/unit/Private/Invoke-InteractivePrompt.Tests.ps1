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

    BeforeAll {
        $script:TestDefaults = @{
            Description          = 'A PowerShell module scaffolded by Anvil.'
            CompanyName          = ''
            MinPowerShellVersion = '5.1'
            CompatiblePSEditions = @('Desktop', 'Core')
            CIProvider           = 'GitHub'
            License              = 'MIT'
            CoverageThreshold    = 80
            IncludeDocs          = $false
            Tags                 = @()
            ProjectUri           = ''
            LicenseUri           = ''
            GitInit              = $false
        }
    }

    Context 'All values pre-bound' {
        It 'returns bound values without prompting' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Read-Host { throw 'Read-Host should not be called' }
                Mock Write-Host {}
                Mock Resolve-AuthorName { $null }

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

                $Result = Invoke-InteractivePrompt -BoundParams $Params -Defaults $Defaults -Interactive $true
                $Result.Name | Should -Be 'TestMod'
                $Result.Author | Should -Be 'Tester'
                $Result.CIProvider | Should -Be 'GitHub'
                $Result.PassThru | Should -BeTrue
                $Result.GitInit | Should -BeFalse
                Should -Invoke Read-Host -Times 0 -Exactly
            }
        }
    }

    Context 'Interactive mode — no values pre-bound' {
        It 'prompts for all values and returns a complete hashtable' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Write-Host {}
                Mock Resolve-AuthorName { $null }
                Mock Read-PromptValue { param($Prompt, $Default, [switch]$Required)
                    if ($Required -and -not $Default) { return 'PromptMod' }
                    return $Default
                }
                Mock Read-PromptChoice { param($Prompt, $Choices, $Default) return $Default }

                $Result = Invoke-InteractivePrompt -BoundParams @{} -Defaults $Defaults -Interactive $true

                $Result.Name | Should -Be 'PromptMod'
                $Result.CIProvider | Should -Be 'GitHub'
                $Result.License | Should -Be 'MIT'
                $Result.CoverageThreshold | Should -Be 80
                $Result.Force | Should -BeFalse
                $Result.PassThru | Should -BeFalse
            }
        }
    }

    Context 'Interactive mode — partial values pre-bound' {
        It 'prompts only for missing values' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Write-Host {}
                Mock Resolve-AuthorName { $null }
                Mock Read-PromptValue { param($Prompt, $Default, [switch]$Required)
                    if ($Required -and -not $Default) { return 'Prompted' }
                    return $Default
                }
                Mock Read-PromptChoice { param($Prompt, $Choices, $Default) return $Default }

                $Params = @{
                    Name   = 'PreBound'
                    Author = 'KnownAuthor'
                }

                $Result = Invoke-InteractivePrompt -BoundParams $Params -Defaults $Defaults -Interactive $true
                $Result.Name | Should -Be 'PreBound'
                $Result.Author | Should -Be 'KnownAuthor'
                $Result.CIProvider | Should -Be 'GitHub'
            }
        }
    }

    Context 'Non-interactive mode' {
        It 'fills optional values from Defaults silently' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Write-Host {}
                Mock Read-Host { throw 'Read-Host should not be called' }
                Mock Resolve-AuthorName { $null }

                $Params = @{
                    Name            = 'CIMod'
                    DestinationPath = 'C:\temp'
                    Author          = 'CI'
                }

                $Result = Invoke-InteractivePrompt -BoundParams $Params -Defaults $Defaults
                $Result.Description | Should -Be 'A PowerShell module scaffolded by Anvil.'
                $Result.MinPowerShellVersion | Should -Be '5.1'
                $Result.CompatiblePSEditions | Should -Be @('Desktop', 'Core')
                $Result.CIProvider | Should -Be 'GitHub'
                $Result.License | Should -Be 'MIT'
                $Result.CoverageThreshold | Should -Be 80
                $Result.IncludeDocs | Should -BeFalse
                $Result.Tags | Should -Be @()
                $Result.GitInit | Should -BeFalse
                Should -Invoke Read-Host -Times 0 -Exactly
            }
        }

        It 'throws when Name is missing' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Resolve-AuthorName { $null }

                { Invoke-InteractivePrompt -BoundParams @{} -Defaults $Defaults } |
                    Should -Throw "*'Name'*required*"
            }
        }

        It 'throws when DestinationPath is missing' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Resolve-AuthorName { $null }

                $Params = @{ Name = 'Test' }
                { Invoke-InteractivePrompt -BoundParams $Params -Defaults $Defaults } |
                    Should -Throw "*'DestinationPath'*required*"
            }
        }

        It 'throws when Author is missing and git has no user.name' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Resolve-AuthorName { $null }

                $Params = @{
                    Name            = 'Test'
                    DestinationPath = 'C:\temp'
                }
                { Invoke-InteractivePrompt -BoundParams $Params -Defaults $Defaults } |
                    Should -Throw "*'Author'*required*"
            }
        }

        It 'falls back to git user.name for Author when available' {
            InModuleScope 'Anvil' -Parameters @{ Defaults = $script:TestDefaults } {
                param($Defaults)

                Mock Write-Host {}
                Mock Resolve-AuthorName { 'Git Author' }

                $Params = @{
                    Name            = 'Test'
                    DestinationPath = 'C:\temp'
                }
                $Result = Invoke-InteractivePrompt -BoundParams $Params -Defaults $Defaults
                $Result.Author | Should -Be 'Git Author'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Invoke-InteractivePrompt'
    }
}
