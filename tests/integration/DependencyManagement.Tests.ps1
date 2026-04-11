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

    # Clean up orphaned temp directories
    Get-ChildItem -Path ([IO.Path]::GetTempPath()) -Directory -Filter 'AnvilDepInteg_*' -ErrorAction SilentlyContinue |
        Where-Object { $_.CreationTime -lt (Get-Date).AddHours(-1) } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) "AnvilDepInteg_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $script:TempRoot -ItemType Directory -Force | Out-Null

    $script:ProjectName = 'DepIntegMod'
    $script:ProjectPath = New-AnvilModule -Name $script:ProjectName -DestinationPath $script:TempRoot -Author 'Integration Test' -PassThru -Confirm:$false
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
    if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
        Remove-Item -Path $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Dependency management end-to-end' -Tag 'Integration' {

    Context 'Add a real dependency' {
        It 'adds PSReadLine to requirements.psd1' {
            $Result = Add-AnvilDependency -Name 'PSReadLine' -Version '>=2.0.0' -Path $script:ProjectPath -Confirm:$false
            $Result.Name | Should -Be 'PSReadLine'
            $Result.Version | Should -Be '>=2.0.0'

            $ReqPath = Join-Path $script:ProjectPath 'requirements.psd1'
            $ReqPath | Should -Exist
            $Reqs = Import-PowerShellDataFile -Path $ReqPath
            $Reqs['PSReadLine'] | Should -Be '>=2.0.0'
        }

        It 'updates the source manifest with the correct RequiredModules entry' {
            $ManifestFile = Join-Path $script:ProjectPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            $Manifest = Import-PowerShellDataFile -Path $ManifestFile
            $Entry = $Manifest.RequiredModules | Where-Object { $_.ModuleName -eq 'PSReadLine' }
            $Entry | Should -Not -BeNullOrEmpty
            $Entry.ModuleVersion | Should -Be '2.0.0'
        }

        It 'produces a valid manifest after adding the dependency' {
            $ManifestFile = Join-Path $script:ProjectPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            { Test-ModuleManifest -Path $ManifestFile -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'Add a second dependency' {
        It 'adds a second module without losing the first' {
            Add-AnvilDependency -Name 'PSScriptAnalyzer' -Version '1.23.0' -Path $script:ProjectPath -Confirm:$false

            $ReqPath = Join-Path $script:ProjectPath 'requirements.psd1'
            $Reqs = Import-PowerShellDataFile -Path $ReqPath
            $Reqs.Count | Should -Be 2
            $Reqs['PSReadLine'] | Should -Be '>=2.0.0'
            $Reqs['PSScriptAnalyzer'] | Should -Be '1.23.0'
        }

        It 'has both entries in the source manifest' {
            $ManifestFile = Join-Path $script:ProjectPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            $Manifest = Import-PowerShellDataFile -Path $ManifestFile
            $Manifest.RequiredModules.Count | Should -Be 2
        }
    }

    Context 'Remove a dependency' {
        It 'removes PSReadLine from both files' {
            Remove-AnvilDependency -Name 'PSReadLine' -Path $script:ProjectPath -Force -Confirm:$false

            $ReqPath = Join-Path $script:ProjectPath 'requirements.psd1'
            $Reqs = Import-PowerShellDataFile -Path $ReqPath
            $Reqs.ContainsKey('PSReadLine') | Should -BeFalse
            $Reqs['PSScriptAnalyzer'] | Should -Be '1.23.0'

            $ManifestFile = Join-Path $script:ProjectPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            $Manifest = Import-PowerShellDataFile -Path $ManifestFile
            $Names = $Manifest.RequiredModules | ForEach-Object {
                if ($_ -is [hashtable]) { $_.ModuleName } else { $_ }
            }
            $Names | Should -Not -Contain 'PSReadLine'
            $Names | Should -Contain 'PSScriptAnalyzer'
        }

        It 'still produces a valid manifest' {
            $ManifestFile = Join-Path $script:ProjectPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            { Test-ModuleManifest -Path $ManifestFile -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
