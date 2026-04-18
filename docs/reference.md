# Reference

## Project structure

```
MyModule/
├── src/MyModule/              Module source code
│   ├── MyModule.psd1          Module manifest
│   ├── MyModule.psm1          Module loader
│   ├── Imports.ps1            Module-scoped variables and setup
│   ├── PrivateClasses/        PowerShell classes
│   ├── Public/                Exported functions (one per file)
│   └── Private/               Internal helper functions (one per file)
├── requirements.psd1          Module dependencies (managed by Add-AnvilDependency)
├── build/
│   ├── module.build.ps1       InvokeBuild task definitions
│   ├── bootstrap.ps1          ModuleFast dependency installer
│   ├── build.settings.psd1    Build configuration
│   ├── build.requires.psd1    Build toolchain versions
│   └── analyzers/             Custom PSScriptAnalyzer rules
├── tests/
│   ├── unit/                  Pester 5 unit tests
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

### Module source

The **manifest** (`MyModule.psd1`) declares metadata and runtime properties. The source version is always `0.0.0` — real versions are injected at build time.

The **module loader** (`MyModule.psm1`) dot-sources files in order: `Imports.ps1`, then `PrivateClasses/`, `Public/`, and `Private/`. At build time, these are compiled into a single `.psm1`.

**`Imports.ps1`** runs before any classes or functions load. Use it for `$script:` variables, assembly loading, or other module-wide initialization.

**`Public/`**, **`Private/`**, and **`PrivateClasses/`** each support nested subdirectories. The module loader discovers `.ps1` files recursively.

### Build system

**`bootstrap.ps1`** installs [ModuleFast](https://github.com/JustinGrote/ModuleFast) and uses it to install build tools from `build.requires.psd1` and module dependencies from `requirements.psd1`. Modules are installed to the user-scoped module path.

**`build.requires.psd1`** declares build tool versions grouped by scope (Build, Test, Docs). Versions are pinned for reproducible builds.

**`requirements.psd1`** declares runtime module dependencies. Managed by `Add-AnvilDependency` and `Remove-AnvilDependency`.

**`build.settings.psd1`** contains user-editable build configuration. Invalid or missing settings fall back to defaults from `build.settings_DEFAULTS_DO_NOT_EDIT.psd1`.

**`analyzers/`** contains custom PSScriptAnalyzer rules. The Lint task loads every `.psm1` file in this directory automatically.

### Tests

Unit tests in `tests/unit/` mirror the source structure. Integration tests in `tests/integration/` validate the compiled module after the Build task.

### Configuration files

**`PSScriptAnalyzerSettings.psd1`** controls linter rules, formatting style, and rule exclusions.

**`.editorconfig`** sets editor-agnostic formatting (indent style, line endings, trailing whitespace).

**`.vscode/`** includes workspace settings, build tasks, and recommended extensions for VS Code.

## Build pipeline

The build is powered by [InvokeBuild](https://github.com/nightroman/Invoke-Build). All tasks are defined in `build/module.build.ps1`.

### Pipelines

The default pipeline runs everything except publishing:

```
. (default)  →  Clean, Validate, Format, Lint, Test, Build, IntegrationTest, Package
```

If the project was scaffolded with `-IncludeDocs`, a Docs task is included between Test and Build.

The release pipeline adds Version at the start and Publish at the end:

```
Release  →  Version, ., Publish
```

### Running the build

```powershell
Invoke-AnvilBuild                                     # full pipeline
Invoke-AnvilBuild -Task Lint, Test                    # fast feedback
Invoke-AnvilBuild -Task Release -NewVersion 1.0.0     # release build
```

### Build settings

All settings live in `build/build.settings.psd1`:

| Setting | Default | What it controls |
|---------|---------|-----------------|
| `ModuleName` | *(your module)* | Module to build |
| `CoverageThreshold` | `80` | Minimum code coverage percentage (0 to disable) |
| `IncludeDocs` | `$true` or `$false` | Whether the Docs task runs |
| `TestOutputFormat` | `'NUnitXml'` | Test result format for CI |
| `TestVerbosity` | `'Detailed'` | Pester output verbosity |
| `LintFailOn` | `@('Warning', 'Error')` | Severity levels that fail the build |
| `AssetDirectories` | `@('Types', 'Formats', 'Assemblies')` | Extra directories copied to the staged module |

### Task reference

**Clean** — deletes and recreates `artifacts/` so every build starts clean.

**Validate** — checks that the module manifest and `.psm1` exist and are valid.

**Format** — runs `Invoke-Formatter` on all `.ps1` files using the rules from `PSScriptAnalyzerSettings.psd1`. Modifies files in place.

**Lint** — runs `Invoke-ScriptAnalyzer` with project settings and custom rules from `build/analyzers/`. Fails the build if issues matching `LintFailOn` severities are found.

**Test** — runs Pester 5 unit tests with code coverage. Fails if any test fails or coverage drops below `CoverageThreshold`.

**Docs** — generates and updates platyPS markdown documentation in `docs/commands/`. Skips if `IncludeDocs` is `$false` or platyPS is not installed.

**Build** — compiles all source files into a single `.psm1`, generates a clean manifest with `FunctionsToExport`, copies assets, and generates MAML help.

**IntegrationTest** — runs tests from `tests/integration/` against the compiled output.

**Package** — creates a ZIP archive of the staged module.

**Version** — reports the current version and what `-NewVersion` or `-Prerelease` will apply.

**Publish** — publishes to the PowerShell Gallery using `Publish-PSResource`. Requires the `PSGALLERY_API_KEY` environment variable. Refuses to publish version `0.0.0`.

**DevCC** — generates a Coverage Gutters-compatible `coverage.xml` for VS Code inline coverage. Does not enforce the threshold.

### Custom PSScriptAnalyzer rules

The rules that ship with Anvil projects:

| Rule | What it catches |
|------|----------------|
| AvoidProcessWithoutPipeline | `process` block in a function that doesn't accept pipeline input |
| AvoidNestedFunctions | Function definitions inside other functions |
| AvoidSmartQuotes | Curly/smart quote characters |
| AvoidEmptyNamedBlocks | Empty `begin`, `process`, `end`, or `dynamicparam` blocks |
| AvoidNewObjectPSObject | `New-Object PSObject` instead of `[PSCustomObject]@{}` |
| AvoidWriteOutput | Unnecessary `Write-Output` |

To disable a rule, add it to `ExcludeRules` in `PSScriptAnalyzerSettings.psd1`. To add your own, drop a `.psm1` file in `build/analyzers/`.

### Version management

The source manifest always contains version `0.0.0`. Versions are injected at build time, not maintained in source. In CI, the version comes from the git tag:

```bash
git tag v1.0.0
git push origin v1.0.0
# CI runs: Invoke-Build -Task Release -NewVersion 1.0.0
```

For prerelease labels:

```powershell
Invoke-Build -Task Release -NewVersion 1.0.0 -Prerelease beta1
```

### Types and formatting

PowerShell supports custom type extensions and formatting views via `.ps1xml` files. Create them in `src/MyModule/Types/` and `src/MyModule/Formats/`, then reference them in the module manifest:

```powershell
TypesToProcess   = @('Types/MyModule.Types.ps1xml')
FormatsToProcess = @('Formats/MyModule.Format.ps1xml')
```

The Build task copies these directories to the staged module and carries the manifest properties through.

### Adding build tasks

Add tasks to `build/module.build.ps1`:

```powershell
task Deploy {
    Write-BuildHeader 'Deploy'
    # your deployment logic
    Write-BuildFooter 'Deploy complete'
}
```

Run standalone or add to a composite task. Modifying the build script means your pipeline has diverged from Anvil's default — future updates will require manual merging.

## CI/CD integration

Anvil generates CI/CD workflows that run the full pipeline on push/PR and publish on tagged releases.

### How releases work

All providers follow the same pattern:

1. Push and merge as normal. CI runs the default pipeline on every push.
2. Tag a commit when ready to release: `git tag v1.0.0 && git push origin v1.0.0`
3. The release workflow extracts the version from the tag, passes it as `-NewVersion`, and runs the Release pipeline including Publish.

The source manifest is never modified. The version exists only during the CI build.

### GitHub Actions

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci.yml` | Push/PR to main | Default pipeline |
| `.github/workflows/release.yml` | Tags matching `v*` | Build + publish |

