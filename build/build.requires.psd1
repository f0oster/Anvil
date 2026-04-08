@{
    # Build toolchain for Anvil
    #
    # Group modules by purpose.  Use any group names you like -- they become
    # selectable scopes in bootstrap.ps1 via -Scope.
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
        'Microsoft.PowerShell.PlatyPS' = '1.0.1'
    }
}
