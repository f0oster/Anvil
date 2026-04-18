# Anvil

[![CI][ci-badge]][ci-link]
[![PowerShell Gallery][gallery-badge]][gallery-link]
[![License][license-badge]][license-link]

Anvil scaffolds PowerShell module projects with a working build pipeline, test infrastructure, linting, and CI/CD. It also provides commands for adding functions, classes, and dependencies as you develop.

## Installation

```powershell
Install-Module -Name Anvil -Scope CurrentUser
```

Requires PowerShell 7.2 or later. Modules you build can target any version down to 5.1.

## Create a module

```powershell
New-AnvilModule -Interactive
```

This walks you through naming the module, choosing a CI provider, selecting a license, and configuring build options. When it finishes, you have a complete project that builds, lints, tests, and packages out of the box:

```powershell
cd MyModule
Invoke-AnvilBootstrapDeps
Invoke-AnvilBuild
```

For scripted or CI-driven usage, pass parameters directly:

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

## Project structure

```
NetworkTools/
├── src/NetworkTools/          Module source (Public/, Private/, PrivateClasses/)
├── build/                     InvokeBuild pipeline, bootstrap, settings
├── tests/                     Pester 5 unit and integration tests
├── docs/                      Documentation
├── requirements.psd1          Module dependencies
├── .github/workflows/         CI/CD (or Azure Pipelines / GitLab CI)
├── PSScriptAnalyzerSettings.psd1
├── .editorconfig, .vscode/
├── README.md, CONTRIBUTING.md, LICENSE
└── .gitignore
```

The build pipeline handles formatting, linting, unit tests with code coverage, module compilation into a single distributable file, integration tests, and packaging. Build dependencies are bootstrapped automatically — nothing to install manually beyond Anvil itself.

CI/CD workflows are included for GitHub Actions, Azure Pipelines, or GitLab CI, with tag-triggered releases to the PowerShell Gallery.

## Developing with Anvil

After scaffolding, Anvil provides commands for common tasks:

```powershell
New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public    # creates function + test
New-AnvilFunction -FunctionName 'Format-Row' -Scope Private   # internal helper + test
New-AnvilClass -ClassName 'WidgetResult'                      # class + test
Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0'    # adds to manifest + requirements
Import-AnvilModule                                            # reload for interactive testing
```

## Custom templates

Anvil's scaffolding is driven by a manifest-based template system. You can create your own templates with custom parameters, conditions, and file structures. See [Template Authoring](docs/template-authoring.md).

## Documentation

| | |
|---|---|
| [Getting Started](docs/getting-started.md) | Scaffold a project, bootstrap, first build |
| [Reference](docs/reference.md) | Project structure, build pipeline, CI/CD, customization |
| [Template Authoring](docs/template-authoring.md) | Creating custom templates |
| [Command Reference](docs/commands/) | Detailed help for all commands |
| [FAQ](docs/faq.md) | Troubleshooting |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

[MIT](LICENSE)

## Acknowledgements

Anvil builds on and is inspired by the work of these projects:

| Project | License | Role |
|---------|---------|------|
| [Catesta](https://github.com/techthoughts2/Catesta) | MIT | Inspiration for Anvil's design |
| [InvokeBuild](https://github.com/nightroman/Invoke-Build) | Apache 2.0 | Build pipeline engine |
| [ModuleFast](https://github.com/JustinGrote/ModuleFast) | MIT | Dependency bootstrapping |
| [Pester](https://github.com/pester/Pester) | Apache 2.0 | Test framework |
| [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) | MIT | Linting and formatting |
| [PSResourceGet](https://github.com/PowerShell/PSResourceGet) | MIT | Module publishing |
| [platyPS](https://github.com/PowerShell/platyPS) | MIT | Documentation generation |
| [Indented.ScriptAnalyzerRules](https://github.com/indented-automation/Indented.ScriptAnalyzerRules) | MIT | Custom PSScriptAnalyzer rules |

<!-- Badge links -->
[ci-badge]: https://github.com/f0oster/Anvil/actions/workflows/ci.yml/badge.svg?branch=main
[ci-link]: https://github.com/f0oster/Anvil/actions/workflows/ci.yml
[gallery-badge]: https://img.shields.io/powershellgallery/v/Anvil
[gallery-link]: https://www.powershellgallery.com/packages/Anvil
[license-badge]: https://img.shields.io/badge/license-MIT-blue
[license-link]: https://github.com/f0oster/Anvil/blob/main/LICENSE
