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

Describe 'New-AnvilModule' -Tag 'Unit' {

    Context 'Non-interactive parameter validation' {
        It 'throws when DestinationPath is missing' {
            { New-AnvilModule -Name 'Test' -Author 'Dev' } | Should -Throw '*DestinationPath*'
        }

        It 'throws when Author is missing' {
            { New-AnvilModule -Name 'Test' -DestinationPath $TestDrive } | Should -Throw '*Author*'
        }
    }

    Context 'Scaffolding' {
        It 'creates a project directory' {
            $Params = @{
                Name            = 'ScaffoldTest'
                DestinationPath = $TestDrive
                Author          = 'Tester'
                Force           = $true
            }
            New-AnvilModule @Params
            Join-Path $TestDrive 'ScaffoldTest' | Should -Exist
        }

        It 'returns the path with -PassThru' {
            $Params = @{
                Name            = 'PassThruTest'
                DestinationPath = $TestDrive
                Author          = 'Tester'
                PassThru        = $true
                Force           = $true
            }
            $Result = New-AnvilModule @Params
            $Result | Should -Be (Join-Path $TestDrive 'PassThruTest')
        }

        It 'creates the module manifest' {
            $Params = @{
                Name            = 'ManifestTest'
                DestinationPath = $TestDrive
                Author          = 'Tester'
                Force           = $true
            }
            New-AnvilModule @Params
            Join-Path $TestDrive 'ManifestTest/src/ManifestTest/ManifestTest.psd1' | Should -Exist
        }

        It 'creates the build script' {
            $Params = @{
                Name            = 'BuildTest'
                DestinationPath = $TestDrive
                Author          = 'Tester'
                Force           = $true
            }
            New-AnvilModule @Params
            Join-Path $TestDrive 'BuildTest/build/module.build.ps1' | Should -Exist
        }

        It 'errors when destination exists without -Force' {
            $Params = @{
                Name            = 'ExistsTest'
                DestinationPath = $TestDrive
                Author          = 'Tester'
            }
            New-AnvilModule @Params
            { New-AnvilModule @Params } | Should -Throw '*already exists*'
        }
    }
}
