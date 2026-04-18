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

    It 'includes the Module template' {
        $Results = Get-AnvilTemplate
        $Module = $Results | Where-Object { $_.Name -eq 'Module' }
        $Module | Should -Not -BeNullOrEmpty
    }

    It 'returns objects with expected properties' {
        $Results = Get-AnvilTemplate
        $First = $Results | Select-Object -First 1
        $First.PSObject.Properties.Name | Should -Contain 'Name'
        $First.PSObject.Properties.Name | Should -Contain 'Type'
        $First.PSObject.Properties.Name | Should -Contain 'Description'
        $First.PSObject.Properties.Name | Should -Contain 'Version'
        $First.PSObject.Properties.Name | Should -Contain 'Parameters'
        $First.PSObject.Properties.Name | Should -Contain 'FileCount'
        $First.PSObject.Properties.Name | Should -Contain 'Layers'
        $First.PSObject.Properties.Name | Should -Contain 'Path'
    }

    It 'reads manifest metadata for the Module template' {
        $Results = Get-AnvilTemplate
        $Module = $Results | Where-Object { $_.Name -eq 'Module' }
        $Module.Description | Should -Not -BeNullOrEmpty
        $Module.Version | Should -Not -BeNullOrEmpty
        $Module.Parameters | Should -Not -BeNullOrEmpty
        $Module.Parameters | Should -Contain 'Name'
        $Module.Parameters | Should -Contain 'Author'
    }

    It 'excludes template.psd1 from file count' {
        $Results = Get-AnvilTemplate
        $Module = $Results | Where-Object { $_.Name -eq 'Module' }
        $ManifestFile = Join-Path $Module.Path 'template.psd1'
        $ManifestFile | Should -Exist
        $AllFiles = (Get-ChildItem -Path $Module.Path -File -Recurse -Force).Count
        $Module.FileCount | Should -BeLessThan $AllFiles
    }

    Context 'Layers' {

        It 'discovers CI providers as layers on the Module template' {
            $Results = Get-AnvilTemplate
            $Module = $Results | Where-Object { $_.Name -eq 'Module' }
            $Module.Layers | Should -Not -BeNullOrEmpty
            $Module.Layers.Name | Should -Contain 'GitHub'
            $Module.Layers.Name | Should -Contain 'AzurePipelines'
            $Module.Layers.Name | Should -Contain 'GitLab'
        }

        It 'layer objects have expected properties' {
            $Results = Get-AnvilTemplate
            $Module = $Results | Where-Object { $_.Name -eq 'Module' }
            $GitHub = $Module.Layers | Where-Object { $_.Name -eq 'GitHub' }
            $GitHub.PathKey | Should -Be 'CIProvider'
            $GitHub.FileCount | Should -BeGreaterThan 0
            $GitHub.Path | Should -Not -BeNullOrEmpty
        }

        It 'does not include the Skip value as a layer' {
            $Results = Get-AnvilTemplate
            $Module = $Results | Where-Object { $_.Name -eq 'Module' }
            $Module.Layers.Name | Should -Not -Contain 'None'
        }
    }

    It 'only discovers templates with a manifest' {
        $Results = Get-AnvilTemplate
        $Results | ForEach-Object {
            $ManifestFile = Join-Path $_.Path 'template.psd1'
            $ManifestFile | Should -Exist
        }
    }
}
