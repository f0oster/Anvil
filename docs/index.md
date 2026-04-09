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

After scaffolding, Anvil provides commands to add functions, classes, and tests to the project without leaving the terminal.

## Quick start

```powershell
Install-Module -Name Anvil -Scope CurrentUser
New-AnvilModule
```

With no arguments, Anvil runs an interactive wizard. It detects your name from `git config`, defaults to the current directory, and prompts for everything else. Press Enter to accept defaults.

Or pass everything up front:

```powershell
$Params = @{
    Name            = 'NetworkTools'
    DestinationPath = '~/Projects'
    Author          = 'Jane Doe'
    CIProvider      = 'GitHub'
    IncludeDocs     = $true
    GitInit         = $true
}
New-AnvilModule @Params
```

Then build:

```powershell
cd ~/Projects/NetworkTools
./build/bootstrap.ps1
Invoke-Build -File ./build/module.build.ps1
```

The first build installs Pester, PSScriptAnalyzer, InvokeBuild, and platyPS into a user-scoped location via ModuleFast, then runs the full pipeline. Subsequent builds skip the install if the tools are already present.

## Documentation

| Guide | What it covers |
|-------|---------------|
| [Getting Started](getting-started.md) | Create a module, add functions, run tests, build |
| [Project Structure](project-structure.md) | What every file and directory does |
| [Build Pipeline](build-pipeline.md) | Every build task explained, with customization guidance |
| [CI/CD Integration](cicd-integration.md) | GitHub Actions, Azure Pipelines, GitLab CI setup |
| [Customization](customization.md) | Classes, custom lint rules, types, formats, and more |
| [FAQ](faq.md) | Common issues and how to resolve them |

## Command reference

| Command | Purpose |
|---------|---------|
| [New-AnvilModule](commands/New-AnvilModule.md) | Scaffold a new module project |
| [New-AnvilFunction](commands/New-AnvilFunction.md) | Add a function and its test to a project |
| [New-AnvilClass](commands/New-AnvilClass.md) | Add a PowerShell class and its test |
| [New-AnvilTest](commands/New-AnvilTest.md) | Add a standalone test file |
| [Get-AnvilTemplate](commands/Get-AnvilTemplate.md) | List available templates and CI providers |
