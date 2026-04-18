function Read-TemplateManifest {
    <#
    .SYNOPSIS
        Loads and validates a template manifest from a template directory.

    .DESCRIPTION
        Reads a template.psd1 file from the specified directory using
        Import-PowerShellDataFile, then validates the resulting hashtable
        with Assert-TemplateManifest.

        Returns the validated manifest hashtable on success.  Throws if
        the file is missing, cannot be parsed, or fails schema validation.

    .PARAMETER TemplatePath
        Path to the template directory containing a template.psd1 file.

    .OUTPUTS
        System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TemplatePath
    )

    $ManifestFile = Join-Path -Path $TemplatePath -ChildPath 'template.psd1'

    if (-not (Test-Path -Path $ManifestFile)) {
        throw "Template manifest not found: $ManifestFile"
    }

    $Manifest = Import-PowerShellDataFile -Path $ManifestFile -ErrorAction Stop

    Assert-TemplateManifest -Manifest $Manifest

    return $Manifest
}
