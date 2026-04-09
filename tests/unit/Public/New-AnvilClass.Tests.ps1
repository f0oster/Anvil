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

    # Scaffold a temp project to test against
    $script:TestProject = Join-Path $TestDrive 'ClassTestMod'
    $Params = @{
        Name            = 'ClassTestMod'
        DestinationPath = $TestDrive
        Author          = 'Tester'
        Force           = $true
    }
    New-AnvilModule @Params
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'New-AnvilClass' -Tag 'Unit' {

    It 'creates the class file in PrivateClasses/' {
        $Params = @{
            ClassName = 'HttpClient'
            Path      = $script:TestProject
        }
        New-AnvilClass @Params
        Join-Path $script:TestProject 'src/ClassTestMod/PrivateClasses/HttpClient.ps1' | Should -Exist
    }

    It 'creates the matching test file' {
        Join-Path $script:TestProject 'tests/unit/PrivateClasses/HttpClient.Tests.ps1' | Should -Exist
    }

    It 'supports -Location for nested directories' {
        $Params = @{
            ClassName = 'CacheEntry'
            Path      = $script:TestProject
            Location  = 'Models'
        }
        New-AnvilClass @Params
        Join-Path $script:TestProject 'src/ClassTestMod/PrivateClasses/Models/CacheEntry.ps1' | Should -Exist
        Join-Path $script:TestProject 'tests/unit/PrivateClasses/Models/CacheEntry.Tests.ps1' | Should -Exist
    }

    It 'errors when file exists without -Force' {
        $Params = @{
            ClassName = 'Duplicate'
            Path      = $script:TestProject
        }
        New-AnvilClass @Params
        New-AnvilClass @Params -ErrorVariable Err -ErrorAction SilentlyContinue
        $Err | Should -Not -BeNullOrEmpty
    }

    It 'overwrites with -Force' {
        $Params = @{
            ClassName = 'Overwrite'
            Path      = $script:TestProject
            Force     = $true
        }
        New-AnvilClass @Params
        $Result = New-AnvilClass @Params
        $Result | Should -Not -BeNullOrEmpty
    }
}
