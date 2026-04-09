# Private Classes

PowerShell classes in this directory are loaded before any functions, so both Public and Private functions can depend on them. Classes defined here are internal to the module and not accessible to users.

## Adding a new class

1. Create `<ClassName>.ps1` in this directory
2. Define one class per file, named to match the class
3. Create a matching test file in `tests/unit/PrivateClasses/`

## Known quirks

PowerShell classes have several behaviors that differ from functions. Be aware of these before relying heavily on classes:

### Classes are parsed at load time, not at runtime

Unlike functions, classes must be syntactically valid when the file is dot-sourced. If a class references another class that hasn't been loaded yet, you'll get a parse error. **Load order matters** -- files are loaded alphabetically, so name files accordingly or keep dependent classes in the same file.

### Classes do not inherit module scope the way functions do

A class method cannot see `$script:` variables from the module. If you need module-scoped state inside a class, pass it in through the constructor or a method parameter.

### Classes are not exported like functions

There is no `ClassesToExport` in the module manifest. Classes defined inside a module are private by default. Users outside the module cannot reference `[YourClass]` unless you expose it through a `using module` statement, which has its own limitations.

### Type updates require a new session

Unlike functions (which can be re-imported with `Import-Module -Force`), PowerShell classes are tied to the .NET type system. If you change a class definition, you must start a new PowerShell session to pick up the changes. `Import-Module -Force` will reload functions but will **not** update class definitions.

### No method overloading by parameter name

PowerShell classes support method overloading by parameter count and type, but not by parameter name alone. Two methods with the same name and same number of parameters must differ by type:

```powershell
class Example {
    [string] Greet([string]$Name) { return "Hello, $Name" }
    [string] Greet([int]$Count)   { return "Hello x$Count" }    # OK, different type
    # [string] Greet([string]$Other) { ... }                    # NOT OK, same signature
}
```

### Inheritance from .NET types is limited

You can inherit from other PowerShell classes or simple .NET types, but inheriting from generic types or complex .NET classes may not work as expected.

## Testing

Private classes are tested via `InModuleScope`, the same as private functions. See `tests/unit/PrivateClasses/README.md` for details.
