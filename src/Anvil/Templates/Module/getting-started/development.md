# Development

This page covers the day-to-day workflow of building a module with Anvil — adding functions, writing tests, managing dependencies, and running the build. If you haven't scaffolded a project yet, start with [Getting Started](getting-started.md).

## The development loop

Once your project is scaffolded and bootstrapped, the development cycle looks like this:

1. **Scaffold a new function** with `New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public`. This creates the function file with boilerplate and a matching test file.

2. **Write your implementation** in `src/<ModuleName>/Public/Get-Widget.ps1`. Public functions get comment-based help scaffolding. Private functions get a minimal template.

3. **Write tests** in `tests/unit/Public/Get-Widget.Tests.ps1`. The generated test file already imports the module and has the right `BeforeAll`/`AfterAll` pattern — just add your assertions.

4. **Add dependencies** if needed with `Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0'`, then run `Invoke-AnvilBootstrapDeps` to install them.

5. **Reload the module** with `Import-AnvilModule`. This finds and re-imports the development version of your module from anywhere in the project tree, so you can test interactively in the terminal without typing out manifest paths.

6. **Lint and test** with `Invoke-Build -Task Lint, Test`. This runs PSScriptAnalyzer and your Pester unit tests and reports on test coverage. For integration tests, run a full build.

7. **Run the full pipeline** before committing: `Invoke-Build -File ./build/module.build.ps1`. This adds docs generation, module compilation, integration tests, and packaging on top of lint and test.

## Adding functions

### Public functions

```powershell
New-AnvilFunction -FunctionName 'Test-NetworkConnection' -Scope Public
```

This creates two files:

- `src/<ModuleName>/Public/Test-NetworkConnection.ps1` — a function scaffold with `[CmdletBinding()]`, `[OutputType()]`, and a comment-based help block
- `tests/unit/Public/Test-NetworkConnection.Tests.ps1` — a Pester test scaffold with module import, a placeholder test, and the standard `BeforeAll`/`AfterAll` pattern

Open the function file, replace the placeholder logic, then open the test file and write real assertions. The scaffolds are starting points, not finished code.

Public function names must use an [approved PowerShell verb](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands). Anvil validates this and rejects names like `Fetch-Data`. If you have a good reason to use a non-standard verb, pass `-SkipVerbCheck`.

### Private functions

```powershell
New-AnvilFunction -FunctionName 'Resolve-HostAddress' -Scope Private
```

Private functions don't need approved verbs, don't get comment-based help by default, and their tests use `InModuleScope` to reach inside the module. They're internal helpers — not visible to users of your module.

### Organizing with subdirectories

As your module grows, you can organize functions into subdirectories:

```powershell
New-AnvilFunction -FunctionName 'Get-DnsRecord' -Scope Public -Location 'Dns'
```

This creates `src/<ModuleName>/Public/Dns/Get-DnsRecord.ps1` and `tests/unit/Public/Dns/Get-DnsRecord.Tests.ps1`. The module loader and build system discover files recursively, so nesting is purely organizational — it doesn't affect behavior.

## Adding classes

```powershell
New-AnvilClass -ClassName 'ConnectionResult'
```

Classes go in `PrivateClasses/` and are loaded before any functions, so your functions can use them. The generated test uses `InModuleScope` to instantiate the class and includes a test verifying it's not accessible outside the module.

### Things to know about PowerShell classes

**Type updates require a new session.** When you change a class definition and run `Import-Module -Force`, PowerShell reloads the functions but the class definition is pinned to the .NET type system from the first load. You must close and reopen your PowerShell session to pick up class changes. There's no workaround — this is a PowerShell engine limitation.

**Load order is alphabetical.** Anvil authored products process the files in `PrivateClasses/` in filename order. If class `B` inherits from class `A`, make sure `A.ps1` sorts before `B.ps1`. A common convention is to prefix with numbers (`01-BaseClass.ps1`, `02-DerivedClass.ps1`) when inheritance order matters, or to always group classes that depend on each other together in a single file, in the required order.

