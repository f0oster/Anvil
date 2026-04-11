# Customization

Anvil projects are convention-based. You can extend the structure by adding files in the right places — the build system discovers them automatically without configuration changes.

## Module-scoped variables

`Imports.ps1` runs before any functions or classes load. It's the right place for module-level state:

```powershell
$script:ResourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'Resources'
$script:ApiBaseUrl = 'https://api.example.com/v1'
$script:DefaultTimeout = 30
```

These `$script:` variables are accessible from all functions and are merged into the compiled `.psm1` at build time. Don't put function definitions here — use `Public/` or `Private/` for that.

## PowerShell classes

Classes in `PrivateClasses/` are loaded before functions, so both Public and Private functions can depend on them.

```powershell
New-AnvilClass -ClassName 'ApiResponse'
```

### Things to know about PowerShell classes

Classes behave differently from functions in several ways that matter for daily development.

**Type updates require a new session.** This is the most common source of confusion. When you change a class definition and run `Import-Module -Force`, PowerShell reloads the functions but the class definition is pinned to the .NET type system from the first load. You must close and reopen your PowerShell session to pick up class changes. There's no workaround — this is a PowerShell engine limitation.

**Load order is alphabetical.** Files in `PrivateClasses/` are loaded in filename order. If class `B` inherits from class `A`, make sure `A.ps1` sorts before `B.ps1`. A common convention is to prefix with numbers (`01-BaseClass.ps1`, `02-DerivedClass.ps1`) when inheritance order matters.

**Classes can't see `$script:` variables.** Unlike functions, class methods don't have access to module-scoped variables. If a class needs configuration or state from the module, pass it through the constructor or a method parameter.

**Classes are private by default.** There's no `ClassesToExport` in the module manifest. Classes defined inside a module aren't accessible to users. If you need to expose a class, users must use `using module YourModule`, which has its own limitations (it runs at parse time, not runtime).

**Method overloading is limited.** You can overload by parameter count or type, but not by parameter name alone. Two methods with the same name and the same number of `[string]` parameters won't compile.

## Custom PSScriptAnalyzer rules

The Lint task automatically discovers `.psm1` files in `build/analyzers/` and loads them as custom rule sources. To add a rule, create a new `.psm1` file:

```powershell
# build/analyzers/MyProjectRules.psm1
using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic
using namespace System.Management.Automation.Language

function AvoidHardcodedPaths {
    [CmdletBinding()]
    [OutputType([DiagnosticRecord])]
    param(
        [StringConstantExpressionAst]$ast
    )

    if ($ast.Value -match '^[A-Z]:\\') {
        [DiagnosticRecord]@{
            Message  = 'Avoid hardcoded Windows paths. Use Join-Path or environment variables.'
            Extent   = $ast.Extent
            RuleName = $myinvocation.MyCommand.Name
            Severity = 'Warning'
        }
    }
}
```

Each rule is a function that receives an AST node and returns `DiagnosticRecord` objects for violations. The function name becomes the rule name. PSSA calls your function once per matching AST node in each file being analyzed.

Common AST parameter types:
- `[ScriptBlockAst]` — entire function/script bodies
- `[FunctionDefinitionAst]` — function definitions
- `[CommandAst]` — command invocations
- `[StringConstantExpressionAst]` — string literals

To disable any rule (built-in or custom), add it to `ExcludeRules` in `PSScriptAnalyzerSettings.psd1`:

```powershell
ExcludeRules = @(
    'PSAvoidUsingWriteHost'
    'AvoidHardcodedPaths'
)
```

## Runtime dependencies

Use `Add-AnvilDependency` to declare modules your module needs at runtime:

```powershell
Add-AnvilDependency -Name 'PSFramework' -Version '>=1.10.0'
Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0'
```

This updates `requirements.psd1` and the source manifest's `RequiredModules`. The bootstrap installs these during development, and the Build task populates `RequiredModules` in the published manifest automatically.

