# Build Pipeline

The build is powered by [InvokeBuild](https://github.com/nightroman/Invoke-Build). All tasks are defined in `build/module.build.ps1` and configured via `build/build.settings.psd1`.

## Pipelines

There are two composite tasks. The default pipeline runs everything except publishing:

```
. (default)  →  Clean, Validate, Format, Lint, Test, Docs, Build, IntegrationTest, Package
```

The release pipeline adds Version at the start and Publish at the end:

```
Release  →  Version, ., Publish
```

## Running the build

```powershell
# Full default pipeline
Invoke-Build -File ./build/module.build.ps1

# Specific tasks
Invoke-Build -File ./build/module.build.ps1 -Task Lint, Test

# Release with version injection
Invoke-Build -File ./build/module.build.ps1 -Task Release -NewVersion 1.0.0

# Release with prerelease label
Invoke-Build -File ./build/module.build.ps1 -Task Release -NewVersion 1.0.0 -Prerelease beta1
```

During development, `Invoke-Build -Task Lint, Test` is the fastest feedback loop. It skips formatting, docs, compilation, and packaging — just checks your code and runs tests.

## Task reference

### Clean

Deletes and recreates the `artifacts/` directory with subdirectories for `package/`, `testResults/`, and `archive/`. This ensures every build starts from a clean state.

### Validate

Sanity checks before doing real work. Verifies the module manifest exists and is valid (`Test-ModuleManifest`), confirms the `.psm1` exists, and reports the PowerShell version. If the manifest is malformed, the build fails here with a clear error rather than somewhere deeper in the pipeline.

### Format

Runs `Invoke-Formatter` on every `.ps1` file in the module source directory using the rules from `PSScriptAnalyzerSettings.psd1`. This auto-fixes formatting issues — indentation, whitespace around operators, brace placement — so the Lint task only reports substantive problems.

The formatter has safety guards: it skips empty files, catches formatter errors gracefully, and refuses to overwrite a file if the formatted output is empty. If a file can't be formatted, you'll see a yellow "Skipped" warning.

This task modifies your source files in place. If you're tracking formatting changes, commit before running the build.

### Lint

Runs `Invoke-ScriptAnalyzer` against the module source with the settings from `PSScriptAnalyzerSettings.psd1`. It also loads any `.psm1` files found in `build/analyzers/` as custom rules.

The build fails if any Warning or Error severity issues are found. Information-level findings are reported but don't fail the build.

The custom rules that ship with Anvil projects catch:

| Rule | What it catches |
|------|----------------|
| AvoidProcessWithoutPipeline | `process` block in a function that doesn't accept pipeline input |
| AvoidNestedFunctions | Function definitions inside other functions |
| AvoidSmartQuotes | Curly/smart quote characters copied from word processors |
| AvoidEmptyNamedBlocks | Empty `begin`, `process`, `end`, or `dynamicparam` blocks |
| AvoidNewObjectPSObject | `New-Object PSObject` instead of `[PSCustomObject]@{}` |
| AvoidWriteOutput | Unnecessary `Write-Output` (output flows implicitly in PowerShell) |

To disable any rule, add its name to `ExcludeRules` in `PSScriptAnalyzerSettings.psd1`. To add your own rules, drop a `.psm1` file in `build/analyzers/`.

### Test

Runs Pester 5 unit tests from `tests/unit/` with code coverage enabled. Coverage is measured against `.ps1` files in `PrivateClasses/`, `Public/`, and `Private/`.

Output:
- `artifacts/testResults/unit-results.xml` — NUnit XML test results (for CI reporting)
- `artifacts/testResults/coverage.xml` — JaCoCo coverage XML

The test task fails the build if any test fails or if coverage drops below the threshold in `build.settings.psd1` (default: 80%). Set the threshold to 0 if you want to disable coverage enforcement while keeping the report.

### Docs

Generates and maintains platyPS markdown documentation in `docs/commands/`. The behavior depends on whether documentation already exists:

- **First run** (no `docs/commands/` directory): generates markdown for every exported function from the module's comment-based help using `New-MarkdownHelp`
- **Subsequent runs**: updates existing markdown with `Update-MarkdownHelp`, which refreshes parameter metadata and syntax blocks while preserving any manual edits you've made to descriptions, examples, and notes

The generated markdown is meant to be committed and maintained as source. Edit the files to add richer descriptions, usage notes, or links — the update process won't overwrite your changes.

If platyPS isn't installed, the Docs task skips gracefully.

### Build

Produces the compiled module in `artifacts/package/<ModuleName>/`. This is the most complex task and does several things:

1. **Copies static assets** — `Types/`, `Formats/`, `Assemblies/` directories (if they exist in source)
2. **Compiles the `.psm1`** — merges `Imports.ps1`, then `PrivateClasses/*.ps1`, `Private/*.ps1`, and `Public/*.ps1` into a single file. The compiled module loads faster than dot-sourcing individual files at import time.
3. **Generates the manifest** — creates a fresh `.psd1` via `New-ModuleManifest` with values from the source manifest. `FunctionsToExport` is set to the actual Public function names (discovered from filenames), not a wildcard.
4. **Generates MAML help** — if `docs/commands/` has markdown and platyPS is available, converts it to MAML XML in the staged module's `en-US/` directory for `Get-Help` support.
5. **Injects version** — if `-NewVersion` was passed, the staged manifest gets that version instead of the source's `0.0.0`.

### IntegrationTest

Runs Pester 5 integration tests from `tests/integration/` against the build output in `artifacts/package/`. These tests validate that the compilation worked correctly:

- The staged directory exists and contains both `.psd1` and `.psm1`
- The manifest is valid
- The compiled `.psm1` doesn't contain `Export-ModuleMember` (the manifest handles exports)
- The compiled `.psm1` doesn't dot-source individual files (it's a single merged file)
- The manifest has explicit `FunctionsToExport` (not a wildcard)
- The staged module can be imported successfully

These tests catch build process bugs, not module logic bugs.

### Package

Creates a ZIP archive of the staged module in `artifacts/archive/`. The archive is named `<ModuleName>-<Version>.zip`.

### Version

Reports the source manifest version and, if `-NewVersion` or `-Prerelease` were provided, confirms what the Build task will use. This task does not modify any files — version injection happens in the Build task when generating the staged manifest.

### Publish

Publishes the staged module to the PowerShell Gallery using `Publish-Module`. Requires the `PSGALLERY_API_KEY` environment variable.

The task has two safety checks:
- Refuses to run without an API key
- Refuses to publish version `0.0.0` (the placeholder), with a message telling you to pass `-NewVersion`

### DevCC

Generates a Coverage Gutters-compatible `coverage.xml` at the project root for VS Code inline coverage display. Unlike the Test task, DevCC doesn't fail on coverage threshold — it's meant for iterative local use, not enforcement.

Install the [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) extension in VS Code to see green/red inline markers.

## Version management

The source manifest always contains version `0.0.0`. This is deliberate. Versions are injected at build time, not maintained in source.

For local development, `0.0.0` artifacts are clearly not releases. For CI releases, the version comes from the git tag:

```bash
git tag v1.2.0
git push origin v1.2.0
# CI runs: Invoke-Build -Task Release -NewVersion 1.2.0
```

The Build task writes the injected version into the staged manifest. The source `.psd1` is never modified. This means:
- No "bump version" commits cluttering your history
- No drift between tags and manifest versions
- CI is the single source of truth for release versions

For prerelease labels:

```powershell
Invoke-Build -Task Release -NewVersion 1.2.0 -Prerelease beta1
```

This produces a module that the Gallery treats as prerelease (requires `-AllowPrerelease` to install).
