function New-AnvilClass {
    <#
    .SYNOPSIS
        Creates a new PowerShell class file and its corresponding Pester test
        in an Anvil-scaffolded module.

    .DESCRIPTION
        Generates a class file in src/<ModuleName>/PrivateClasses/ and a
        matching test file in tests/unit/PrivateClasses/.

        The module name is read from build/build.settings.psd1 in the project root.

    .PARAMETER ClassName
        The name of the class to create. The generated files will be named
        <ClassName>.ps1 and <ClassName>.Tests.ps1.

    .PARAMETER Location
        Optional subdirectory path relative to PrivateClasses/. For example,
        -Location 'Models' places the files under
        src/<ModuleName>/PrivateClasses/Models/ and
        tests/unit/PrivateClasses/Models/.

    .PARAMETER Path
        The project root directory. If not provided, the current directory is
        used and the command walks up the directory tree to find the project root.
        You will be prompted to confirm before the walk-up begins.

    .PARAMETER Force
        Overwrite existing files if they already exist.

    .EXAMPLE
        New-AnvilClass -ClassName 'HttpClient'

    .EXAMPLE
        New-AnvilClass -ClassName 'CacheEntry' -Location 'Models'

    .EXAMPLE
        New-AnvilClass -ClassName 'HttpClient' -Path C:\Projects\MyModule

    .INPUTS
        None

    .OUTPUTS
        System.IO.FileInfo
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClassName,

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

    # Build the class file path
    $ClassDir = Join-Path $ProjectRoot 'src' |
        Join-Path -ChildPath $ModuleName |
        Join-Path -ChildPath 'PrivateClasses'
    if ($Location) {
        $ClassDir = Join-Path $ClassDir $Location
    }
    $ClassFile = Join-Path $ClassDir "$ClassName.ps1"

    if ((Test-Path $ClassFile) -and -not $Force) {
        Write-Error "Class file already exists: $ClassFile. Use -Force to overwrite."
        return
    }

    # Create the class file
    $Content = Get-ClassContent -ClassName $ClassName

    if ($PSCmdlet.ShouldProcess($ClassFile, 'Create class file')) {
        if (-not (Test-Path $ClassDir)) {
            New-Item -Path $ClassDir -ItemType Directory -Force | Out-Null
        }
        Set-Content -Path $ClassFile -Value $Content -Encoding UTF8 -NoNewline
        Get-Item $ClassFile
    }

    # Create the matching test file
    $TestParams = @{
        Name  = $ClassName
        Scope = 'PrivateClasses'
        Path  = $ProjectRoot
    }
    if ($Location) { $TestParams.Location = $Location }
    if ($Force) { $TestParams.Force = $true }
    New-AnvilTest @TestParams
}
