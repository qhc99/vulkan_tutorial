<#
.SYNOPSIS
  Build (and optionally run) a project with MSBuild. MSBuild sets up cl/link itself,
  so no Developer Command Prompt is needed.

.EXAMPLE
  .\tools\build.ps1                        # Debug build of triangle
  .\tools\build.ps1 -Run                   # build then run from the output dir
  .\tools\build.ps1 -Config Release -Rebuild
#>
param(
    [string]$Project = 'triangle',
    [ValidateSet('Debug', 'Release')][string]$Config = 'Debug',
    [switch]$Run,
    [switch]$Rebuild
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$msbuild = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\amd64\MSBuild.exe' | Select-Object -First 1
if (-not $msbuild) { throw 'MSBuild not found (vswhere).' }

$proj = Join-Path $Root "$Project\$Project.vcxproj"
$target = if ($Rebuild) { 'Rebuild' } else { 'Build' }
& $msbuild $proj -nologo -m -v:minimal "-t:$target" "-p:Configuration=$Config;Platform=x64"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Run) {
    $outDir = Join-Path $Root "out\$Project\$Config"
    Push-Location $outDir
    try { & ".\$Project.exe"; exit $LASTEXITCODE } finally { Pop-Location }
}
