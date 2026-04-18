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

Describe 'Resolve-AutoToken' -Tag 'Unit' {

    Context 'NewGuid' {

        It 'returns a valid GUID string' {
            InModuleScope 'Anvil' {
                $Result = Resolve-AutoToken -Source 'NewGuid'
                { [guid]::Parse($Result) } | Should -Not -Throw
            }
        }

        It 'returns a different GUID on each call' {
            InModuleScope 'Anvil' {
                $First  = Resolve-AutoToken -Source 'NewGuid'
                $Second = Resolve-AutoToken -Source 'NewGuid'
                $First | Should -Not -Be $Second
            }
        }
    }

    Context 'CurrentYear' {

        It 'returns the current four-digit year' {
            InModuleScope 'Anvil' {
                $Result = Resolve-AutoToken -Source 'CurrentYear'
                $Result | Should -Be (Get-Date).Year.ToString()
                $Result | Should -Match '^\d{4}$'
            }
        }
    }

    Context 'CurrentDate' {

        It 'returns the current date in yyyy-MM-dd format' {
            InModuleScope 'Anvil' {
                $Result = Resolve-AutoToken -Source 'CurrentDate'
                $Result | Should -Be (Get-Date).ToString('yyyy-MM-dd')
                $Result | Should -Match '^\d{4}-\d{2}-\d{2}$'
            }
        }
    }

    Context 'unknown source' {

        It 'throws for an unrecognized source name' {
            InModuleScope 'Anvil' {
                { Resolve-AutoToken -Source 'Nonexistent' } |
                    Should -Throw "*Unknown auto-token source 'Nonexistent'*"
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Resolve-AutoToken'
    }
}
