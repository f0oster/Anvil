# Module-scoped variables and initialization for local development.
# This file is dot-sourced by the .psm1 during development and merged
# into the compiled .psm1 at build time.

$script:TemplateRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Templates'
