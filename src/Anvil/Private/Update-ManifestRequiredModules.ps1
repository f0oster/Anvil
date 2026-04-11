function Update-ManifestRequiredModules {
    <#
    .SYNOPSIS
        Updates the RequiredModules field in a module manifest from a
        requirements hashtable.

    .DESCRIPTION
        Reads the requirements hashtable, converts each entry to the
        RequiredModules format, and replaces the RequiredModules line
        in the manifest file.

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

    # Build the replacement text for RequiredModules
    if ($Entries.Count -eq 0) {
        $Replacement = '    RequiredModules    = @()'
    } else {
        $Lines = @()
        foreach ($Entry in $Entries) {
            if ($Entry -is [string]) {
                $Lines += "        '$Entry'"
            } else {
                $Parts = @("ModuleName = '$($Entry.ModuleName)'")
                if ($Entry.ContainsKey('ModuleVersion')) {
                    $Parts += "ModuleVersion = '$($Entry.ModuleVersion)'"
                }
                if ($Entry.ContainsKey('RequiredVersion')) {
                    $Parts += "RequiredVersion = '$($Entry.RequiredVersion)'"
                }
                $Lines += "        @{ $($Parts -join '; ') }"
            }
        }
        $Replacement = "    RequiredModules    = @(`n$($Lines -join "`n")`n    )"
    }

    if ($PSCmdlet.ShouldProcess($ManifestPath, 'Update RequiredModules')) {
        $Content = Get-Content -Path $ManifestPath -Raw
        $Content = $Content -replace '(?m)^\s*RequiredModules\s*=\s*@\([^)]*\)', $Replacement
        Set-Content -Path $ManifestPath -Value $Content -NoNewline
    }
}
