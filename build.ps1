# SPDX-License-Identifier: LGPL-3.0+
# Copyright (c) 2017-2022 XVM Team



Import-Module "$PSScriptRoot/src_build/library.psm1" -Force -DisableNameChecking
Build-Package -PackageDirectory "$PSScriptRoot/src" -OutputDirectory "$PSScriptRoot/~output"
