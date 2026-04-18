# Getting Started

## Prerequisites

You need **PowerShell 7.2 or later** for building. The module you create can target any version down to 5.1 — the build tooling and the runtime target are separate concerns.

You do not need to install InvokeBuild, Pester, PSScriptAnalyzer, or platyPS manually. The bootstrap script handles all of that.

## Creating a module

The `-Interactive` switch starts a guided wizard:

```powershell
New-AnvilModule -Interactive
```

You can also pre-fill parameters and let the wizard prompt for the rest:

```powershell
New-AnvilModule -Interactive -Name 'NetworkTools' -Author 'Jane Doe'
```

For repeatable scaffolding, pass parameters directly:

```powershell
$Params = @{
    Name            = 'NetworkTools'
    DestinationPath = '~/Projects'
    Author          = 'Jane Doe'
    CIProvider      = 'GitHub'
    License         = 'MIT'
    GitInit         = $true
}
New-AnvilModule @Params
```

Without `-Interactive`, Anvil applies defaults silently for any optional parameters not specified.

## First build

```powershell
cd ~/Projects/NetworkTools
Invoke-AnvilBootstrapDeps
Invoke-AnvilBuild
```

The bootstrap installs pinned versions of the build toolchain via [ModuleFast](https://github.com/JustinGrote/ModuleFast). `Invoke-AnvilBuild` runs the full pipeline: format, lint, test, compile, and package.

The scaffolded project comes with sample functions, a sample class, and tests for all of them. The first build should pass out of the box.

## What to do next

At this point you have a working module with sample code and a green build. The scaffolded project includes a README with the development workflow, project layout, and conventions. Open it to learn how to add functions, manage dependencies, write tests, and run individual build tasks.

For reference documentation on Anvil's build system, CI/CD setup, and customization, see the [Reference](reference.md) guide.
