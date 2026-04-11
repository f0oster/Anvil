---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# Invoke-AnvilBootstrapDeps

## SYNOPSIS
Runs the bootstrap script in an Anvil project to install dependencies.

## SYNTAX

```
Invoke-AnvilBootstrapDeps [[-Path] <String>] [[-Scope] <String[]>] [-Update] [-Plan]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Locates and executes build/bootstrap.ps1 in the project root, which
installs both the Anvil build toolchain and any module dependencies
declared in requirements.psd1.

## EXAMPLES

### EXAMPLE 1
```
Invoke-AnvilBootstrapDeps
```

### EXAMPLE 2
```
Invoke-AnvilBootstrapDeps -Scope Build,Test
```

### EXAMPLE 3
```
Invoke-AnvilBootstrapDeps -Plan
```

## PARAMETERS

### -Path
The project root directory.
If not provided, walks up from the
current directory to find the project root.

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

### -Scope
One or more dependency group names to install from build.requires.psd1.
When omitted, all groups are installed.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Update
Forces ModuleFast to re-check for newer versions.

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

### -Plan
Shows what would be installed without installing anything.

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

### None
## NOTES

## RELATED LINKS
