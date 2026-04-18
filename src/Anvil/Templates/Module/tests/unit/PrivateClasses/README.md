# Private Class Tests

One test file per class. Classes defined in `PrivateClasses/` are not accessible outside the module, so tests use `InModuleScope` to construct and test them.

Each test file should include an assertion that verifies the class is not accessible outside the module.

Use `GreetingBuilder.Tests.ps1` as a starting point for new tests.
