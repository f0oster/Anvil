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
    $script:TestProject = Join-Path $TestDrive 'FuncTestMod'
    $Params = @{
        Name            = 'FuncTestMod'
        DestinationPath = $TestDrive
        Author          = 'Tester'
        Force           = $true
    }
    New-AnvilModule @Params
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'New-AnvilFunction' -Tag 'Unit' {

    Context 'Verb validation' {
        It 'rejects unapproved verbs for Public scope' {
            $Params = @{
                FunctionName  = 'Fetch-Data'
                Scope         = 'Public'
                Path          = $script:TestProject
            }
            New-AnvilFunction @Params -ErrorVariable Err -ErrorAction SilentlyContinue
            $Err | Should -Not -BeNullOrEmpty
            $Err[0].Exception.Message | Should -Match 'approved PowerShell verb'
        }

        It 'accepts approved verbs' {
            $Params = @{
                FunctionName = 'Get-Data'
                Scope        = 'Public'
                Path         = $script:TestProject
                Force        = $true
            }
            $Result = New-AnvilFunction @Params
            $Result | Should -Not -BeNullOrEmpty
        }

        It 'skips verb check with -SkipVerbCheck' {
            $Params = @{
                FunctionName  = 'Fetch-Data'
                Scope         = 'Public'
                Path          = $script:TestProject
                SkipVerbCheck = $true
                Force         = $true
            }
            $Result = New-AnvilFunction @Params
            $Result | Should -Not -BeNullOrEmpty
        }

        It 'does not validate verbs for Private scope' {
            $Params = @{
                FunctionName = 'Fetch-Internal'
                Scope        = 'Private'
                Path         = $script:TestProject
                Force        = $true
            }
            $Result = New-AnvilFunction @Params
            $Result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'File creation' {
        It 'creates the function file in the correct directory' {
            $Params = @{
                FunctionName = 'Get-Widget'
                Scope        = 'Public'
                Path         = $script:TestProject
                Force        = $true
            }
            New-AnvilFunction @Params
            Join-Path $script:TestProject 'src/FuncTestMod/Public/Get-Widget.ps1' | Should -Exist
        }

        It 'creates the matching test file' {
            Join-Path $script:TestProject 'tests/unit/Public/Get-Widget.Tests.ps1' | Should -Exist
        }

        It 'supports -Location for nested directories' {
            $Params = @{
                FunctionName = 'Get-Nested'
                Scope        = 'Public'
                Path         = $script:TestProject
                Location     = 'Core/Sub'
                Force        = $true
            }
            New-AnvilFunction @Params
            Join-Path $script:TestProject 'src/FuncTestMod/Public/Core/Sub/Get-Nested.ps1' | Should -Exist
            Join-Path $script:TestProject 'tests/unit/Public/Core/Sub/Get-Nested.Tests.ps1' | Should -Exist
        }

        It 'errors when file exists without -Force' {
            $Params = @{
                FunctionName = 'Get-Existing'
                Scope        = 'Public'
                Path         = $script:TestProject
            }
            New-AnvilFunction @Params
            New-AnvilFunction @Params -ErrorVariable Err -ErrorAction SilentlyContinue
            $Err | Should -Not -BeNullOrEmpty
        }
    }
}
