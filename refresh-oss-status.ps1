<#
.SYNOPSIS
  Refreshes an OSS-STATUS.md file with the latest state of a user's PRs across
  upstream repos. Designed to be reusable across GitHub accounts and runnable
  unattended in GitHub Actions.

.DESCRIPTION
  Uses `gh search prs` + `gh pr view` to poll open PRs and recent merges
  authored by -User. Rewrites only the two tables marked by BEGIN/END comments
  in the status file so the rest of the file (priorities, notes, queue) is
  preserved across runs.

.PARAMETER User
  GitHub login whose PRs are tracked. Defaults to the OSS_TRACKER_USER env var,
  or `jluocsa` if unset.

.PARAMETER StatusFile
  Path to the OSS-STATUS.md to rewrite. Defaults to ./OSS-STATUS.md next to
  this script.

.PARAMETER MergedDays
  Window (days) for the "Recently merged" table. Default: 30.

.PARAMETER IgnoreRepos
  nameWithOwner values to exclude (e.g. throwaway practice repos).

.NOTES
  Requires: gh CLI authenticated as -User (or with `repo` + `read:discussion`
  scope on a token). For GitHub Actions, set $env:GH_TOKEN to a PAT with the
  scopes you need to read non-public discussions, or rely on the default
  GITHUB_TOKEN for public-only data.
#>

[CmdletBinding()]
param(
  [string]$User       = $(if ($env:OSS_TRACKER_USER) { $env:OSS_TRACKER_USER } else { 'jluocsa' }),
  [string]$StatusFile,
  [int]   $MergedDays = 30,
  [string[]]$IgnoreRepos = $(if ($env:OSS_TRACKER_IGNORE_REPOS) { $env:OSS_TRACKER_IGNORE_REPOS -split '[,\s]+' | Where-Object { $_ } } else { @() })
)

$ErrorActionPreference = 'Stop'

if (-not $StatusFile) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
  $StatusFile = Join-Path $scriptDir 'OSS-STATUS.md'
}

function Get-AgeDays { param([datetime]$Date) [int]([datetime]::UtcNow - $Date.ToUniversalTime()).TotalDays }

Write-Host "Polling gh search prs --author $User ..." -ForegroundColor Cyan
$openJson = gh search prs --author $User --state open   --limit 100 --json repository,number,title,state,isDraft,createdAt,updatedAt,url 2>&1
if ($LASTEXITCODE -ne 0) { Write-Error "gh search (open) failed: $openJson";   exit 1 }
$closedJson = gh search prs --author $User --state closed --limit 100 --json repository,number,title,state,isDraft,createdAt,updatedAt,url 2>&1
if ($LASTEXITCODE -ne 0) { Write-Error "gh search (closed) failed: $closedJson"; exit 1 }
$allPrs = @(($openJson | ConvertFrom-Json) + ($closedJson | ConvertFrom-Json)) |
  Where-Object { $_.repository.nameWithOwner -notin $IgnoreRepos }

# --- Open PRs ---
$openPrs = $allPrs | Where-Object { $_.state -eq 'open' }
Write-Host "Found $($openPrs.Count) open PRs. Fetching details..." -ForegroundColor Cyan

$openRows = foreach ($pr in $openPrs) {
  $repo   = $pr.repository.nameWithOwner
  $detail = gh pr view $pr.number --repo $repo --json url,number,title,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews,createdAt 2>&1 | ConvertFrom-Json

  $checks = @($detail.statusCheckRollup)
  $checkSummary = if ($checks.Count -eq 0) {
    'none reported'
  } else {
    $byStatus = @($checks | Group-Object status | ForEach-Object { "$($_.Name)=$($_.Count)" })
    $completed = @($checks | Where-Object { $_.status -eq 'COMPLETED' })
    $byConclusion = @($completed | Group-Object conclusion | ForEach-Object {
      $name = if ($_.Name) { "$($_.Name)" } else { 'unknown' }
      switch ($name) {
        'SUCCESS' { "$($_.Count)✅" }
        'FAILURE' { "$($_.Count)❌" }
        default   { "$($_.Count) $($name.ToLower())" }
      }
    })
    if ($byConclusion.Count -gt 0) { ($byConclusion -join ', ') } else { ($byStatus -join ', ') }
  }

  $reviewSummary = if ($detail.reviews.Count -eq 0) { 'none' } else {
    ($detail.reviews | ForEach-Object { "$($_.author.login):$($_.state)" }) -join ', '
  }

  $age = Get-AgeDays -Date $detail.createdAt

  [PSCustomObject]@{
    Number  = $detail.number
    Repo    = $repo
    Title   = ($detail.title -replace '\|', '\|')
    Url     = $detail.url
    Merge   = $detail.mergeable
    State   = $detail.mergeStateStatus
    Checks  = $checkSummary
    Reviews = $reviewSummary
    Age     = "${age}d"
  }
}

