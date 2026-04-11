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

Describe 'Read-RequirementsFile' -Tag 'Unit' {

    It 'returns empty hashtable for nonexistent file' {
        InModuleScope 'Anvil' {
            $Result = Read-RequirementsFile -Path 'TestDrive:/does-not-exist.psd1'
            $Result | Should -BeOfType [hashtable]
            $Result.Count | Should -Be 0
        }
    }

    It 'reads a valid requirements file correctly' {
        InModuleScope 'Anvil' {
            $TempFile = Join-Path $TestDrive 'requirements.psd1'
            Set-Content -Path $TempFile -Value "@{`n    'Pester' = '>=5.0.0'`n    'PSScriptAnalyzer' = 'latest'`n}"

            $Result = Read-RequirementsFile -Path $TempFile
            $Result | Should -BeOfType [hashtable]
            $Result['Pester'] | Should -Be '>=5.0.0'
            $Result['PSScriptAnalyzer'] | Should -Be 'latest'
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Read-RequirementsFile'
    }
}
