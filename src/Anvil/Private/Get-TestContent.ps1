function Get-TestContent {
    param(
        [string]$FunctionName,
        [string]$ModuleName,
        [ValidateSet('Public', 'Private')]
        [string]$Scope
    )

    $Header = @"
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    `$ProjectRoot = `$PSScriptRoot
    while (`$ProjectRoot -and -not (Test-Path (Join-Path `$ProjectRoot 'build/build.settings.psd1'))) {
        `$ProjectRoot = Split-Path `$ProjectRoot -Parent
    }
    `$ModuleName   = '$ModuleName'
    `$ModuleDir    = Join-Path -Path `$ProjectRoot -ChildPath 'src' | Join-Path -ChildPath `$ModuleName
    `$ManifestPath = Join-Path -Path `$ModuleDir -ChildPath "`$ModuleName.psd1"

    Get-Module -Name `$ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module `$ManifestPath -Force -ErrorAction Stop
}

AfterAll {
    Get-Module -Name '$ModuleName' -ErrorAction SilentlyContinue | Remove-Module -Force
}
"@

    if ($Scope -eq 'Public') {
        $Body = @"

Describe '$FunctionName' -Tag 'Unit' {

    It 'should do something' {
        # TODO: Replace with real test
        `$true | Should -BeTrue
    }
}
"@
    }
    else {
        $Body = @"

Describe '$FunctionName' -Tag 'Unit' {

    It 'should do something' {
        InModuleScope '$ModuleName' {
            # TODO: Replace with real test
            `$true | Should -BeTrue
        }
    }

    It 'is not exported' {
        `$Exported = (Get-Module '$ModuleName').ExportedFunctions.Keys
        `$Exported | Should -Not -Contain '$FunctionName'
    }
}
"@
    }

    $Header + $Body
}
