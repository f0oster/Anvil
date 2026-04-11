function Read-RequirementsFile {
    <#
    .SYNOPSIS
        Reads a requirements.psd1 file and returns its contents as a hashtable.

    .DESCRIPTION
        Parses the given requirements file using Import-PowerShellDataFile.
        Returns an empty hashtable if the file does not exist.

    .PARAMETER Path
        Full path to the requirements.psd1 file.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        return @{}
    }

    Import-PowerShellDataFile -Path $Path
}
