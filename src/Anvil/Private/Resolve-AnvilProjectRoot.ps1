function Resolve-AnvilProjectRoot {
    <#
    .SYNOPSIS
        Locates the nearest Anvil project root and reads its module name.

    .DESCRIPTION
        Walks up the directory tree from the given starting path looking for
        build/build.settings.psd1.  When found, reads the ModuleName from
        that file and returns both values in a hashtable.

        Returns nothing if the project root cannot be found or the settings
        file is missing a ModuleName key.

    .PARAMETER StartPath
        The directory to start searching from.  Walks up toward the drive
        root until build/build.settings.psd1 is found.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$StartPath
    )

    $SearchDir = $StartPath
    while ($SearchDir -and -not (Test-Path (Join-Path $SearchDir 'build/build.settings.psd1'))) {
        $Parent = Split-Path $SearchDir -Parent
        if ($Parent -eq $SearchDir) {
            $SearchDir = $null
            break
        }
        $SearchDir = $Parent
    }

    if (-not $SearchDir) {
        $ErrorParams = @{
            Message      = "Could not find build/build.settings.psd1 in '$StartPath' or any parent directory. Are you inside an Anvil project?"
            Category     = 'ObjectNotFound'
            TargetObject = $StartPath
        }
        Write-Error @ErrorParams
        return
    }

    $SettingsPath = Join-Path $SearchDir 'build/build.settings.psd1'
    $Settings = Import-PowerShellDataFile -Path $SettingsPath

    if (-not $Settings.ModuleName) {
        Write-Error "build/build.settings.psd1 does not contain a ModuleName key."
        return
    }

    @{
        ProjectRoot = $SearchDir
        ModuleName  = $Settings.ModuleName
    }
}
