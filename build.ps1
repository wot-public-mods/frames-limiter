# This file is part of the XFW NVIDIA project.
#
# Copyright (c) 2017-2021 XVM Team.
#
# XFW NVIDIA is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, version 3.
#
# XFW NVIDIA is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

#
# Push to script location
#

Push-Location $PSScriptRoot
$root = (Get-Location).Path -replace "\\","/"

#
# Import library
#

Import-Module ./3rdparty/xfw_buildlib/library.psm1 -Force -DisableNameChecking

#
# Clean output
#

Remove-Item -Path ./~output/  -Force -Recurse -ErrorAction SilentlyContinue

#
# Download devel package
#

Download-NativeDevelPackage -OutputPath ./~output/build_cpp_prefix/

#
# Build Native
#

function Build-Native() {
    Build-CmakeProject -SourceDirectory ./src_cpp -BuildDirectory "$root/~output/build_cpp_library/" -InstallDirectory "$root/~output/component_native/" -PrefixDirectory "$root/~output/build_cpp_prefix/" -Generator "Visual Studio 17 2022" -Toolchain "v143" -Arch "Win32"
    Build-CmakeProject -SourceDirectory ./src_cpp -BuildDirectory "$root/~output/build_cpp_library/" -InstallDirectory "$root/~output/component_native/" -PrefixDirectory "$root/~output/build_cpp_prefix/" -Generator "Visual Studio 17 2022" -Toolchain "v143" -Arch "x64"
}

Build-Native

#
# Build python
#


function Build-Python()
{
    Build-PythonFile -FilePath "./src_python/__empty__.py" -OutputDirectory "$root/~output/component_python/res/mods/xfw_packages/frames_limiter/" -OutputFileName "__init__.pyc"
    Build-PythonFile -FilePath "./src_python/__init__.py"  -OutputDirectory "$root/~output/component_python/res/mods/xfw_packages/frames_limiter/python/"
}

Build-Python


#
# Build flash
#


function Build-Flash()
{
    New-Item -Path "$root/~output/component_flash/res/flash/" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Copy-Item -Path "$root/src_flash/*.swf" -Destination "$root/~output/component_flash/res/flash/"
}

 Build-Flash


#
# Sign
#

function Build-Sign(){
    if(Sign-IsAvailable){
        Write-Output "Signing files"
        Sign-Folder -Folder "./~output/component_native/Win32/bin/"
        Sign-Folder -Folder "./~output/component_native/x64/bin/"
        Write-Output ""
    }
}

Build-Sign

#
# Copy
#

function Build-Copy()
{
    $version = Get-Content "./src_meta/version.txt"

    Copy-Item -Path "$root/~output/component_python/res/" -Destination "$root/~output/wotmod/res" -Force -Recurse

    New-Item -Path "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_32bit/" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_64bit/" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    Copy-Item -Path "$root/~output/component_native/Win32/bin/*.pyd" -Destination "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_32bit/" -Recurse
    Copy-Item -Path "$root/~output/component_native/Win32/bin/*.dll" -Destination "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_32bit/" -Recurse
    Copy-Item -Path "$root/~output/component_native/Win32/bin/*.exe" -Destination "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_32bit/" -Recurse

    Copy-Item -Path "$root/~output/component_native/x64/bin/*.pyd" -Destination "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_64bit/" -Recurse
    Copy-Item -Path "$root/~output/component_native/x64/bin/*.dll" -Destination "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_64bit/" -Recurse
    Copy-Item -Path "$root/~output/component_native/x64/bin/*.exe" -Destination "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/native_64bit/" -Recurse

    New-Item -Path "$root/~output/wotmod/res/gui/flash/" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Copy-Item -Path "$root/~output/component_flash/res/flash/*.swf" -Destination "$root/~output/wotmod/res/gui/flash/" -Recurse
	
    Copy-Item -Path "./LICENSE.md"                       -Destination "$root/~output/wotmod/LICENSE.md"

    (Get-Content "src_meta/wotmod_meta.xml.in").Replace("{{VERSION}}","${version}") | Set-Content "$root/~output/wotmod/meta.xml"
    (Get-Content "src_meta/xfw_package.json").Replace("{{VERSION}}","${version}")  | Set-Content "$root/~output/wotmod/res/mods/xfw_packages/frames_limiter/xfw_package.json"

}

Build-Copy

#
# Deploy
#

function Build-Deploy()
{
    $version = Get-Content "./src_meta/version.txt"

    Create-Zip -Directory "$root/~output/wotmod/"

    New-Item -Path "$root/~output/deploy/" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Move-Item "$root/~output/wotmod/output.zip" "$root/~output/deploy/poliroid.frames_limiter_${version}.wotmod" -Force
}

Build-Deploy



#
# Pop location
#

Pop-Location
