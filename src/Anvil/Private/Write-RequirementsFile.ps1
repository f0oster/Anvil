function Write-RequirementsFile {
    <#
    .SYNOPSIS
        Writes a hashtable to a requirements.psd1 file.

    .DESCRIPTION
        Serializes a flat hashtable of module names and version specs
        into PowerShell data file format.

    .PARAMETER Path
        Full path to the requirements.psd1 file.

    .PARAMETER Requirements
        Hashtable of module names to ModuleFast version specs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Requirements
    )

    $Sb = [System.Text.StringBuilder]::new()
    [void]$Sb.AppendLine('@{')

    $SortedKeys = $Requirements.Keys | Sort-Object
    $MaxKeyLength = ($SortedKeys | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    if (-not $MaxKeyLength) { $MaxKeyLength = 0 }

    foreach ($Key in $SortedKeys) {
        $PaddedKey = "'$Key'".PadRight($MaxKeyLength + 2)
        [void]$Sb.AppendLine("    $PaddedKey = '$($Requirements[$Key])'")
    }

    [void]$Sb.AppendLine('}')

    Set-Content -Path $Path -Value $Sb.ToString() -NoNewline
}
