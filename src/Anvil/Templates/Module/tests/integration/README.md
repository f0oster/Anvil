# Integration Tests

Integration tests validate the compiled build output in `artifacts/package/`, not the source code. They run after the Build task and verify that the compiled module is valid and importable.

Integration tests require a successful build first. They run automatically as part of the full pipeline, or individually with `Invoke-AnvilBuild -Task Build, IntegrationTest`.

Add new checks to `BuildArtifacts.Tests.ps1` or create additional test files for scenarios that need the compiled module (e.g. verifying help content, testing against external services).
