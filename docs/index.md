# Anvil

Anvil is a PowerShell module scaffolder. It generates complete module projects with build pipelines, test infrastructure, linting, documentation, and CI/CD workflows so you can start writing code immediately instead of wiring up tooling.

## Why Anvil?

Setting up a PowerShell module project properly is tedious. You need InvokeBuild tasks, Pester configuration, PSScriptAnalyzer settings, code coverage, CI workflows, a bootstrap script, a compiled module build, and a publishing pipeline. You either copy-paste from your last project (inheriting its mistakes) or spend an afternoon getting it right.

Anvil does this in one command. The generated project follows community best practices: compiled modules for fast loading, separate source and build artifacts, automated formatting, and version injection from CI tags. Everything is opinionated but configurable.

## What you get

A scaffolded project includes:

- **Module source** with Public/Private/PrivateClasses layout and an `Imports.ps1` for module-scoped initialization
- **InvokeBuild pipeline** with Format, Lint, Test, Docs, Build, IntegrationTest, Package, and Publish tasks
- **Pester 5 tests** with unit test scaffolds for the sample functions and post-build integration tests that validate the compiled output
- **PSScriptAnalyzer** configuration with formatting rules and custom analyzers that catch common mistakes (nested functions, process blocks without pipeline parameters, smart quotes)
- **platyPS documentation** generation with a generate-once, update-on-subsequent-builds workflow
- **CI/CD workflows** for GitHub Actions, Azure Pipelines, or GitLab CI with tag-triggered releases
- **ModuleFast bootstrap** that installs build dependencies from a pinned manifest with zero prerequisite tooling

After scaffolding, Anvil provides commands to add functions, classes, tests, and module dependencies to the project without leaving the terminal.

## Quick start

```powershell
Install-Module -Name Anvil -Scope CurrentUser
New-AnvilModule -Interactive
```

See [Getting Started](getting-started.md) for the full walkthrough.

## Documentation

| Guide | What it covers |
|-------|---------------|
| [Getting Started](getting-started.md) | Scaffold a project, bootstrap, first build |
| [Development](development.md) | Adding functions, classes, dependencies, testing, the daily workflow |
| [Project Structure](project-structure.md) | What every file and directory does |
| [Build Pipeline](build-pipeline.md) | Every build task explained, settings reference |
| [CI/CD Integration](cicd-integration.md) | GitHub Actions, Azure Pipelines, GitLab CI setup |
| [Customization](customization.md) | Custom lint rules, types, formats, build tasks |
| [FAQ](faq.md) | Common issues and troubleshooting |

## Command reference

| Command | Purpose |
|---------|---------|
| [New-AnvilModule](commands/New-AnvilModule.md) | Scaffold a new module project |
| [New-AnvilFunction](commands/New-AnvilFunction.md) | Add a function and its test to a project |
| [New-AnvilClass](commands/New-AnvilClass.md) | Add a PowerShell class and its test |
| [New-AnvilTest](commands/New-AnvilTest.md) | Add a standalone test file |
| [Add-AnvilDependency](commands/Add-AnvilDependency.md) | Declare a module dependency |
| [Remove-AnvilDependency](commands/Remove-AnvilDependency.md) | Remove a module dependency |
| [Invoke-AnvilBootstrapDeps](commands/Invoke-AnvilBootstrapDeps.md) | Install build tools and module dependencies |
| [Import-AnvilModule](commands/Import-AnvilModule.md) | Import the development module from the current project |
| [Get-AnvilTemplate](commands/Get-AnvilTemplate.md) | List available templates and CI providers |
