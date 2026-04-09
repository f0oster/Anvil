function Get-ClassContent {
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
