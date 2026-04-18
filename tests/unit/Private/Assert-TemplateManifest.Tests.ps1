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

Describe 'Assert-TemplateManifest' -Tag 'Unit' {

    BeforeAll {
        $script:MinimalValid = @{
            Name        = 'TestTemplate'
            Description = 'A test template'
            Version     = '1.0.0'
            Parameters  = @(
                @{ Name = 'Name'; Type = 'string'; Prompt = 'Module name' }
            )
        }
    }

    Context 'valid manifests' {

        It 'accepts a minimal valid manifest' {
            InModuleScope 'Anvil' -Parameters @{ M = $script:MinimalValid } {
                param($M)
                { Assert-TemplateManifest -Manifest $M } | Should -Not -Throw
            }
        }

        It 'accepts a full manifest with all optional keys' {
            InModuleScope 'Anvil' {
                $Full = @{
                    Name        = 'Module'
                    Description = 'Full template'
                    Version     = '2.0.0'
                    Parameters  = @(
                        @{ Name = 'Name'; Type = 'string'; Required = $true; Prompt = 'Name'
                           Validate = '^\w+$'; ValidateMessage = 'Alpha only'; Format = 'raw' }
                        @{ Name = 'License'; Type = 'choice'; Prompt = 'License'; Choices = @('MIT','None') }
                        @{ Name = 'Coverage'; Type = 'int'; Prompt = 'Coverage'; Range = @(0, 100) }
                        @{ Name = 'Docs'; Type = 'bool'; Prompt = 'Include docs?'; Format = 'lower-string' }
                        @{ Name = 'Tags'; Type = 'csv'; Prompt = 'Tags'; Format = 'psd1-array' }
                        @{ Name = 'Uri'; Type = 'uri'; Prompt = 'Project URI' }
                        @{ Name = 'Author'; Type = 'string'; Prompt = 'Author'; DefaultFrom = 'GitUserName' }
                    )
                    AutoTokens = @(
                        @{ Name = 'ModuleGuid'; Source = 'NewGuid' }
                        @{ Name = 'Year'; Source = 'CurrentYear' }
                    )
                    IncludeWhen = @{ 'docs/*' = @{ Docs = 'true' } }
                    ExcludeWhen = @{ 'LICENSE.tmpl' = @{ License = 'None' } }
                    Sections = @{
                        DocsTask = @{ IncludeWhen = @{ Docs = 'true' } }
                    }
                    Layers = @(
                        @{ PathKey = 'CIProvider'; BasePath = 'CI'; Skip = 'None' }
                    )
                }
                { Assert-TemplateManifest -Manifest $Full } | Should -Not -Throw
            }
        }
    }

    Context 'missing required top-level keys' {

        It 'rejects manifest missing Name' {
            InModuleScope 'Anvil' {
                $M = @{
                    Description = 'Test'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*'Name' is required*"
            }
        }

        It 'rejects manifest missing Parameters' {
            InModuleScope 'Anvil' {
                $M = @{ Name = 'T'; Description = 'T'; Version = '1.0.0' }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*'Parameters' is required*"
            }
        }

        It 'rejects manifest with empty Parameters' {
            InModuleScope 'Anvil' {
                $M = @{ Name = 'T'; Description = 'T'; Version = '1.0.0'; Parameters = @() }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*'Parameters' is required*"
            }
        }
    }

    Context 'parameter validation' {

        It 'rejects parameter with unknown Type' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'number'; Prompt = 'X' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*Type 'number' is not valid*"
            }
        }

        It 'rejects choice parameter missing Choices' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'choice'; Prompt = 'X' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*'Choices' is required for choice type*"
            }
        }

        It 'rejects parameter with invalid Range' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'int'; Prompt = 'X'; Range = @(100, 0) })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*Range minimum*must not exceed*"
            }
        }

        It 'rejects parameter with unknown Format' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X'; Format = 'xml-array' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*Format 'xml-array' is not valid*"
            }
        }

        It 'rejects parameter with unknown DefaultFrom' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X'; DefaultFrom = 'MagicValue' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*DefaultFrom 'MagicValue' is not valid*"
            }
        }

        It 'rejects parameter with invalid Validate regex' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X'; Validate = '[invalid' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*not a valid regex*"
            }
        }

        It 'rejects duplicate parameter names' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(
                        @{ Name = 'Dup'; Type = 'string'; Prompt = 'First' }
                        @{ Name = 'Dup'; Type = 'string'; Prompt = 'Second' }
                    )
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*duplicate name 'Dup'*"
            }
        }

        It 'rejects parameter missing Prompt' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*'Prompt' is required*"
            }
        }
    }

    Context 'auto-token validation' {

        It 'rejects auto-token with unknown Source' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X' })
                    AutoTokens = @(@{ Name = 'Magic'; Source = 'Imaginary' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*Source 'Imaginary' is not valid*"
            }
        }

        It 'rejects auto-token name that duplicates a parameter name' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'Year'; Type = 'string'; Prompt = 'Year' })
                    AutoTokens = @(@{ Name = 'Year'; Source = 'CurrentYear' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*duplicate name 'Year'*"
            }
        }
    }

    Context 'section validation' {

        It 'rejects section with neither IncludeWhen nor ExcludeWhen' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X' })
                    Sections = @{ Bad = @{ SomethingElse = @{ X = 'y' } } }
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*must have either 'IncludeWhen' or 'ExcludeWhen'*"
            }
        }

        It 'rejects section with both IncludeWhen and ExcludeWhen' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X' })
                    Sections = @{
                        Bad = @{
                            IncludeWhen = @{ X = 'a' }
                            ExcludeWhen = @{ X = 'b' }
                        }
                    }
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*must have only one of*"
            }
        }
    }

    Context 'layer validation' {

        It 'rejects layer missing PathKey' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X' })
                    Layers = @(@{ BasePath = 'CI' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*'PathKey' is required*"
            }
        }

        It 'rejects layer missing BasePath' {
            InModuleScope 'Anvil' {
                $M = @{
                    Name = 'T'; Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Name = 'X'; Type = 'string'; Prompt = 'X' })
                    Layers = @(@{ PathKey = 'CI' })
                }
                { Assert-TemplateManifest -Manifest $M } | Should -Throw "*'BasePath' is required*"
            }
        }
    }

    Context 'error aggregation' {

        It 'reports multiple errors in a single throw' {
            InModuleScope 'Anvil' {
                $M = @{
                    Description = 'T'; Version = '1.0.0'
                    Parameters = @(@{ Type = 'string'; Prompt = 'X' })
                }
                try {
                    Assert-TemplateManifest -Manifest $M
                } catch {
                    $_.Exception.Message | Should -Match "'Name' is required"
                    $_.Exception.Message | Should -Match "Parameters\[0\].*'Name' is required"
                    return
                }
                throw 'Expected Assert-TemplateManifest to throw'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Assert-TemplateManifest'
    }
}
