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

Describe 'Copy-CITemplates' -Tag 'Unit' {

    It 'returns a file count for a valid provider' {
        $DestDir = Join-Path $TestDrive 'ci-test'
        $Tokens = @{ ModuleName = 'TestMod' }
        $Count = InModuleScope 'Anvil' -ArgumentList $DestDir, $Tokens {
            param($Dst, $Tok)
            Copy-CITemplates -Provider 'GitHub' -DestinationPath $Dst -Tokens $Tok
        }
        $Count | Should -BeGreaterThan 0
    }

    It 'creates CI workflow files' {
        $DestDir = Join-Path $TestDrive 'ci-test2'
        $Tokens = @{ ModuleName = 'TestMod' }
        InModuleScope 'Anvil' -ArgumentList $DestDir, $Tokens {
            param($Dst, $Tok)
            Copy-CITemplates -Provider 'GitHub' -DestinationPath $Dst -Tokens $Tok
        }
        Join-Path $DestDir '.github/workflows' | Should -Exist
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Copy-CITemplates'
    }
}
