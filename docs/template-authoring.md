# Template Authoring Guide

## Quick start

Create a directory with a manifest and some template files:

```
MyTemplate/
    template.psd1
    README.md.tmpl
    src/
        __Name__/
            __Name__.ps1.tmpl
```

Write the manifest:

```powershell
@{
    Name        = 'MyTemplate'
    Description = 'A minimal project template'
    Version     = '1.0.0'

    Parameters = @(
        @{ Name = 'Name'; Type = 'string'; Required = $true; Prompt = 'Project name' }
        @{ Name = 'Author'; Type = 'string'; Required = $true; Prompt = 'Author' }
    )
}
```

Write a template file (`README.md.tmpl`):

```
# <%Name%>

By <%Author%>
```

Scaffold from it:

```powershell
New-AnvilModule -Name 'MyProject' -DestinationPath . -Template 'C:\path\to\MyTemplate' -Author 'Jane'
```

This produces:

```
MyProject/
    README.md           # contains "# MyProject" and "By Jane"
    src/
        MyProject/
            MyProject.ps1
```

## Token syntax

Templates use two token formats:

### Content tokens: `<%TokenName%>`

Used inside `.tmpl` file content. Replaced with the parameter or auto-token value during scaffolding.

```powershell
# <%Name%>.psm1
# Author: <%Author%>
```

Content tokens use literal string replacement, not regex. Values containing special characters are handled safely.

### Path tokens: `__TokenName__`

Used in file and directory names. Replaced during scaffolding.

```
src/__Name__/__Name__.psd1.tmpl
```

Becomes:

```
src/MyModule/MyModule.psd1
```

### Processing order

When a `.tmpl` file is processed, sections are resolved first, then token replacement runs on whatever content remains. This means section bodies can contain `<%Token%>` placeholders:

```
<%#section Greeting%>
Hello, <%Author%>! Welcome to <%Name%>.
<%#endsection%>
```

If the section is kept, the tokens are replaced normally. If the section is removed, the tokens inside it are never evaluated — they're discarded along with the section body.

### Template vs static files

Files with a `.tmpl` extension are processed for content token replacement. The `.tmpl` suffix is stripped from the output filename.

Files without `.tmpl` are copied verbatim (binary-safe). No token replacement occurs in their content. Path tokens in their names are still replaced.

## Manifest reference

The manifest is a PowerShell data file (`template.psd1`) at the root of the template directory.

### Metadata

Every manifest requires `Name`, `Description`, and `Version`:

```powershell
@{
    Name        = 'Module'
    Description = 'PowerShell module with build pipeline and tests'
    Version     = '1.0.0'
}
```

### Parameters

An ordered array of parameter declarations. The order determines the interactive prompt sequence.

```powershell
Parameters = @(
    @{
        Name            = 'Name'            # Token name (used as <%Name%> and __Name__)
        Type            = 'string'          # Parameter type (see below)
        Required        = $true             # Whether a value must be provided
        Prompt          = 'Module name'     # Text shown during interactive prompts
        Default         = $null             # Default value when not provided
        DefaultFrom     = 'GitUserName'     # Named default resolver (see below)
        Validate        = '^\w+$'           # Regex pattern for validation (string type)
        ValidateMessage = 'Alpha only.'     # Error message when validation fails
        Choices         = @('A', 'B', 'C')  # Valid options (choice type only)
        Range           = @(0, 100)         # Min/max bounds (int type only)
        Format          = 'raw'             # Output formatter (see below)
    }
)
```

`Name`, `Type`, and `Prompt` are required. All other fields are optional.

#### Parameter types

| Type | Interactive behavior | Validation | Default format |
|---|---|---|---|
| `string` | Text prompt | Optional regex | `raw` |
| `choice` | Selection from `Choices` list | Must be in `Choices` | `raw` |
| `bool` | y/n prompt | Boolean | `lower-string` |
| `int` | Numeric prompt | Optional `Range` bounds | `raw` |
| `csv` | Comma-separated text, split into array | None | `raw` |
| `uri` | Text prompt with URI validation and retry | Absolute URI | `raw` |

#### DefaultFrom resolvers

Named resolvers that derive default values from the environment:

| Resolver | Value |
|---|---|
| `GitUserName` | `git config user.name` |
| `CurrentDirectory` | Current working directory path |

#### Formatters

Formatters transform parameter values into strings for token replacement. Declared via the `Format` field.

| Formatter | Input | Output | Use case |
|---|---|---|---|
| `raw` | Any | `.ToString()` | Most parameters |
| `psd1-array` | String array | `@('a', 'b')` or `@()` | Embedding arrays in `.psd1` files |
| `lower-string` | Boolean | `'true'` or `'false'` | Boolean values in config files |
| `quoted` | String | `'value'` | Values needing single quotes |

### Auto-tokens

Some tokens are computed by the engine rather than provided by the user. A module manifest needs a GUID, a license file needs the current year — these shouldn't be prompted for.

