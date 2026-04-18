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

Describe 'Test-FileCondition' -Tag 'Unit' {

    Context 'IncludeWhen' {

        It 'includes a file when the condition matches' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'docs/README.md'
                    IncludeWhen  = @{ 'docs/*' = @{ IncludeDocs = 'true' } }
                    Tokens       = @{ IncludeDocs = 'true' }
                }
                Test-FileCondition @Params | Should -BeTrue
            }
        }

        It 'excludes a file when the condition does not match' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'docs/README.md'
                    IncludeWhen  = @{ 'docs/*' = @{ IncludeDocs = 'true' } }
                    Tokens       = @{ IncludeDocs = 'false' }
                }
                Test-FileCondition @Params | Should -BeFalse
            }
        }
    }

    Context 'ExcludeWhen' {

        It 'excludes a file when the condition matches' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'LICENSE.tmpl'
                    ExcludeWhen  = @{ 'LICENSE.tmpl' = @{ License = 'None' } }
                    Tokens       = @{ License = 'None' }
                }
                Test-FileCondition @Params | Should -BeFalse
            }
        }

        It 'includes a file when the condition does not match' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'LICENSE.tmpl'
                    ExcludeWhen  = @{ 'LICENSE.tmpl' = @{ License = 'None' } }
                    Tokens       = @{ License = 'MIT' }
                }
                Test-FileCondition @Params | Should -BeTrue
            }
        }
    }

    Context 'no matching pattern' {

        It 'includes a file not mentioned in any condition table' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'src/Module.psm1'
                    IncludeWhen  = @{ 'docs/*' = @{ IncludeDocs = 'true' } }
                    ExcludeWhen  = @{ 'LICENSE.tmpl' = @{ License = 'None' } }
                    Tokens       = @{ IncludeDocs = 'false'; License = 'None' }
                }
                Test-FileCondition @Params | Should -BeTrue
            }
        }
    }

    Context 'wildcard path matching' {

        It 'matches nested paths with wildcard pattern' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'docs/commands/Get-Thing.md'
                    IncludeWhen  = @{ 'docs/*' = @{ IncludeDocs = 'true' } }
                    Tokens       = @{ IncludeDocs = 'true' }
                }
                Test-FileCondition @Params | Should -BeTrue
            }
        }
    }

    Context 'ExcludeWhen takes precedence' {

        It 'excludes when both tables match the same path' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'docs/README.md'
                    IncludeWhen  = @{ 'docs/*' = @{ IncludeDocs = 'true' } }
                    ExcludeWhen  = @{ 'docs/*' = @{ License = 'None' } }
                    Tokens       = @{ IncludeDocs = 'true'; License = 'None' }
                }
                Test-FileCondition @Params | Should -BeFalse
            }
        }
    }

    Context 'empty tables' {

        It 'includes everything when both tables are empty' {
            InModuleScope 'Anvil' {
                $Params = @{
                    RelativePath = 'anything.ps1'
                    IncludeWhen  = @{}
                    ExcludeWhen  = @{}
                    Tokens       = @{ License = 'MIT' }
                }
                Test-FileCondition @Params | Should -BeTrue
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Test-FileCondition'
    }
}
