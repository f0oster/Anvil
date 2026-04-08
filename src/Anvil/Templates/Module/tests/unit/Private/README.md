# Private Function Tests

Tests in this directory validate your module's internal (private) functions -- commands that are not exported and cannot be called by users directly.

## Adding a new test file

1. Create `<FunctionName>.Tests.ps1` in this directory
2. Use `Format-GreetingText.Tests.ps1` as a starting point
3. Always include an "is not exported" test to verify the function stays private

## When to test private functions

Private functions with meaningful logic (parsing, formatting, validation) benefit from direct tests. If a private function is a trivial wrapper or one-liner, testing the public function that calls it is usually sufficient.

## Structure

Every private function test uses `InModuleScope` to reach inside the module:

```powershell
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $ProjectRoot = $PSScriptRoot
    while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
        $ProjectRoot = Split-Path $ProjectRoot -Parent
    }

    $ModuleName   = 'YourModule'
    $ModuleDir    = Join-Path -Path $ProjectRoot -ChildPath 'src' | Join-Path -ChildPath $ModuleName
    $ManifestPath = Join-Path -Path $ModuleDir -ChildPath "$ModuleName.psd1"

    Get-Module -Name $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $ManifestPath -Force -ErrorAction Stop
}

AfterAll {
    Get-Module -Name 'YourModule' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'Some-PrivateFunction' -Tag 'Unit' {
    It 'does the expected thing' {
        InModuleScope 'YourModule' {
            Some-PrivateFunction -Name 'test' | Should -Be 'expected'
        }
    }

    It 'is not exported' {
        $Exported = (Get-Module 'YourModule').ExportedFunctions.Keys
        $Exported | Should -Not -Contain 'Some-PrivateFunction'
    }
}
```

## Key concepts

### InModuleScope

`InModuleScope` executes a scriptblock inside the module's session state, where private functions are visible. Always place it **inside individual `It` blocks** -- never around `Describe` or `Context`.

Wrapping outer blocks in `InModuleScope` causes problems:
- Prevents Pester from verifying that public functions are actually exported
- Slows down test discovery by forcing module loading during the Discovery phase

See: https://pester.dev/docs/usage/modules#testing-private-functions

### Passing data into InModuleScope

Variables from the test scope are **not automatically visible** inside `InModuleScope`. Use `-ArgumentList` with a matching `param()` block:

```powershell
It 'validates the configuration' {
    $Config = @{ Name = 'Test'; Value = 42 }
    InModuleScope 'YourModule' -ArgumentList $Config {
        param($Config)
        Assert-ValidConfig -Configuration $Config | Should -Not -Throw
    }
}
```

### Verifying a function is not exported

Always include a test that confirms the function stays private. This catches accidental additions to `FunctionsToExport` in the manifest:

```powershell
It 'is not exported' {
    $Exported = (Get-Module 'YourModule').ExportedFunctions.Keys
    $Exported | Should -Not -Contain 'Some-PrivateFunction'
}
```

This test does **not** need `InModuleScope` because it checks the module's public interface from the outside.