```powershell
AutoTokens = @(
    @{ Name = 'ModuleGuid'; Source = 'NewGuid' }
    @{ Name = 'Year'; Source = 'CurrentYear' }
)
```

| Source | Value |
|---|---|
| `NewGuid` | A new random GUID string |
| `CurrentYear` | Four-digit year (e.g. `2026`) |
| `CurrentDate` | Date in `yyyy-MM-dd` format |

### Conditions

Not every file belongs in every scaffolded project. A project with `License = 'None'` shouldn't include a LICENSE file. A project without docs shouldn't include documentation templates.

Conditions control which files are included or excluded based on parameter values.

#### ExcludeWhen

Exclude a file when the condition matches:

```powershell
ExcludeWhen = @{
    'LICENSE.tmpl' = @{ License = 'None' }
}
```

This skips `LICENSE.tmpl` when `License` equals `'None'`.

#### IncludeWhen

Include a file only when the condition matches:

```powershell
IncludeWhen = @{
    'docs/*' = @{ IncludeDocs = 'true' }
}
```

This only processes files under `docs/` when `IncludeDocs` equals `'true'`.

#### Condition keys and values

- Keys are wildcard patterns matched against file paths using `-like`
- Values are hashtables of `{ ParameterName = 'expected value' }`
- Multiple values for a key means OR: `@{ License = 'MIT', 'Apache2' }`
- Multiple keys in a condition means AND: `@{ A = 'x'; B = 'y' }`
- Conditions match against **formatted** token values (after formatters are applied)
- Files not matched by any pattern are always included

#### Precedence

`ExcludeWhen` is evaluated before `IncludeWhen`. If a file matches both, it is excluded.

### Sections

Conditions work at the file level — include or exclude an entire file. Sections handle the case where part of a file should vary based on a parameter, but the rest of the file is always needed.

The built-in Module template uses sections to conditionally include the platyPS documentation task in the build script. When `IncludeDocs` is false, the Docs task definition, the MAML help build step, and the Docs entry in the composite task line are all removed — but the rest of the build script stays intact.

#### Markers

```
<%#section SectionName%>
Content that may or may not appear in the output.
<%#endsection%>
```

- Markers must appear on their own line
- Marker lines are always stripped from the output (whether the section is kept or removed)
- Sections cannot nest

#### Section conditions

Declared in the manifest using the same condition format as file conditions:

```powershell
Sections = @{
    DocsTask = @{
        IncludeWhen = @{ IncludeDocs = 'true' }
    }
    LicenseBadge = @{
        ExcludeWhen = @{ License = 'None' }
    }
}
```

Each section must have exactly one of `IncludeWhen` or `ExcludeWhen`.

A section marker in a template file without a corresponding manifest entry causes an error.

#### Mutually exclusive sections

When a line has two variants, use a pair of sections with opposite conditions:

```powershell
Sections = @{
    DocsComposite   = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
    NoDocsComposite = @{ ExcludeWhen = @{ IncludeDocs = 'true' } }
}
```

In the template file:

```
<%#section DocsComposite%>
task . Clean, Validate, Format, Lint, Test, Docs, Build, IntegrationTest, Package
<%#endsection%>
<%#section NoDocsComposite%>
task . Clean, Validate, Format, Lint, Test, Build, IntegrationTest, Package
<%#endsection%>
```

Exactly one of the two blocks appears in the output, depending on `IncludeDocs`.

### Layers

A template might support multiple variants of the same concern. The Module template supports GitHub, Azure Pipelines, and GitLab CI — each with its own workflow files. Rather than bundling all three and conditionally excluding two, layers let each variant live in its own directory. The parameter value selects which one to apply.

```powershell
Layers = @(
    @{
        PathKey  = 'CIProvider'     # Parameter that selects the layer
        BasePath = 'CI'             # Directory containing layer subdirectories
        Skip     = 'None'           # Value that means "no layer"
    }
)
```

Given `CIProvider = 'GitHub'`, the engine processes the directory at `CI/GitHub/` after the base template. Layer directories sit alongside the template directory (as siblings, not children).

Layer files use the same token replacement and are merged into the output.

## Directory structure

A typical template layout:

```
Templates/
    MyTemplate/
        template.psd1           # Manifest
        README.md.tmpl          # Processed for tokens
        .gitignore              # Copied verbatim
        src/
            __Name__/           # Directory name has path token
                __Name__.psd1.tmpl
                __Name__.psm1.tmpl
    CI/                         # Layer directory (sibling)
        GitHub/
            .github/
                workflows/
                    ci.yml.tmpl
        GitLab/
            .gitlab-ci.yml.tmpl
```

The `template.psd1` file itself is automatically excluded from the output.

## Scaffolding from a custom template

### By path

```powershell
New-AnvilModule -Name 'MyProject' -DestinationPath . -Template 'C:\templates\MyTemplate' -Interactive
```

### By name (bundled templates)

```powershell
New-AnvilModule -Name 'MyProject' -DestinationPath . -Template 'Module'
```

### Discovering templates

```powershell
Get-AnvilTemplate
```

Returns template metadata including description, version, parameters, and available layers.
