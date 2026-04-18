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

    # Clean up orphaned temp directories from prior crashed runs
    Get-ChildItem -Path ([IO.Path]::GetTempPath()) -Directory -Filter 'AnvilTest_*' -ErrorAction SilentlyContinue |
        Where-Object { $_.CreationTime -lt (Get-Date).AddHours(-1) } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Scaffold into a temp directory
    $script:TempRoot = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "AnvilTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $script:TempRoot -ItemType Directory -Force | Out-Null

    $script:ProjectName = 'TestScaffold'
    $NewModuleParams = @{
        Name              = $script:ProjectName
        DestinationPath   = $script:TempRoot
        Author            = 'Integration Test'
        Description       = 'A test-scaffolded module'
        CIProvider        = 'GitHub'
        License           = 'MIT'
        CoverageThreshold = 75
        IncludeDocs       = $true
        PassThru          = $true
        Confirm           = $false
    }
    $script:ProjectPath = New-AnvilModule @NewModuleParams
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
    if ($script:TempRoot -and (Test-Path -Path $script:TempRoot)) {
        Remove-Item -Path $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'New-AnvilModule golden template' -Tag 'Integration' {

    Context 'Return value' {
        It 'returns the project path with -PassThru' {
            $script:ProjectPath | Should -Not -BeNullOrEmpty
            $script:ProjectPath | Should -Exist
        }
    }

    Context 'Directory structure' {
        It 'creates src/<ModuleName>/' {
            Join-Path -Path $script:ProjectPath -ChildPath 'src' |
                Join-Path -ChildPath $script:ProjectName | Should -Exist
        }
        It 'creates build/' {
            Join-Path -Path $script:ProjectPath -ChildPath 'build' | Should -Exist
        }
        It 'creates tests/unit/' {
            Join-Path -Path $script:ProjectPath -ChildPath 'tests' |
                Join-Path -ChildPath 'unit' | Should -Exist
        }
        It 'creates tests/integration/' {
            Join-Path -Path $script:ProjectPath -ChildPath 'tests' |
                Join-Path -ChildPath 'integration' | Should -Exist
        }
        It 'creates docs/' {
            Join-Path -Path $script:ProjectPath -ChildPath 'docs' | Should -Exist
        }
    }

    Context 'Module source files' {
        It 'generates the module manifest' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            $P | Should -Exist
        }
        It 'generated manifest is valid' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            { Test-ModuleManifest -Path $P -ErrorAction Stop } | Should -Not -Throw
        }
        It 'generates the module .psm1' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psm1"
            $P | Should -Exist
        }
        It 'creates Public/ and Private/ directories' {
            $ModDir = Join-Path -Path $script:ProjectPath -ChildPath 'src' |
                Join-Path -ChildPath $script:ProjectName
            Join-Path -Path $ModDir -ChildPath 'Public'  | Should -Exist
            Join-Path -Path $ModDir -ChildPath 'Private' | Should -Exist
        }
    }

    Context 'Token replacement in content' {
        It 'manifest contains the correct module name' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            $Content = Get-Content -Path $P -Raw
            $Content | Should -Match $script:ProjectName
            $Content | Should -Not -Match '<%Name%>'
        }
        It 'manifest contains the correct author' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath 'src' |
                Join-Path -ChildPath $script:ProjectName |
                Join-Path -ChildPath "$($script:ProjectName).psd1"
            $Content = Get-Content -Path $P -Raw
            $Content | Should -Match 'Integration Test'
            $Content | Should -Not -Match '<%Author%>'
        }
        It 'build script contains the correct module name' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath 'build' |
                Join-Path -ChildPath 'module.build.ps1'
            $Content = Get-Content -Path $P -Raw
            $Content | Should -Match $script:ProjectName
            $Content | Should -Not -Match '<%Name%>'
        }
        It 'build settings contains the correct coverage threshold' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath 'build' |
                Join-Path -ChildPath 'build.settings.psd1'
            $Content = Get-Content -Path $P -Raw
            $Content | Should -Match '75'
        }
        It 'no unreplaced content tokens remain in any .ps1 or .psd1 file' {
            $Files = Get-ChildItem -Path $script:ProjectPath -Include '*.ps1','*.psd1','*.psm1','*.md','*.yml' -Recurse
            foreach ($F in $Files) {
                $Content = Get-Content -Path $F.FullName -Raw -ErrorAction SilentlyContinue
                if ($Content) {
                    $Content | Should -Not -Match '<%\w+%>' -Because "File $($F.Name) should have no unreplaced tokens"
                }
            }
        }
        It 'no unreplaced path tokens (__Name__) in directory names' {
            $Dirs = Get-ChildItem -Path $script:ProjectPath -Directory -Recurse
            foreach ($D in $Dirs) {
                $D.Name | Should -Not -Match '__\w+__' -Because "Directory $($D.FullName) should have no path tokens"
            }
        }
    }

    Context 'CI templates (GitHub)' {
        It 'creates .github/workflows/ci.yml' {
            Join-Path -Path $script:ProjectPath -ChildPath '.github' |
                Join-Path -ChildPath 'workflows' |
                Join-Path -ChildPath 'ci.yml' | Should -Exist
        }
        It 'creates .github/workflows/release.yml' {
            Join-Path -Path $script:ProjectPath -ChildPath '.github' |
                Join-Path -ChildPath 'workflows' |
                Join-Path -ChildPath 'release.yml' | Should -Exist
        }
        It 'CI YAML contains the module name' {
            $P = Join-Path -Path $script:ProjectPath -ChildPath '.github' |
                Join-Path -ChildPath 'workflows' |
                Join-Path -ChildPath 'release.yml'
            $Content = Get-Content -Path $P -Raw
            $Content | Should -Match $script:ProjectName
        }
    }

    Context 'Static files' {
        It 'includes LICENSE' {
            Join-Path -Path $script:ProjectPath -ChildPath 'LICENSE' | Should -Exist
        }
        It 'includes .gitignore' {
            Join-Path -Path $script:ProjectPath -ChildPath '.gitignore' | Should -Exist
        }
        It 'includes .editorconfig' {
            Join-Path -Path $script:ProjectPath -ChildPath '.editorconfig' | Should -Exist
        }
        It 'includes PSScriptAnalyzerSettings.psd1' {
            Join-Path -Path $script:ProjectPath -ChildPath 'PSScriptAnalyzerSettings.psd1' | Should -Exist
        }
        It 'includes README.md' {
            Join-Path -Path $script:ProjectPath -ChildPath 'README.md' | Should -Exist
        }
        It 'includes CONTRIBUTING.md' {
            Join-Path -Path $script:ProjectPath -ChildPath 'CONTRIBUTING.md' | Should -Exist
        }
    }

    Context 'Anvil version stamp' {
        It 'creates .ANVIL_VERSION' {
            Join-Path -Path $script:ProjectPath -ChildPath '.ANVIL_VERSION' | Should -Exist
        }
        It 'contains a valid version string' {
            $Version = Get-Content -Path (Join-Path $script:ProjectPath '.ANVIL_VERSION')
            $Version -as [version] | Should -Not -BeNullOrEmpty
        }
        It 'matches the running Anvil module version' {
            $Version = Get-Content -Path (Join-Path $script:ProjectPath '.ANVIL_VERSION')
            $Expected = (Get-Module -Name 'Anvil').Version.ToString()
            $Version | Should -Be $Expected
        }
    }

    Context 'No input mutation' {
        It 'does not mutate a hashtable passed to the same parameters' {
            $OriginalHash = @{ SomeKey = 'SomeValue' }
            $HashBefore   = $OriginalHash.Clone()

            $Dest2 = Join-Path -Path $script:TempRoot -ChildPath 'MutationTest'
            New-Item -Path $Dest2 -ItemType Directory -Force | Out-Null
            New-AnvilModule -Name 'MutCheck' -DestinationPath $Dest2 -Author 'X' -Confirm:$false

            $OriginalHash.Keys | Should -Be $HashBefore.Keys
            $OriginalHash['SomeKey'] | Should -Be 'SomeValue'
        }
    }
}

