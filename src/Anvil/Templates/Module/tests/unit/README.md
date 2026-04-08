# Unit Tests

Unit tests validate your module's source code directly. They import the module from `src/` and test individual functions in isolation.

## Directory layout

```
tests/unit/
    YourModule.Module.Tests.ps1   # Module-level tests (manifest, imports, exports)
    Public/                       # One test file per public function
        README.md
        Get-Greeting.Tests.ps1
    Private/                      # One test file per private function
        README.md
        Format-GreetingText.Tests.ps1
```

## Running tests

```powershell
# Run all unit tests
Invoke-Pester -Path tests/unit -Tag 'Unit'

# Run a single test file
Invoke-Pester -Path tests/unit/Public/Get-Greeting.Tests.ps1
```

Or through the build pipeline:

```powershell
Invoke-Build Test
```

## Pester 5 concepts

### Two-phase execution: Discovery and Run

Pester 5 runs your test files twice. Understanding this is critical for writing correct tests.

**Discovery phase** -- Pester reads the file to find all `Describe`, `Context`, and `It` blocks. Code at the top level of the file (outside `BeforeAll`/`BeforeEach`) runs during this phase. `BeforeDiscovery` is a named wrapper that signals "this code intentionally runs during Discovery."

**Run phase** -- Pester executes the tests it found. `BeforeAll`, `BeforeEach`, `It`, `AfterEach`, and `AfterAll` all run during this phase.

**Why it matters:** A variable defined during Discovery (in `BeforeDiscovery` or at script level) is not available inside `It` blocks during the Run phase. If you need data for both test generation (`-ForEach`) and assertions (`It`), define it in both places.

### BeforeDiscovery vs BeforeAll

| | BeforeDiscovery | BeforeAll |
|---|---|---|
| **When** | Discovery phase | Run phase |
| **Purpose** | Generate test data for `-ForEach` | Set up state for `It` blocks |
| **Variables visible in** | `-ForEach` parameters only | All child `It` blocks (read-only) |

Example from `YourModule.Module.Tests.ps1`:

```powershell
BeforeDiscovery {
    # $DeclaredFunctions drives -ForEach to generate one It per function
    $ManifestData      = Import-PowerShellDataFile -Path $ManifestPath
    $DeclaredFunctions = @($ManifestData.FunctionsToExport)
}

BeforeAll {
    # $ExpectedFunctionCount is used inside an It block for a count assertion
    $ManifestData = Import-PowerShellDataFile -Path $ManifestPath
    $ExpectedFunctionCount = @($ManifestData.FunctionsToExport).Count
}
```

See: https://pester.dev/docs/usage/data-driven-tests

### Data-driven tests with -ForEach

`-ForEach` generates one test per item in an array. Use `$_` to reference the current item, and `<_>` in the test name:

```powershell
It 'exports <_>' -ForEach $DeclaredFunctions {
    $Exported = (Get-Module 'YourModule').ExportedFunctions.Keys
    $_ | Should -BeIn $Exported
}
```

With hashtable arrays, keys become variables:

```powershell
It 'converts <Input> to <Expected>' -ForEach @(
    @{ Input = 'hello'; Expected = 'HELLO' }
    @{ Input = 'world'; Expected = 'WORLD' }
) {
    ConvertTo-Upper $Input | Should -Be $Expected
}
```

### Project root discovery

All test files use a walk-up pattern to find the project root, making tests resilient to directory restructuring:

```powershell
$ProjectRoot = $PSScriptRoot
while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
    $ProjectRoot = Split-Path $ProjectRoot -Parent
}
```

This searches up from the test file's location until it finds `build/build.settings.psd1`, which anchors the project root regardless of how deeply nested the test file is.
