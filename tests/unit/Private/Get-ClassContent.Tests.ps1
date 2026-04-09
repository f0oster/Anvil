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

Describe 'Get-ClassContent' -Tag 'Unit' {

    It 'includes the class name in the declaration' {
        InModuleScope 'Anvil' {
            $Result = Get-ClassContent -ClassName 'MyWidget'
            $Result | Should -Match 'class MyWidget'
        }
    }

    It 'includes a default constructor' {
        InModuleScope 'Anvil' {
            $Result = Get-ClassContent -ClassName 'MyWidget'
            $Result | Should -Match 'MyWidget\(\)'
        }
    }

    It 'includes a parameterized constructor' {
        InModuleScope 'Anvil' {
            $Result = Get-ClassContent -ClassName 'MyWidget'
            $Result | Should -Match 'MyWidget\(\[string\]'
        }
    }

    It 'includes a ToString method' {
        InModuleScope 'Anvil' {
            $Result = Get-ClassContent -ClassName 'MyWidget'
            $Result | Should -Match 'ToString\(\)'
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Get-ClassContent'
    }
}
