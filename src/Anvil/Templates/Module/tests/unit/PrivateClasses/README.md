# Private Class Tests

Tests in this directory validate your module's PowerShell classes. Classes defined in `PrivateClasses/` are internal to the module and not accessible to users directly.

## Adding a new test file

1. Create `<ClassName>.Tests.ps1` in this directory
2. Use `GreetingBuilder.Tests.ps1` as a starting point

## Key concepts

### Classes are loaded before functions

The module loader dot-sources `PrivateClasses/` before `Public/` and `Private/`, so your functions can depend on classes without worrying about load order.

### Accessing private classes in tests

Classes defined inside a module are not visible outside it. Use `InModuleScope` to construct and test them:

```powershell
It 'creates an instance' {
    InModuleScope 'YourModule' {
        $Obj = [MyClass]::new()
        $Obj.SomeProperty | Should -Be 'expected'
    }
}
```

### Verifying a class is not accessible outside the module

Include a test that confirms the class stays internal:

```powershell
It 'is not accessible outside the module' {
    { [MyClass]::new() } | Should -Throw
}
```

### Passing data into InModuleScope

Variables from the test scope are not visible inside `InModuleScope`. Use `-ArgumentList`:

```powershell
It 'accepts external input' {
    $Input = 'test value'
    InModuleScope 'YourModule' -ArgumentList $Input {
        param($Input)
        $Obj = [MyClass]::new($Input)
        $Obj.Value | Should -Be 'test value'
    }
}
```
