#Requires -Version 5.1
<#
.SYNOPSIS
    Module loader for Anvil.

.DESCRIPTION
    Dot-sources all Public and Private .ps1 files and sets the script-scoped
    template resource path.
#>

# Template resource root (used by scaffolding commands)
$script:TemplateRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Templates'

# Discover and dot-source function files
$PublicDir  = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$PrivateDir = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

$PublicFunctions  = @()
$PrivateFunctions = @()

if (Test-Path -Path $PublicDir) {
    $PublicFunctions = Get-ChildItem -Path $PublicDir -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
}
if (Test-Path -Path $PrivateDir) {
    $PrivateFunctions = Get-ChildItem -Path $PrivateDir -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
}

foreach ($File in @($PublicFunctions + $PrivateFunctions)) {
    try {
        . $File.FullName
    }
    catch {
        Write-Error -Message "Failed to import $($File.FullName): $_"
    }
}

$ExportNames = $PublicFunctions | ForEach-Object { $_.BaseName }
if ($ExportNames) {
    Export-ModuleMember -Function $ExportNames
}
