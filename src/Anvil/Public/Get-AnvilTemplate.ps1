function Get-AnvilTemplate {
    <#
    .SYNOPSIS
        Lists the available Anvil templates.

    .DESCRIPTION
        Inspects the bundled template directories shipped with Anvil and
        returns objects describing each template.  Templates must contain
        a template.psd1 manifest to be discovered.

        Each template object includes metadata from the manifest
        (Description, Version, Parameters) and a Layers property listing
        any layer options declared by the template (e.g. CI providers).

        A summary is also written to the information stream.

    .INPUTS
        None

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .LINK
        New-AnvilModule

    .EXAMPLE
        Get-AnvilTemplate

        Lists all available templates with metadata and layers.

    .EXAMPLE
        (Get-AnvilTemplate | Where-Object Name -eq 'Module').Layers

        Shows the available layers (e.g. CI providers) for the Module template.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $TemplateRoot = $script:TemplateRoot

    $Templates = Get-ChildItem -Path $TemplateRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'template.psd1') } |
        ForEach-Object {
            $TemplatePath = $_.FullName
            $Manifest = Import-PowerShellDataFile -Path (Join-Path $TemplatePath 'template.psd1') -ErrorAction SilentlyContinue
            if (-not $Manifest) { return }

            $FileCount = (Get-ChildItem -Path $TemplatePath -File -Recurse -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -ne 'template.psd1' }).Count

                $Layers = @()
                if ($Manifest.ContainsKey('Layers')) {
                    foreach ($Layer in $Manifest.Layers) {
                        $LayerRoot = Join-Path -Path $TemplateRoot -ChildPath $Layer.BasePath
                        if (Test-Path -Path $LayerRoot) {
                            $LayerDirs = Get-ChildItem -Path $LayerRoot -Directory -ErrorAction SilentlyContinue
                            foreach ($Dir in $LayerDirs) {
                                $Skip = if ($Layer.ContainsKey('Skip')) { $Layer.Skip } else { $null }
                                if ($Dir.Name -eq $Skip) { continue }
                                $LayerFileCount = (Get-ChildItem -Path $Dir.FullName -File -Recurse -Force -ErrorAction SilentlyContinue).Count
                                $Layers += [PSCustomObject]@{
                                    Name      = $Dir.Name
                                    PathKey   = $Layer.PathKey
                                    FileCount = $LayerFileCount
                                    Path      = $Dir.FullName
                                }
                            }
                        }
                    }
                }

                $Parameters = @($Manifest.Parameters | ForEach-Object { $_.Name })

                [PSCustomObject]@{
                    Name        = $Manifest.Name
                    Type        = 'BaseTemplate'
                    Description = $Manifest.Description
                    Version     = $Manifest.Version
                    Parameters  = $Parameters
                    FileCount   = $FileCount
                    Layers      = $Layers
                    Path        = $TemplatePath
                }
            }

    Write-Information ''
    Write-Information 'Anvil Templates'
    Write-Information ''
    foreach ($T in $Templates) {
        $LayerNames = if ($T.Layers.Count -gt 0) { " [Layers: $($T.Layers.Name -join ', ')]" } else { '' }
        Write-Information "  $($T.Name.PadRight(20)) v$($T.Version)  ($($T.FileCount) files)$LayerNames"
        Write-Information "  $(' ' * 20) $($T.Description)"
    }
    Write-Information ''

    return $Templates
}
