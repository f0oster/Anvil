---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# New-AnvilModule

## SYNOPSIS
Scaffolds a new PowerShell module project with build, test, lint, docs,
and CI/CD pipelines.

## SYNTAX

```
New-AnvilModule [[-Name] <String>] [[-DestinationPath] <String>] [-Author <String>] [-Description <String>]
 [-CompanyName <String>] [-MinPowerShellVersion <String>] [-CompatiblePSEditions <String[]>]
 [-CIProvider <String>] [-License <String>] [-IncludeDocs] [-CoverageThreshold <Int32>] [-Tags <String[]>]
 [-ProjectUri <String>] [-LicenseUri <String>] [-Force] [-GitInit] [-PassThru]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generates a complete, opinionated module project structure including:

  - Module source (manifest, .psm1 entry point, Public/Private/PrivateClasses layout)
  - InvokeBuild pipeline (Validate, Format, Lint, Test, Build, IntegrationTest, Package, Publish)
  - Dependency manifest with pinned tool versions (installed via ModuleFast)
  - Pester 5 unit tests and post-build integration tests
  - PSScriptAnalyzer settings with formatting rules and custom analyzers
  - CI/CD workflows for the chosen provider (GitHub, Azure Pipelines, GitLab)
  - README, CONTRIBUTING, LICENSE, .editorconfig, VS Code config

When called without parameters, runs an interactive wizard that prompts
for each value.
When parameters are provided, runs non-interactively.

## EXAMPLES

### EXAMPLE 1
```
New-AnvilModule
```

Runs the interactive wizard, prompting for all values.

### EXAMPLE 2
```
New-AnvilModule -Name 'NetworkTools' -DestinationPath '~/Projects' -Author 'Jane Doe'
```

Scaffolds a GitHub CI project at ~/Projects/NetworkTools/ with MIT
license and default settings.

### EXAMPLE 3
```
$Params = @{
    Name            = 'VaultHelper'
    DestinationPath = '~/src'
    Author          = 'Team'
    CompanyName     = 'Contoso'
    CIProvider      = 'GitLab'
    License         = 'Apache2'
    Tags            = @('Vault', 'Security')
    IncludeDocs     = $true
    GitInit         = $true
}
New-AnvilModule @Params
```

Scaffolds a GitLab CI project with Apache 2.0 license, platyPS
documentation, and an initialised git repository.

## PARAMETERS

### -Name
The name of the new module.
Must start with a letter and contain only
letters, digits, dots, hyphens, or underscores (max 128 characters).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationPath
Parent directory where the project folder will be created.
A child
directory named after -Name is created inside this path.
Interactive default: current directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Author
Author name written into the module manifest, LICENSE, and copyright.
Interactive default: git config user.name (if available).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Short description for the module manifest.
Default: 'A PowerShell module scaffolded by Anvil.'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CompanyName
Company name written into the module manifest.
Default: empty string.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinPowerShellVersion
Minimum PowerShell version declared in the generated module manifest.
Must be a valid .NET version string (e.g.
'5.1', '7.2').
Default: '5.1'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CompatiblePSEditions
PowerShell editions the module supports.
Default: @('Desktop', 'Core').

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CIProvider
CI/CD platform to scaffold workflows for.
Valid values: GitHub, AzurePipelines, GitLab, None.
Default: GitHub.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -License
License type to include.
Valid values: MIT, Apache2, None.
Default: MIT.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeDocs
When set, the build pipeline adds a Docs task that generates markdown
and MAML help via Microsoft.PowerShell.PlatyPS.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CoverageThreshold
Minimum code coverage percentage enforced by Pester during the Test
task.
Valid range: 0-100.
Default: 80.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tags
Tags for PSGallery discoverability.
Default: empty array.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectUri
Project URI for the module manifest (e.g.
GitHub repo URL).
Default: empty string.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LicenseUri
License URI for the module manifest.
Default: empty string.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Removes and re-creates the destination directory if it already exists.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -GitInit
Initialises a git repository in the scaffolded project and creates an
initial commit.
Requires git to be available on PATH.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Returns the full path of the generated project directory as a string.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.String
## NOTES

## RELATED LINKS
