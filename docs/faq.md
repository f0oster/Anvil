# FAQ

## The first build after scaffolding fails

This should not happen. The scaffolded project includes sample functions and tests that pass out of the box. Check:

- **Are you running PowerShell 7.2+?** The bootstrap requires it. Run `$PSVersionTable.PSVersion` to check.
- **Are you running from the project root?** InvokeBuild expects the build script path to be correct.

If neither of these helps, this is a bug in Anvil.

## The Publish task doesn't run

The Publish task requires the `PSGALLERY_API_KEY` environment variable and a version other than `0.0.0`. Both are normally handled by the CI/CD workflow — the release pipeline extracts the version from the git tag and the API key comes from the environment secret. If publishing fails, check that your CI environment has the API key configured and that the tag follows the `v*` pattern. See the [CI/CD section](reference.md#cicd-integration) for setup instructions.

## My class tests fail after changing the class

PowerShell classes are tied to the .NET type system. `Import-Module -Force` reloads functions but does not update class definitions. Start a new PowerShell session to pick up class changes.

## Why is there a `{{ Fill ProgressAction Description }}` in my docs?

The `-ProgressAction` common parameter was introduced in PowerShell 7.4. platyPS v0.14.2 predates this parameter and does not know how to describe it. This placeholder appears in every function's documentation.

You can replace it with a description like "Determines how the cmdlet responds to progress updates" or leave it as-is.

## Can I target Windows PowerShell 5.1?

Yes. Set `-MinPowerShellVersion 5.1` and `-CompatiblePSEditions @('Desktop', 'Core')` when scaffolding. The build tooling requires 7.2+, but the module you produce can target any version of PowerShell that your module code supports.
