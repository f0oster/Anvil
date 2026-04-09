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

Describe 'Resolve-ContentTokens' -Tag 'Unit' {

    It 'replaces content token placeholders' {
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
