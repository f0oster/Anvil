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

    # Scaffold a test project and seed some dependencies
    $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) "AnvilDepTest_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $script:TempRoot -ItemType Directory -Force | Out-Null

    $script:TestProject = New-AnvilModule -Name 'RemDepMod' -DestinationPath $script:TempRoot -Author 'Test' -PassThru -Confirm:$false
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
    if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
        Remove-Item -Path $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Remove-AnvilDependency' -Tag 'Unit' {

    BeforeAll {
        # Seed dependencies
        Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0' -Path $script:TestProject -Force -Confirm:$false
        Add-AnvilDependency -Name 'ImportExcel' -Path $script:TestProject -Force -Confirm:$false
    }

    It 'removes a dependency from requirements.psd1' {
        $Result = Remove-AnvilDependency -Name 'Az.Storage' -Path $script:TestProject -Force -Confirm:$false
        $Result.Name | Should -Be 'Az.Storage'
        $Result.Action | Should -Be 'Removed'

        $ReqPath = Join-Path $script:TestProject 'requirements.psd1'
        $Reqs = Import-PowerShellDataFile -Path $ReqPath
        $Reqs.ContainsKey('Az.Storage') | Should -BeFalse
        $Reqs['ImportExcel'] | Should -Be 'latest'
    }

    It 'errors when removing a dependency that does not exist' {
        Remove-AnvilDependency -Name 'NonExistent' -Path $script:TestProject -ErrorAction SilentlyContinue -ErrorVariable err -Confirm:$false
        $err | Should -Not -BeNullOrEmpty
        $err[0].Exception.Message | Should -Match 'not a declared dependency'
    }

    It 'removes the last dependency leaving an empty file' {
        Remove-AnvilDependency -Name 'ImportExcel' -Path $script:TestProject -Force -Confirm:$false

        $ReqPath = Join-Path $script:TestProject 'requirements.psd1'
        $Reqs = Import-PowerShellDataFile -Path $ReqPath
        $Reqs.Count | Should -Be 0
    }

}
