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
        BeforeEach {
            InModuleScope 'Anvil' {
                Mock Resolve-AuthorName { $null }
            }
        }

        It 'throws when DestinationPath is missing' {
            { New-AnvilModule -Name 'Test' -Author 'Dev' } | Should -Throw '*DestinationPath*required*'
        }

        It 'throws when Author is missing' {
            { New-AnvilModule -Name 'Test' -DestinationPath $TestDrive } | Should -Throw '*Author*required*'
        }
    }

    Context 'URI parameter validation' {
        It 'rejects a non-URI string for ProjectUri' {
            $Params = @{
                Name            = 'UriTest'
                DestinationPath = $TestDrive
                Author          = 'Dev'
                ProjectUri      = 'not-a-uri'
            }
            { New-AnvilModule @Params } | Should -Throw '*not a valid absolute URI*'
        }

        It 'rejects a relative URI for ProjectUri' {
            $Params = @{
                Name            = 'UriTest'
                DestinationPath = $TestDrive
                Author          = 'Dev'
                ProjectUri      = 'github.com/user/repo'
            }
            { New-AnvilModule @Params } | Should -Throw '*not a valid absolute URI*'
        }

        It 'rejects a non-URI string for LicenseUri' {
            $Params = @{
                Name            = 'UriTest'
                DestinationPath = $TestDrive
                Author          = 'Dev'
                LicenseUri      = 'just some text'
            }
            { New-AnvilModule @Params } | Should -Throw '*not a valid absolute URI*'
        }

        It 'rejects a relative URI for LicenseUri' {
            $Params = @{
                Name            = 'UriTest'
                DestinationPath = $TestDrive
                Author          = 'Dev'
                LicenseUri      = 'example.com/license'
            }
            { New-AnvilModule @Params } | Should -Throw '*not a valid absolute URI*'
        }

        It 'accepts a valid absolute URI for ProjectUri' {
            $Params = @{
                Name            = 'UriValidTest'
                DestinationPath = $TestDrive
                Author          = 'Dev'
                ProjectUri      = 'https://github.com/user/repo'
                Force           = $true
            }
            { New-AnvilModule @Params } | Should -Not -Throw
        }

        It 'accepts an empty string for ProjectUri' {
            $Params = @{
                Name            = 'UriEmptyTest'
                DestinationPath = $TestDrive
                Author          = 'Dev'
                ProjectUri      = ''
                Force           = $true
            }
            { New-AnvilModule @Params } | Should -Not -Throw
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
