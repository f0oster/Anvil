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

Describe 'Invoke-AnvilBootstrapDeps' -Tag 'Unit' {

    It 'errors when not inside an Anvil project' {
        $FakeDir = Join-Path ([IO.Path]::GetTempPath()) "NotAnvil_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $FakeDir -ItemType Directory -Force | Out-Null
        try {
            Invoke-AnvilBootstrapDeps -Path $FakeDir -ErrorAction SilentlyContinue -ErrorVariable err
            $err | Should -Not -BeNullOrEmpty
        } finally {
            Remove-Item $FakeDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'finds the bootstrap script in a valid project' {
        Invoke-AnvilBootstrapDeps -Path $ProjectRoot -Plan
    }
}
