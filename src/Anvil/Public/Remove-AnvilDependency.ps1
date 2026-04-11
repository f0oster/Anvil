function Remove-AnvilDependency {
    <#
    .SYNOPSIS
        Removes a module dependency from an Anvil project.

    .DESCRIPTION
        Removes a required module dependency from both requirements.psd1
        and the source module manifest RequiredModules.

    .PARAMETER Name
        The name of the module to remove.

    .PARAMETER Path
        The project root directory. If not provided, walks up from the
        current directory to find the project root.

    .PARAMETER Force
        Remove the dependency without prompting for confirmation.

    .EXAMPLE
        Remove-AnvilDependency -Name 'Az.Storage'

    .INPUTS
        None

    .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [string]$Path,

        [Parameter()]
        [switch]$Force
    )

    # Resolve project root
    if ($Path) {
        $StartPath = $Path
    } else {
        $Message = 'No -Path provided. The current directory will be searched, ' +
        'walking up the directory tree to find the project root (build/build.settings.psd1). ' +
        'If you are not inside an Anvil project, this will walk to the root of the drive.'
        if (-not $PSCmdlet.ShouldContinue($Message, 'Search for project root?')) {
            return
        }
        $StartPath = $PWD.Path
    }

    $Resolved = Resolve-AnvilProjectRoot -StartPath $StartPath
    if (-not $Resolved) { return }
    $ProjectRoot = $Resolved.ProjectRoot
    $ModuleName = $Resolved.ModuleName

    $RequirementsPath = Join-Path $ProjectRoot 'requirements.psd1'
    $ManifestPath = Join-Path $ProjectRoot 'src' |
        Join-Path -ChildPath $ModuleName |
        Join-Path -ChildPath "$ModuleName.psd1"

    $Requirements = Read-RequirementsFile -Path $RequirementsPath

    if (-not $Requirements.ContainsKey($Name)) {
        Write-Error "'$Name' is not a declared dependency."
        return
    }

    $OldVersion = $Requirements[$Name]

    if (-not $Force -and -not $PSCmdlet.ShouldContinue("Remove dependency '$Name' ($OldVersion)?", 'Confirm removal')) {
        return
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Remove module dependency')) {
        $Requirements.Remove($Name)

        Write-RequirementsFile -Path $RequirementsPath -Requirements $Requirements
        Update-ManifestRequiredModules -ManifestPath $ManifestPath -Requirements $Requirements

        Write-Host "[Anvil] Removed dependency: $Name (was $OldVersion)" -ForegroundColor Yellow

        [PSCustomObject]@{
            Name    = $Name
            Version = $OldVersion
            Action  = 'Removed'
        }
    }
}
