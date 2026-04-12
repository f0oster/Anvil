# Customization

Anvil projects are convention-based. The build system discovers files automatically — you extend the project by adding files in the right places, not by editing configuration.

For day-to-day tasks like adding functions, classes, and dependencies, see [Development](development.md). This page covers advanced extension points.

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

Note that modifying `module.build.ps1` means your project's build pipeline has diverged from Anvil's default. Future Anvil versions may ship updated build scripts, and migrating will require manually merging your changes.
