---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# Import-AnvilModule

## SYNOPSIS
Imports the development version of the module from the current
Anvil project.

## SYNTAX

```
Import-AnvilModule [[-Path] <String>] [-PassThru] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Locates the source module manifest by walking up the directory
tree, then imports it with -Force so any changes are picked up.

## EXAMPLES

### EXAMPLE 1
```
Import-AnvilModule
```

### EXAMPLE 2
```
Import-AnvilModule -PassThru
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

### -PassThru
Returns the imported module info object.

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

### System.Management.Automation.PSModuleInfo
## NOTES

## RELATED LINKS
