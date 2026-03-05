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

# Helper: detect if a directory has any changes vs origin/main
function HasChanges([string]$dir) {
    try {
        $committed   = git diff --name-only origin/main..HEAD -- $dir 2>$null
        $uncommitted = git diff --name-only -- $dir 2>$null
        $staged      = git diff --staged --name-only -- $dir 2>$null
        return -not ([string]::IsNullOrWhiteSpace($committed) -and
                     [string]::IsNullOrWhiteSpace($uncommitted) -and
                     [string]::IsNullOrWhiteSpace($staged))
    } catch {
        return $true # Fallback: deploy if git check fails
    }
}

$SkipBackend = -not (HasChanges "backend/")
$SkipMobile  = -not (HasChanges "mobile/")
$SkipWear    = (-not (Test-Path "$ProjectRoot/wear")) -or (-not (HasChanges "wear/"))

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "        DEPLOY ALL: Backend + Mobile   " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# 1. Deploy backend
if (-not $SkipBackend) {
    Write-Host ">>> BACKEND <<<" -ForegroundColor Magenta
    $backendArgs = @()
    if ($SkipCI) { $backendArgs += "-SkipCI" }
    if ($SkipGitCheck -or $SkipFirebase) { $backendArgs += "-SkipGitCheck" }
    & "$ScriptDir\deploy-backend.ps1" @backendArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host ">>> BACKEND (Skipped: no changes) <<<" -ForegroundColor Gray
}

Write-Host ""

# 2. Deploy mobile
if (-not $SkipMobile) {
    Write-Host ">>> MOBILE <<<" -ForegroundColor Magenta
    $mobileArgs = @()
    if ($ReleaseNotes) { $mobileArgs += $ReleaseNotes }
    if ($SkipTests) { $mobileArgs += "-SkipTests" }
    if ($SkipFirebase) { $mobileArgs += "-SkipFirebase" }
    & "$ScriptDir\deploy-mobile.ps1" @mobileArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host ">>> MOBILE (Skipped: no changes) <<<" -ForegroundColor Gray
}

Write-Host ""

# 3. Deploy Wear OS
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
