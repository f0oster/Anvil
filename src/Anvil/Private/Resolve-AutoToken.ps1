function Resolve-AutoToken {
    <#
    .SYNOPSIS
        Resolves a named auto-token source to a string value.

    .DESCRIPTION
        Auto-tokens are values computed by the engine rather than provided
        by the user.  Each source name maps to a deterministic or generated
        value.

        Supported sources:
          NewGuid       A new random GUID string.
          CurrentYear   The current four-digit year.
          CurrentDate   The current date in yyyy-MM-dd format.

    .PARAMETER Source
        The name of the auto-token source to resolve.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Source
    )

    switch ($Source) {
        'NewGuid' {
            return [guid]::NewGuid().ToString()
        }
        'CurrentYear' {
            return (Get-Date).Year.ToString()
        }
        'CurrentDate' {
            return (Get-Date).ToString('yyyy-MM-dd')
        }
        default {
            throw "Unknown auto-token source '$Source'. Valid sources: NewGuid, CurrentYear, CurrentDate."
        }
    }
}
