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

    It 'replaces path tokens in a path segment' {
        InModuleScope 'Anvil' {
            $Result = Resolve-PathTokens -RelativePath 'src/__Name__/Public' -Tokens @{ Name = 'Foo' }
            $Result | Should -Be 'src/Foo/Public'
        }
    }

    It 'replaces multiple different tokens' {
        InModuleScope 'Anvil' {
            $Result = Resolve-PathTokens -RelativePath '__Author__/__Name__' -Tokens @{
                Author = 'Jane'
                Name   = 'Bar'
            }
            $Result | Should -Be 'Jane/Bar'
        }
    }

    It 'leaves paths without tokens unchanged' {
        InModuleScope 'Anvil' {
            $Result = Resolve-PathTokens -RelativePath 'build/bootstrap.ps1' -Tokens @{ Name = 'X' }
            $Result | Should -Be 'build/bootstrap.ps1'
        }
    }
}
