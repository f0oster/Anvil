---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# New-AnvilTest

## SYNOPSIS
Creates a new Pester 5 test file in an Anvil-scaffolded module.

## SYNTAX

```
New-AnvilTest [-Name] <String> [-Scope] <String> [[-Location] <String>] [[-Path] <String>] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generates a test file with the correct boilerplate for testing a public
function, private function, or private class. 
The file is placed in the
appropriate tests/unit/\<Scope\>/ directory.

The module name is read from build/build.settings.psd1 in the project root.

## EXAMPLES

### EXAMPLE 1
```
New-AnvilTest -Name 'Get-Widget' -Scope Public
```

### EXAMPLE 2
```
New-AnvilTest -Name 'Resolve-InternalState' -Scope Private -Path C:\Projects\MyModule
```

### EXAMPLE 3
```
New-AnvilTest -Name 'GreetingBuilder' -Scope PrivateClasses
```

### EXAMPLE 4
```
New-AnvilTest -Name 'Get-Widget' -Scope Public -Location 'Core/Greetings'
```

## PARAMETERS

### -Name
The name of the function or class to test. 
The generated file will
be named \<Name\>.Tests.ps1.

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

### -Scope
Whether the target is Public, Private, or PrivateClasses.
Determines the output directory and the test pattern used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
Optional subdirectory path relative to the scope root. 
For example,
-Location 'Core/Greetings' places the test file under
tests/unit/\<Scope\>/Core/Greetings/.

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
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrite the test file if it already exists.

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
