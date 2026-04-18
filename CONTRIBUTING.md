# Contributing to Anvil

## Prerequisites

- **PowerShell 7.2+**

## Setup

```powershell
git clone git@github.com:f0oster/Anvil.git
cd Anvil
./build/bootstrap.ps1
```

## Development

```powershell
Invoke-Build -File ./build/module.build.ps1 -Task Lint, Test
```

Run the full pipeline before submitting:

```powershell
Invoke-Build -File ./build/module.build.ps1
```

To test your changes interactively:

```powershell
Import-Module ./src/Anvil/Anvil.psd1 -Force
```

## Conventions

- One function per file, filename matches function name
- Public functions in `src/Anvil/Public/`, private in `Private/`
- Always use `Join-Path` for path construction
- Pester 5 syntax only
- Tag tests with `'Unit'` or `'Integration'`
- Template tokens use `<%Name%>` for content and `__Name__` for paths
- Template manifests (`template.psd1`) are the source of truth for template parameters and conditions

## Testing

Unit tests cover individual functions. Integration tests scaffold real projects and verify the output. Both must pass before merging.

When adding a new private function, include an "is not exported" test in the test file.

## Pull requests

1. Branch from `main`
2. Run the full pipeline and ensure it passes
3. Open a PR against `main`
