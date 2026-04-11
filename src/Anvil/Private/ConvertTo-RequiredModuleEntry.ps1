function ConvertTo-RequiredModuleEntry {
    <#
    .SYNOPSIS
        Converts a module name and ModuleFast version spec into a
        RequiredModules entry for New-ModuleManifest.

    .DESCRIPTION
        Maps ModuleFast version spec syntax to the hashtable format
        expected by the RequiredModules manifest key:

          '>=5.0.0'  -> @{ ModuleName = '...'; ModuleVersion = '5.0.0' }
          '5.7.1'    -> @{ ModuleName = '...'; RequiredVersion = '5.7.1' }
          'latest'   -> 'ModuleName' (bare string)

    .PARAMETER Name
        The module name.

    .PARAMETER VersionSpec
        ModuleFast version specification string.
    #>
    [CmdletBinding()]
    [OutputType([string], [hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$VersionSpec
    )

    if ($VersionSpec -eq 'latest') {
        return $Name
    }

    if ($VersionSpec -match '^>=(.+)$') {
        return @{
            ModuleName    = $Name
            ModuleVersion = $Matches[1]
        }
    }

    @{
        ModuleName      = $Name
        RequiredVersion = $VersionSpec
    }
}
