function Invoke-AnvilBuild {
    <#
    .SYNOPSIS
        Runs the InvokeBuild pipeline in an Anvil project.

    .DESCRIPTION
        Locates build/module.build.ps1 in the project root and invokes it
        with the specified tasks. If no tasks are specified, runs the
        default pipeline.

    .PARAMETER Task
        One or more build tasks to run. When omitted, runs the default
        pipeline (Clean, Validate, Format, Lint, Test, Build,
        IntegrationTest, Package).

    .PARAMETER NewVersion
        Version number to inject into the compiled module manifest.

    .PARAMETER Prerelease
        Prerelease label to set on the compiled module manifest.

    .PARAMETER Path
        The project root directory. If not provided, walks up from the
        current directory to find the project root.

    .EXAMPLE
        Invoke-AnvilBuild

    .EXAMPLE
        Invoke-AnvilBuild -Task Lint, Test

    .EXAMPLE
        Invoke-AnvilBuild -Task Release -NewVersion 1.0.0

    .INPUTS
        None

    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Justification = 'Invoke-Build is the canonical entry point for InvokeBuild')]
    param(
        [Parameter(Position = 0)]
        [string[]]$Task,

        [Parameter()]
        [string]$NewVersion,

        [Parameter()]
        [string]$Prerelease,

        [Parameter()]
        [string]$Path
    )

    if ($Path) {
        $StartPath = $Path
    } else {
        $StartPath = $PWD.Path
    }

    $Resolved = Resolve-AnvilProjectRoot -StartPath $StartPath
    if (-not $Resolved) { return }

    $BuildScript = Join-Path $Resolved.ProjectRoot 'build' | Join-Path -ChildPath 'module.build.ps1'

    if (-not (Test-Path $BuildScript)) {
        Write-Error "Build script not found: $BuildScript"
        return
    }

    if (-not (Get-Command -Name 'Invoke-Build' -ErrorAction SilentlyContinue)) {
        Write-Error "Invoke-Build is not installed. Run Invoke-AnvilBootstrapDeps first."
        return
    }

    $BuildParams = @{
        File = $BuildScript
    }
    if ($Task) { $BuildParams['Task'] = $Task }
    if ($NewVersion) { $BuildParams['NewVersion'] = $NewVersion }
    if ($Prerelease) { $BuildParams['Prerelease'] = $Prerelease }

    $Script = [scriptblock]::Create('param($Params) Invoke-Build @Params')
    $PSCmdlet.InvokeCommand.InvokeScript($PSCmdlet.SessionState, $Script, @($BuildParams))
}
