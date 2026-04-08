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

Describe 'Assert-ValidConfiguration' -Tag 'Unit' {

    Context 'Valid configurations' {
        It 'accepts a minimal valid config' {
            $Config = @{
                ModuleName  = 'MyModule'
                Author      = 'Test Author'
                Description = 'A test module'
            }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Not -Throw
        }

        It 'accepts a full config with all optional keys' {
            $Config = @{
                ModuleName           = 'My.Cool-Module_1'
                Author               = 'Jane Doe'
                Description          = 'Something useful'
                CIProvider           = 'GitHub'
                License              = 'MIT'
                CoverageThreshold    = 80
                MinPowerShellVersion = '7.0'
            }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Not -Throw
        }
    }

    Context 'Missing required keys' {
        It 'rejects a config missing ModuleName' {
            $Config = @{ Author = 'X'; Description = 'Y' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*ModuleName*'
        }

        It 'rejects a config missing Author' {
            $Config = @{ ModuleName = 'X'; Description = 'Y' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*Author*'
        }

        It 'rejects a config with empty Description' {
            $Config = @{ ModuleName = 'X'; Author = 'Y'; Description = '' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*Description*'
        }
    }

    Context 'ModuleName validation' {
        It 'rejects names starting with a digit' {
            $Config = @{ ModuleName = '1Bad'; Author = 'X'; Description = 'Y' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*invalid characters*'
        }

        It 'rejects names with spaces' {
            $Config = @{ ModuleName = 'My Module'; Author = 'X'; Description = 'Y' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*invalid characters*'
        }
    }

    Context 'Enum validation' {
        It 'rejects an unknown CIProvider' {
            $Config = @{ ModuleName = 'X'; Author = 'Y'; Description = 'Z'; CIProvider = 'Jenkins' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*CIProvider*'
        }

        It 'rejects an unknown License' {
            $Config = @{ ModuleName = 'X'; Author = 'Y'; Description = 'Z'; License = 'GPL' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*License*'
        }
    }

    Context 'Numeric validation' {
        It 'rejects CoverageThreshold above 100' {
            $Config = @{ ModuleName = 'X'; Author = 'Y'; Description = 'Z'; CoverageThreshold = 150 }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*CoverageThreshold*'
        }

        It 'rejects an invalid MinPowerShellVersion' {
            $Config = @{ ModuleName = 'X'; Author = 'Y'; Description = 'Z'; MinPowerShellVersion = 'nope' }
            { InModuleScope 'Anvil' -ArgumentList $Config { param($Config) Assert-ValidConfiguration -Configuration $Config } } |
                Should -Throw '*MinPowerShellVersion*'
        }
    }
}
