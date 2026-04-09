#Requires -Version 5.1
<#
.SYNOPSIS
    Module loader for Anvil.

.DESCRIPTION
    Dot-sources Imports.ps1 for module-scoped variables, then loads all
    Public and Private .ps1 files and exports only the Public functions.
#>

# Module-scoped variables and initialization
. $PSScriptRoot\Imports.ps1

# Discover and dot-source files
$PrivateClassesDir = Join-Path -Path $PSScriptRoot -ChildPath 'PrivateClasses'
$PublicDir = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$PrivateDir = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

$PrivateClasses = @()
$PublicFunctions = @()
$PrivateFunctions = @()

if (Test-Path -Path $PrivateClassesDir) {
    $PrivateClasses = @(Get-ChildItem -Path $PrivateClassesDir -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)
}
if (Test-Path -Path $PublicDir) {
    $PublicFunctions = @(Get-ChildItem -Path $PublicDir -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)
}
if (Test-Path -Path $PrivateDir) {
    $PrivateFunctions = @(Get-ChildItem -Path $PrivateDir -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)
}

# Classes first, then functions (functions may depend on classes)
foreach ($File in @($PrivateClasses + $PublicFunctions + $PrivateFunctions)) {
    try {
        . $File.FullName
    } catch {
        Write-Error -Message "Failed to import $($File.FullName): $_"
    }
}

$ExportNames = $PublicFunctions | ForEach-Object { $_.BaseName }
if ($ExportNames) {
    Export-ModuleMember -Function $ExportNames
}
