@{
    RootModule        = 'Anvil.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '3a2b1c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d'
    # TODO: Replace placeholder values before publishing to PSGallery
    Author            = 'TODO'
    CompanyName       = 'TODO'
    Copyright         = '(c) 2026 TODO. All rights reserved.'
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
            # TODO: Replace placeholder URIs before publishing to PSGallery
            LicenseUri   = 'https://github.com/TODO/Anvil/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/TODO/Anvil'
            ReleaseNotes = ''
            Prerelease = ''
            ExternalModuleDependencies = @()
        }
    }
}
