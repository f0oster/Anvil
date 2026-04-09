# Anvil

An opinionated PowerShell module scaffolder for people who don't want to wire up build pipelines by hand.

## Installation

```powershell
Install-Module -Name Anvil -Scope CurrentUser
```

## Usage

```powershell
Import-Module Anvil

$Params = @{
    Name            = 'NetworkTools'
    DestinationPath = '~/Projects'
    Author          = 'Jane Doe'
    CIProvider      = 'GitHub'
    GitInit         = $true
}
New-ModuleProject @Params
```

This creates a `NetworkTools/` directory with module source, build scripts, tests, CI workflows, and everything needed to start developing immediately. Run `./build/bootstrap.ps1` then `Invoke-Build` to build it.

`New-ModuleProject` accepts parameters for CI provider (`GitHub`, `AzurePipelines`, `GitLab`, `None`), license type (`MIT`, `Apache2`, `None`), coverage threshold, minimum PowerShell version, and whether to include platyPS documentation generation. Use `Get-Help New-ModuleProject -Full` for the complete list.

`Get-AnvilTemplate` lists the available templates and CI providers shipped with the module.

### After scaffolding

Anvil also provides commands for working inside a scaffolded project:

```powershell
# Create a public function and its test file
New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public

# Create a private function in a subdirectory
New-AnvilFunction -FunctionName 'Format-Row' -Scope Private -Location 'Helpers'

# Create a private class and its test file
New-AnvilClass -ClassName 'HttpClient'

# Create just a test file for an existing function or class
New-AnvilTest -Name 'Get-Widget' -Scope Public
New-AnvilTest -Name 'HttpClient' -Scope PrivateClasses
```

`New-AnvilFunction` validates that public function names use an [approved PowerShell verb](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands). Use `-SkipVerbCheck` to override this.

Both commands auto-detect the project root by walking up the directory tree from your current location. Pass `-Path` to specify it explicitly.

## What gets generated

The scaffolded project follows a `src/` + `build/` + `tests/` layout. During development, the `.psm1` dot-sources individual files from `Public/` and `Private/`. At build time, InvokeBuild compiles them into a single `.psm1` for faster module loading.

The build pipeline runs: Clean, Validate, Lint, Test, Build, IntegrationTest, Package. A separate `Release` task publishes to PSGallery. CI templates include both a PR/push pipeline and a tag-triggered release workflow.

Dependencies are managed via [ModuleFast](https://github.com/JustinGrote/ModuleFast) with a scoped `build.requires.psd1` manifest. Build tooling and runtime dependencies are kept strictly separate. Building requires PowerShell 7.2+, but the generated module can target any version.

## Development

```powershell
git clone git@github.com:f0oster/Anvil.git
cd Anvil
./build/bootstrap.ps1
Invoke-Build -File ./build/module.build.ps1
```

## License

MIT
