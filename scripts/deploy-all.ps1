# Deploy all: backend (git push + SSH update) + mobile (build + Firebase App Distribution)
# Usage: .\scripts\deploy-all.ps1 [release-notes]
#        .\scripts\deploy-all.ps1 -SkipTests
#        .\scripts\deploy-all.ps1 "New feature" -SkipTests

param(
    [string]$ReleaseNotes = "",
    [switch]$SkipTests,
    [switch]$SkipCI,
    [switch]$SkipFirebase,
    [switch]$SkipGitCheck
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Load repo-local .env files before reading $env:* toggles.
. "$ScriptDir\\load-env.ps1" -ProjectRoot $ProjectRoot

# When invoked as "powershell -File script.ps1 -SkipCI", args may not bind; also support env vars (npm on Windows)
if ($args -contains "-SkipCI") { $SkipCI = $true }
if ($args -contains "-SkipFirebase") { $SkipFirebase = $true }
if ($args -contains "-SkipGitCheck") { $SkipGitCheck = $true }
if ($args -contains "-SkipTests") { $SkipTests = $true }
if ($env:DEPLOY_SKIP_CI -eq "1") { $SkipCI = $true; $SkipGitCheck = $true }
if ($env:DEPLOY_SKIP_FIREBASE -eq "1") { $SkipFirebase = $true }

# Detect Wear OS changes early (before backend push)
$SkipWear = $false
try {
    $latestTag = git describe --tags --match "v*" --abbrev=0 2>$null
    if ($null -eq $latestTag) {
        # No tags, check if there are any commits in wear/ at all in the last 10 commits of HEAD
        $wearChanges = git log -n 10 --oneline -- wear/
    } else {
        $wearChanges = git log "$latestTag..HEAD" --oneline -- wear/
    }
    
    if ([string]::IsNullOrWhiteSpace($wearChanges)) {
        $SkipWear = $true
    }
} catch {
    $SkipWear = $false # Fallback to deploy if git fails
}

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "        DEPLOY ALL: Backend + Mobile   " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# 1. Deploy backend
Write-Host ">>> BACKEND <<<" -ForegroundColor Magenta
$backendArgs = @()
if ($SkipCI) { $backendArgs += "-SkipCI" }
if ($SkipGitCheck -or $SkipFirebase) { $backendArgs += "-SkipGitCheck" }
& "$ScriptDir\deploy-backend.ps1" @backendArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host ">>> MOBILE <<<" -ForegroundColor Magenta

# 2. Deploy mobile
$mobileArgs = @()
if ($ReleaseNotes) { $mobileArgs += $ReleaseNotes }
if ($SkipTests) { $mobileArgs += "-SkipTests" }
if ($SkipFirebase) { $mobileArgs += "-SkipFirebase" }

& "$ScriptDir\deploy-mobile.ps1" @mobileArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
if (-not $SkipWear) {
    Write-Host ">>> WEAR OS <<<" -ForegroundColor Magenta

    $wearArgs = @()
    if ($SkipFirebase) { $wearArgs += "-SkipFirebase" }

    & "$ScriptDir\deploy-wear.ps1" @wearArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host ">>> WEAR OS (Skipped: no changes) <<<" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "        ALL DEPLOYED SUCCESSFULLY!     " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
