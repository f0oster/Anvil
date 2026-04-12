# Anvil

[![CI][ci-badge]][ci-link]
[![License][license-badge]][license-link]

Anvil helps you create, develop, and ship PowerShell modules. It scaffolds a complete project structure with build pipelines, testing, linting, and CI/CD — then stays useful as you add functions, manage dependencies, and iterate.

> **Note:** Anvil is in early development. Expect breaking changes, incomplete features, and rough edges. Not yet published to the PowerShell Gallery.

## Features

- Scaffold a new module project that's ready to go from a single command
- Helpers to add functions, classes, tests, and dependencies to your module as you develop from the terminal
- A build process that auto-formats your code, lints it, runs tests with coverage, generates docs, compiles a single-file module, and packages it for publishing
  - Pester (v5) test harness, with code coverage reporting and thresholds
  - PSScriptAnalyzer linting with custom rules that ship with the project, and a simple process for adding your own
  - Narkdown documentation generation using platyPS
  - Anvil bootstraps its own build dependencies and your runtime dependencies during development via [ModuleFast](https://github.com/JustinGrote/ModuleFast)
- CI/CD workflows for GitHub Actions, Azure Pipelines (untested), and GitLab CI (untested)
- Can build modules that are compatible with PowerShell 5.1, but authoring requires PowerShell >=7.2

## Installation

```powershell
Install-Module -Name Anvil -Scope CurrentUser
```

## Quick Start

Scaffold a new module:

```powershell
$Params = @{
    Name            = 'NetworkTools'
    DestinationPath = '~/Projects'
    Author          = 'Jane Doe'
    CIProvider      = 'GitHub'
    GitInit         = $true
}
New-AnvilModule @Params
```

Or run `New-AnvilModule -Interactive` for a guided wizard.

Bootstrap and build:

```powershell
cd ~/Projects/NetworkTools
Invoke-AnvilBootstrapDeps
Invoke-Build -File ./build/module.build.ps1
```

Then keep developing — Anvil stays with you after scaffolding:

```powershell
New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public
New-AnvilFunction -FunctionName 'Format-Row' -Scope Private
New-AnvilClass -ClassName 'HttpClient'
Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0'
Invoke-AnvilBootstrapDeps
Import-AnvilModule
```

## What you get

```
NetworkTools/
├── src/NetworkTools/          Module source (Public/, Private/, PrivateClasses/)
├── build/                     InvokeBuild pipeline, bootstrap, settings
├── tests/                     Pester 5 unit and integration tests
├── docs/                      platyPS documentation
├── requirements.psd1          Module dependencies
├── .github/workflows/         CI/CD (or Azure Pipelines / GitLab CI)
├── PSScriptAnalyzerSettings.psd1
├── .editorconfig, .vscode/
├── README.md, CONTRIBUTING.md, LICENSE
└── .gitignore
```

## Documentation

- [Getting Started](docs/getting-started.md) — scaffold a project, bootstrap, first build
- [Development](docs/development.md) — adding functions, classes, dependencies, testing, the daily workflow
- [Project Structure](docs/project-structure.md) — what every file and directory does
- [Build Pipeline](docs/build-pipeline.md) — every build task explained, settings reference
- [CI/CD Integration](docs/cicd-integration.md) — GitHub Actions, Azure Pipelines, GitLab CI
- [Customization](docs/customization.md) — custom lint rules, types, formats, build tasks
- [FAQ](docs/faq.md) — common questions and troubleshooting
- [Command Reference](docs/commands/) — detailed help for all commands

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

[MIT](LICENSE)

## Acknowledgements

Heavily inspired by [Catesta](https://github.com/techthoughts2/Catesta). See the [FAQ](docs/faq.md#anvil-was-heavily-inspired-by-catesta-but-how-does-it-differ) for how Anvil differs.

<!-- Badge links -->
[ci-badge]: https://github.com/f0oster/Anvil/actions/workflows/ci.yml/badge.svg?branch=main
[ci-link]: https://github.com/f0oster/Anvil/actions/workflows/ci.yml
[license-badge]: https://img.shields.io/badge/license-MIT-blue
[license-link]: https://github.com/f0oster/Anvil/blob/main/LICENSE
