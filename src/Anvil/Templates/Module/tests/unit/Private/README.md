# Private Function Tests

One test file per private function. Private functions are not exported, so tests use `InModuleScope` inside `It` blocks to access them.

Each test file should include an "is not exported" assertion to verify the function stays private.

Variables from the test scope are not visible inside `InModuleScope`. Use `-ArgumentList` with a `param()` block to pass data in.

Use `Format-GreetingText.Tests.ps1` as a starting point for new tests.
