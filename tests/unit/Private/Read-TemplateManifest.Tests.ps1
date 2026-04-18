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

Describe 'Read-TemplateManifest' -Tag 'Unit' {

    BeforeAll {
        $script:TempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "AnvilManifestTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $script:TempRoot -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        if (Test-Path -Path $script:TempRoot) {
            Remove-Item -Path $script:TempRoot -Recurse -Force
        }
    }

    Context 'valid manifest' {

        It 'loads and returns a valid manifest hashtable' {
            InModuleScope 'Anvil' -Parameters @{ Root = $script:TempRoot } {
                param($Root)
                $TemplateDir = Join-Path -Path $Root -ChildPath 'ValidTemplate'
                New-Item -Path $TemplateDir -ItemType Directory -Force | Out-Null
                $Content = @"
@{
    Name        = 'TestTemplate'
    Description = 'A test template'
    Version     = '1.0.0'
    Parameters  = @(
        @{ Name = 'Name'; Type = 'string'; Prompt = 'Module name' }
    )
}
"@
                Set-Content -Path (Join-Path $TemplateDir 'template.psd1') -Value $Content

                $Result = Read-TemplateManifest -TemplatePath $TemplateDir
                $Result | Should -Not -BeNullOrEmpty
                $Result.Name | Should -Be 'TestTemplate'
                $Result.Parameters.Count | Should -Be 1
            }
        }
    }

    Context 'missing file' {

        It 'throws when template.psd1 does not exist' {
            InModuleScope 'Anvil' -Parameters @{ Root = $script:TempRoot } {
                param($Root)
                $EmptyDir = Join-Path -Path $Root -ChildPath 'EmptyTemplate'
                New-Item -Path $EmptyDir -ItemType Directory -Force | Out-Null

                { Read-TemplateManifest -TemplatePath $EmptyDir } |
                    Should -Throw '*Template manifest not found*'
            }
        }
    }

    Context 'malformed PSD1' {

        It 'throws when the file is not valid PowerShell data' {
            InModuleScope 'Anvil' -Parameters @{ Root = $script:TempRoot } {
                param($Root)
                $BadDir = Join-Path -Path $Root -ChildPath 'BadTemplate'
                New-Item -Path $BadDir -ItemType Directory -Force | Out-Null
                Set-Content -Path (Join-Path $BadDir 'template.psd1') -Value 'this is not valid psd1 {'

                { Read-TemplateManifest -TemplatePath $BadDir } | Should -Throw
            }
        }
    }

    Context 'schema validation' {

        It 'throws when the manifest fails schema validation' {
            InModuleScope 'Anvil' -Parameters @{ Root = $script:TempRoot } {
                param($Root)
                $InvalidDir = Join-Path -Path $Root -ChildPath 'InvalidTemplate'
                New-Item -Path $InvalidDir -ItemType Directory -Force | Out-Null
                $Content = @"
@{
    Name = 'Bad'
    Description = 'Missing Parameters'
    Version = '1.0.0'
}
"@
                Set-Content -Path (Join-Path $InvalidDir 'template.psd1') -Value $Content

                { Read-TemplateManifest -TemplatePath $InvalidDir } |
                    Should -Throw '*Parameters*required*'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Read-TemplateManifest'
    }
}
