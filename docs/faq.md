# FAQ

## Why create Anvil when similar projects like ModuleBuilder, Catesta, Stucco, etc. exist?

Anvil grew out of using Catesta across several projects. Eventually I decided to build something in line with my own preferences. A simple build system I could understand and modify without the complexity of Plaster, and authoring tools that streamline some of the more tedious areas of module authoring.


## Why is the version in my build 0.0.0?

This is actually by design. The source manifest (the development manifest) uses `0.0.0` as a placeholder. The version is injected at build time:

```powershell
Invoke-Build -Task Release -NewVersion x.x.x
```

In CI, the version is extracted from the git tag automatically, and no references to the modules version is referenced anywhere in the repository itself. This avoids "version bump" commits and means that git tags on your repository are the single source of truth for module versions. See [Build Pipeline > Version Management](build-pipeline.md#version-management).

## The first build after scaffolding fails

This shouldn't happen. The scaffolded project includes sample functions and tests that should pass out of the box. If the build fails, check:

- **Are you running PowerShell 7.2+?** The bootstrap script requires it because ModuleFast does. Run `$PSVersionTable.PSVersion` to check.
- **Are you running from the project root?** InvokeBuild expects to be invoked from the directory containing the build script, or with an explicit `-File` path.

If none of these help, this is a bug in Anvil — please report it.

## The Publish task refuses to run

It checks two things:
1. The `PSGALLERY_API_KEY` environment variable must be set
2. The staged manifest version must not be `0.0.0`

If you see "Cannot publish placeholder version 0.0.0", pass `-NewVersion`:

```powershell
Invoke-Build -Task Release -NewVersion 1.0.0
```

## My class tests fail after changing the class

PowerShell classes are tied to the .NET type system. `Import-Module -Force` reloads functions but does not update class definitions. You must start a new PowerShell session to pick up class changes. This is a PowerShell limitation, not a Pester or Anvil issue. See [Development > Adding classes](development.md#adding-classes) for more on class quirks.

## Why is there a `{{ Fill ProgressAction Description }}` in my docs?

The `-ProgressAction` common parameter was introduced in PowerShell 7.4. platyPS v0.14.2 predates this parameter and doesn't know how to describe it. This placeholder appears in every function's documentation.

You can safely replace it with a description like "Determines how the cmdlet responds to progress updates" or leave it as-is — it doesn't affect `Get-Help` output.

## Can I target Windows PowerShell 5.1?

Yes. Set `-MinPowerShellVersion 5.1` and `-CompatiblePSEditions @('Desktop', 'Core')` when scaffolding. The generated module will work on both Windows PowerShell and PowerShell 7+.

The build tooling itself requires 7.2+ (because ModuleFast does), but the module you produce can target 5.1. You build on modern PowerShell and ship for whatever version your users need.
