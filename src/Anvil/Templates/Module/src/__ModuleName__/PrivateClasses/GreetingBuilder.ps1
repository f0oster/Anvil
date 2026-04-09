class GreetingBuilder {
    [string]$Prefix
    [string]$Suffix

    GreetingBuilder() {
        $this.Prefix = 'Hello'
        $this.Suffix = '!'
    }

    GreetingBuilder([string]$Prefix, [string]$Suffix) {
        $this.Prefix = $Prefix
        $this.Suffix = $Suffix
    }

    [string] Build([string]$Name) {
        return "$($this.Prefix), $Name$($this.Suffix)"
    }

    [string] ToString() {
        return "$($this.Prefix)...$($this.Suffix)"
    }
}
