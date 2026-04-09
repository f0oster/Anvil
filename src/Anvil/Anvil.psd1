@{
    RootModule        = 'Anvil.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = '3a2b1c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d'
    Author            = 'f0oster'
    CompanyName       = ''
    Copyright         = '(c) 2026 f0oster. All rights reserved.'
    Description       = 'Scaffolds production-grade PowerShell module projects with opinionated build, test, lint, docs, and CI/CD pipelines.'
    PowerShellVersion = '7.2'

    RequiredModules = @()
    RequiredAssemblies = @()
    NestedModules = @()
    
    ScriptsToProcess = @()
    TypesToProcess = @()
    FormatsToProcess = @()

    # FunctionsToExport = @()
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Module', 'Scaffold', 'Template', 'Build', 'CI', 'Pester', 'InvokeBuild')
            LicenseUri   = 'https://github.com/f0oster/Anvil/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/f0oster/Anvil'
            ReleaseNotes = ''
            Prerelease = ''
            ExternalModuleDependencies = @()
        }
    }
}
