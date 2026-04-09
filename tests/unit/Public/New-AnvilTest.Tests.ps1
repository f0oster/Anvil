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
    $script:TestProject = Join-Path $TestDrive 'TestTestMod'
    $Params = @{
        Name            = 'TestTestMod'
        DestinationPath = $TestDrive
        Author          = 'Tester'
        Force           = $true
    }
    New-AnvilModule @Params
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'New-AnvilTest' -Tag 'Unit' {

    Context 'Public scope' {
        It 'creates a test file in tests/unit/Public/' {
            New-AnvilTest -Name 'Get-Thing' -Scope Public -Path $script:TestProject
            Join-Path $script:TestProject 'tests/unit/Public/Get-Thing.Tests.ps1' | Should -Exist
        }
    }

    Context 'Private scope' {
        It 'creates a test file in tests/unit/Private/' {
            New-AnvilTest -Name 'Format-Row' -Scope Private -Path $script:TestProject
            Join-Path $script:TestProject 'tests/unit/Private/Format-Row.Tests.ps1' | Should -Exist
        }
    }

    Context 'PrivateClasses scope' {
        It 'creates a test file in tests/unit/PrivateClasses/' {
            New-AnvilTest -Name 'MyClass' -Scope PrivateClasses -Path $script:TestProject
            Join-Path $script:TestProject 'tests/unit/PrivateClasses/MyClass.Tests.ps1' | Should -Exist
        }
    }

    Context 'Location support' {
        It 'creates nested directories with -Location' {
            New-AnvilTest -Name 'Get-Deep' -Scope Public -Path $script:TestProject -Location 'Nested/Path'
            Join-Path $script:TestProject 'tests/unit/Public/Nested/Path/Get-Deep.Tests.ps1' | Should -Exist
        }
    }

    Context 'Collision handling' {
        It 'errors when file exists without -Force' {
            New-AnvilTest -Name 'Get-Collision' -Scope Public -Path $script:TestProject
            New-AnvilTest -Name 'Get-Collision' -Scope Public -Path $script:TestProject -ErrorVariable Err -ErrorAction SilentlyContinue
            $Err | Should -Not -BeNullOrEmpty
        }

        It 'overwrites with -Force' {
            New-AnvilTest -Name 'Get-Overwrite' -Scope Public -Path $script:TestProject
            $Result = New-AnvilTest -Name 'Get-Overwrite' -Scope Public -Path $script:TestProject -Force
            $Result | Should -Not -BeNullOrEmpty
        }
    }
}
