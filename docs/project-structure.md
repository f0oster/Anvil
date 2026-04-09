# Project Structure

This page explains what Anvil generates and why each piece exists. Understanding the structure helps when you need to customize or debug the build.

## Overview

```
MyModule/
├── src/MyModule/              Module source code
│   ├── MyModule.psd1          Module manifest
│   ├── MyModule.psm1          Module loader (dot-sources everything)
│   ├── Imports.ps1            Module-scoped variables and setup
│   ├── PrivateClasses/        PowerShell classes
│   ├── Public/                Exported functions (one per file)
│   └── Private/               Internal helper functions (one per file)
├── build/
│   ├── module.build.ps1       InvokeBuild task definitions
│   ├── bootstrap.ps1          ModuleFast dependency installer
│   ├── build.settings.psd1    Module name and coverage threshold
│   ├── build.requires.psd1    Pinned build tool versions
│   └── analyzers/             Custom PSScriptAnalyzer rules
├── tests/
│   ├── unit/                  Pester 5 unit tests
│   │   ├── MyModule.Module.Tests.ps1
│   │   ├── Public/
│   │   ├── Private/
│   │   └── PrivateClasses/
│   └── integration/           Post-build validation tests
├── docs/                      Documentation
│   └── commands/              platyPS command reference (generated)
├── PSScriptAnalyzerSettings.psd1
├── .editorconfig
├── .vscode/
├── .gitignore
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Module source

### The manifest (`MyModule.psd1`)

The module manifest declares metadata (author, description, version, tags) and runtime properties (PowerShell version, compatible editions, required modules). During development, `FunctionsToExport` is commented out — the `.psm1` controls exports instead. The Build task generates a clean manifest for publishing with an explicit export list derived from the filenames in `Public/`.

The source version is always `0.0.0`. This is a placeholder. Real versions are injected at build time (see [Build Pipeline](build-pipeline.md#version-management)).

### The module loader (`MyModule.psm1`)

During development, the `.psm1` dot-sources files in a specific order:

1. **`Imports.ps1`** — module-scoped variables and initialization
2. **`PrivateClasses/*.ps1`** — classes, loaded first because functions may depend on them
3. **`Public/*.ps1`** — exported functions
4. **`Private/*.ps1`** — internal helpers

It then calls `Export-ModuleMember` to export only the Public functions. This file is replaced entirely during compilation — the Build task merges everything into a single `.psm1` for faster module loading in production.

### Imports.ps1

This file runs before anything else loads. Use it for `$script:` variables, assembly loading, or other initialization that your functions and classes depend on:

```powershell
$script:ResourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Resources'
$script:DefaultTimeout = 30
```

At build time, its contents are prepended to the compiled `.psm1`. The file is not copied to the build output as a separate file.

### Public, Private, PrivateClasses

The convention is one function or class per file, with the filename matching the function/class name. All three directories support nested subdirectories — the module loader discovers `.ps1` files recursively.

- **Public** functions are exported and visible to users after `Import-Module`
- **Private** functions are loaded but not exported — they're internal helpers
- **PrivateClasses** are loaded before functions so they can be used by both Public and Private code

## Build system

### bootstrap.ps1

A self-contained script that installs [ModuleFast](https://github.com/JustinGrote/ModuleFast) (if not present) and then uses it to install build dependencies from `build.requires.psd1`. It requires PowerShell 7.2+ because ModuleFast does.

Modules are installed to the user-scoped module path, not globally. The bootstrap is safe to run repeatedly — it's fast when dependencies are already installed.

### build.requires.psd1

Declares build tool versions grouped by scope:

```powershell
@{
    Build = @{
        'InvokeBuild'      = '5.12.1'
        'PSScriptAnalyzer' = '1.23.0'
    }
    Test = @{
        'Pester' = '5.7.1'
    }
    Docs = @{
        'platyPS' = '0.14.2'
    }
}
```

You can add custom scopes (e.g. `Deploy`) and install selectively with `./build/bootstrap.ps1 -Scope Build,Test`. Versions are pinned for reproducible builds — update them deliberately, not accidentally.

### build.settings.psd1

Project-specific values read by the build script:

```powershell
@{
    ModuleName        = 'MyModule'
    CoverageThreshold = 80
}
```

The module name is used to locate source files and name artifacts. The coverage threshold is the minimum percentage Pester enforces during the Test task (0-100, set to 0 to disable).

### module.build.ps1

The InvokeBuild task graph. See [Build Pipeline](build-pipeline.md) for a detailed explanation of every task.

### analyzers/

Custom PSScriptAnalyzer rules shipped with the project. The Lint task automatically discovers every `.psm1` file in this directory and loads it as a rule source. You can add your own rules by dropping files here and disable any rule (built-in or custom) via `ExcludeRules` in `PSScriptAnalyzerSettings.psd1`.

## Tests

The test structure mirrors the source structure:

| Source | Tests |
|--------|-------|
| `Public/Get-Widget.ps1` | `tests/unit/Public/Get-Widget.Tests.ps1` |
| `Private/Format-Row.ps1` | `tests/unit/Private/Format-Row.Tests.ps1` |
| `PrivateClasses/MyClass.ps1` | `tests/unit/PrivateClasses/MyClass.Tests.ps1` |

**Unit tests** (`tests/unit/`) test source code directly by importing the module from `src/`. Public function tests call functions by name. Private function and class tests use `InModuleScope` to reach inside the module.

**Integration tests** (`tests/integration/`) run after the Build task and validate the compiled artifacts. They check that the compiled `.psm1` is a single file (no dot-sourcing), the manifest has explicit exports, and the module can be imported from the build output.

Each test file follows the same pattern: walk up to find the project root, import the module in `BeforeAll`, clean up in `AfterAll`. This walk-up pattern makes tests resilient to directory restructuring — you can nest test files in subdirectories without breaking path resolution.

## Configuration files

**`PSScriptAnalyzerSettings.psd1`** — linter rules and formatting configuration. Controls brace style (OTBS), indentation (4 spaces), whitespace rules, and which rules to exclude.

**`.editorconfig`** — editor-agnostic formatting (indent style, line endings, trailing whitespace). Respected by VS Code, JetBrains, and most other editors.

**`.vscode/`** — VS Code workspace settings (PowerShell extension configuration), build tasks (Bootstrap, Build, Lint, Test, Coverage), and recommended extensions.

## Build output

After a successful build, `artifacts/` contains:

```
artifacts/
├── package/MyModule/       Staged module (ready to publish)
│   ├── MyModule.psd1       Clean manifest with explicit exports
│   ├── MyModule.psm1       Compiled single-file module
│   └── en-US/              MAML help (generated from docs/commands/)
├── testResults/            NUnit XML + JaCoCo coverage XML
└── archive/                ZIP of the staged module
```

The `en-US/` directory only appears in build output, never in source. The compiled `.psm1` contains all code from Imports, PrivateClasses, Private, and Public merged into one file. The manifest has a real `FunctionsToExport` list (not a wildcard) derived from the Public function filenames.
