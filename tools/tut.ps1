<#
.SYNOPSIS
  Fetch a Khronos Vulkan Tutorial page and print its article body as Markdown.

.EXAMPLE
  .\tools\tut.ps1 03_Drawing_a_triangle/00_Setup/00_Base_code.html   # specific page (path or full URL)
  .\tools\tut.ps1 -Next                                              # page after the current one
  .\tools\tut.ps1                                                    # re-print the current page
  .\tools\tut.ps1 -Nav                                               # list all pages in nav order

  The current page is stored in .tutorial-current. Fetched pages are cached in .cache\pages.
#>
param(
    [string]$Page,
    [switch]$Next,
    [switch]$Nav,
    [switch]$Refresh
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$Base     = 'https://docs.vulkan.org/tutorial/latest/'
$Root     = Split-Path $PSScriptRoot -Parent
$Cache    = Join-Path $Root '.cache\pages'
$Current  = Join-Path $Root '.tutorial-current'
$Utf8     = New-Object Text.UTF8Encoding $false

function Get-Remote([string]$url, [string]$file) {
    if ($Refresh -or -not (Test-Path $file)) {
        New-Item -ItemType Directory -Force (Split-Path $file) | Out-Null
        & curl.exe -sSfL $url -o $file
        if ($LASTEXITCODE -ne 0) { throw "curl failed ($LASTEXITCODE): $url" }
    }
    [IO.File]::ReadAllText($file, $Utf8)
}

function Get-NavPages {
    $js = Get-Remote ($Base + '_static_nav.js') (Join-Path $Cache '_static_nav.js')
    $seen = @{}
    foreach ($m in [regex]::Matches($js, 'href=\\?"([^"\\#]+)')) {
        $h = $m.Groups[1].Value
        if ($h -notmatch '^https?:' -and -not $seen.ContainsKey($h)) { $seen[$h] = 1; $h }
    }
}

function ConvertTo-Md([string]$html, [string]$pageUrl) {
    $s = $html.IndexOf('<article class="doc">')
    $e = $html.IndexOf('</article>', $s)
    if ($s -lt 0 -or $e -lt 0) { throw 'article body not found' }
    $a = $html.Substring($s, $e - $s)

    # Code blocks: pull out first so later rules don't touch them.
    $blocks = New-Object System.Collections.Generic.List[string]
    $a = [regex]::Replace($a, '(?s)<pre[^>]*>(?:<code[^>]*?(?:data-lang="([^"]*)"[^>]*)?>)?(.*?)(?:</code>)?</pre>', {
        param($m)
        $code = $m.Groups[2].Value -replace '<i class="conum" data-value="(\d+)"></i><b>\(\d+\)</b>', '// ($1)'
        $code = [Net.WebUtility]::HtmlDecode(($code -replace '<[^>]+>', ''))
        $blocks.Add("``````$($m.Groups[1].Value)`n$($code.TrimEnd())`n``````")
        "`n@@BLOCK$($blocks.Count - 1)@@`n"
    })

    $a = [regex]::Replace($a, '<h([1-6])[^>]*>(.*?)</h\1>', { param($m) "`n`n" + ('#' * [int]$m.Groups[1].Value) + ' ' + $m.Groups[2].Value + "`n" })
    $a = $a -replace '<i class="fa icon-\w+" title="(\w+)"></i>', '> **[$1]** '
    $a = $a -replace '<a class="anchor"[^>]*></a>', ''
    $a = [regex]::Replace($a, '<img [^>]*?src="([^"]+)"[^>]*?(?:alt="([^"]*)")?[^>]*>', {
        param($m) '![' + $m.Groups[2].Value + '](' + [Uri]::new([Uri]$pageUrl, $m.Groups[1].Value).AbsoluteUri + ')'
    })
    $a = [regex]::Replace($a, '(?s)<a [^>]*?href="([^"]+)"[^>]*>(.*?)</a>', {
        param($m)
        $t = $m.Groups[2].Value; $h = $m.Groups[1].Value
        if ($h.StartsWith('#')) { $t } else { "[$t](" + [Uri]::new([Uri]$pageUrl, $h).AbsoluteUri + ')' }
    })
    $a = $a -replace '</?code[^>]*>', '`'
    $a = $a -replace '</?(strong|b)>', '**'
    $a = $a -replace '</?(em|i)>', '*'
    $a = $a -replace '<td class="(icon|content)">', ''
    $a = $a -replace '<li[^>]*>', "`n- "
    $a = $a -replace '<t[hd][^>]*>', ' | '
    $a = $a -replace '</tr>', "`n"
    $a = $a -replace '<(p|div|br|tr|table|ul|ol|dl|dt|dd)[^>]*>', "`n"
    $a = $a -replace '<[^>]+>', ''
    $a = [Net.WebUtility]::HtmlDecode($a)
    $a = ($a -split "`n" | ForEach-Object { $_.TrimEnd() }) -join "`n"
    $a = [regex]::Replace($a, '\n{3,}', "`n`n")
    $a = [regex]::Replace($a, '@@BLOCK(\d+)@@', { param($m) $blocks[[int]$m.Groups[1].Value] })
    $a.Trim()
}

$pages = @(Get-NavPages)
if ($Nav) { $pages; return }

if ($Page) {
    $Page = $Page -replace '^https?://docs\.vulkan\.org/tutorial/latest/', '' -replace '#.*$', ''
} else {
    if (-not (Test-Path $Current)) { throw 'No current page; pass a page path.' }
    $Page = (Get-Content $Current -Raw).Trim()
    if ($Next) {
        $i = [array]::IndexOf($pages, $Page)
        if ($i -lt 0) { throw "Current page '$Page' not in nav; pass the next page explicitly." }
        if ($i + 1 -ge $pages.Count) { throw 'Already at the last page.' }
        $Page = $pages[$i + 1]
    }
}

$url  = $Base + $Page
$html = Get-Remote $url (Join-Path $Cache ($Page -replace '/', '\'))
[IO.File]::WriteAllText($Current, $Page, $Utf8)

$i = [array]::IndexOf($pages, $Page)
$after = if ($i -ge 0 -and $i + 1 -lt $pages.Count) { $pages[$i + 1] } else { '(unknown)' }

"<!-- page: $url -->"
"<!-- next: $after -->"
""
ConvertTo-Md $html $url
