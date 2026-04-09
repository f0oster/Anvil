---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# Get-AnvilTemplate

## SYNOPSIS
Lists the available Anvil templates and CI providers.

## SYNTAX

```
Get-AnvilTemplate [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Inspects the bundled template directories shipped with Anvil and
returns objects describing each template and CI provider. 
Use this
to discover what New-AnvilModule can generate.

A summary is also written to the information stream. 
Pipe to
Format-Table or use -InformationAction Continue to see it.

## EXAMPLES

### EXAMPLE 1
```
Get-AnvilTemplate
```

Lists all base templates and CI providers with file counts.

### EXAMPLE 2
```
Get-AnvilTemplate | Where-Object Type -eq 'CIProvider'
```

Returns only the CI provider entries.

## PARAMETERS

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

### System.Management.Automation.PSCustomObject
## NOTES

## RELATED LINKS

[New-AnvilModule]()

