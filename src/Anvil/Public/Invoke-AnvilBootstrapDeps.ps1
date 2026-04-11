function Invoke-AnvilBootstrapDeps {
    <#
    .SYNOPSIS
        Runs the bootstrap script in an Anvil project to install dependencies.

    .DESCRIPTION
        Locates and executes build/bootstrap.ps1 in the project root, which
        installs both the Anvil build toolchain and any module dependencies
        declared in requirements.psd1.

    .PARAMETER Path
        The project root directory. If not provided, walks up from the
        current directory to find the project root.

    .PARAMETER Scope
        One or more dependency group names to install from build.requires.psd1.
        When omitted, all groups are installed.

    .PARAMETER Update
        Forces ModuleFast to re-check for newer versions.

    .PARAMETER Plan
        Shows what would be installed without installing anything.

    .EXAMPLE
        Invoke-AnvilBootstrapDeps

    .EXAMPLE
        Invoke-AnvilBootstrapDeps -Scope Build,Test

    .EXAMPLE
        Invoke-AnvilBootstrapDeps -Plan

    .INPUTS
        None

    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path,

        [Parameter()]
        [string[]]$Scope,

        [Parameter()]
        [switch]$Update,

        [Parameter()]
        [switch]$Plan
    )

    if ($Path) {
        $StartPath = $Path
    } else {
        $StartPath = $PWD.Path
    }

    $Resolved = Resolve-AnvilProjectRoot -StartPath $StartPath
    if (-not $Resolved) { return }

    $BootstrapPath = Join-Path $Resolved.ProjectRoot 'build' | Join-Path -ChildPath 'bootstrap.ps1'

    if (-not (Test-Path $BootstrapPath)) {
        Write-Error "Bootstrap script not found: $BootstrapPath"
        return
    }

    $BootstrapParams = @{}
    if ($Scope) { $BootstrapParams['Scope'] = $Scope }
    if ($Update) { $BootstrapParams['Update'] = $true }
    if ($Plan) { $BootstrapParams['Plan'] = $true }

    & $BootstrapPath @BootstrapParams
}
