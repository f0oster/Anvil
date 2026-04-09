# Custom PSScriptAnalyzer rules adapted from Indented.ScriptAnalyzerRules
# by Chris Dent (https://github.com/indented-automation/Indented.ScriptAnalyzerRules)
# Licensed under the MIT License.

using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic
using namespace System.Management.Automation.Language

function AvoidProcessWithoutPipeline {
    <#
    .SYNOPSIS
        Flags functions that declare a process block without pipeline input.

    .DESCRIPTION
        A process block only runs per-item when the function accepts pipeline
        input via ValueFromPipeline or ValueFromPipelineByPropertyName.
        Without either attribute, process behaves identically to end and
        misleads readers into thinking the function supports the pipeline.
    #>
    [CmdletBinding()]
    [OutputType([DiagnosticRecord])]
    param(
        [ScriptBlockAst]$ast
    )

    if ($null -ne $ast.ProcessBlock -and $ast.ParamBlock) {
        $PipelineParam = $ast.ParamBlock.Find(
            {
                param($node)
                $node -is [AttributeAst] -and
                $node.TypeName.Name -eq 'Parameter' -and
                $node.NamedArguments.Where{
                    $_.ArgumentName -in 'ValueFromPipeline', 'ValueFromPipelineByPropertyName' -and
                    $_.Argument.SafeGetValue() -eq $true
                }
            },
            $false
        )

        if (-not $PipelineParam) {
            [DiagnosticRecord]@{
                Message = 'process block declared without a pipeline parameter (ValueFromPipeline or ValueFromPipelineByPropertyName)'
                Extent = $ast.ProcessBlock.Extent
                RuleName = $myinvocation.MyCommand.Name
                Severity = 'Warning'
            }
        }
    }
}

function AvoidNestedFunctions {
    <#
    .SYNOPSIS
        Flags function definitions nested inside other functions.

    .DESCRIPTION
        Nested functions are re-created on every call, pollute the parent
        scope, and are difficult to test independently. Extract them to
        module-level private functions instead.
    #>
    [CmdletBinding()]
    [OutputType([DiagnosticRecord])]
    param(
        [FunctionDefinitionAst]$ast
    )

    $ast.Body.FindAll(
        { param($node) $node -is [FunctionDefinitionAst] },
        $true
    ) | ForEach-Object {
        [DiagnosticRecord]@{
            Message = "Function '$($ast.Name)' contains nested function '$($_.Name)'. Extract it to a separate file."
            Extent = $_.Extent
            RuleName = $myinvocation.MyCommand.Name
            Severity = 'Warning'
        }
    }
}

function AvoidSmartQuotes {
    <#
    .SYNOPSIS
        Flags curly/smart quotation marks copied from word processors.

    .DESCRIPTION
        Smart quotes (U+2018, U+2019, U+201C, U+201D) look identical to
        normal quotes in some fonts but are not valid PowerShell syntax
        delimiters. Replace them with standard ASCII quotes.
    #>
    [CmdletBinding()]
    [OutputType([DiagnosticRecord])]
    param(
        [StringConstantExpressionAst]$ast
    )

    if ($ast.StringConstantType -eq 'BareWord') { return }

    $NormalQuotes = @("'", '"')

    if ($ast.StringConstantType -in 'DoubleQuotedHereString', 'SingleQuotedHereString') {
        $StartQuote, $EndQuote = $ast.Extent.Text[1, -2]
    } else {
        $StartQuote, $EndQuote = $ast.Extent.Text[0, -1]
    }

    if ($StartQuote -notin $NormalQuotes -or $EndQuote -notin $NormalQuotes) {
        [DiagnosticRecord]@{
            Message = 'Avoid smart quotes. Use standard ASCII quotes (" or '').'
            Extent = $ast.Extent
            RuleName = $myinvocation.MyCommand.Name
            Severity = 'Warning'
        }
    }
}

function AvoidEmptyNamedBlocks {
    <#
    .SYNOPSIS
        Flags empty begin, process, end, or dynamicparam blocks.

    .DESCRIPTION
        Empty named blocks are dead code that adds noise. Remove them
        unless you plan to add logic soon.
    #>
    [CmdletBinding()]
    [OutputType([DiagnosticRecord])]
    param(
        [ScriptBlockAst]$ast
    )

    foreach ($Block in @($ast.BeginBlock, $ast.ProcessBlock, $ast.EndBlock, $ast.DynamicParamBlock)) {
        if ($null -eq $Block) { continue }
        if ($null -eq $Block.Statements -or $Block.Statements.Count -eq 0) {
            [DiagnosticRecord]@{
                Message = "Empty '$($Block.BlockKind)' block. Remove it or add logic."
                Extent = $Block.Extent
                RuleName = $myinvocation.MyCommand.Name
                Severity = 'Warning'
            }
        }
    }
}

function AvoidNewObjectPSObject {
    <#
    .SYNOPSIS
        Flags New-Object PSObject in favor of [PSCustomObject].

    .DESCRIPTION
        [PSCustomObject]@{} is the modern, faster, and more readable way
        to create custom objects. New-Object PSObject is the legacy pattern.
    #>
    [CmdletBinding()]
    [OutputType([DiagnosticRecord])]
    param(
        [CommandAst]$ast
    )

    if ($ast.GetCommandName() -eq 'New-Object') {
        $TypeArg = $ast.CommandElements | Where-Object {
            $_ -is [StringConstantExpressionAst] -and
            $_.Value -in 'PSObject', 'PSCustomObject', 'System.Management.Automation.PSObject'
        }
        if ($TypeArg) {
            [DiagnosticRecord]@{
                Message = 'Use [PSCustomObject]@{} instead of New-Object PSObject.'
                Extent = $ast.Extent
                RuleName = $myinvocation.MyCommand.Name
                Severity = 'Information'
            }
        }
    }
}

function AvoidWriteOutput {
    <#
    .SYNOPSIS
        Flags unnecessary Write-Output calls.

    .DESCRIPTION
        In PowerShell, unassigned expressions automatically flow to the
        output pipeline. Write-Output is almost never needed and adds
        visual noise. Just emit the value directly.
    #>
    [CmdletBinding()]
    [OutputType([DiagnosticRecord])]
    param(
        [CommandAst]$ast
    )

    if ($ast.GetCommandName() -in 'Write-Output', 'write-output') {
        [DiagnosticRecord]@{
            Message = 'Avoid Write-Output. Unassigned expressions are output automatically.'
            Extent = $ast.Extent
            RuleName = $myinvocation.MyCommand.Name
            Severity = 'Information'
        }
    }
}
