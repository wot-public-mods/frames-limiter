#!/usr/bin/env pwsh

Import-Module "$PSScriptRoot/src_build/library.psm1" -Force -DisableNameChecking

Build-Packages -PackageDirectory "$PSScriptRoot/src/" -OutputDirectory "$PSScriptRoot/~output"
