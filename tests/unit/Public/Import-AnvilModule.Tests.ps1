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

    $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) "AnvilImportTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $script:TempRoot -ItemType Directory -Force | Out-Null
    $script:TestProject = New-AnvilModule -Name 'ImportTestMod' -DestinationPath $script:TempRoot -Author 'Test' -PassThru -Confirm:$false
}

AfterAll {
    Get-Module -Name 'ImportTestMod' -ErrorAction SilentlyContinue | Remove-Module -Force
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
    if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
        Remove-Item -Path $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Import-AnvilModule' -Tag 'Unit' {

    It 'imports the development module from a project path' {
        Get-Module -Name 'ImportTestMod' -ErrorAction SilentlyContinue | Remove-Module -Force
        Import-AnvilModule -Path $script:TestProject
        $Mod = Get-Module -Name 'ImportTestMod'
        $Mod | Should -Not -BeNullOrEmpty
    }

    It 'returns module info with -PassThru' {
        $Result = Import-AnvilModule -Path $script:TestProject -PassThru
        $Result | Should -Not -BeNullOrEmpty
        $Result.Name | Should -Be 'ImportTestMod'
    }

    It 'errors when not inside an Anvil project' {
        $FakeDir = Join-Path ([IO.Path]::GetTempPath()) "NotAnvil_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $FakeDir -ItemType Directory -Force | Out-Null
        try {
            Import-AnvilModule -Path $FakeDir -ErrorAction SilentlyContinue -ErrorVariable err
            $err | Should -Not -BeNullOrEmpty
        } finally {
            Remove-Item $FakeDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
