# Public Function Tests

Tests in this directory validate your module's exported (public) functions -- the commands your users call directly.

## Adding a new test file

1. Create `<FunctionName>.Tests.ps1` in this directory
2. Use `Get-Greeting.Tests.ps1` as a starting point

## Structure

Every public function test file follows this pattern:

```powershell
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    # Walk up to find the project root
    $ProjectRoot = $PSScriptRoot
    while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
        $ProjectRoot = Split-Path $ProjectRoot -Parent
    }

    $ModuleName   = 'YourModule'
    $ModuleDir    = Join-Path -Path $ProjectRoot -ChildPath 'src' | Join-Path -ChildPath $ModuleName
    $ManifestPath = Join-Path -Path $ModuleDir -ChildPath "$ModuleName.psd1"

    # Import the module fresh
    Get-Module -Name $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $ManifestPath -Force -ErrorAction Stop
}

AfterAll {
    Get-Module -Name 'YourModule' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'Get-Something' -Tag 'Unit' {
    It 'does the expected thing' {
        Get-Something | Should -Be 'expected value'
    }
}
```

## Key concepts

### BeforeAll / AfterAll

`BeforeAll` runs once before all tests in the file. Import your module here so every `It` block can call the function by name. Variables defined in `BeforeAll` are visible (read-only) to all child blocks.

`AfterAll` cleans up after all tests so the module does not leak into other test files.

### No special scoping needed

Public functions are exported and available by name after `Import-Module`. Call them exactly as a user would -- no `InModuleScope` required.

### Mocking

When your function calls other commands internally, use `Mock` with `-ModuleName` to inject the mock into the module's scope:

```powershell
It 'uses today''s date' {
    Mock -ModuleName 'YourModule' Get-Date { [datetime]'2025-01-01' }
    Get-Something | Should -Be '2025-01-01'
}
```

Without `-ModuleName`, the mock only exists in the test scope and the module's internal call to `Get-Date` will hit the real command.

See: https://pester.dev/docs/usage/mocking

### Assertions

Pester provides many assertion operators:

- `Should -Be` -- exact equality
- `Should -BeExactly` -- case-sensitive equality
- `Should -BeLike` -- wildcard match
- `Should -Match` -- regex match
- `Should -Throw` -- expects an error
- `Should -Exist` -- file/directory exists
- `Should -BeNullOrEmpty` / `Should -Not -BeNullOrEmpty`

Full reference: https://pester.dev/docs/assertions

### Tags

`-Tag 'Unit'` on the `Describe` block allows selective execution:

```powershell
Invoke-Pester -Tag 'Unit'        # run only unit tests
Invoke-Pester -ExcludeTag 'Slow' # skip slow tests
```
