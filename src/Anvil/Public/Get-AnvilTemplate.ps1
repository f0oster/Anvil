function Get-AnvilTemplate {
    <#
    .SYNOPSIS
        Lists the available Anvil templates and CI providers.

    .DESCRIPTION
        Inspects the bundled template directories shipped with Anvil and
        returns objects describing each template and CI provider.  Use this
        to discover what New-AnvilModule can generate.

        A summary is also written to the information stream.  Pipe to
        Format-Table or use -InformationAction Continue to see it.

    .INPUTS
        None.  This command does not accept pipeline input.

    .OUTPUTS
        PSCustomObject
            Objects with Name, Type ('BaseTemplate' or 'CIProvider'),
            FileCount, and Path properties.

    .EXAMPLE
        Get-AnvilTemplate

        Lists all base templates and CI providers with file counts.

    .EXAMPLE
        Get-AnvilTemplate | Where-Object Type -eq 'CIProvider'

        Returns only the CI provider entries.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $TemplateRoot = $script:TemplateRoot

    # Discover base templates
    $BaseTemplates = Get-ChildItem -Path $TemplateRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'CI' } |
        ForEach-Object {
            $FileCount = (Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue).Count
            [PSCustomObject]@{
                Name      = $_.Name
                Type      = 'BaseTemplate'
                FileCount = $FileCount
                Path      = $_.FullName
            }
        }

    # Discover CI providers
    $CiRoot = Join-Path -Path $TemplateRoot -ChildPath 'CI'
    $CiProviders = @()
    if (Test-Path -Path $CiRoot) {
        $CiProviders = Get-ChildItem -Path $CiRoot -Directory -ErrorAction SilentlyContinue |
            ForEach-Object {
                $FileCount = (Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue).Count
                [PSCustomObject]@{
                    Name      = $_.Name
                    Type      = 'CIProvider'
                    FileCount = $FileCount
                    Path      = $_.FullName
                }
            }
    }

    $All = @($BaseTemplates) + @($CiProviders)

    Write-Information ''
    Write-Information 'Anvil Templates'
    Write-Information ''
    foreach ($T in $All) {
        Write-Information "  $($T.Type.PadRight(14)) $($T.Name.PadRight(20)) ($($T.FileCount) files)"
    }
    Write-Information ''
    Write-Information 'Supported licenses: MIT, Apache2, None'
    Write-Information ''

    return $All
}
