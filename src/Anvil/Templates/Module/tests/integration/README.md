# Integration Tests

Integration tests validate the build pipeline's output. Unlike unit tests (which test source code from `src/`), these tests exercise the compiled artifacts in `artifacts/package/` -- the same files that would be published to the PowerShell Gallery.

## Directory layout

```
tests/integration/
    README.md
    BuildArtifacts.Tests.ps1   # Validates compiled module structure
```

## Running tests

Integration tests require a successful build first:

```powershell
# Build then run integration tests
Invoke-Build Build, IntegrationTest

# Or run the full pipeline (includes integration tests)
Invoke-Build
```

To run integration tests directly (after building):

```powershell
Invoke-Pester -Path tests/integration -Tag 'Integration'
```

## How integration tests differ from unit tests

| | Unit tests | Integration tests |
|---|---|---|
| **Import from** | `src/YourModule/` | `artifacts/package/YourModule/` |
| **Test target** | Individual functions | Compiled build output |
| **InModuleScope** | Yes, for private functions | No -- only public interface |
| **When they run** | `Invoke-Build Test` | `Invoke-Build IntegrationTest` (after Build) |
| **Tag** | `Unit` | `Integration` |

## What to test here

Integration tests should verify things that only matter after compilation:

- The compiled `.psm1` is a single file (no dot-sourcing of individual `.ps1` files)
- The staged manifest is valid and importable
- `Export-ModuleMember` is present in the compiled module
- Required assemblies or nested modules are included
- Help XML files are generated (if using PlatyPS)

Do **not** test individual function behavior here -- that belongs in unit tests. Integration tests answer: "did the build produce a valid, publishable module?"

## Extending

Add new `Context` blocks to `BuildArtifacts.Tests.ps1` for additional artifact checks, or create new `.Tests.ps1` files for distinct integration scenarios (e.g. testing against a real API, database, or service).
