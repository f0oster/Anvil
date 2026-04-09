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

Describe 'Get-AnvilTemplate' -Tag 'Unit' {

    It 'returns results' {
        $Results = Get-AnvilTemplate
        $Results | Should -Not -BeNullOrEmpty
    }

    It 'includes base templates' {
        $Results = Get-AnvilTemplate
        $Base = $Results | Where-Object { $_.Type -eq 'BaseTemplate' }
        $Base | Should -Not -BeNullOrEmpty
    }

    It 'includes CI providers' {
        $Results = Get-AnvilTemplate
        $CI = $Results | Where-Object { $_.Type -eq 'CIProvider' }
        $CI | Should -Not -BeNullOrEmpty
    }

    It 'includes the Module base template' {
        $Results = Get-AnvilTemplate
        $Module = $Results | Where-Object { $_.Name -eq 'Module' -and $_.Type -eq 'BaseTemplate' }
        $Module | Should -Not -BeNullOrEmpty
    }

    It 'includes GitHub as a CI provider' {
        $Results = Get-AnvilTemplate
        $GitHub = $Results | Where-Object { $_.Name -eq 'GitHub' -and $_.Type -eq 'CIProvider' }
        $GitHub | Should -Not -BeNullOrEmpty
    }

    It 'returns objects with expected properties' {
        $Results = Get-AnvilTemplate
        $First = $Results | Select-Object -First 1
        $First.PSObject.Properties.Name | Should -Contain 'Name'
        $First.PSObject.Properties.Name | Should -Contain 'Type'
        $First.PSObject.Properties.Name | Should -Contain 'FileCount'
        $First.PSObject.Properties.Name | Should -Contain 'Path'
    }
}
