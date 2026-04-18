# Public Functions

Functions in this directory are exported by the module and available to users after `Import-Module`.

## Adding a new function

1. Create `<Verb>-<Noun>.ps1` in this directory (or a subdirectory)
2. Add the function name to `FunctionsToExport` in the module manifest (`.psd1`)
3. Create a matching test file in `tests/unit/Public/`

Or use Anvil if installed:

```powershell
New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public
```

## Guidelines

- Use an [approved PowerShell verb](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands) (`Get-Verb` lists them all)
- Include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- Add `[CmdletBinding()]` and `[OutputType()]` to every function
- One function per file, named to match the function

## Subdirectories

You can organize functions into subdirectories (e.g. `Public/Core/`, `Public/Utilities/`). The module loader discovers `.ps1` files recursively, so nesting has no effect on behavior. The build compiles them all into the same `.psm1`.
