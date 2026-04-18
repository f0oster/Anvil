function Resolve-TemplateSections {
    <#
    .SYNOPSIS
        Processes conditional section markers in template content.

    .DESCRIPTION
        Scans template content for <%#section Name%> / <%#endsection%>
        marker pairs and evaluates the corresponding manifest condition
        to determine whether to keep or strip each block.

        When a section's condition is met, the block content is kept and
        the marker lines are removed.  When the condition is not met, the
        entire block including markers is removed.

        Sections cannot nest.  A section name appearing in the content
        without a matching entry in the Sections hashtable causes a
        terminating error.

        Content with no section markers passes through unchanged.

    .PARAMETER Content
        The raw template file content to process.

    .PARAMETER Sections
        Hashtable from the template manifest mapping section names to
        condition definitions.  Each value is a hashtable with exactly
        one key: either 'IncludeWhen' or 'ExcludeWhen', whose value is
        a condition hashtable compatible with Test-ManifestCondition.

    .PARAMETER Tokens
        Hashtable of resolved token values used to evaluate conditions.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Sections', Justification = 'Used inside regex Replace scriptblock')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Tokens', Justification = 'Used inside regex Replace scriptblock')]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory)]
        [hashtable]$Sections,

        [Parameter(Mandatory)]
        [hashtable]$Tokens
    )

    $Pattern = '(?m)^[ \t]*<%#section\s+(\w+)%>\s*\r?\n([\s\S]*?)^[ \t]*<%#endsection%>\s*\r?\n?'

    $Result = [regex]::Replace($Content, $Pattern, {
            param($Match)

            $SectionName = $Match.Groups[1].Value
            $SectionBody = $Match.Groups[2].Value

            if (-not $Sections.ContainsKey($SectionName)) {
                throw "Section '$SectionName' found in template but not declared in manifest Sections."
            }

            $SectionDef = $Sections[$SectionName]
            $Keep = $false

            if ($SectionDef.ContainsKey('IncludeWhen')) {
                $Keep = Test-ManifestCondition -Condition $SectionDef['IncludeWhen'] -Tokens $Tokens
            } elseif ($SectionDef.ContainsKey('ExcludeWhen')) {
                $Keep = -not (Test-ManifestCondition -Condition $SectionDef['ExcludeWhen'] -Tokens $Tokens)
            }

            if ($Keep) { $SectionBody } else { '' }
        })

    return $Result
}
