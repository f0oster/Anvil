function Import-AnvilModule {
    <#
    .SYNOPSIS
        Imports the development version of the module from the current
        Anvil project.

    .DESCRIPTION
        Locates the source module manifest by walking up the directory
        tree, then imports it with -Force so any changes are picked up.

    .PARAMETER Path
        The project root directory. If not provided, walks up from the
        current directory to find the project root.

    .PARAMETER PassThru
        Returns the imported module info object.

    .EXAMPLE
        Import-AnvilModule

    .EXAMPLE
        Import-AnvilModule -PassThru

    .INPUTS
        None

    .OUTPUTS
        System.Management.Automation.PSModuleInfo
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo])]
    param(
        [Parameter()]
        [string]$Path,

        [Parameter()]
        [switch]$PassThru
    )

    if ($Path) {
        $StartPath = $Path
    } else {
        $StartPath = $PWD.Path
    }

    $Resolved = Resolve-AnvilProjectRoot -StartPath $StartPath
    if (-not $Resolved) { return }

    $ManifestPath = Join-Path $Resolved.ProjectRoot 'src' |
        Join-Path -ChildPath $Resolved.ModuleName |
        Join-Path -ChildPath "$($Resolved.ModuleName).psd1"

    if (-not (Test-Path $ManifestPath)) {
        Write-Error "Module manifest not found: $ManifestPath"
        return
    }

    $ImportParams = @{
        Name    = $ManifestPath
        Force   = $true
        Global  = $true
    }
    if ($PassThru) { $ImportParams.PassThru = $true }

    Import-Module @ImportParams
}
