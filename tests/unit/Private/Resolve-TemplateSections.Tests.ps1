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

Describe 'Resolve-TemplateSections' -Tag 'Unit' {

    Context 'section kept when condition matches' {

        It 'keeps content and strips markers for IncludeWhen match' {
            InModuleScope 'Anvil' {
                $Content = @"
before
<%#section DocsTask%>
task Docs {
    Write-Host 'docs'
}
<%#endsection%>
after
"@
                $Sections = @{
                    DocsTask = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
                }
                $Tokens = @{ IncludeDocs = 'true' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Match 'before'
                $Result | Should -Match 'task Docs'
                $Result | Should -Match 'after'
                $Result | Should -Not -Match '<%#section'
                $Result | Should -Not -Match '<%#endsection'
            }
        }

        It 'keeps content for ExcludeWhen non-match' {
            InModuleScope 'Anvil' {
                $Content = @"
top
<%#section LicenseBadge%>
![License](badge.svg)
<%#endsection%>
bottom
"@
                $Sections = @{
                    LicenseBadge = @{ ExcludeWhen = @{ License = 'None' } }
                }
                $Tokens = @{ License = 'MIT' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Match 'License.*badge'
                $Result | Should -Not -Match '<%#section'
            }
        }
    }

    Context 'section stripped when condition does not match' {

        It 'strips content for IncludeWhen non-match' {
            InModuleScope 'Anvil' {
                $Content = @"
before
<%#section DocsTask%>
task Docs {
    Write-Host 'docs'
}
<%#endsection%>
after
"@
                $Sections = @{
                    DocsTask = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
                }
                $Tokens = @{ IncludeDocs = 'false' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Match 'before'
                $Result | Should -Not -Match 'task Docs'
                $Result | Should -Match 'after'
            }
        }

        It 'strips content for ExcludeWhen match' {
            InModuleScope 'Anvil' {
                $Content = @"
top
<%#section LicenseBadge%>
![License](badge.svg)
<%#endsection%>
bottom
"@
                $Sections = @{
                    LicenseBadge = @{ ExcludeWhen = @{ License = 'None' } }
                }
                $Tokens = @{ License = 'None' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Not -Match 'License.*badge'
                $Result | Should -Match 'top'
                $Result | Should -Match 'bottom'
            }
        }
    }

    Context 'multiple sections in one file' {

        It 'processes each section independently' {
            InModuleScope 'Anvil' {
                $Content = @"
header
<%#section Alpha%>
alpha content
<%#endsection%>
middle
<%#section Beta%>
beta content
<%#endsection%>
footer
"@
                $Sections = @{
                    Alpha = @{ IncludeWhen = @{ A = 'yes' } }
                    Beta  = @{ IncludeWhen = @{ B = 'yes' } }
                }
                $Tokens = @{ A = 'yes'; B = 'no' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Match 'alpha content'
                $Result | Should -Not -Match 'beta content'
                $Result | Should -Match 'header'
                $Result | Should -Match 'middle'
                $Result | Should -Match 'footer'
            }
        }
    }

    Context 'no sections in content' {

        It 'returns content unchanged when there are no markers' {
            InModuleScope 'Anvil' {
                $Content = "just plain content`nwith multiple lines"
                $Sections = @{
                    DocsTask = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
                }
                $Tokens = @{ IncludeDocs = 'true' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Be $Content
            }
        }
    }

    Context 'preserves surrounding content' {

        It 'does not eat extra whitespace around sections' {
            InModuleScope 'Anvil' {
                $Content = @"
line1
line2
<%#section Keep%>
kept
<%#endsection%>
line3
line4
"@
                $Sections = @{
                    Keep = @{ IncludeWhen = @{ X = 'y' } }
                }
                $Tokens = @{ X = 'y' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Match 'line1'
                $Result | Should -Match 'line2'
                $Result | Should -Match 'kept'
                $Result | Should -Match 'line3'
                $Result | Should -Match 'line4'
            }
        }
    }

    Context 'undeclared section' {

        It 'throws when a section marker has no manifest entry' {
            InModuleScope 'Anvil' {
                $Content = @"
<%#section Unknown%>
content
<%#endsection%>
"@
                $Sections = @{}
                $Tokens = @{}

                { Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens } |
                    Should -Throw "*Section 'Unknown' found in template but not declared*"
            }
        }
    }

    Context 'indented markers' {

        It 'handles markers with leading whitespace' {
            InModuleScope 'Anvil' {
                $Content = @"
task . Clean, Build
    <%#section DocsTask%>
    task Docs {
        Write-Host 'docs'
    }
    <%#endsection%>
task Release Version
"@
                $Sections = @{
                    DocsTask = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
                }
                $Tokens = @{ IncludeDocs = 'false' }

                $Result = Resolve-TemplateSections -Content $Content -Sections $Sections -Tokens $Tokens

                $Result | Should -Not -Match 'task Docs'
                $Result | Should -Match 'task \. Clean'
                $Result | Should -Match 'task Release'
            }
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module -Name 'Anvil').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Resolve-TemplateSections'
    }
}
