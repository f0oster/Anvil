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

Describe 'Format-TokenValue' -Tag 'Unit' {

    Context 'raw formatter' {

        It 'returns string value unchanged' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value 'hello' -Formatter 'raw' | Should -Be 'hello'
            }
        }

        It 'converts integer to string' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value 80 -Formatter 'raw' | Should -Be '80'
            }
        }

        It 'returns empty string for null' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value $null -Formatter 'raw' | Should -Be ''
            }
        }
    }

    Context 'psd1-array formatter' {

        It 'formats a string array as psd1 array literal' {
            InModuleScope 'Anvil' {
                $Result = Format-TokenValue -Value @('Desktop', 'Core') -Formatter 'psd1-array'
                $Result | Should -Be "@('Desktop', 'Core')"
            }
        }

        It 'formats a single-element array' {
            InModuleScope 'Anvil' {
                $Result = Format-TokenValue -Value @('Core') -Formatter 'psd1-array'
                $Result | Should -Be "@('Core')"
            }
        }

        It 'formats an empty array as @()' {
            InModuleScope 'Anvil' {
                $Result = Format-TokenValue -Value @() -Formatter 'psd1-array'
                $Result | Should -Be '@()'
            }
        }
    }

    Context 'lower-string formatter' {

        It 'formats boolean true as lowercase string' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value $true -Formatter 'lower-string' | Should -Be 'true'
            }
        }

        It 'formats boolean false as lowercase string' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value $false -Formatter 'lower-string' | Should -Be 'false'
            }
        }

        It 'lowercases a string value' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value 'GitHub' -Formatter 'lower-string' | Should -Be 'github'
            }
        }
    }

    Context 'quoted formatter' {

        It 'wraps value in single quotes' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value 'hello' -Formatter 'quoted' | Should -Be "'hello'"
            }
        }

        It 'wraps empty string in single quotes' {
            InModuleScope 'Anvil' {
                Format-TokenValue -Value '' -Formatter 'quoted' | Should -Be "''"
            }
        }
    }

    Context 'unknown formatter' {

        It 'throws for an unrecognized formatter name' {
            InModuleScope 'Anvil' {
                { Format-TokenValue -Value 'x' -Formatter 'nonexistent' } |
                    Should -Throw "*Unknown formatter 'nonexistent'*"
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Format-TokenValue'
    }
}
