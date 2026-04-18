---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# Invoke-AnvilBuild

## SYNOPSIS
Runs the InvokeBuild pipeline in an Anvil project.

## SYNTAX

```
Invoke-AnvilBuild [[-Task] <String[]>] [-NewVersion <String>] [-Prerelease <String>] [-Path <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Locates build/module.build.ps1 in the project root and invokes it
with the specified tasks.
If no tasks are specified, runs the
default pipeline.

## EXAMPLES

### EXAMPLE 1
```
Invoke-AnvilBuild
```

### EXAMPLE 2
```
Invoke-AnvilBuild -Task Lint, Test
```

### EXAMPLE 3
```
Invoke-AnvilBuild -Task Release -NewVersion 1.0.0
```

## PARAMETERS

### -Task
One or more build tasks to run.
When omitted, runs the default
pipeline (Clean, Validate, Format, Lint, Test, Build,
IntegrationTest, Package).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewVersion
Version number to inject into the compiled module manifest.

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

### -Prerelease
Prerelease label to set on the compiled module manifest.

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

### -Path
The project root directory.
If not provided, walks up from the
current directory to find the project root.

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
