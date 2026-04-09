function Copy-CITemplates {
    <#
    .SYNOPSIS
        Layers CI-provider-specific template files into a scaffolded project.

    .DESCRIPTION
        Called after the base module template is expanded.  Copies and
        processes .tmpl files from Templates/CI/<Provider>/ into the
        destination, applying the same token replacement rules as the base
        template engine.

    .PARAMETER Provider
        CI platform whose templates should be applied.
        Valid values: GitHub, AzurePipelines, GitLab.

    .PARAMETER DestinationPath
        Root of the already-scaffolded project directory.

    .PARAMETER Tokens
        Token hashtable passed through to Invoke-TemplateEngine.

    .OUTPUTS
        System.Int32
            The number of CI template files processed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GitHub', 'AzurePipelines', 'GitLab')]
        [string]$Provider,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [Parameter(Mandatory)]
        [hashtable]$Tokens
    )

    $CiTemplatePath = Join-Path -Path $script:TemplateRoot -ChildPath 'CI'
    $ProviderPath = Join-Path -Path $CiTemplatePath -ChildPath $Provider

    if (-not (Test-Path -Path $ProviderPath)) {
        Write-Warning "CI template directory not found for provider '$Provider' at: $ProviderPath"
        return 0
    }

    $Count = Invoke-TemplateEngine -SourcePath $ProviderPath -DestinationPath $DestinationPath -Tokens $Tokens
    return $Count
}
