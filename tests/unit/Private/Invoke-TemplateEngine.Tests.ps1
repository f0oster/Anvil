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

Describe 'Invoke-TemplateEngine' -Tag 'Unit' {

    Context 'Token replacement in file content' {
        It 'replaces tokens in .tmpl files' {
            $SrcDir = Join-Path $TestDrive 'src1'
            $DstDir = Join-Path $TestDrive 'dst1'
            New-Item -Path $SrcDir -ItemType Directory -Force | Out-Null
            $TokenPattern = '<%' + 'Name' + '%>'
            Set-Content -Path (Join-Path $SrcDir 'file.txt.tmpl') -Value "Hello $TokenPattern"
            $Tokens = @{ Name = 'World' }
            InModuleScope 'Anvil' -ArgumentList $SrcDir, $DstDir, $Tokens {
                param($Src, $Dst, $Tok)
                Invoke-TemplateEngine -SourcePath $Src -DestinationPath $Dst -Tokens $Tok
            }
            $Content = Get-Content (Join-Path $DstDir 'file.txt') -Raw
            $Content | Should -Match 'Hello World'
        }

        It 'strips the .tmpl extension' {
            $SrcDir = Join-Path $TestDrive 'src2'
            $DstDir = Join-Path $TestDrive 'dst2'
            New-Item -Path $SrcDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $SrcDir 'readme.md.tmpl') -Value 'content'
            InModuleScope 'Anvil' -ArgumentList $SrcDir, $DstDir, @{} {
                param($Src, $Dst, $Tok)
                Invoke-TemplateEngine -SourcePath $Src -DestinationPath $Dst -Tokens $Tok
            }
            Join-Path $DstDir 'readme.md' | Should -Exist
            Join-Path $DstDir 'readme.md.tmpl' | Should -Not -Exist
        }
    }

    Context 'Token replacement in paths' {
        It 'replaces __Token__ in directory names' {
            $SrcDir = Join-Path $TestDrive 'src3'
            $DstDir = Join-Path $TestDrive 'dst3'
            $SubDir = Join-Path $SrcDir '__ModuleName__'
            New-Item -Path $SubDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $SubDir 'file.txt') -Value 'static'
            $Tokens = @{ ModuleName = 'MyMod' }
            InModuleScope 'Anvil' -ArgumentList $SrcDir, $DstDir, $Tokens {
                param($Src, $Dst, $Tok)
                Invoke-TemplateEngine -SourcePath $Src -DestinationPath $Dst -Tokens $Tok
            }
            Join-Path $DstDir 'MyMod' | Should -Exist
            Join-Path $DstDir 'MyMod/file.txt' | Should -Exist
        }
    }

    Context 'Static file handling' {
        It 'copies non-.tmpl files without token replacement' {
            $SrcDir = Join-Path $TestDrive 'src4'
            $DstDir = Join-Path $TestDrive 'dst4'
            New-Item -Path $SrcDir -ItemType Directory -Force | Out-Null
            $TokenPattern = '<%' + 'Token' + '%>'
            Set-Content -Path (Join-Path $SrcDir 'static.txt') -Value "unchanged $TokenPattern"
            $Tokens = @{ Token = 'replaced' }
            InModuleScope 'Anvil' -ArgumentList $SrcDir, $DstDir, $Tokens {
                param($Src, $Dst, $Tok)
                Invoke-TemplateEngine -SourcePath $Src -DestinationPath $Dst -Tokens $Tok
            }
            $Content = Get-Content (Join-Path $DstDir 'static.txt') -Raw
            $Content | Should -Match $TokenPattern
        }
    }

    Context 'Return value' {
        It 'returns the number of files processed' {
            $SrcDir = Join-Path $TestDrive 'src5'
            $DstDir = Join-Path $TestDrive 'dst5'
            New-Item -Path $SrcDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $SrcDir 'a.txt') -Value 'one'
            Set-Content -Path (Join-Path $SrcDir 'b.txt.tmpl') -Value 'two'
            $Count = InModuleScope 'Anvil' -ArgumentList $SrcDir, $DstDir, @{} {
                param($Src, $Dst, $Tok)
                Invoke-TemplateEngine -SourcePath $Src -DestinationPath $Dst -Tokens $Tok
            }
            $Count | Should -Be 2
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Invoke-TemplateEngine'
    }
}
