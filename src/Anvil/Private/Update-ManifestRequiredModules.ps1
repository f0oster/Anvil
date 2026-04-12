function Update-ManifestRequiredModules {
    <#
    .SYNOPSIS
        Updates the RequiredModules field in a module manifest from a
        requirements hashtable.

    .DESCRIPTION
        Reads the manifest, rebuilds RequiredModules from the requirements
        hashtable, and writes the manifest back using New-ModuleManifest.

    .PARAMETER ManifestPath
        Full path to the module manifest (.psd1) to update.

    .PARAMETER Requirements
        Hashtable of module names to ModuleFast version specs.
        An empty hashtable clears RequiredModules.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [Parameter(Mandatory)]
        [hashtable]$Requirements
    )

    $Entries = @()
    foreach ($Key in ($Requirements.Keys | Sort-Object)) {
        $Entries += ConvertTo-RequiredModuleEntry -Name $Key -VersionSpec $Requirements[$Key]
    }

    if (-not $PSCmdlet.ShouldProcess($ManifestPath, 'Update RequiredModules')) {
        return
    }

    $Source = Import-PowerShellDataFile -Path $ManifestPath
    $PSData = $Source.PrivateData.PSData

    $Params = @{
        Path              = $ManifestPath
        RootModule        = $Source.RootModule
        ModuleVersion     = $Source.ModuleVersion
        Guid              = $Source.GUID
        Author            = $Source.Author
        CompanyName       = $Source.CompanyName
        Copyright         = $Source.Copyright
        Description       = $Source.Description
        PowerShellVersion = $Source.PowerShellVersion
        RequiredModules   = $Entries
        FunctionsToExport = $Source.FunctionsToExport
        CmdletsToExport   = $Source.CmdletsToExport
        VariablesToExport  = $Source.VariablesToExport
        AliasesToExport    = $Source.AliasesToExport
    }

    if ($Source.CompatiblePSEditions) { $Params.CompatiblePSEditions = $Source.CompatiblePSEditions }
    if ($Source.RequiredAssemblies) { $Params.RequiredAssemblies = $Source.RequiredAssemblies }
    if ($Source.NestedModules) { $Params.NestedModules = $Source.NestedModules }
    if ($Source.ScriptsToProcess) { $Params.ScriptsToProcess = $Source.ScriptsToProcess }
    if ($Source.TypesToProcess) { $Params.TypesToProcess = $Source.TypesToProcess }
    if ($Source.FormatsToProcess) { $Params.FormatsToProcess = $Source.FormatsToProcess }

    if ($PSData) {
        if ($PSData.Tags -and $PSData.Tags.Count -gt 0) { $Params.Tags = $PSData.Tags }
        if ($PSData.LicenseUri) { $Params.LicenseUri = $PSData.LicenseUri }
        if ($PSData.ProjectUri) { $Params.ProjectUri = $PSData.ProjectUri }
        if ($PSData.ReleaseNotes) { $Params.ReleaseNotes = $PSData.ReleaseNotes }
        if ($PSData.Prerelease) { $Params.Prerelease = $PSData.Prerelease }
    }

    New-ModuleManifest @Params

    $Warning = @(
        '# WARNING: This file is managed by Anvil. Do not edit it directly.'
        '# Changes to RequiredModules will be overwritten by Add-AnvilDependency / Remove-AnvilDependency.'
        '# The build process regenerates this manifest from source when packaging.'
    ) -join "`n"
    $Content = Get-Content -Path $ManifestPath -Raw
    Set-Content -Path $ManifestPath -Value "$Warning`n$Content" -NoNewline
}
