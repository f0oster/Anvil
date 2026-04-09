---
external help file: Anvil-help.xml
Module Name: Anvil
online version:
schema: 2.0.0
---

# New-AnvilFunction

## SYNOPSIS
Creates a new function file and its corresponding Pester test in an
Anvil-scaffolded module.

## SYNTAX

```
New-AnvilFunction [-FunctionName] <String> [-Scope] <String> [[-Location] <String>] [[-Path] <String>]
 [-SkipVerbCheck] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generates a function file in the appropriate src/\<ModuleName\>/Public/ or
src/\<ModuleName\>/Private/ directory, and a matching test file in
tests/unit/Public/ or tests/unit/Private/.

The module name is read from build/build.settings.psd1 in the project root.

Public functions are created with a comment-based help block.
After
creating a public function, add its name to FunctionsToExport in the
module manifest (.psd1) to export it.

## EXAMPLES

### EXAMPLE 1
```
New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public
```

### EXAMPLE 2
```
New-AnvilFunction -FunctionName 'Resolve-InternalState' -Scope Private -Path C:\Projects\MyModule
```

### EXAMPLE 3
```
New-AnvilFunction -FunctionName 'Get-Widget' -Scope Public -Location 'Core/Greetings'
```

### EXAMPLE 4
```
New-AnvilFunction -FunctionName 'Fetch-Data' -Scope Public -SkipVerbCheck
```

## PARAMETERS

### -FunctionName
The name of the function to create.
The generated files will be named
\<FunctionName\>.ps1 and \<FunctionName\>.Tests.ps1.

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
Whether the function is Public (exported) or Private (internal).
Determines the output directories and the test pattern used.

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
-Location 'Core/Greetings' places the files under
src/\<ModuleName\>/\<Scope\>/Core/Greetings/ and
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

### -SkipVerbCheck
Skip the approved verb validation for public functions.
By default,
public function names must use an approved PowerShell verb (see Get-Verb).

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.IO.FileInfo
## NOTES

## RELATED LINKS
