# Getting Started

This guide walks through creating a module from scratch, adding real functionality, running the build, and understanding the development loop.

## Prerequisites

You need **PowerShell 7.2 or later** for building. This is a firm requirement because ModuleFast (the dependency installer) needs it. The module you create can target any version down to 5.1 — the build tooling and the runtime target are separate concerns.

You don't need to install InvokeBuild, Pester, PSScriptAnalyzer, or platyPS manually. The bootstrap script handles all of that.

Git is optional but recommended. If you pass `-GitInit`, Anvil creates a repository with an initial commit. If git is on your PATH, the interactive wizard also detects your name from `git config user.name`.

## Creating a module

### The interactive way

The `-Interactive` switch starts a guided wizard:

```powershell
New-AnvilModule -Interactive
```

You'll see prompts for module name, destination, author, description, CI provider, license, and more. Each prompt shows a default in brackets — press Enter to accept it. The author name is pulled from your git config if available.

You can also pre-fill some parameters and let the wizard prompt for the rest:

```powershell
New-AnvilModule -Interactive -Name 'NetworkTools' -Author 'Jane Doe'
```

This is the fastest way to get started if you're exploring. Every value can be overridden later by editing the generated files.

### The scripted way

For repeatable scaffolding (or CI-driven project creation), pass parameters directly:

```powershell
$Params = @{
    Name                 = 'NetworkTools'
    DestinationPath      = '~/Projects'
    Author               = 'Jane Doe'
    Description          = 'Cmdlets for network diagnostics and monitoring.'
    CompanyName          = 'Contoso'
    CIProvider           = 'GitHub'
    License              = 'MIT'
    MinPowerShellVersion = '7.2'
    CompatiblePSEditions = @('Core')
    Tags                 = @('Network', 'Diagnostics')
    IncludeDocs          = $true
    GitInit              = $true
}
New-AnvilModule @Params
```

Without `-Interactive`, Anvil applies defaults silently for any optional parameters not specified. `-Name`, `-DestinationPath`, and `-Author` are required.

### What happens next

Anvil creates a `NetworkTools/` directory with the full project structure, prints a summary, and (if `-GitInit` was set) commits everything. You'll see output like:

```
[Anvil] Creating project: NetworkTools
[Anvil] Destination: ~/Projects/NetworkTools
[Anvil] Base template: 34 files
[Anvil] CI (GitHub): 2 files

[Anvil] Project 'NetworkTools' scaffolded successfully!
[Anvil] Next steps:
  cd ~/Projects/NetworkTools
  ./build/bootstrap.ps1
  Invoke-Build -File ./build/module.build.ps1
```

## First build

```powershell
cd ~/Projects/NetworkTools
./build/bootstrap.ps1
Invoke-Build -File ./build/module.build.ps1
```

The bootstrap script uses [ModuleFast](https://github.com/JustinGrote/ModuleFast) to install pinned versions of InvokeBuild, Pester, PSScriptAnalyzer, and platyPS into your user module path. This takes a few seconds on first run and is near-instant on subsequent runs.

The build pipeline then runs: Clean, Validate, Format, Lint, Test, Docs, Build, IntegrationTest, Package.

The scaffolded project comes with a sample public function (`Get-Greeting`), a sample private function (`Format-GreetingText`), a sample class (`GreetingBuilder`), and tests for all three. The first build should pass out of the box — if it doesn't, that's a bug in Anvil.

## What to do next

At this point you have a working module with sample code and a green build. Read [Development](development.md) to learn the day-to-day workflow — adding functions, managing dependencies, running tests, and building.

Other useful references:

- [Project Structure](project-structure.md) — what every file and directory does
- [Build Pipeline](build-pipeline.md) — every build task explained
- [CI/CD Integration](cicd-integration.md) — setting up GitHub Actions, Azure Pipelines, or GitLab CI
