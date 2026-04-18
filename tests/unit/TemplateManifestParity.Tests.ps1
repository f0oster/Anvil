#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $ProjectRoot = $PSScriptRoot
    while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot 'build/build.settings.psd1'))) {
        $ProjectRoot = Split-Path $ProjectRoot -Parent
    }
    $ModuleName   = 'Anvil'
    $ModuleDir    = Join-Path -Path $ProjectRoot -ChildPath 'src' | Join-Path -ChildPath $ModuleName
    $ManifestPath = Join-Path -Path $ModuleDir -ChildPath "$ModuleName.psd1"

    Get-Module -Name $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $ManifestPath -Force -ErrorAction Stop

    $script:TemplateRoot = Join-Path -Path $ModuleDir -ChildPath 'Templates'
}

AfterAll {
    Get-Module -Name 'Anvil' -ErrorAction SilentlyContinue | Remove-Module -Force
}

Describe 'Template Manifest Parity' -Tag 'Unit' {

    BeforeAll {
        $script:ModuleTemplatePath = Join-Path -Path $script:TemplateRoot -ChildPath 'Module'
        $script:CITemplatePath = Join-Path -Path $script:TemplateRoot -ChildPath 'CI'

        $script:Manifest = InModuleScope 'Anvil' -Parameters @{ P = $script:ModuleTemplatePath } {
            param($P)
            Read-TemplateManifest -TemplatePath $P
        }

        $script:DeclaredParams = $script:Manifest.Parameters | ForEach-Object { $_.Name }
        $script:DeclaredAuto = @()
        if ($script:Manifest.ContainsKey('AutoTokens')) {
            $script:DeclaredAuto = $script:Manifest.AutoTokens | ForEach-Object { $_.Name }
        }
        $script:DeclaredTokens = @($script:DeclaredParams) + @($script:DeclaredAuto)

        # Collect all content tokens from Module and CI templates
        $script:ContentTokens = [System.Collections.Generic.HashSet[string]]::new()
        $AllTmplFiles = Get-ChildItem -Path $script:ModuleTemplatePath -Recurse -File -Filter '*.tmpl'
        $AllTmplFiles += Get-ChildItem -Path $script:CITemplatePath -Recurse -File -Filter '*.tmpl'
        foreach ($File in $AllTmplFiles) {
            $Content = Get-Content -Path $File.FullName -Raw
            $Matches = [regex]::Matches($Content, '<%(\w+)%>')
            foreach ($M in $Matches) {
                [void]$script:ContentTokens.Add($M.Groups[1].Value)
            }
        }

        # Collect all path tokens from Module templates
        $script:PathTokens = [System.Collections.Generic.HashSet[string]]::new()
        $AllDirs = Get-ChildItem -Path $script:ModuleTemplatePath -Recurse -Directory
        foreach ($Dir in $AllDirs) {
            $DirMatches = [regex]::Matches($Dir.Name, '__(\w+)__')
            foreach ($M in $DirMatches) {
                [void]$script:PathTokens.Add($M.Groups[1].Value)
            }
        }
        $AllFiles = Get-ChildItem -Path $script:ModuleTemplatePath -Recurse -File
        foreach ($File in $AllFiles) {
            $FileMatches = [regex]::Matches($File.Name, '__(\w+)__')
            foreach ($M in $FileMatches) {
                [void]$script:PathTokens.Add($M.Groups[1].Value)
            }
        }

        $script:UsedTokens = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($T in $script:ContentTokens) { [void]$script:UsedTokens.Add($T) }
        foreach ($T in $script:PathTokens) { [void]$script:UsedTokens.Add($T) }
    }

    It 'manifest loads successfully' {
        $script:Manifest | Should -Not -BeNullOrEmpty
    }

    It 'every content token in template files is declared in the manifest' {
        $Undeclared = $script:ContentTokens | Where-Object { $_ -notin $script:DeclaredTokens }
        $Undeclared | Should -BeNullOrEmpty -Because "tokens used in templates must be declared in template.psd1: $($Undeclared -join ', ')"
    }

    It 'every path token in template files is declared in the manifest' {
        $Undeclared = $script:PathTokens | Where-Object { $_ -notin $script:DeclaredTokens }
        $Undeclared | Should -BeNullOrEmpty -Because "path tokens used in templates must be declared in template.psd1: $($Undeclared -join ', ')"
    }

    It 'every auto-token is used in at least one template file' {
        $Unused = $script:DeclaredAuto | Where-Object { $_ -notin $script:UsedTokens }
        $Unused | Should -BeNullOrEmpty -Because "declared auto-tokens should appear in template files: $($Unused -join ', ')"
    }
}
