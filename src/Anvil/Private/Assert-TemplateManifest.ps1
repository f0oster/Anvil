function Assert-TemplateManifest {
    <#
    .SYNOPSIS
        Validates the structure of a template manifest hashtable.

    .DESCRIPTION
        Checks a hashtable loaded from template.psd1 against the expected
        schema.  All violations are collected and thrown as a single error
        so the caller sees every problem at once.

        Validates:
          - Required top-level keys: Name, Description, Version, Parameters
          - Each parameter entry has Name, Type, and Prompt
          - Type is one of: string, choice, bool, int, csv, uri
          - Choice parameters have a non-empty Choices array
          - Range (if present) is a two-element numeric array
          - Format (if present) is a recognized formatter name
          - DefaultFrom (if present) is a recognized resolver name
          - Validate (if present) is a compilable regex
          - Parameter names are unique across Parameters and AutoTokens
          - AutoToken entries have Name and Source with valid source names
          - Section entries have exactly one of IncludeWhen or ExcludeWhen
          - Layer entries have PathKey and BasePath

    .PARAMETER Manifest
        The hashtable to validate.

    .OUTPUTS
        None.  Throws on validation failure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Manifest
    )

    $ValidTypes = @('string', 'choice', 'bool', 'int', 'csv', 'uri')
    $ValidFormatters = @('raw', 'psd1-array', 'lower-string', 'quoted')
    $ValidResolvers = @('GitUserName', 'CurrentDirectory')
    $ValidSources = @('NewGuid', 'CurrentYear', 'CurrentDate')

    $Errors = [System.Collections.Generic.List[string]]::new()

    # Required top-level keys
    foreach ($Key in @('Name', 'Description', 'Version')) {
        if (-not $Manifest.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Manifest[$Key])) {
            $Errors.Add("'$Key' is required and must not be empty.")
        }
    }

    if (-not $Manifest.ContainsKey('Parameters') -or $Manifest['Parameters'].Count -eq 0) {
        $Errors.Add("'Parameters' is required and must contain at least one entry.")
    }

    # Track all token names for uniqueness
    $AllNames = [System.Collections.Generic.List[string]]::new()

    # Parameter entries
    $Parameters = @($Manifest['Parameters'])
    for ($i = 0; $i -lt $Parameters.Count; $i++) {
        $P = $Parameters[$i]
        $Prefix = "Parameters[$i]"

        if (-not $P -or $P -isnot [hashtable]) {
            $Errors.Add("$Prefix must be a hashtable.")
            continue
        }

        # Required fields
        if (-not $P.ContainsKey('Name') -or [string]::IsNullOrWhiteSpace($P['Name'])) {
            $Errors.Add("${Prefix}: 'Name' is required.")
        } else {
            if ($AllNames -contains $P['Name']) {
                $Errors.Add("${Prefix}: duplicate name '$($P['Name'])'.")
            }
            $AllNames.Add($P['Name'])
            $Prefix = "Parameter '$($P['Name'])'"
        }

        if (-not $P.ContainsKey('Type') -or [string]::IsNullOrWhiteSpace($P['Type'])) {
            $Errors.Add("${Prefix}: 'Type' is required.")
        } elseif ($P['Type'] -notin $ValidTypes) {
            $Errors.Add("${Prefix}: Type '$($P['Type'])' is not valid. Choose from: $($ValidTypes -join ', ').")
        }

        if (-not $P.ContainsKey('Prompt') -or [string]::IsNullOrWhiteSpace($P['Prompt'])) {
            $Errors.Add("${Prefix}: 'Prompt' is required.")
        }

        # Type-specific checks
        $Type = $P['Type']

        if ($Type -eq 'choice') {
            if (-not $P.ContainsKey('Choices') -or @($P['Choices']).Count -eq 0) {
                $Errors.Add("${Prefix}: 'Choices' is required for choice type and must not be empty.")
            }
        }

        if ($P.ContainsKey('Range')) {
            $Range = @($P['Range'])
            if ($Range.Count -ne 2) {
                $Errors.Add("${Prefix}: 'Range' must be a two-element array @(min, max).")
            } elseif ($Range[0] -gt $Range[1]) {
                $Errors.Add("${Prefix}: Range minimum ($($Range[0])) must not exceed maximum ($($Range[1])).")
            }
        }

        if ($P.ContainsKey('Format') -and $P['Format'] -notin $ValidFormatters) {
            $Errors.Add("${Prefix}: Format '$($P['Format'])' is not valid. Choose from: $($ValidFormatters -join ', ').")
        }

        if ($P.ContainsKey('DefaultFrom') -and $P['DefaultFrom'] -notin $ValidResolvers) {
            $Errors.Add("${Prefix}: DefaultFrom '$($P['DefaultFrom'])' is not valid. Choose from: $($ValidResolvers -join ', ').")
        }

        if ($P.ContainsKey('Validate') -and -not [string]::IsNullOrWhiteSpace($P['Validate'])) {
            try {
                [void][regex]::new($P['Validate'])
            } catch {
                $Errors.Add("${Prefix}: Validate pattern '$($P['Validate'])' is not a valid regex.")
            }
        }
    }

    # AutoTokens
    if ($Manifest.ContainsKey('AutoTokens')) {
        $AutoTokens = @($Manifest['AutoTokens'])
        for ($i = 0; $i -lt $AutoTokens.Count; $i++) {
            $AT = $AutoTokens[$i]
            $Prefix = "AutoTokens[$i]"

            if (-not $AT -or $AT -isnot [hashtable]) {
                $Errors.Add("$Prefix must be a hashtable.")
                continue
            }

            if (-not $AT.ContainsKey('Name') -or [string]::IsNullOrWhiteSpace($AT['Name'])) {
                $Errors.Add("${Prefix}: 'Name' is required.")
            } else {
                if ($AllNames -contains $AT['Name']) {
                    $Errors.Add("${Prefix}: duplicate name '$($AT['Name'])'.")
                }
                $AllNames.Add($AT['Name'])
                $Prefix = "AutoToken '$($AT['Name'])'"
            }

            if (-not $AT.ContainsKey('Source') -or [string]::IsNullOrWhiteSpace($AT['Source'])) {
                $Errors.Add("${Prefix}: 'Source' is required.")
            } elseif ($AT['Source'] -notin $ValidSources) {
                $Errors.Add("${Prefix}: Source '$($AT['Source'])' is not valid. Choose from: $($ValidSources -join ', ').")
            }
        }
    }

    # Sections
    if ($Manifest.ContainsKey('Sections')) {
        foreach ($SectionName in $Manifest['Sections'].Keys) {
            $Def = $Manifest['Sections'][$SectionName]
            $Prefix = "Section '$SectionName'"

            if ($Def -isnot [hashtable]) {
                $Errors.Add("${Prefix}: value must be a hashtable.")
                continue
            }

            $HasInclude = $Def.ContainsKey('IncludeWhen')
            $HasExclude = $Def.ContainsKey('ExcludeWhen')

            if (-not $HasInclude -and -not $HasExclude) {
                $Errors.Add("${Prefix}: must have either 'IncludeWhen' or 'ExcludeWhen'.")
            }
            if ($HasInclude -and $HasExclude) {
                $Errors.Add("${Prefix}: must have only one of 'IncludeWhen' or 'ExcludeWhen', not both.")
            }
        }
    }

    # Layers
    if ($Manifest.ContainsKey('Layers')) {
        $Layers = @($Manifest['Layers'])
        for ($i = 0; $i -lt $Layers.Count; $i++) {
            $L = $Layers[$i]
            $Prefix = "Layers[$i]"

            if (-not $L -or $L -isnot [hashtable]) {
                $Errors.Add("$Prefix must be a hashtable.")
                continue
            }

            if (-not $L.ContainsKey('PathKey') -or [string]::IsNullOrWhiteSpace($L['PathKey'])) {
                $Errors.Add("${Prefix}: 'PathKey' is required.")
            }
            if (-not $L.ContainsKey('BasePath') -or [string]::IsNullOrWhiteSpace($L['BasePath'])) {
                $Errors.Add("${Prefix}: 'BasePath' is required.")
            }
        }
    }

    if ($Errors.Count -gt 0) {
        $Message = "Template manifest validation failed:`n  - " + ($Errors -join "`n  - ")
        throw $Message
    }
}
