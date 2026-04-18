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

    $script:TestManifest = @{
        Name        = 'Test'
        Description = 'Test'
        Version     = '1.0.0'
        Parameters  = @(
            @{ Name = 'Name'; Type = 'string'; Required = $true; Prompt = 'Name'
               Validate = '^[A-Za-z][A-Za-z0-9._\-]{0,127}$'
               ValidateMessage = 'Must start with a letter.' }
            @{ Name = 'Author'; Type = 'string'; Required = $true; Prompt = 'Author' }
            @{ Name = 'Description'; Type = 'string'; Prompt = 'Description' }
            @{ Name = 'License'; Type = 'choice'; Prompt = 'License'; Choices = @('MIT','Apache2','None'); Default = 'MIT' }
            @{ Name = 'Coverage'; Type = 'int'; Prompt = 'Coverage'; Range = @(0, 100); Default = 80 }
            @{ Name = 'ProjectUri'; Type = 'uri'; Prompt = 'URI'; Default = '' }
        )
    }
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'Assert-ManifestConfiguration' -Tag 'Unit' {

    Context 'valid configuration' {

        It 'accepts a valid configuration' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{
                    Name  = 'ValidModule'
                    Author      = 'Jane'
                    Description = 'A module'
                    License     = 'MIT'
                    Coverage    = 80
                    ProjectUri  = 'https://example.com'
                }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } | Should -Not -Throw
            }
        }

        It 'accepts empty optional values' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{
                    Name  = 'ValidModule'
                    Author      = 'Jane'
                    Description = ''
                    License     = 'MIT'
                    Coverage    = 80
                    ProjectUri  = ''
                }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } | Should -Not -Throw
            }
        }
    }

    Context 'required validation' {

        It 'rejects missing required value' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{ Name = ''; Author = 'Jane'; License = 'MIT'; Coverage = 80 }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } |
                    Should -Throw "*'Name' is required*"
            }
        }
    }

    Context 'regex validation' {

        It 'rejects value that fails regex with custom message' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{ Name = '123bad'; Author = 'Jane'; License = 'MIT'; Coverage = 80 }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } |
                    Should -Throw '*Must start with a letter*'
            }
        }

        It 'uses generic message when no ValidateMessage is set' {
            InModuleScope 'Anvil' {
                $Manifest = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(
                        @{ Name = 'Field'; Type = 'string'; Prompt = 'F'; Validate = '^\d+$' }
                    )
                }
                $Config = @{ Field = 'notdigits' }
                { Assert-ManifestConfiguration -Manifest $Manifest -Configuration $Config } |
                    Should -Throw "*does not match required format*"
            }
        }
    }

    Context 'choice validation' {

        It 'rejects value not in choices' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{ Name = 'Mod'; Author = 'Jane'; License = 'GPL'; Coverage = 80 }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } |
                    Should -Throw "*'License' must be one of*"
            }
        }
    }

    Context 'range validation' {

        It 'rejects value above maximum' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{ Name = 'Mod'; Author = 'Jane'; License = 'MIT'; Coverage = 200 }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } |
                    Should -Throw "*'Coverage' must be between 0 and 100*"
            }
        }

        It 'rejects value below minimum' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{ Name = 'Mod'; Author = 'Jane'; License = 'MIT'; Coverage = -5 }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } |
                    Should -Throw "*'Coverage' must be between 0 and 100*"
            }
        }
    }

    Context 'URI validation' {

        It 'rejects invalid URI' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{ Name = 'Mod'; Author = 'Jane'; License = 'MIT'; Coverage = 80; ProjectUri = 'not-a-uri' }
                { Assert-ManifestConfiguration -Manifest $M -Configuration $Config } |
                    Should -Throw "*'ProjectUri' must be a valid absolute URI*"
            }
        }
    }

    Context 'error aggregation' {

        It 'reports multiple errors in a single throw' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Config = @{ Name = ''; Author = ''; License = 'GPL'; Coverage = 200 }
                try {
                    Assert-ManifestConfiguration -Manifest $M -Configuration $Config
                } catch {
                    $_.Exception.Message | Should -Match "'Name' is required"
                    $_.Exception.Message | Should -Match "'Author' is required"
                    $_.Exception.Message | Should -Match "'License' must be one of"
                    $_.Exception.Message | Should -Match "'Coverage' must be between"
                    return
                }
                throw 'Expected Assert-ManifestConfiguration to throw'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Assert-ManifestConfiguration'
    }
}
