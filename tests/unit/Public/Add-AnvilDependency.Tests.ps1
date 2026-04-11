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

    # Scaffold a test project
    $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) "AnvilDepTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $script:TempRoot -ItemType Directory -Force | Out-Null

    $script:TestProject = New-AnvilModule -Name 'DepTestMod' -DestinationPath $script:TempRoot -Author 'Test' -PassThru -Confirm:$false
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
    if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
        Remove-Item -Path $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Add-AnvilDependency' -Tag 'Unit' {

    It 'creates requirements.psd1 and adds the dependency' {
        $Result = Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0' -Path $script:TestProject -Confirm:$false
        $Result.Name | Should -Be 'Az.Storage'
        $Result.Version | Should -Be '>=5.0.0'
        $Result.Action | Should -Be 'Added'

        $ReqPath = Join-Path $script:TestProject 'requirements.psd1'
        $ReqPath | Should -Exist
        $Reqs = Import-PowerShellDataFile -Path $ReqPath
        $Reqs['Az.Storage'] | Should -Be '>=5.0.0'
    }

    It 'adds a second dependency to the same file' {
        $Result = Add-AnvilDependency -Name 'ImportExcel' -Path $script:TestProject -Confirm:$false
        $Result.Name | Should -Be 'ImportExcel'
        $Result.Version | Should -Be 'latest'

        $ReqPath = Join-Path $script:TestProject 'requirements.psd1'
        $Reqs = Import-PowerShellDataFile -Path $ReqPath
        $Reqs['Az.Storage'] | Should -Be '>=5.0.0'
        $Reqs['ImportExcel'] | Should -Be 'latest'
    }

    It 'updates an existing dependency with -Force' {
        $Result = Add-AnvilDependency -Name 'Az.Storage' -Version '>=6.0.0' -Path $script:TestProject -Force -Confirm:$false
        $Result.Version | Should -Be '>=6.0.0'

        $ReqPath = Join-Path $script:TestProject 'requirements.psd1'
        $Reqs = Import-PowerShellDataFile -Path $ReqPath
        $Reqs['Az.Storage'] | Should -Be '>=6.0.0'
    }

    It 'defaults version to latest' {
        $Result = Add-AnvilDependency -Name 'PSFramework' -Path $script:TestProject -Confirm:$false
        $Result.Version | Should -Be 'latest'
    }

    Context 'Version spec validation' {
        It 'rejects garbage strings' {
            { Add-AnvilDependency -Name 'Foo' -Version 'not-a-version' -Path $script:TestProject } |
                Should -Throw '*not a valid version spec*'
        }

        It 'rejects >= with an invalid version' {
            { Add-AnvilDependency -Name 'Foo' -Version '>=abc' -Path $script:TestProject } |
                Should -Throw '*not a valid version spec*'
        }

        It 'accepts latest' {
            { Add-AnvilDependency -Name 'ValidLatest' -Path $script:TestProject -Confirm:$false } |
                Should -Not -Throw
        }

        It 'accepts an exact version' {
            { Add-AnvilDependency -Name 'ValidExact' -Version '1.2.3' -Path $script:TestProject -Force -Confirm:$false } |
                Should -Not -Throw
        }

        It 'accepts a >= version spec' {
            { Add-AnvilDependency -Name 'ValidMin' -Version '>=2.0.0' -Path $script:TestProject -Force -Confirm:$false } |
                Should -Not -Throw
        }
    }
}
