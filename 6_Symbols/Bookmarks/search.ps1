# Search-Raindrop.ps1
# Usage: .\Search-Raindrop.ps1 -Query "kubernetes" [-Collection 0] [-Page 0] [-PerPage 25]

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,

    [int]$Collection = 0,   # 0 = all bookmarks
    [int]$Page = 0,
    [int]$PerPage = 25
)

# -- Config -------------------------------------------------------------------
$envFile = Join-Path $PSScriptRoot "..\..\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]*)=(.*)$") {
            [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
        }
    }
}
$TestToken = $env:RAINDROP_TEST_TOKEN
if (-not $TestToken -or $TestToken -eq "YOUR_TEST_TOKEN_HERE") {
    Write-Host "  ERROR: Set RAINDROP_TEST_TOKEN in .env at repo root" -ForegroundColor Red
    Read-Host "  Press Enter to close"
    exit 1
}
# -----------------------------------------------------------------------------

$headers = @{
    "Authorization" = "Bearer $TestToken"
    "Content-Type"  = "application/json"
}

$encodedQuery = [Uri]::EscapeDataString($Query)
$url = "https://api.raindrop.io/rest/v1/raindrops/$Collection" +
       "?search=$encodedQuery&page=$Page&perpage=$PerPage"

Write-Host ""
Write-Host "  Searching Raindrop.io for: " -NoNewline -ForegroundColor Cyan
Write-Host "`"$Query`"" -ForegroundColor Yellow
Write-Host "  Collection: $(if ($Collection -eq 0) {'All bookmarks'} else {"#$Collection"})" -ForegroundColor DarkGray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET

    $total = $response.count
    $items = $response.items

    if ($total -eq 0) {
        Write-Host "  No results found." -ForegroundColor DarkGray
        Read-Host "  Press Enter to close"
        exit
    }

    Write-Host "  Found $total result$(if ($total -ne 1){'s'}) (showing page $($Page+1))" -ForegroundColor Green
    Write-Host ("  " + "-" * 70) -ForegroundColor DarkGray
    Write-Host ""

    $index = 1
    foreach ($item in $items) {
        Write-Host "  [$index] $($item.title)" -ForegroundColor White
        Write-Host "      $($item.link)" -ForegroundColor DarkCyan

        if ($item.tags -and $item.tags.Count -gt 0) {
            $tagStr = ($item.tags | ForEach-Object { "#$_" }) -join "  "
            Write-Host "      $tagStr" -ForegroundColor DarkYellow
        }

        if ($item.excerpt) {
            $excerpt = $item.excerpt.Substring(0, [Math]::Min(120, $item.excerpt.Length))
            if ($item.excerpt.Length -gt 120) { $excerpt += "..." }
            Write-Host "      $excerpt" -ForegroundColor DarkGray
        }

        $created = [DateTime]$item.created
        Write-Host "      Saved: $($created.ToString('yyyy-MM-dd'))" -ForegroundColor DarkGray
        Write-Host ("  " + "-" * 70) -ForegroundColor DarkGray
        Write-Host ""
        $index++
    }

    # Pagination hint
    $totalPages = [Math]::Ceiling($total / $PerPage)
    if ($totalPages -gt 1) {
        Write-Host "  Page $($Page+1) of $totalPages  --  use -Page $($Page+1) for next page" -ForegroundColor DarkGray
        Write-Host ""
    }

    # Auto-open first result
    $firstUrl = $items[0].link
    Write-Host "  Opening: $firstUrl" -ForegroundColor Green
    Start-Process $firstUrl

    Write-Host ""
    $choice = Read-Host "  Open another? Enter number (1-$([Math]::Min($items.Count, $PerPage))) or press Enter to close"
    if ($choice -match '^\d+$') {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $items.Count) {
            $chosenUrl = $items[$idx].link
            Write-Host "  Opening: $chosenUrl" -ForegroundColor Green
            Start-Process $chosenUrl
        } else {
            Write-Host "  Invalid selection." -ForegroundColor DarkGray
        }
    }

} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "  ERROR: Request failed (HTTP $statusCode)" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor DarkRed
    Read-Host "  Press Enter to close"
}
