function New-AnvilTest {
    <#
    .SYNOPSIS
        Creates a new Pester 5 test file for a function in an Anvil-scaffolded module.

    .DESCRIPTION
        Generates a test file with the correct boilerplate for testing a public or
        private function.  The file is placed in the appropriate tests/unit/Public/
        or tests/unit/Private/ directory based on the -Scope parameter.

        The module name is read from build/build.settings.psd1 in the project root.

    .PARAMETER FunctionName
        The name of the function to test.  The generated file will be named
        <FunctionName>.Tests.ps1.

    .PARAMETER Scope
        Whether the function is Public (exported) or Private (internal).
        Determines the output directory and whether InModuleScope is used.

    .PARAMETER Location
        Optional subdirectory path relative to the scope root.  For example,
        -Location 'Core/Greetings' places the test file under
        tests/unit/<Scope>/Core/Greetings/.

    .PARAMETER Path
        The project root directory.  If not provided, the current directory is
        used and the command walks up the directory tree to find the project root.
        You will be prompted to confirm before the walk-up begins.

    .PARAMETER Force
        Overwrite the test file if it already exists.

    .EXAMPLE
        New-AnvilTest -FunctionName 'Get-Widget' -Scope Public

    .EXAMPLE
        New-AnvilTest -FunctionName 'Resolve-InternalState' -Scope Private -Path C:\Projects\MyModule

    .EXAMPLE
        New-AnvilTest -FunctionName 'Get-Widget' -Scope Public -Location 'Core/Greetings'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        [ValidateSet('Public', 'Private')]
        [string]$Scope,

        [Parameter()]
        [string]$Location,

        [Parameter()]
        [string]$Path,

        [Parameter()]
        [switch]$Force
    )

    # Resolve the project root
    if ($Path) {
        $ProjectRoot = $Path
    } else {
        $Message = 'No -Path provided. The current directory will be searched, ' +
        'walking up the directory tree to find the project root (build/build.settings.psd1). ' +
        'If you are not inside an Anvil project, this will walk to the root of the drive.'
        if (-not $PSCmdlet.ShouldContinue($Message, 'Search for project root?')) {
            return
        }
        $ProjectRoot = $PWD.Path
    }

    # Walk up to find build/build.settings.psd1
    $SearchDir = $ProjectRoot
    while ($SearchDir -and -not (Test-Path (Join-Path $SearchDir 'build/build.settings.psd1'))) {
        $Parent = Split-Path $SearchDir -Parent
        if ($Parent -eq $SearchDir) {
            # Reached the root of the drive
            $SearchDir = $null
            break
        }
        $SearchDir = $Parent
    }

    if (-not $SearchDir) {
        $ErrorParams = @{
            Message      = "Could not find build/build.settings.psd1 in '$ProjectRoot' or any parent directory. Are you inside an Anvil project?"
            Category     = 'ObjectNotFound'
            TargetObject = $ProjectRoot
        }
        Write-Error @ErrorParams
        return
    }
    $ProjectRoot = $SearchDir

    # Read the module name from build settings
    $SettingsPath = Join-Path $ProjectRoot 'build/build.settings.psd1'
    $Settings = Import-PowerShellDataFile -Path $SettingsPath

    if (-not $Settings.ModuleName) {
        Write-Error "build/build.settings.psd1 does not contain a ModuleName key."
        return
    }
    $ModuleName = $Settings.ModuleName

    # Build the output path
    $TestDir = Join-Path $ProjectRoot 'tests' | Join-Path -ChildPath 'unit' | Join-Path -ChildPath $Scope
    if ($Location) {
        $TestDir = Join-Path $TestDir $Location
    }
    $TestFile = Join-Path $TestDir "$FunctionName.Tests.ps1"

    if ((Test-Path $TestFile) -and -not $Force) {
        Write-Error "Test file already exists: $TestFile. Use -Force to overwrite."
        return
    }

    # Generate test content
    $ContentParams = @{
        FunctionName = $FunctionName
        ModuleName   = $ModuleName
        Scope        = $Scope
    }
    $Content = Get-TestContent @ContentParams

    if ($PSCmdlet.ShouldProcess($TestFile, 'Create test file')) {
        if (-not (Test-Path $TestDir)) {
            New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
        }
        Set-Content -Path $TestFile -Value $Content -Encoding UTF8 -NoNewline
        Get-Item $TestFile
    }
}