To remove a dependency:

```powershell
Remove-AnvilDependency -Name 'PSFramework' -Force
```

Build tools (InvokeBuild, Pester, PSScriptAnalyzer) belong in `build/build.requires.psd1`, not in `requirements.psd1`. Users of your published module shouldn't need Pester installed.

## Types and formatting

PowerShell supports custom type extensions and formatting views via `.ps1xml` files. These are useful when your module returns custom objects and you want to control how they display.

### Type extensions

Create `src/MyModule/Types/MyModule.Types.ps1xml` to add calculated properties, methods, or default display property sets to your types:

```xml
<Types>
  <Type>
    <Name>MyModule.ConnectionResult</Name>
    <Members>
      <ScriptProperty>
        <Name>IsSuccess</Name>
        <GetScriptBlock>$this.StatusCode -lt 400</GetScriptBlock>
      </ScriptProperty>
    </Members>
  </Type>
</Types>
```

### Formatting views

Create `src/MyModule/Formats/MyModule.Format.ps1xml` to define table or list views:

```xml
<Configuration>
  <ViewDefinitions>
    <View>
      <Name>MyModule.ConnectionResult</Name>
      <ViewSelectedBy>
        <TypeName>MyModule.ConnectionResult</TypeName>
      </ViewSelectedBy>
      <TableControl>
        <TableHeaders>
          <TableColumnHeader><Label>Host</Label></TableColumnHeader>
          <TableColumnHeader><Label>Status</Label></TableColumnHeader>
          <TableColumnHeader><Label>Latency</Label></TableColumnHeader>
        </TableHeaders>
        <TableRowEntries>
          <TableRowEntry>
            <TableColumnItems>
              <TableColumnItem><PropertyName>Host</PropertyName></TableColumnItem>
              <TableColumnItem><PropertyName>StatusCode</PropertyName></TableColumnItem>
              <TableColumnItem><PropertyName>LatencyMs</PropertyName></TableColumnItem>
            </TableColumnItems>
          </TableRowEntry>
        </TableRowEntries>
      </TableControl>
    </View>
  </ViewDefinitions>
</Configuration>
```

### Wiring them up

Reference both in your module manifest:

```powershell
TypesToProcess   = @('Types/MyModule.Types.ps1xml')
FormatsToProcess = @('Formats/MyModule.Format.ps1xml')
```

The Build task copies `Types/` and `Formats/` directories to the staged module and carries these manifest properties through to the published manifest.

**Important:** Type and format files affect the entire PowerShell session, not just your module. If you add a formatting view for `System.IO.FileInfo`, it changes how files display everywhere. Keep your type extensions scoped to types your module owns.

## Subdirectory organization

All three source directories (`Public/`, `Private/`, `PrivateClasses/`) support arbitrary nesting:

```
src/MyModule/
    Public/
        Dns/
            Get-DnsRecord.ps1
            Resolve-DnsName.ps1
        Http/
            Invoke-ApiRequest.ps1
    Private/
        Dns/
            Format-DnsResponse.ps1
```

Use `-Location` when creating files to place them in subdirectories:

```powershell
New-AnvilFunction -FunctionName 'Get-DnsRecord' -Scope Public -Location 'Dns'
```

The module loader and build system discover `.ps1` files recursively, so nesting is purely organizational. It doesn't affect loading order, exports, or compilation. Use it when your module has enough functions that a flat directory becomes hard to navigate.

## Adding build tasks

InvokeBuild tasks are PowerShell scriptblocks. Add them to `build/module.build.ps1`:

```powershell
task Deploy {
    Write-BuildHeader 'Deploy'
    # your deployment logic here
    Write-BuildFooter 'Deploy complete'
}
```

Add the task name to a composite task to include it in a pipeline, or run it standalone:

```powershell
Invoke-Build -File ./build/module.build.ps1 -Task Deploy
```
