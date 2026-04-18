# Unit Tests

Unit tests validate source code from `src/`. Each function and class has a matching test file in the corresponding subdirectory.

```
tests/unit/
    YourModule.Module.Tests.ps1       Module-level tests (manifest, imports, exports)
    Public/                           One test file per public function
    Private/                          One test file per private function
    PrivateClasses/                   One test file per class
```

Add tests with `New-AnvilFunction` (creates both function and test) or `New-AnvilTest` (creates a test only).

Run with `Invoke-AnvilBuild -Task Test` or directly with `Invoke-Pester -Path tests/unit`.
