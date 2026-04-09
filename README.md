# Anvil

[![CI][ci-badge]][ci-link]
[![License][license-badge]][license-link]

Scaffold production-grade PowerShell module projects with opinionated build, test, lint, and CI/CD pipelines — so you can start writing code, not boilerplate.

> **Note:** Anvil is in early development. Expect breaking changes, incomplete features, and rough edges. Not yet published to the PowerShell Gallery.

## Features

- Scaffold a complete module project from a single command
- InvokeBuild pipeline: lint, test, build, package, publish
- Pester 5 test infrastructure with code coverage enforcement
- PSScriptAnalyzer linting with custom rules
- CI/CD workflows for GitHub Actions, Azure Pipelines, and GitLab CI
- Optional platyPS documentation generation
- Zero runtime dependencies — build tools bootstrapped via [ModuleFast](https://github.com/JustinGrote/ModuleFast)
- Target PowerShell 5.1+ at runtime while building on 7.2+

## Installation

```powershell
Install-Module -Name Anvil -Scope CurrentUser
```

## Quick Start

### Scaffold a new module

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

Or run `New-AnvilModule` with no parameters for an interactive wizard.

### Build it

```powershell
cd ~/Projects/NetworkTools
./build/bootstrap.ps1
Invoke-Build -File ./build/module.build.ps1
```

### Add functions and classes

```powershell
New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public
New-AnvilFunction -FunctionName 'Format-Row' -Scope Private
New-AnvilClass -ClassName 'HttpClient'
New-AnvilTest -Name 'Get-Widget' -Scope Public
```

## Documentation

Full documentation is available in the [docs](docs/) directory:

- [Getting Started](docs/getting-started.md) - step-by-step guide
- [Project Structure](docs/project-structure.md) - what gets generated and why
- [Build Pipeline](docs/build-pipeline.md) - task reference and customization
- [CI/CD Integration](docs/cicd-integration.md) - GitHub Actions, Azure Pipelines, GitLab CI
- [Customization](docs/customization.md) - classes, custom analyzers, types, formats
- [FAQ](docs/faq.md) - common questions and troubleshooting
- [Command Reference](docs/commands/) - detailed help for all commands

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

[MIT](LICENSE)

<!-- Badge links -->
[ci-badge]: https://github.com/f0oster/Anvil/actions/workflows/ci.yml/badge.svg?branch=main
[ci-link]: https://github.com/f0oster/Anvil/actions/workflows/ci.yml
[license-badge]: https://img.shields.io/badge/license-MIT-blue
[license-link]: https://github.com/f0oster/Anvil/blob/main/LICENSE
