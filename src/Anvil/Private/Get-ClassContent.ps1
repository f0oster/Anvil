function Get-ClassContent {
    <#
    .SYNOPSIS
        Returns the boilerplate content for a new PowerShell class file.

    .PARAMETER ClassName
        The name of the class to generate.
    #>
    param(
        [string]$ClassName
    )

    @"
class $ClassName {
    [string]`$Name

    $ClassName() {
        `$this.Name = ''
    }

    $ClassName([string]`$Name) {
        `$this.Name = `$Name
    }

    [string] ToString() {
        return `$this.Name
    }
}
"@
}
