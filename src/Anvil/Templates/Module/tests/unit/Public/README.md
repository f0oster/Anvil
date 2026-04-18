# Public Function Tests

One test file per exported function. Public functions are available by name after `Import-Module` — no `InModuleScope` needed.

When mocking commands that your function calls internally, use `Mock -ModuleName 'YourModule'` to inject the mock into the module's scope.

Use `Get-Greeting.Tests.ps1` as a starting point for new tests.
