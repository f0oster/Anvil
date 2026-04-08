@{
    Severity = @('Error', 'Warning', 'Information')
    ExcludeRules = @('PSAvoidUsingWriteHost')
    Rules = @{
        PSPlaceOpenBrace = @{ Enable = $true; OnSameLine = $true; NewLineAfter = $true; IgnoreOneLineBlock = $true }
        PSPlaceCloseBrace = @{ Enable = $true; NoEmptyLineBefore = $false; IgnoreOneLineBlock = $true; NewLineAfter = $true }
        PSUseConsistentIndentation = @{ Enable = $true; IndentationSize = 4; PipelineIndentation = 'IncreaseIndentationForFirstPipeline'; Kind = 'space' }
        PSUseConsistentWhitespace = @{ Enable = $true; CheckInnerBrace = $true; CheckOpenBrace = $true; CheckOpenParen = $true; CheckOperator = $true; CheckPipe = $true; CheckSeparator = $true; IgnoreAssignmentOperatorInsideHashTable = $true }
        PSUseCorrectCasing = @{ Enable = $true }
        PSUseCompatibleSyntax = @{ Enable = $true; TargetVersions = @('5.1', '7.2') }
    }
}
