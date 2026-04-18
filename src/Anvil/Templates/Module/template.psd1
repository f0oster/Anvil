@{
    Name        = 'Module'
    Description = 'PowerShell module with build pipeline, tests, and CI/CD'
    Version     = '1.0.0'

    Parameters = @(
        @{
            Name     = 'Name'
            Type     = 'string'
            Required = $true
            Prompt   = 'Module name'
            Validate = '^[A-Za-z][A-Za-z0-9._\-]{0,127}$'
            ValidateMessage = 'Must start with a letter. Letters, digits, dots, hyphens, underscores only. Max 128 characters.'
        }
        @{
            Name        = 'Author'
            Type        = 'string'
            Required    = $true
            Prompt      = 'Author'
            DefaultFrom = 'GitUserName'
        }
        @{
            Name    = 'Description'
            Type    = 'string'
            Prompt  = 'Description'
            Default = 'A PowerShell module scaffolded by Anvil.'
        }
        @{
            Name    = 'CompanyName'
            Type    = 'string'
            Prompt  = 'Company name'
            Default = ''
        }
        @{
            Name     = 'MinPowerShellVersion'
            Type     = 'string'
            Prompt   = 'Minimum PowerShell version'
            Default  = '5.1'
            Validate = '^\d+\.\d+(\.\d+(\.\d+)?)?$'
            ValidateMessage = 'Must be a valid version string (e.g. 5.1, 7.2).'
        }
        @{
            Name    = 'CompatiblePSEditions'
            Type    = 'csv'
            Prompt  = 'Compatible PS editions (Desktop,Core / Core)'
            Default = 'Desktop,Core'
            Format  = 'psd1-array'
        }
        @{
            Name    = 'CIProvider'
            Type    = 'choice'
            Prompt  = 'CI provider'
            Choices = @('GitHub', 'AzurePipelines', 'GitLab', 'None')
            Default = 'GitHub'
        }
        @{
            Name    = 'License'
            Type    = 'choice'
            Prompt  = 'License'
            Choices = @('MIT', 'Apache2', 'None')
            Default = 'MIT'
        }
        @{
            Name    = 'CoverageThreshold'
            Type    = 'int'
            Prompt  = 'Code coverage threshold (0-100)'
            Default = 80
            Range   = @(0, 100)
        }
        @{
            Name    = 'IncludeDocs'
            Type    = 'bool'
            Prompt  = 'Include platyPS docs generation?'
            Default = $true
            Format  = 'lower-string'
        }
        @{
            Name    = 'Tags'
            Type    = 'csv'
            Prompt  = 'Tags (comma-separated)'
            Default = ''
            Format  = 'psd1-array'
        }
        @{
            Name    = 'ProjectUri'
            Type    = 'uri'
            Prompt  = 'Project URI'
            Default = ''
        }
        @{
            Name    = 'LicenseUri'
            Type    = 'uri'
            Prompt  = 'License URI'
            Default = ''
        }
    )

    AutoTokens = @(
        @{ Name = 'ModuleGuid'; Source = 'NewGuid' }
        @{ Name = 'Year'; Source = 'CurrentYear' }
    )

    Sections = @{
        DocsTask         = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
        DocsBuildStep    = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
        DocsTaskGraph    = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
        DocsComposite    = @{ IncludeWhen = @{ IncludeDocs = 'true' } }
        NoDocsTaskGraph  = @{ ExcludeWhen = @{ IncludeDocs = 'true' } }
        NoDocsComposite  = @{ ExcludeWhen = @{ IncludeDocs = 'true' } }
        LicenseMIT       = @{ IncludeWhen = @{ License = 'MIT' } }
        LicenseApache2   = @{ IncludeWhen = @{ License = 'Apache2' } }
    }

    ExcludeWhen = @{
        'LICENSE.tmpl' = @{ License = 'None' }
        'docs/*'       = @{ IncludeDocs = 'false' }
    }

    Layers = @(
        @{ PathKey = 'CIProvider'; BasePath = 'CI'; Skip = 'None' }
    )
}
