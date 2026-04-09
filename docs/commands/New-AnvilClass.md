---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# New-AnvilClass

## SYNOPSIS
Creates a new PowerShell class file and its corresponding Pester test
in an Anvil-scaffolded module.

## SYNTAX

```
New-AnvilClass [-ClassName] <String> [[-Location] <String>] [[-Path] <String>] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generates a class file in src/\<ModuleName\>/PrivateClasses/ and a
matching test file in tests/unit/PrivateClasses/.

The module name is read from build/build.settings.psd1 in the project root.

## EXAMPLES

### EXAMPLE 1
```
New-AnvilClass -ClassName 'HttpClient'
```

### EXAMPLE 2
```
New-AnvilClass -ClassName 'CacheEntry' -Location 'Models'
```

### EXAMPLE 3
```
New-AnvilClass -ClassName 'HttpClient' -Path C:\Projects\MyModule
```

## PARAMETERS

### -ClassName
The name of the class to create.
The generated files will be named
\<ClassName\>.ps1 and \<ClassName\>.Tests.ps1.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
Optional subdirectory path relative to PrivateClasses/.
For example,
-Location 'Models' places the files under
src/\<ModuleName\>/PrivateClasses/Models/ and
tests/unit/PrivateClasses/Models/.

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

### -Path
The project root directory.
If not provided, the current directory is
used and the command walks up the directory tree to find the project root.
You will be prompted to confirm before the walk-up begins.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrite existing files if they already exist.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.IO.FileInfo
## NOTES

## RELATED LINKS
