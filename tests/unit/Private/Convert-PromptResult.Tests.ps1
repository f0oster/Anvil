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

Describe 'Convert-PromptResult' -Tag 'Unit' {

    Context 'csv type' {

        It 'splits comma-separated string into array' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value 'A, B, C' -Type 'csv'
                $Result | Should -HaveCount 3
                $Result[0] | Should -Be 'A'
                $Result[2] | Should -Be 'C'
            }
        }

        It 'passes through arrays unchanged' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value @('X', 'Y') -Type 'csv'
                $Result | Should -HaveCount 2
                $Result[0] | Should -Be 'X'
            }
        }

        It 'returns empty array for empty string' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value '' -Type 'csv'
                $Result | Should -HaveCount 0
            }
        }

        It 'returns empty array for null' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value $null -Type 'csv'
                $Result | Should -HaveCount 0
            }
        }
    }

    Context 'int type' {

        It 'casts string to integer' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value '42' -Type 'int'
                $Result | Should -Be 42
                $Result | Should -BeOfType [int]
            }
        }

        It 'passes through integers unchanged' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value 80 -Type 'int'
                $Result | Should -Be 80
            }
        }
    }

    Context 'bool type' {

        It 'passes through boolean true' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value $true -Type 'bool'
                $Result | Should -BeTrue
            }
        }

        It 'passes through boolean false' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value $false -Type 'bool'
                $Result | Should -BeFalse
            }
        }

        It 'converts y to true' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value 'y' -Type 'bool'
                $Result | Should -BeTrue
            }
        }

        It 'converts n to false' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value 'n' -Type 'bool'
                $Result | Should -BeFalse
            }
        }
    }

    Context 'string type (default)' {

        It 'returns string values unchanged' {
            InModuleScope 'Anvil' {
                $Result = Convert-PromptResult -Value 'hello' -Type 'string'
                $Result | Should -Be 'hello'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Convert-PromptResult'
    }
}
