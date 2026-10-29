<#
.SYNOPSIS
  Download the official source code attached to a tutorial chapter into reference\main.cpp,
  so it can be built/run with: .\tools\build.ps1 -Project reference -Run

.EXAMPLE
  .\tools\ref.ps1 https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/00_Setup/01_Instance.html
  .\tools\ref.ps1 03_Drawing_a_triangle/00_Setup/01_Instance.html
  .\tools\ref.ps1 01_instance_creation.cpp      # attachment name directly
  .\tools\ref.ps1                               # chapter in .tutorial-current
#>
param([string]$Page)

$ErrorActionPreference = 'Stop'
$Base    = 'https://docs.vulkan.org/tutorial/latest/'
$Root    = Split-Path $PSScriptRoot -Parent
$Current = Join-Path $Root '.tutorial-current'
$Utf8    = New-Object Text.UTF8Encoding $false

if (-not $Page) {
    if (-not (Test-Path $Current)) { throw 'No chapter given and no .tutorial-current.' }
    $Page = (Get-Content $Current -Raw).Trim()
}
$Page = $Page -replace '^https?://docs\.vulkan\.org/tutorial/latest/', '' -replace '#.*$', ''

if ($Page -match '\.cpp$') {
    $files = @($Page)
} else {
    $html = (& curl.exe -sSfL ($Base + $Page)) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "curl failed: $Page" }
    $files = @([regex]::Matches($html, 'href="[^"]*_attachments/([^"]+\.cpp)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    if (-not $files) { throw "No .cpp attachment on $Page" }
    [IO.File]::WriteAllText($Current, $Page, $Utf8)
}

$dst = Join-Path $Root 'reference\main.cpp'
& curl.exe -sSfL ($Base + '_attachments/' + $files[0]) -o $dst
if ($LASTEXITCODE -ne 0) { throw "download failed: $($files[0])" }
"reference\main.cpp <- $($files[0])"
if ($files.Count -gt 1) { "other attachments: $($files[1..($files.Count-1)] -join ', ')" }
