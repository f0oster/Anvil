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
