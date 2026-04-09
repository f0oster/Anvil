#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $ProjectRoot = $PSScriptRoot
    while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
        $ProjectRoot = Split-Path $ProjectRoot -Parent
    }
    $TemplateDir = Join-Path $ProjectRoot 'src' |
        Join-Path -ChildPath 'Anvil' |
        Join-Path -ChildPath 'Templates' |
        Join-Path -ChildPath 'Module'
}

Describe 'Template parity' -Tag 'Unit' {

    It '.editorconfig matches template' {
        $Anvil = Get-Content (Join-Path $ProjectRoot '.editorconfig') -Raw
        $Template = Get-Content (Join-Path $TemplateDir '.editorconfig') -Raw
        $Anvil | Should -Be $Template
    }

    It '.vscode/settings.json matches template' {
        $Anvil = Get-Content (Join-Path $ProjectRoot '.vscode/settings.json') -Raw
        $Template = Get-Content (Join-Path $TemplateDir '.vscode/settings.json') -Raw
        $Anvil | Should -Be $Template
    }

    It '.vscode/tasks.json matches template' {
        $Anvil = Get-Content (Join-Path $ProjectRoot '.vscode/tasks.json') -Raw
        $Template = Get-Content (Join-Path $TemplateDir '.vscode/tasks.json') -Raw
        $Anvil | Should -Be $Template
    }

    It '.vscode/extensions.json matches template' {
        $Anvil = Get-Content (Join-Path $ProjectRoot '.vscode/extensions.json') -Raw
        $Template = Get-Content (Join-Path $TemplateDir '.vscode/extensions.json') -Raw
        $Anvil | Should -Be $Template
    }

    It 'PSScriptAnalyzerSettings.psd1 matches template' {
        $Anvil = Get-Content (Join-Path $ProjectRoot 'PSScriptAnalyzerSettings.psd1') -Raw
        $Template = Get-Content (Join-Path $TemplateDir 'PSScriptAnalyzerSettings.psd1') -Raw
        $Anvil | Should -Be $Template
    }

    It 'build/analyzers/ScriptAnalyzerCustomRules.psm1 matches template' {
        $Anvil = Get-Content (Join-Path $ProjectRoot 'build/analyzers/ScriptAnalyzerCustomRules.psm1') -Raw
        $Template = Get-Content (Join-Path $TemplateDir 'build/analyzers/ScriptAnalyzerCustomRules.psm1') -Raw
        $Anvil | Should -Be $Template
    }
}