Describe 'New-AnvilModule manifest conditions' -Tag 'Integration' {

    BeforeAll {
        $script:CondRoot = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "AnvilCondTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $script:CondRoot -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        if ($script:CondRoot -and (Test-Path -Path $script:CondRoot)) {
            Remove-Item -Path $script:CondRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'License = MIT' {

        BeforeAll {
            $Params = @{
                Name            = 'MitLicense'
                DestinationPath = $script:CondRoot
                Author          = 'Test'
                License         = 'MIT'
                PassThru        = $true
                Confirm         = $false
            }
            $script:MitPath = New-AnvilModule @Params
            $script:MitLicenseContent = Get-Content -Path (Join-Path $script:MitPath 'LICENSE') -Raw
        }

        It 'creates a LICENSE file' {
            Join-Path $script:MitPath 'LICENSE' | Should -Exist
        }

        It 'contains the MIT license text' {
            $script:MitLicenseContent | Should -Match 'MIT License'
            $script:MitLicenseContent | Should -Match 'Permission is hereby granted'
        }

        It 'does not contain Apache license text' {
            $script:MitLicenseContent | Should -Not -Match 'Apache License'
        }

        It 'has no section markers' {
            $script:MitLicenseContent | Should -Not -Match '<%#section'
        }
    }

    Context 'License = Apache2' {

        BeforeAll {
            $Params = @{
                Name            = 'ApacheLicense'
                DestinationPath = $script:CondRoot
                Author          = 'Test'
                License         = 'Apache2'
                PassThru        = $true
                Confirm         = $false
            }
            $script:ApachePath = New-AnvilModule @Params
            $script:ApacheLicenseContent = Get-Content -Path (Join-Path $script:ApachePath 'LICENSE') -Raw
        }

        It 'creates a LICENSE file' {
            Join-Path $script:ApachePath 'LICENSE' | Should -Exist
        }

        It 'contains the Apache 2.0 license text' {
            $script:ApacheLicenseContent | Should -Match 'Apache License'
            $script:ApacheLicenseContent | Should -Match 'Version 2\.0'
        }

        It 'does not contain MIT license text' {
            $script:ApacheLicenseContent | Should -Not -Match 'MIT License'
        }

        It 'has no section markers' {
            $script:ApacheLicenseContent | Should -Not -Match '<%#section'
        }
    }

    Context 'License = None' {

        BeforeAll {
            $Params = @{
                Name            = 'NoLicense'
                DestinationPath = $script:CondRoot
                Author          = 'Test'
                License         = 'None'
                PassThru        = $true
                Confirm         = $false
            }
            $script:NoLicensePath = New-AnvilModule @Params
        }

        It 'does not create a LICENSE file' {
            Join-Path $script:NoLicensePath 'LICENSE' | Should -Not -Exist
        }

        It 'still creates the module manifest' {
            Join-Path $script:NoLicensePath "src/NoLicense/NoLicense.psd1" | Should -Exist
        }
    }

    Context 'IncludeDocs = $false' {

        BeforeAll {
            $Params = @{
                Name            = 'NoDocs'
                DestinationPath = $script:CondRoot
                Author          = 'Test'
                PassThru        = $true
                Confirm         = $false
            }
            $script:NoDocsPath = New-AnvilModule @Params
            $script:NoDocsBuild = Get-Content -Path (Join-Path $script:NoDocsPath 'build/module.build.ps1') -Raw
        }

        It 'does not create files in docs/' {
            $DocsDir = Join-Path $script:NoDocsPath 'docs'
            $DocsFiles = Get-ChildItem -Path $DocsDir -File -Recurse -ErrorAction SilentlyContinue
            $DocsFiles | Should -BeNullOrEmpty
        }

        It 'still creates the build script' {
            Join-Path $script:NoDocsPath 'build/module.build.ps1' | Should -Exist
        }

        It 'build script does not contain the Docs task' {
            $script:NoDocsBuild | Should -Not -Match 'task Docs \{'
        }

        It 'build script composite task does not include Docs' {
            $CompositeLine = $script:NoDocsBuild -split '\r?\n' |
                Where-Object { $_ -match '^task \. ' } |
                Select-Object -First 1
            $CompositeLine | Should -Not -Match 'Docs'
        }

        It 'build script has no section markers' {
            $script:NoDocsBuild | Should -Not -Match '<%#section'
            $script:NoDocsBuild | Should -Not -Match '<%#endsection'
        }
    }

    Context 'CIProvider = None' {

        BeforeAll {
            $Params = @{
                Name            = 'NoCI'
                DestinationPath = $script:CondRoot
                Author          = 'Test'
                CIProvider      = 'None'
                PassThru        = $true
                Confirm         = $false
            }
            $script:NoCIPath = New-AnvilModule @Params
        }

        It 'does not create .github directory' {
            Join-Path $script:NoCIPath '.github' | Should -Not -Exist
        }

        It 'does not create any CI workflow files' {
            $CIFiles = Get-ChildItem -Path $script:NoCIPath -Recurse -File |
                Where-Object { $_.Name -match '(ci|pipeline|gitlab).*\.(yml|yaml)$' }
            $CIFiles | Should -BeNullOrEmpty
        }

        It 'still creates the module source' {
            Join-Path $script:NoCIPath 'src/NoCI/NoCI.psd1' | Should -Exist
        }
    }

    Context 'IncludeDocs = $true' {

        BeforeAll {
            $Params = @{
                Name            = 'WithDocs'
                DestinationPath = $script:CondRoot
                Author          = 'Test'
                IncludeDocs     = $true
                PassThru        = $true
                Confirm         = $false
            }
            $script:WithDocsPath = New-AnvilModule @Params
            $script:WithDocsBuild = Get-Content -Path (Join-Path $script:WithDocsPath 'build/module.build.ps1') -Raw
        }

        It 'creates files in docs/' {
            $DocsDir = Join-Path $script:WithDocsPath 'docs'
            $DocsFiles = Get-ChildItem -Path $DocsDir -File -Recurse -ErrorAction SilentlyContinue
            $DocsFiles | Should -Not -BeNullOrEmpty
        }

        It 'build script contains the Docs task' {
            $script:WithDocsBuild | Should -Match 'task Docs \{'
        }

        It 'build script composite task includes Docs' {
            $CompositeLine = $script:WithDocsBuild -split '\r?\n' |
                Where-Object { $_ -match '^task \. ' } |
                Select-Object -First 1
            $CompositeLine | Should -Match 'Docs'
        }

        It 'build script has no section markers' {
            $script:WithDocsBuild | Should -Not -Match '<%#section'
            $script:WithDocsBuild | Should -Not -Match '<%#endsection'
        }
    }
}
