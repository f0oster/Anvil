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

Describe 'Write-RequirementsFile' -Tag 'Unit' {

    It 'writes an empty hashtable' {
        InModuleScope 'Anvil' {
            $TempFile = Join-Path $TestDrive 'empty-req.psd1'
            Write-RequirementsFile -Path $TempFile -Requirements @{}

            $Content = Get-Content -Path $TempFile -Raw
            $Content | Should -Match '@\{'
            $Content | Should -Match '\}'

            $Parsed = Import-PowerShellDataFile -Path $TempFile
            $Parsed.Count | Should -Be 0
        }
    }

    It 'writes a populated hashtable and reads it back' {
        InModuleScope 'Anvil' {
            $TempFile = Join-Path $TestDrive 'populated-req.psd1'
            $Requirements = @{
                'Pester'           = '>=5.0.0'
                'PSScriptAnalyzer' = 'latest'
            }
            Write-RequirementsFile -Path $TempFile -Requirements $Requirements

            $Parsed = Import-PowerShellDataFile -Path $TempFile
            $Parsed['Pester'] | Should -Be '>=5.0.0'
            $Parsed['PSScriptAnalyzer'] | Should -Be 'latest'
        }
    }

    It 'writes keys in sorted order' {
        InModuleScope 'Anvil' {
            $TempFile = Join-Path $TestDrive 'sorted-req.psd1'
            $Requirements = @{
                'Zebra'  = 'latest'
                'Alpha'  = '1.0.0'
                'Middle' = '>=2.0.0'
            }
            Write-RequirementsFile -Path $TempFile -Requirements $Requirements

            $Lines = Get-Content -Path $TempFile | Where-Object { $_ -match "^\s+'" }
            $Keys = $Lines | ForEach-Object { if ($_ -match "'([^']+)'") { $Matches[1] } }
            $Keys | Should -Be @('Alpha', 'Middle', 'Zebra')
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Write-RequirementsFile'
    }
}
