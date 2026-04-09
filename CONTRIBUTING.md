# Contributing to Anvil

## Prerequisites

- **PowerShell 7.2+** (required by the bootstrap script and ModuleFast)
- No other tooling required — the bootstrap script handles everything.

## Setup

```powershell
git clone git@github.com:f0oster/Anvil.git
cd Anvil
./build/bootstrap.ps1
```

## Development loop

```powershell
Invoke-Build -File ./build/module.build.ps1 -Task Lint, Test
```

## Conventions

- One function per file, filename matches function name.
- Public functions in `src/Anvil/Public/`, private in `Private/`.
- Always use `Join-Path` — never backslash concatenation.
- Pester 5 syntax only (`New-PesterConfiguration`, `BeforeAll`, `BeforeDiscovery`).
- Tag tests with `'Unit'` or `'Integration'`.

## Pull requests

1. Branch from `main`
2. Run `Invoke-Build -File ./build/module.build.ps1` — ensure it passes
3. Open a PR against `main`
