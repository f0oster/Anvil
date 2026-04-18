function Invoke-ManifestPrompt {
    <#
    .SYNOPSIS
        Resolves template parameters using manifest declarations, bound
        values, defaults, or interactive prompts.

    .DESCRIPTION
        Walks the manifest's Parameters array and resolves each value
        from one of these sources (in priority order):

          1. BoundParams - values already provided by the caller.
          2. Interactive prompt - when Interactive is $true and the value
             is not bound.
          3. DefaultFrom resolver - named default (e.g. GitUserName).
          4. Default - static default from the manifest.

        When Interactive is $false, missing required values with no
        default cause a terminating error.

        Returns a hashtable of raw (unformatted) resolved values keyed
        by parameter name.

    .PARAMETER Manifest
        The template manifest hashtable (from Read-TemplateManifest).

    .PARAMETER BoundParams
        Hashtable of values already provided by the caller.

    .PARAMETER Interactive
        When $true, prompts the user for missing values.

    .OUTPUTS
        System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Manifest,

        [Parameter(Mandatory)]
        [hashtable]$BoundParams,

        [Parameter()]
        [bool]$Interactive = $false
    )

    if ($Interactive) {
        Write-Host ''
        Write-Host "  Anvil - $($Manifest.Name)" -ForegroundColor Cyan
        Write-Host '  Press Enter to accept defaults shown in [brackets].' -ForegroundColor DarkGray
        Write-Host ''
    }

    $Result = @{}

    foreach ($Param in $Manifest.Parameters) {
        $Name = $Param.Name
        $Type = $Param.Type

        if ($BoundParams.ContainsKey($Name)) {
            $Result[$Name] = Convert-PromptResult -Value $BoundParams[$Name] -Type $Type
            continue
        }

        $Default = $null
        $HasDefault = $Param.ContainsKey('Default')
        if ($HasDefault) {
            $Default = $Param.Default
        }
        if ($Param.ContainsKey('DefaultFrom')) {
            $Resolved = Resolve-DefaultFrom -ResolverName $Param.DefaultFrom
            if ($null -ne $Resolved -and $Resolved -ne '') {
                $Default = $Resolved
                $HasDefault = $true
            }
        }

        if (-not $Interactive) {
            if ($HasDefault) {
                $Result[$Name] = Convert-PromptResult -Value $Default -Type $Type
                continue
            }
            if ($Param.Required) {
                throw "'$Name' is required. Use -Interactive for the guided wizard."
            }
            $Result[$Name] = $Default
            continue
        }

        $Result[$Name] = switch ($Type) {
            'string' {
                Read-PromptValue -Prompt "  $($Param.Prompt)" -Default $Default -Required:([bool]$Param.Required)
            }
            'choice' {
                Read-PromptChoice -Prompt "  $($Param.Prompt)" -Choices $Param.Choices -Default $Default
            }
            'bool' {
                $BoolDefault = if ($Default) { 'y' } else { 'n' }
                $BoolInput = Read-PromptValue -Prompt "  $($Param.Prompt) (y/n)" -Default $BoolDefault
                $BoolInput -match '^[Yy]'
            }
            'int' {
                $DefaultStr = if ($null -ne $Default) { $Default.ToString() } else { '' }
                [int](Read-PromptValue -Prompt "  $($Param.Prompt)" -Default $DefaultStr)
            }
            'csv' {
                $CsvDefault = if ($Default -is [array]) { $Default -join ',' } else { "$Default" }
                $CsvInput = Read-PromptValue -Prompt "  $($Param.Prompt)" -Default $CsvDefault
                if ($CsvInput) {
                    @($CsvInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                } else {
                    @()
                }
            }
            'uri' {
                Read-PromptUri -Prompt "  $($Param.Prompt)" -Default $Default
            }
        }
    }

    if ($Interactive) {
        Write-Host ''
    }

    return $Result
}
