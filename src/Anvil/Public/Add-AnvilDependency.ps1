function Add-AnvilDependency {
    <#
    .SYNOPSIS
        Adds a module dependency to an Anvil project.

    .DESCRIPTION
        Declares a required module dependency by updating both
        requirements.psd1 (for bootstrap/build) and the source module
        manifest RequiredModules (for development).

        If the dependency already exists, its version spec is updated.

    .PARAMETER Name
        The name of the module to add as a dependency.

    .PARAMETER Version
        ModuleFast version specification string.
        Examples: '>=5.0.0' (minimum), '5.7.1' (exact), 'latest' (any).
        Default: 'latest'.

    .PARAMETER Path
        The project root directory. If not provided, walks up from the
        current directory to find the project root.

    .PARAMETER Force
        Overwrite the version spec if the dependency already exists
        without prompting.

    .EXAMPLE
        Add-AnvilDependency -Name 'Az.Storage' -Version '>=5.0.0'

    .EXAMPLE
        Add-AnvilDependency -Name 'PSFramework' -Version '1.12.346'

    .EXAMPLE
        Add-AnvilDependency -Name 'ImportExcel'

        Adds ImportExcel with version spec 'latest'.

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

        [Parameter(Position = 1)]
        [ValidateScript({
                if ($_ -eq 'latest') { return $true }
                if ($_ -match '^>=.+$') {
                    $ver = $_ -replace '^>=', ''
                    if ($ver -as [version]) { return $true }
                    throw "'$_' is not a valid version spec. The version after >= must be a valid version string (e.g. '>=5.0.0')."
                }
                if ($_ -as [version]) { return $true }
                throw "'$_' is not a valid version spec. Use 'latest', '>=x.y.z', or an exact version like '5.7.1'."
            })]
        [string]$Version = 'latest',

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

    # Read current requirements
    $Requirements = Read-RequirementsFile -Path $RequirementsPath

    # Check for existing entry
    if ($Requirements.ContainsKey($Name) -and -not $Force) {
        $Existing = $Requirements[$Name]
        if ($Existing -eq $Version) {
            Write-Host "[Anvil] '$Name' already at version spec '$Version'." -ForegroundColor DarkGray
            return
        }
        $ConfirmMsg = "'$Name' already exists with version spec '$Existing'. Update to '$Version'?"
        if (-not $PSCmdlet.ShouldContinue($ConfirmMsg, 'Update dependency?')) {
            return
        }
    }

    if ($PSCmdlet.ShouldProcess("$Name = $Version", 'Add module dependency')) {
        $Requirements[$Name] = $Version

        Write-RequirementsFile -Path $RequirementsPath -Requirements $Requirements
        Update-ManifestRequiredModules -ManifestPath $ManifestPath -Requirements $Requirements

        Write-Host "[Anvil] Added dependency: $Name = $Version" -ForegroundColor Green
        Write-Host "[Anvil] Run Invoke-AnvilBootstrapDeps to install it." -ForegroundColor White

        [PSCustomObject]@{
            Name    = $Name
            Version = $Version
            Action  = 'Added'
        }
    }
}
