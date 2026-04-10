function New-AnvilFunction {
    <#
    .SYNOPSIS
        Creates a new function file and its corresponding Pester test in an
        Anvil-scaffolded module.

    .DESCRIPTION
        Generates a function file in the appropriate src/<ModuleName>/Public/ or
        src/<ModuleName>/Private/ directory, and a matching test file in
        tests/unit/Public/ or tests/unit/Private/.

        The module name is read from build/build.settings.psd1 in the project root.

        Public functions are created with a comment-based help block and
        are automatically exported by the Build task.

    .PARAMETER FunctionName
        The name of the function to create. The generated files will be named
        <FunctionName>.ps1 and <FunctionName>.Tests.ps1.

    .PARAMETER Scope
        Whether the function is Public (exported) or Private (internal).
        Determines the output directories and the test pattern used.

    .PARAMETER Location
        Optional subdirectory path relative to the scope root. For example,
        -Location 'Core/Greetings' places the files under
        src/<ModuleName>/<Scope>/Core/Greetings/ and
        tests/unit/<Scope>/Core/Greetings/.

    .PARAMETER Path
        The project root directory. If not provided, the current directory is
        used and the command walks up the directory tree to find the project root.
        You will be prompted to confirm before the walk-up begins.

    .PARAMETER SkipVerbCheck
        Skip the approved verb validation for public functions. By default,
        public function names must use an approved PowerShell verb (see Get-Verb).

    .PARAMETER Force
        Overwrite existing files if they already exist.

    .EXAMPLE
        New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public

    .EXAMPLE
        New-AnvilFunction -FunctionName 'Resolve-InternalState' -Scope Private -Path C:\Projects\MyModule

    .EXAMPLE
        New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public -Location 'Core/Greetings'

    .EXAMPLE
        New-AnvilFunction -FunctionName 'Fetch-Data' -Scope Public -SkipVerbCheck

    .INPUTS
        None

    .OUTPUTS
        System.IO.FileInfo
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
        [switch]$SkipVerbCheck,

        [Parameter()]
        [switch]$Force
    )

    # Validate approved verb for public functions
    if ($Scope -eq 'Public' -and -not $SkipVerbCheck) {
        $Verb = ($FunctionName -split '-', 2)[0]
        $ApprovedVerbs = (Get-Verb).Verb
        if ($Verb -notin $ApprovedVerbs) {
            Write-Error ("'$Verb' is not an approved PowerShell verb. " +
                'See: Get-Verb | Sort-Object Verb. Use -SkipVerbCheck to override.')
            return
        }
    }

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

    # Build the function file path
    $FunctionDir = Join-Path $ProjectRoot 'src' |
        Join-Path -ChildPath $ModuleName |
        Join-Path -ChildPath $Scope
    if ($Location) {
        $FunctionDir = Join-Path $FunctionDir $Location
    }
    $FunctionFile = Join-Path $FunctionDir "$FunctionName.ps1"

    if ((Test-Path $FunctionFile) -and -not $Force) {
        Write-Error "Function file already exists: $FunctionFile. Use -Force to overwrite."
        return
    }

    # Create the function file
    $Content = Get-FunctionContent -FunctionName $FunctionName -Scope $Scope

    if ($PSCmdlet.ShouldProcess($FunctionFile, 'Create function file')) {
        if (-not (Test-Path $FunctionDir)) {
            New-Item -Path $FunctionDir -ItemType Directory -Force | Out-Null
        }
        Set-Content -Path $FunctionFile -Value $Content -Encoding UTF8 -NoNewline
        Get-Item $FunctionFile
    }

    # Create the matching test file
    $TestParams = @{
        Name  = $FunctionName
        Scope = $Scope
        Path  = $ProjectRoot
    }
    if ($Location) { $TestParams.Location = $Location }
    if ($Force) { $TestParams.Force = $true }
    New-AnvilTest @TestParams

}
