@{
    # Anvil build toolchain -- do not add module dependencies here.
    # Use Add-AnvilDependency to manage module dependencies in requirements.psd1.
    #
    # Syntax per module:  'ModuleName' = 'VersionSpec'
    #   '5.7.1'     - exact version
    #   'latest'    - newest stable
    #   '>=5.0.0'   - minimum version
    #   See: https://github.com/JustinGrote/ModuleFast

    Build = @{
        'InvokeBuild'      = '5.12.1'
        'PSScriptAnalyzer' = '1.23.0'
    }

    Test = @{
        'Pester' = '5.7.1'
    }

    Docs = @{
        'platyPS' = '0.14.2'
    }
}
