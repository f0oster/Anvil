# CI/CD Integration

Anvil generates CI/CD workflows that run the full build pipeline on push/PR and publish to the PowerShell Gallery on tagged releases. The generated workflows are starting points — you'll likely need to adjust them for your environment.

## Choosing a provider

```powershell
New-AnvilModule -Name 'MyModule' -DestinationPath . -Author 'Dev' -CIProvider GitHub
```

Available providers: `GitHub`, `AzurePipelines`, `GitLab`, `None`. Use `None` if you handle CI yourself or don't need it yet. You can always add CI files later by scaffolding a second project and copying the workflow files.

## How releases work

All three providers follow the same pattern. Understanding this flow is important before configuring anything.

1. You develop on a branch, push, and merge. CI runs the full default pipeline on every push. No publishing happens.

2. When you're ready to release, you tag the commit:

    ```bash
    git tag v1.0.0
    git push origin v1.0.0
    ```

3. The release workflow triggers on the `v*` tag pattern. It extracts the version number from the tag name (strips the `v` prefix), passes it to the build script as `-NewVersion`, and runs the full Release pipeline including Publish.

4. The Publish task pushes the module to the PowerShell Gallery. It refuses to publish version `0.0.0` (the source placeholder), so if the version extraction fails, the build fails safely rather than publishing garbage.

The source `.psd1` is never modified. The version exists only in the CI workspace during the build. There are no "version bump" commits.

## GitHub Actions

### Generated files

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci.yml` | Push/PR to main | Runs the default pipeline |
| `.github/workflows/release.yml` | Tags matching `v*` | Builds with version injection, publishes |

### Setup

1. Go to your repository **Settings > Environments** and create an environment called `psgallery`
2. Under the `psgallery` environment, add `PSGALLERY_API_KEY` as an environment secret with your PowerShell Gallery API key
3. Optionally, add required reviewers to the environment for manual approval before publishing
4. Optionally, restrict the environment to the `main` branch under **Deployment branches**

## Azure Pipelines

### Generated files

| File | Trigger | Purpose |
|------|---------|---------|
| `azure-pipelines.yml` | Push/PR | CI pipeline |
| `azure-pipelines-release.yml` | Tags matching `v*` | Release pipeline |

### Setup

1. Go to **Pipelines > New pipeline** and create a pipeline from `azure-pipelines.yml`. This is your CI pipeline — name it something like `CI`.
2. Create a second pipeline from `azure-pipelines-release.yml`. This is your release pipeline — name it something like `Release`.
3. On the release pipeline, go to **Variables** and add `PSGALLERY_API_KEY` as a secret variable with your PowerShell Gallery API key.

The release pipeline references a `psgallery` environment, which is created automatically on the first run. In Azure DevOps, environments don't hold secrets — secrets are pipeline variables. Environments are used for approval gates and deployment tracking. If you want manual sign-off before publishing, add an approval check under **Pipelines > Environments > psgallery**.

## GitLab CI

### Generated file

| File | Stages | Purpose |
|------|--------|---------|
| `.gitlab-ci.yml` | ci, publish | Combined CI and release |

The publish stage only runs for tags matching `v*` (controlled by a `rules` clause).

### Setup

1. Go to **Operate > Environments** and create an environment called `psgallery`
2. Go to **Settings > CI/CD > Variables** and add `PSGALLERY_API_KEY` as a protected, masked variable scoped to the `psgallery` environment
3. Go to **Settings > Repository > Protected tags** and add `v*` as a protected tag pattern (required for protected variables to be injected)

For approval gates on the free tier, add `when: manual` to the publish job. Protected environments with role-based approvals require GitLab Premium.

### Notes

GitLab CI uses the `mcr.microsoft.com/powershell:lts-ubuntu-22.04` Docker image and runs on Linux by default. A Windows CI job is included but commented out — it requires a self-hosted runner tagged `windows`. GitLab shared runners on gitlab.com are Linux only.

Test results use JUnit format for GitLab's test report integration.

## Testing CI locally

You can simulate what CI does without pushing:

```powershell
./build/bootstrap.ps1
Invoke-Build -File ./build/module.build.ps1 -Task Release -NewVersion 1.0.0-local
```

The Publish task will fail (no API key), but everything else runs. This is useful for verifying the full pipeline before tagging a release. The `-local` suffix is arbitrary — it just makes the version obviously non-production.

## Adding CI to an existing project

If you scaffolded with `-CIProvider None` and want to add CI later, the simplest approach is to scaffold a throwaway project with the desired provider and copy the workflow files:

```powershell
New-AnvilModule -Name 'Temp' -DestinationPath $env:TEMP -Author 'x' -CIProvider GitHub -Force
```

Then copy `.github/workflows/` (or the equivalent) into your real project. The workflows reference `./build/bootstrap.ps1` and `./build/module.build.ps1`, which already exist in your project.
