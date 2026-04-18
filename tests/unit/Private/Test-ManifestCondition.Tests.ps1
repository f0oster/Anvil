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

Describe 'Test-ManifestCondition' -Tag 'Unit' {

    Context 'single key exact match' {

        It 'returns true when token matches the condition value' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{ License = 'MIT' } -Tokens @{ License = 'MIT' }
                $Result | Should -BeTrue
            }
        }

        It 'returns false when token does not match' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{ License = 'MIT' } -Tokens @{ License = 'Apache2' }
                $Result | Should -BeFalse
            }
        }
    }

    Context 'set membership (array of allowed values)' {

        It 'returns true when token matches one of the allowed values' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{ License = 'MIT', 'Apache2' } -Tokens @{ License = 'Apache2' }
                $Result | Should -BeTrue
            }
        }

        It 'returns false when token matches none of the allowed values' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{ License = 'MIT', 'Apache2' } -Tokens @{ License = 'None' }
                $Result | Should -BeFalse
            }
        }
    }

    Context 'multi-key AND logic' {

        It 'returns true when all keys match' {
            InModuleScope 'Anvil' {
                $Condition = @{ IncludeDocs = 'true'; CIProvider = 'GitHub' }
                $Tokens = @{ IncludeDocs = 'true'; CIProvider = 'GitHub'; License = 'MIT' }
                $Result = Test-ManifestCondition -Condition $Condition -Tokens $Tokens
                $Result | Should -BeTrue
            }
        }

        It 'returns false when one key does not match' {
            InModuleScope 'Anvil' {
                $Condition = @{ IncludeDocs = 'true'; CIProvider = 'GitHub' }
                $Tokens = @{ IncludeDocs = 'true'; CIProvider = 'GitLab' }
                $Result = Test-ManifestCondition -Condition $Condition -Tokens $Tokens
                $Result | Should -BeFalse
            }
        }
    }

    Context 'missing token key' {

        It 'returns false when the token key does not exist' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{ License = 'MIT' } -Tokens @{ Author = 'Jane' }
                $Result | Should -BeFalse
            }
        }
    }

    Context 'empty condition' {

        It 'returns true when condition is empty' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{} -Tokens @{ License = 'MIT' }
                $Result | Should -BeTrue
            }
        }
    }

    Context 'empty string matching' {

        It 'returns true when condition expects empty string and token is empty' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{ ProjectUri = '' } -Tokens @{ ProjectUri = '' }
                $Result | Should -BeTrue
            }
        }

        It 'returns false when condition expects empty string and token has a value' {
            InModuleScope 'Anvil' {
                $Result = Test-ManifestCondition -Condition @{ ProjectUri = '' } -Tokens @{ ProjectUri = 'https://example.com' }
                $Result | Should -BeFalse
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Test-ManifestCondition'
    }
}
