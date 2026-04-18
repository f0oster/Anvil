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

    Context 'Manifest conditions' {

        BeforeEach {
            $script:CondSrc = Join-Path $TestDrive "condsrc_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            $script:CondDst = Join-Path $TestDrive "conddst_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            New-Item -Path $script:CondSrc -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $script:CondSrc 'keep.txt') -Value 'kept'
            Set-Content -Path (Join-Path $script:CondSrc 'LICENSE.tmpl') -Value 'MIT License <%Author%>'
            $DocsDir = Join-Path $script:CondSrc 'docs'
            New-Item -Path $DocsDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $DocsDir 'README.md.tmpl') -Value '# Docs for <%ModuleName%>'
        }

        It 'excludes files matching ExcludeWhen condition' {
            InModuleScope 'Anvil' -Parameters @{ Src = $script:CondSrc; Dst = $script:CondDst } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ License = 'None'; Author = 'Test'; ModuleName = 'M' }
                    ExcludeWhen     = @{ 'LICENSE.tmpl' = @{ License = 'None' } }
                }
                Invoke-TemplateEngine @Params
            }
            Join-Path $script:CondDst 'LICENSE' | Should -Not -Exist
            Join-Path $script:CondDst 'keep.txt' | Should -Exist
        }

        It 'includes files when ExcludeWhen condition does not match' {
            InModuleScope 'Anvil' -Parameters @{ Src = $script:CondSrc; Dst = $script:CondDst } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ License = 'MIT'; Author = 'Test'; ModuleName = 'M' }
                    ExcludeWhen     = @{ 'LICENSE.tmpl' = @{ License = 'None' } }
                }
                Invoke-TemplateEngine @Params
            }
            Join-Path $script:CondDst 'LICENSE' | Should -Exist
        }

        It 'excludes files when IncludeWhen condition does not match' {
            InModuleScope 'Anvil' -Parameters @{ Src = $script:CondSrc; Dst = $script:CondDst } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ License = 'MIT'; Author = 'Test'; ModuleName = 'M'; IncludeDocs = 'false' }
                    IncludeWhen     = @{ 'docs/*' = @{ IncludeDocs = 'true' } }
                }
                Invoke-TemplateEngine @Params
            }
            Join-Path $script:CondDst 'docs/README.md' | Should -Not -Exist
        }

        It 'includes files when IncludeWhen condition matches' {
            InModuleScope 'Anvil' -Parameters @{ Src = $script:CondSrc; Dst = $script:CondDst } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ License = 'MIT'; Author = 'Test'; ModuleName = 'M'; IncludeDocs = 'true' }
                    IncludeWhen     = @{ 'docs/*' = @{ IncludeDocs = 'true' } }
                }
                Invoke-TemplateEngine @Params
            }
            Join-Path $script:CondDst 'docs/README.md' | Should -Exist
        }

        It 'processes all files when no conditions are specified' {
            InModuleScope 'Anvil' -Parameters @{ Src = $script:CondSrc; Dst = $script:CondDst } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ License = 'MIT'; Author = 'Test'; ModuleName = 'M' }
                }
                Invoke-TemplateEngine @Params
            }
            Join-Path $script:CondDst 'keep.txt' | Should -Exist
            Join-Path $script:CondDst 'LICENSE' | Should -Exist
            Join-Path $script:CondDst 'docs/README.md' | Should -Exist
        }
    }

    Context 'Section processing' {

        It 'strips sections when condition does not match' {
            $SrcDir = Join-Path $TestDrive "secsrc_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            $DstDir = Join-Path $TestDrive "secdst_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            New-Item -Path $SrcDir -ItemType Directory -Force | Out-Null
            $Content = @"
before
<%#section DocsTask%>
task Docs { }
<%#endsection%>
after
"@
            Set-Content -Path (Join-Path $SrcDir 'build.ps1.tmpl') -Value $Content
            InModuleScope 'Anvil' -Parameters @{ Src = $SrcDir; Dst = $DstDir } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ IncludeDocs = 'false' }
                    Sections        = @{ DocsTask = @{ IncludeWhen = @{ IncludeDocs = 'true' } } }
                }
                Invoke-TemplateEngine @Params
            }
            $Result = Get-Content (Join-Path $DstDir 'build.ps1') -Raw
            $Result | Should -Match 'before'
            $Result | Should -Match 'after'
            $Result | Should -Not -Match 'task Docs'
        }

        It 'keeps sections when condition matches' {
            $SrcDir = Join-Path $TestDrive "secsrc2_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            $DstDir = Join-Path $TestDrive "secdst2_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            New-Item -Path $SrcDir -ItemType Directory -Force | Out-Null
            $Content = @"
before
<%#section DocsTask%>
task Docs { }
<%#endsection%>
after
"@
            Set-Content -Path (Join-Path $SrcDir 'build.ps1.tmpl') -Value $Content
            InModuleScope 'Anvil' -Parameters @{ Src = $SrcDir; Dst = $DstDir } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ IncludeDocs = 'true' }
                    Sections        = @{ DocsTask = @{ IncludeWhen = @{ IncludeDocs = 'true' } } }
                }
                Invoke-TemplateEngine @Params
            }
            $Result = Get-Content (Join-Path $DstDir 'build.ps1') -Raw
            $Result | Should -Match 'task Docs'
            $Result | Should -Not -Match '<%#section'
        }

        It 'applies token replacement after section processing' {
            $SrcDir = Join-Path $TestDrive "secsrc3_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            $DstDir = Join-Path $TestDrive "secdst3_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            New-Item -Path $SrcDir -ItemType Directory -Force | Out-Null
            $TokenPattern = '<%' + 'ModuleName' + '%>'
            $Content = @"
<%#section Header%>
# $TokenPattern
<%#endsection%>
"@
            Set-Content -Path (Join-Path $SrcDir 'readme.md.tmpl') -Value $Content
            InModuleScope 'Anvil' -Parameters @{ Src = $SrcDir; Dst = $DstDir } {
                param($Src, $Dst)
                $Params = @{
                    SourcePath      = $Src
                    DestinationPath = $Dst
                    Tokens          = @{ ModuleName = 'MyMod'; Show = 'yes' }
                    Sections        = @{ Header = @{ IncludeWhen = @{ Show = 'yes' } } }
                }
                Invoke-TemplateEngine @Params
            }
            $Result = Get-Content (Join-Path $DstDir 'readme.md') -Raw
            $Result | Should -Match '# MyMod'
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Invoke-TemplateEngine'
    }
}