$openRows = $openRows | Sort-Object { [int]($_.Age -replace 'd','') }

$openTable = @()
$openTable += '| # | Repo | Title | Mergeable | MergeState | Checks | Reviews | Age |'
$openTable += '|---|---|---|---|---|---|---|---|'
foreach ($r in $openRows) {
  $openTable += "| [#$($r.Number)]($($r.Url)) | $($r.Repo) | $($r.Title) | $($r.Merge) | $($r.State) | $($r.Checks) | $($r.Reviews) | $($r.Age) |"
}
if ($openRows.Count -eq 0) { $openTable += '| _none open_ | | | | | | | |' }

# --- Recently merged ---
$cutoff = (Get-Date).AddDays(-$MergedDays)
$mergedPrs = $allPrs | Where-Object { $_.state -ne 'open' -and ([datetime]$_.updatedAt) -gt $cutoff }

Write-Host "Checking merged status for $($mergedPrs.Count) closed PRs..." -ForegroundColor Cyan
$mergedRows = foreach ($pr in $mergedPrs) {
  $repo   = $pr.repository.nameWithOwner
  $detail = gh pr view $pr.number --repo $repo --json url,number,title,mergedAt 2>&1 | ConvertFrom-Json
  if ($detail.mergedAt) {
    [PSCustomObject]@{
      Number = $detail.number
      Repo   = $repo
      Title  = ($detail.title -replace '\|', '\|')
      Url    = $detail.url
      Merged = ([datetime]$detail.mergedAt).ToString('yyyy-MM-dd')
    }
  }
}

$mergedTable = @()
$mergedTable += '| # | Repo | Title | Merged |'
$mergedTable += '|---|---|---|---|'
if ($mergedRows) {
  foreach ($r in ($mergedRows | Sort-Object Merged -Descending)) {
    $mergedTable += "| [#$($r.Number)]($($r.Url)) | $($r.Repo) | $($r.Title) | $($r.Merged) |"
  }
} else {
  $mergedTable += "| _none in last $MergedDays days_ | | | |"
}

# --- Write back ---
if (-not (Test-Path $StatusFile)) {
  Write-Host "Status file not found, creating from template: $StatusFile" -ForegroundColor Yellow
  $template = @"
# OSS Status -- $User

Auto-refreshed daily by [refresh-oss-status.ps1](./refresh-oss-status.ps1).
Hand-curated sections (queue, notes) live outside the marker blocks and are
preserved across runs.

**Last refreshed:** _(pending first run)_

## Open PRs

<!-- BEGIN: PR_TABLE -->
<!-- END: PR_TABLE -->

## Recently merged (last $MergedDays days)

<!-- BEGIN: MERGED_TABLE -->
<!-- END: MERGED_TABLE -->

## Queue / Priorities

_(add your own bullets here — they survive every refresh)_
"@
  Set-Content -Path $StatusFile -Value $template -Encoding UTF8
}

$content = Get-Content -Raw -Path $StatusFile

$openBlock   = (@('<!-- BEGIN: PR_TABLE -->')     + $openTable   + @('<!-- END: PR_TABLE -->'))     -join "`n"
$mergedBlock = (@('<!-- BEGIN: MERGED_TABLE -->') + $mergedTable + @('<!-- END: MERGED_TABLE -->')) -join "`n"

$pattern1 = '(?s)<!-- BEGIN: PR_TABLE -->.*?<!-- END: PR_TABLE -->'
$pattern2 = '(?s)<!-- BEGIN: MERGED_TABLE -->.*?<!-- END: MERGED_TABLE -->'
$content = [regex]::Replace($content, $pattern1, { param($m) $openBlock })
$content = [regex]::Replace($content, $pattern2, { param($m) $mergedBlock })

$today = (Get-Date).ToString('yyyy-MM-dd HH:mm')
$content = [regex]::Replace($content, '\*\*Last refreshed:\*\*[^\n]*', "**Last refreshed:** $today")

Set-Content -Path $StatusFile -Value $content -Encoding UTF8 -NoNewline
Write-Host "Updated: $StatusFile" -ForegroundColor Green
Write-Host "  Open: $($openRows.Count) | Merged in last $MergedDays days: $(($mergedRows | Measure-Object).Count)" -ForegroundColor Green
