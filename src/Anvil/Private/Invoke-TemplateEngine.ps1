function Invoke-TemplateEngine {
    <#
    .SYNOPSIS
        Processes a template directory tree, replacing tokens in file content
        and path segments, and writes the result to a destination.

    .DESCRIPTION
        Walks the source template directory recursively.  For each file:

          - Path segments containing __TokenName__ are replaced using the
            supplied token table (e.g. __ModuleName__ becomes MyModule).
          - Files with a .tmpl extension have <%TokenName%> placeholders in
            their content replaced, then the .tmpl suffix is stripped.
          - Files without .tmpl are copied verbatim (binary-safe).
          - Empty directories are created to preserve structure.

        Token replacement uses literal string replacement (not regex), so
        values containing special characters are handled safely.

    .PARAMETER SourcePath
        Root of the template directory tree.  Must exist.

    .PARAMETER DestinationPath
        Root of the output directory.  Created automatically if missing.

    .PARAMETER Tokens
        Hashtable of token names to replacement values.  The same keys serve
        both path tokens (__Name__) and content tokens (<%Name%>).

    .PARAMETER ExcludePatterns
        Optional array of relative path patterns to skip.  Supports simple
        wildcards via the -like operator (*, ?, []).

    .OUTPUTS
        System.Int32
            The number of files processed (excluding skipped files).

    .EXAMPLE
        Invoke-TemplateEngine -SourcePath './templates/Module' -DestinationPath './out' -Tokens @{ ModuleName = 'Foo' }

        Expands the Module template into ./out/, replacing all __ModuleName__
        path segments and <%ModuleName%> content placeholders with 'Foo'.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [Parameter(Mandatory)]
        [hashtable]$Tokens,

        [string[]]$ExcludePatterns = @()
    )

    if (-not (Test-Path -Path $SourcePath)) {
        throw "Template source not found: $SourcePath"
    }

    if (-not (Test-Path -Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }

    # Process directories first (to create structure)
    $Dirs = Get-ChildItem -Path $SourcePath -Directory -Recurse -Force
    foreach ($Dir in $Dirs) {
        $RelativePath = $Dir.FullName.Substring($SourcePath.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $ResolvedPath = Resolve-PathTokens -RelativePath $RelativePath -Tokens $Tokens

        if (Test-Excluded -RelativePath $ResolvedPath -Patterns $ExcludePatterns) {
            continue
        }

        $TargetDir = Join-Path -Path $DestinationPath -ChildPath $ResolvedPath
        if (-not (Test-Path -Path $TargetDir)) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        }
    }

    $Files = Get-ChildItem -Path $SourcePath -File -Recurse -Force
    $ProcessedCount = 0

    foreach ($File in $Files) {
        $RelativePath = $File.FullName.Substring($SourcePath.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $ResolvedPath = Resolve-PathTokens -RelativePath $RelativePath -Tokens $Tokens

        if (Test-Excluded -RelativePath $ResolvedPath -Patterns $ExcludePatterns) {
            continue
        }

        $IsTemplate = $File.Extension -eq '.tmpl'

        if ($IsTemplate) {
            $ResolvedPath = $ResolvedPath -replace '\.tmpl$', ''
        }

        $TargetPath = Join-Path -Path $DestinationPath -ChildPath $ResolvedPath

        $TargetDir = Split-Path -Path $TargetPath -Parent
        if (-not (Test-Path -Path $TargetDir)) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        }

        if ($IsTemplate) {
            $Content = Get-Content -Path $File.FullName -Raw -ErrorAction Stop
            $Content = Resolve-ContentTokens -Content $Content -Tokens $Tokens
            Set-Content -Path $TargetPath -Value $Content -NoNewline -ErrorAction Stop
        } else {
            # Binary-safe copy
            Copy-Item -Path $File.FullName -Destination $TargetPath -Force
        }

        $ProcessedCount++
    }

    return $ProcessedCount
}
