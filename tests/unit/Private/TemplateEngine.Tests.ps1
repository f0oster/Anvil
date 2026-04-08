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

Describe 'Resolve-PathTokens' -Tag 'Unit' {

    It 'replaces __ModuleName__ in a path segment' {
        InModuleScope 'Anvil' {
            $Result = Resolve-PathTokens -RelativePath 'src/__ModuleName__/Public' -Tokens @{ ModuleName = 'Foo' }
            $Result | Should -Be 'src/Foo/Public'
        }
    }

    It 'replaces multiple different tokens' {
        InModuleScope 'Anvil' {
            $Result = Resolve-PathTokens -RelativePath '__Author__/__ModuleName__' -Tokens @{
                Author     = 'Jane'
                ModuleName = 'Bar'
            }
            $Result | Should -Be 'Jane/Bar'
        }
    }

    It 'leaves paths without tokens unchanged' {
        InModuleScope 'Anvil' {
            $Result = Resolve-PathTokens -RelativePath 'build/bootstrap.ps1' -Tokens @{ ModuleName = 'X' }
            $Result | Should -Be 'build/bootstrap.ps1'
        }
    }
}

Describe 'Resolve-ContentTokens' -Tag 'Unit' {

    It 'replaces <%ModuleName%> in content' {
        InModuleScope 'Anvil' {
            $Result = Resolve-ContentTokens -Content 'Module = <%ModuleName%>' -Tokens @{ ModuleName = 'Baz' }
            $Result | Should -Be 'Module = Baz'
        }
    }

    It 'replaces multiple tokens in a single string' {
        InModuleScope 'Anvil' {
            $Result = Resolve-ContentTokens -Content '<%Author%> wrote <%ModuleName%>' -Tokens @{
                Author     = 'Alice'
                ModuleName = 'CoolMod'
            }
            $Result | Should -Be 'Alice wrote CoolMod'
        }
    }

    It 'handles content with no tokens' {
        InModuleScope 'Anvil' {
            $Result = Resolve-ContentTokens -Content 'No tokens here' -Tokens @{ ModuleName = 'X' }
            $Result | Should -Be 'No tokens here'
        }
    }
}

Describe 'Test-Excluded' -Tag 'Unit' {

    It 'returns true for matching wildcard pattern' {
        InModuleScope 'Anvil' {
            $Result = Test-Excluded -RelativePath 'docs/README.md' -Patterns @('docs/*')
            $Result | Should -BeTrue
        }
    }

    It 'returns false for non-matching paths' {
        InModuleScope 'Anvil' {
            $Result = Test-Excluded -RelativePath 'src/Module.psm1' -Patterns @('docs/*')
            $Result | Should -BeFalse
        }
    }

    It 'returns false with empty patterns' {
        InModuleScope 'Anvil' {
            $Result = Test-Excluded -RelativePath 'anything' -Patterns @()
            $Result | Should -BeFalse
        }
    }
}
