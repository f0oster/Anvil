# Private Functions

Functions in this directory are internal helpers. They are loaded at import time but not exported, so users cannot call them directly.

## Adding a new function

1. Create `<FunctionName>.ps1` in this directory (or a subdirectory)
2. Create a matching test file in `tests/unit/Private/`
3. Do **not** add it to `FunctionsToExport` in the manifest

Or use Anvil if installed:

```powershell
New-AnvilFunction -FunctionName 'ConvertTo-Internal' -Scope Private
```

## Guidelines

- Private functions do not need approved verbs, but consistent naming still helps
- `[CmdletBinding()]` is optional but useful if you want `-Verbose`/`-Debug` support
- Comment-based help is optional -- use your judgement based on complexity
- One function per file, named to match the function

## When to use Private vs PrivateClasses

Use Private functions for procedural helper logic (formatting, validation, IO wrappers). Use PrivateClasses for stateful objects, type definitions, or when you need methods, constructors, or inheritance.

## Testing

Private functions are tested via `InModuleScope`. See `tests/unit/Private/README.md` for details.
