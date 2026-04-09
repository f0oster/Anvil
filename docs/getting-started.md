# Getting Started

This guide walks through creating a module from scratch, adding real functionality, running the build, and understanding the development loop.

## Prerequisites

You need **PowerShell 7.2 or later** for building. This is a firm requirement because ModuleFast (the dependency installer) needs it. The module you create can target any version down to 5.1 — the build tooling and the runtime target are separate concerns.

You don't need to install InvokeBuild, Pester, PSScriptAnalyzer, or platyPS manually. The bootstrap script handles all of that.

Git is optional but recommended. If you pass `-GitInit`, Anvil creates a repository with an initial commit. If git is on your PATH, the interactive wizard also detects your name from `git config user.name`.

## Creating a module

### The interactive way

Running `New-AnvilModule` with no arguments starts a guided wizard:

```powershell
New-AnvilModule
```

You'll see prompts for module name, destination, author, description, CI provider, license, and more. Each prompt shows a default in brackets — press Enter to accept it. The author name is pulled from your git config if available.

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

When `-Name` is provided, Anvil runs non-interactively. `-DestinationPath` and `-Author` are required in this mode.

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

## The development loop

The typical workflow when developing a module looks like:

1. Write or modify a function
2. Write or update its test
3. Run `Invoke-Build -Task Lint, Test` to validate
4. Repeat

You don't need to run the full pipeline every time. `Lint, Test` catches most problems in seconds. Run the full pipeline before committing or pushing.

### Adding a public function

```powershell
New-AnvilFunction -FunctionName 'Test-NetworkConnection' -Scope Public
```

This creates two files:

- `src/NetworkTools/Public/Test-NetworkConnection.ps1` — a function scaffold with `[CmdletBinding()]`, `[OutputType()]`, and a comment-based help block
- `tests/unit/Public/Test-NetworkConnection.Tests.ps1` — a Pester test scaffold with module import, a placeholder test, and the standard BeforeAll/AfterAll pattern

Open the function file, replace the placeholder logic, then open the test file and write real assertions. The scaffolds are starting points, not finished code.

Public function names must use an [approved PowerShell verb](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands). Anvil validates this and rejects names like `Fetch-Data`. If you have a good reason to use a non-standard verb, pass `-SkipVerbCheck`.

### Adding a private function

```powershell
New-AnvilFunction -FunctionName 'Resolve-HostAddress' -Scope Private
```

Private functions don't need approved verbs, don't get comment-based help by default, and their tests use `InModuleScope` to reach inside the module. They're internal helpers — not visible to users of your module.

### Adding a class

```powershell
New-AnvilClass -ClassName 'ConnectionResult'
```

Classes go in `PrivateClasses/` and are loaded before any functions, so your functions can use them. The generated test uses `InModuleScope` to instantiate the class and includes a test verifying it's not accessible outside the module.

Be aware that PowerShell classes have quirks. The most important one: **`Import-Module -Force` does not reload class definitions**. If you change a class, you must start a new PowerShell session to pick up the change. This is a PowerShell limitation, not an Anvil issue. See [Customization](customization.md) for more class-specific guidance.

### Organizing with subdirectories

As your module grows, you can organize functions into subdirectories:

```powershell
New-AnvilFunction -FunctionName 'Get-DnsRecord' -Scope Public -Location 'Dns'
```

This creates `src/NetworkTools/Public/Dns/Get-DnsRecord.ps1` and `tests/unit/Public/Dns/Get-DnsRecord.Tests.ps1`. The module loader and build system discover files recursively, so nesting is purely organizational — it doesn't affect behavior.

## Running tests

```powershell
# Run all unit tests
Invoke-Build -File ./build/module.build.ps1 -Task Test

# Run a single test file directly
Invoke-Pester -Path tests/unit/Public/Test-NetworkConnection.Tests.ps1

# Run tests with inline coverage in VS Code
Invoke-Build -File ./build/module.build.ps1 -Task DevCC
```

The DevCC task generates a `coverage.xml` file in Coverage Gutters format. Install the [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) VS Code extension to see coverage inline in your editor.

## What to do next

At this point you have a working module with one sample function. The next steps depend on what you're building:

- **Replace the sample code.** Delete `Get-Greeting.ps1`, `Format-GreetingText.ps1`, `GreetingBuilder.ps1` and their tests. Add your own functions with `New-AnvilFunction`.
- **Set up CI.** Push to GitHub/Azure DevOps/GitLab and configure the generated workflow. See [CI/CD Integration](cicd-integration.md).
- **Understand the build.** Read [Build Pipeline](build-pipeline.md) to learn what each task does and how to customize it.
- **Explore the project layout.** Read [Project Structure](project-structure.md) to understand where everything lives and why.
