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
        Description = 'Test template'
        Version     = '1.0.0'
        Parameters  = @(
            @{ Name = 'Name'; Type = 'string'; Required = $true; Prompt = 'Module name' }
            @{ Name = 'Author'; Type = 'string'; Required = $true; Prompt = 'Author'; DefaultFrom = 'GitUserName' }
            @{ Name = 'Description'; Type = 'string'; Prompt = 'Description'; Default = 'Default desc' }
            @{ Name = 'License'; Type = 'choice'; Prompt = 'License'; Choices = @('MIT','Apache2','None'); Default = 'MIT' }
            @{ Name = 'Coverage'; Type = 'int'; Prompt = 'Coverage'; Default = 80; Range = @(0, 100) }
            @{ Name = 'IncludeDocs'; Type = 'bool'; Prompt = 'Include docs?'; Default = $false; Format = 'lower-string' }
            @{ Name = 'Tags'; Type = 'csv'; Prompt = 'Tags'; Default = ''; Format = 'psd1-array' }
            @{ Name = 'ProjectUri'; Type = 'uri'; Prompt = 'Project URI'; Default = '' }
        )
    }
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'Invoke-ManifestPrompt' -Tag 'Unit' {

    Context 'all values pre-bound' {

        It 'returns bound values without prompting' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                Mock Read-Host { throw 'should not be called' }
                $Bound = @{
                    Name  = 'TestMod'
                    Author      = 'Jane'
                    Description = 'Custom'
                    License     = 'Apache2'
                    Coverage    = 90
                    IncludeDocs = $true
                    Tags        = @('A', 'B')
                    ProjectUri  = 'https://example.com'
                }
                $Result = Invoke-ManifestPrompt -Manifest $M -BoundParams $Bound
                $Result.Name | Should -Be 'TestMod'
                $Result.Author | Should -Be 'Jane'
                $Result.License | Should -Be 'Apache2'
                $Result.Coverage | Should -Be 90
                $Result.IncludeDocs | Should -BeTrue
                Should -Not -Invoke Read-Host
            }
        }
    }

    Context 'non-interactive with defaults' {

        It 'fills optional values from defaults silently' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                Mock Resolve-AuthorName { 'GitUser' }
                $Bound = @{ Name = 'TestMod' }
                $Result = Invoke-ManifestPrompt -Manifest $M -BoundParams $Bound -Interactive $false
                $Result.Name | Should -Be 'TestMod'
                $Result.Author | Should -Be 'GitUser'
                $Result.Description | Should -Be 'Default desc'
                $Result.License | Should -Be 'MIT'
                $Result.Coverage | Should -Be 80
                $Result.IncludeDocs | Should -BeFalse
            }
        }

        It 'throws when required value is missing and no default' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                Mock Resolve-AuthorName { $null }
                $Bound = @{}
                { Invoke-ManifestPrompt -Manifest $M -BoundParams $Bound -Interactive $false } |
                    Should -Throw "*'Name' is required*"
            }
        }
    }

    Context 'interactive mode' {

        It 'prompts for missing values by type' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Script:PromptCount = 0
                Mock Read-Host {
                    $Script:PromptCount++
                    switch ($Script:PromptCount) {
                        1 { 'MyModule' }       # Name (string)
                        2 { 'John' }           # Author (string)
                        3 { '' }               # Description (default)
                        4 { '' }               # License (default)
                        5 { '' }               # Coverage (default)
                        6 { '' }               # IncludeDocs (default n)
                        7 { '' }               # Tags (default empty)
                        8 { '' }               # ProjectUri (default empty)
                    }
                }
                Mock Write-Host {}

                $Result = Invoke-ManifestPrompt -Manifest $M -BoundParams @{} -Interactive $true
                $Result.Name | Should -Be 'MyModule'
                $Result.Author | Should -Be 'John'
                $Result.Description | Should -Be 'Default desc'
                $Result.License | Should -Be 'MIT'
                $Result.Coverage | Should -Be 80
                $Result.IncludeDocs | Should -BeFalse
            }
        }

        It 'skips bound parameters' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Script:PromptCount = 0
                Mock Read-Host {
                    $Script:PromptCount++
                    switch ($Script:PromptCount) {
                        1 { 'Jane' }   # Author
                        2 { '' }       # Description
                        3 { '' }       # License
                        4 { '' }       # Coverage
                        5 { '' }       # IncludeDocs
                        6 { '' }       # Tags
                        7 { '' }       # ProjectUri
                    }
                }
                Mock Write-Host {}

                $Bound = @{ Name = 'PreBound' }
                $Result = Invoke-ManifestPrompt -Manifest $M -BoundParams $Bound -Interactive $true
                $Result.Name | Should -Be 'PreBound'
                $Result.Author | Should -Be 'Jane'
            }
        }
    }

    Context 'csv type handling' {

        It 'splits comma-separated input into array' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                $Bound = @{
                    Name  = 'M'
                    Author      = 'A'
                    Description = 'D'
                    License     = 'MIT'
                    Coverage    = 80
                    IncludeDocs = $false
                    Tags        = 'PowerShell, Module, Tools'
                    ProjectUri  = ''
                }
                $Result = Invoke-ManifestPrompt -Manifest $M -BoundParams $Bound
                $Result.Tags | Should -HaveCount 3
                $Result.Tags[0] | Should -Be 'PowerShell'
                $Result.Tags[2] | Should -Be 'Tools'
            }
        }

        It 'returns empty array for empty csv default' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                Mock Resolve-AuthorName { 'Git' }
                $Result = Invoke-ManifestPrompt -Manifest $M -BoundParams @{ Name = 'M' }
                $Result.Tags | Should -HaveCount 0
            }
        }
    }

    Context 'DefaultFrom resolvers' {

        It 'uses GitUserName resolver for Author default' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:TestManifest } {
                param($M)
                Mock Resolve-AuthorName { 'GitConfigUser' }
                $Result = Invoke-ManifestPrompt -Manifest $M -BoundParams @{ Name = 'M' }
                $Result.Author | Should -Be 'GitConfigUser'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Invoke-ManifestPrompt'
    }
}
