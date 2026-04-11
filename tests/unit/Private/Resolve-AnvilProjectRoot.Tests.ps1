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

Describe 'Resolve-AnvilProjectRoot' -Tag 'Unit' {

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Resolve-AnvilProjectRoot'
    }

    It 'returns ProjectRoot and ModuleName when called from the project root' {
        InModuleScope 'Anvil' {
            $ProjectRoot = $PSScriptRoot
            while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
                $ProjectRoot = Split-Path $ProjectRoot -Parent
            }

            $Result = Resolve-AnvilProjectRoot -StartPath $ProjectRoot
            $Result | Should -Not -BeNullOrEmpty
            $Result.ProjectRoot | Should -Be $ProjectRoot
            $Result.ModuleName | Should -Be 'Anvil'
        }
    }

    It 'walks up from a nested directory to find the project root' {
        InModuleScope 'Anvil' {
            $ProjectRoot = $PSScriptRoot
            while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
                $ProjectRoot = Split-Path $ProjectRoot -Parent
            }
            $NestedDir = Join-Path $ProjectRoot 'src' | Join-Path -ChildPath 'Anvil' | Join-Path -ChildPath 'Public'

            $Result = Resolve-AnvilProjectRoot -StartPath $NestedDir
            $Result | Should -Not -BeNullOrEmpty
            $Result.ProjectRoot | Should -Be $ProjectRoot
        }
    }

    It 'returns nothing when no project root exists' {
        InModuleScope 'Anvil' {
            $TempDir = Join-Path ([IO.Path]::GetTempPath()) "AnvilTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
            try {
                $Result = Resolve-AnvilProjectRoot -StartPath $TempDir -ErrorAction SilentlyContinue
                $Result | Should -BeNullOrEmpty
            } finally {
                Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'writes an error when the project root is not found' {
        InModuleScope 'Anvil' {
            $TempDir = Join-Path ([IO.Path]::GetTempPath()) "AnvilTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
            try {
                $Result = Resolve-AnvilProjectRoot -StartPath $TempDir -ErrorVariable err -ErrorAction SilentlyContinue
                $err | Should -Not -BeNullOrEmpty
                $err[0].Exception.Message | Should -Match 'Could not find build/build.settings.psd1'
            } finally {
                Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'writes an error when build settings has no ModuleName' {
        InModuleScope 'Anvil' {
            $TempDir = Join-Path ([IO.Path]::GetTempPath()) "AnvilTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            $BuildDir = Join-Path $TempDir 'build'
            New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $BuildDir 'build.settings.psd1') -Value "@{ SomeOtherKey = 'value' }"
            try {
                $Result = Resolve-AnvilProjectRoot -StartPath $TempDir -ErrorVariable err -ErrorAction SilentlyContinue
                $Result | Should -BeNullOrEmpty
                $err | Should -Not -BeNullOrEmpty
                $err[0].Exception.Message | Should -Match 'does not contain a ModuleName key'
            } finally {
                Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
