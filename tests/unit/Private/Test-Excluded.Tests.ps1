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