**Classes can't see `$script:` variables.** Unlike functions, class methods don't have access to module-scoped variables. If a class needs configuration or state from the module, pass it through the constructor or a method parameter.

**Classes are not easily exported from modules.** PowerShell has no `ClassesToExport` mechanism. It's recommended to not try expose classes for module consumers to use directly. Classes are best used for organizing internal logic and acting as DTOs. For public module APIs, it's best to stick to exported functions. If you need to expose behavior from a class, wrap its methods in Public functions instead.

For a full list of PowerShell class limitations, see the [Microsoft documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7.6#limitations).

## Module initialization (Imports.ps1)

`Imports.ps1` runs before any classes or functions load. Use it for module-scoped variables, assembly loading, or any initialization your code depends on:

```powershell
$script:ResourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Resources'
$script:ApiBaseUrl = 'https://api.example.com/v1'
$script:DefaultTimeout = 30
Add-Type -Path "$PSScriptRoot\lib\MyLibrary.dll"
```

Any `$script:` variable defined here is accessible from all Public and Private functions within the module. During development, the `.psm1` dot-sources this file. At build time, its content is merged into the top of the compiled module — so behavior is identical in both modes.

Don't put function definitions here — use `Public/` or `Private/` for that.

## Managing dependencies

If your module depends on other modules at runtime, declare them with `Add-AnvilDependency`:

```powershell
Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0'
Add-AnvilDependency -Name 'ImportExcel' -Version '7.8.6'
Add-AnvilDependency -Name 'PSFramework'
```

This updates two files: `requirements.psd1` (used by the bootstrap and build) and the source module manifest's `RequiredModules`. Version specs follow ModuleFast syntax: `'>=5.0.0'` for a minimum version, `'5.7.1'` for an exact pin, or `'latest'` (the default) for any version.

After adding a dependency, install it:

```powershell
Invoke-AnvilBootstrapDeps
```

To remove a dependency:

```powershell
Remove-AnvilDependency -Name 'Az.Storage' -Force
```

Build tools (InvokeBuild, Pester, PSScriptAnalyzer) are managed separately in `build/build.requires.psd1` as module consumers will never need these installed. Don't add them to `requirements.psd1`.

## Testing

### Running tests

```powershell
# Run all unit tests
Invoke-Build -File ./build/module.build.ps1 -Task Test

# Run a single test file directly
Invoke-Pester -Path tests/unit/Public/Test-NetworkConnection.Tests.ps1

# Run tests with inline coverage in VS Code
Invoke-Build -File ./build/module.build.ps1 -Task DevCC
```

The DevCC task generates a `coverage.xml` file in Coverage Gutters format. Install the [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) VS Code extension to see coverage inline in your editor.

### Testing private functions

Use Pester's [`InModuleScope`](https://pester.dev/docs/usage/modules#testing-private-functions) inside individual `It` blocks:

```powershell
It 'formats the output correctly' {
    InModuleScope 'MyModule' {
        Format-Internal -Name 'test' | Should -Be 'expected'
    }
}
```

Don't wrap `Describe` or `Context` in `InModuleScope` — only `It` blocks.

### Passing data into InModuleScope

Variables from the test scope aren't visible inside `InModuleScope`. Use [`-ArgumentList`](https://pester.dev/docs/commands/InModuleScope) with a matching `param()` block:

```powershell
It 'validates the configuration' {
    $Config = @{ Name = 'Test'; Timeout = 30 }
    InModuleScope 'MyModule' -ArgumentList $Config {
        param($Config)
        Assert-ValidConfig -Configuration $Config | Should -Not -Throw
    }
}
```

### Coverage threshold

The default is 80%. Pester fails the Test task if coverage drops below this. Change `CoverageThreshold` in `build/build.settings.psd1` to any value from 0 to 100. Set it to 0 to disable coverage enforcement.

## Reloading the module

After making changes, reload the development module:

```powershell
Import-AnvilModule
```

This walks up the directory tree to find your project root, locates the source manifest, and imports it with `-Force`. You can run it from anywhere inside the project.

Note that class changes require a new PowerShell session — `Import-Module -Force` (which `Import-AnvilModule` uses) reloads functions but not class definitions.