**Setup:** Create a `psgallery` environment in Settings > Environments and add `PSGALLERY_API_KEY` as an environment secret.

### Azure Pipelines

| File | Trigger | Purpose |
|------|---------|---------|
| `azure-pipelines.yml` | Push/PR | CI pipeline |
| `azure-pipelines-release.yml` | Tags matching `v*` | Release pipeline |

**Setup:** Create pipelines from both YAML files. Add `PSGALLERY_API_KEY` as a secret variable on the release pipeline. The `psgallery` environment is created automatically on first run — add approval checks under Pipelines > Environments if needed.

### GitLab CI

| File | Stages | Purpose |
|------|--------|---------|
| `.gitlab-ci.yml` | ci, publish | Combined CI and release |

The publish stage runs only for `v*` tags.

**Setup:** Create a `psgallery` environment under Operate > Environments. Add `PSGALLERY_API_KEY` as a protected, masked variable scoped to the environment. Add `v*` as a protected tag pattern.

GitLab CI uses `mcr.microsoft.com/powershell:lts-ubuntu-22.04` on Linux. A Windows job is included but commented out (requires a self-hosted runner).

### Testing CI locally

```powershell
Invoke-AnvilBootstrapDeps
Invoke-AnvilBuild -Task Release -NewVersion 1.0.0-local
```

The Publish task will fail without an API key, but everything else runs.

### Adding CI to an existing project

If you scaffolded with `-CIProvider None`, scaffold a throwaway project with the desired provider and copy the workflow files:

```powershell
New-AnvilModule -Name 'Temp' -DestinationPath $env:TEMP -Author 'x' -CIProvider GitHub
```

Then copy `.github/workflows/` (or equivalent) into your project.
