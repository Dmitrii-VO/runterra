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

# When invoked as "powershell -File script.ps1 -SkipCI", args may not bind; also support env vars (npm on Windows)
if ($args -contains "-SkipCI") { $SkipCI = $true }
if ($args -contains "-SkipFirebase") { $SkipFirebase = $true }
if ($args -contains "-SkipGitCheck") { $SkipGitCheck = $true }
if ($args -contains "-SkipTests") { $SkipTests = $true }
if ($env:DEPLOY_SKIP_CI -eq "1") { $SkipCI = $true; $SkipGitCheck = $true }
if ($env:DEPLOY_SKIP_FIREBASE -eq "1") { $SkipFirebase = $true }

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "        ALL DEPLOYED SUCCESSFULLY!     " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
