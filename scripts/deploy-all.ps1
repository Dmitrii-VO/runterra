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

# 0. Git push + CI (always, regardless of which modules changed)
Write-Host ">>> GIT PUSH + CI <<<" -ForegroundColor Magenta
$allowUncommitted = $SkipGitCheck -or $SkipCI
$status = git status --porcelain
if ($status -and -not $allowUncommitted) {
    Write-Host "Uncommitted changes detected:" -ForegroundColor Yellow
    Write-Host $status
    Write-Host ""
    Write-Host "Commit your changes first, or they won't be deployed." -ForegroundColor Yellow
    exit 1
}
$ahead = git rev-list --count "@{u}..HEAD" 2>$null
if ($ahead -gt 0) {
    Write-Host "Pushing $ahead commit(s)..."
    git push
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if (-not $SkipCI) {
        Write-Host "`nWaiting for GitHub Actions CI to start..."
        Start-Sleep -Seconds 5
        $branch = git branch --show-current
        $runId = gh run list --branch $branch --limit 1 --json databaseId --jq ".[0].databaseId"
        if (-not $runId) {
            Write-Host "Could not find CI run for branch $branch" -ForegroundColor Red
            exit 1
        }
        Write-Host "Monitoring CI run $runId..."
        gh run watch $runId --exit-status
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nCI FAILED! Aborting deploy." -ForegroundColor Red
            exit 1
        }
        Write-Host "CI passed!" -ForegroundColor Green
    } else {
        Write-Host "Skipping CI check (-SkipCI)." -ForegroundColor Yellow
    }
} else {
    Write-Host "Already up to date with origin."

    if (-not $SkipCI) {
        $ciStatus = gh run list --workflow=ci.yml --limit=1 --json status,conclusion --jq ".[0].status"
        if ($ciStatus -eq "in_progress" -or $ciStatus -eq "queued") {
            Write-Host "CI is still running, waiting..." -ForegroundColor Yellow
            $runId = gh run list --workflow=ci.yml --limit=1 --json databaseId --jq ".[0].databaseId"
            gh run watch $runId --exit-status
            if ($LASTEXITCODE -ne 0) {
                Write-Host "`nCI FAILED! Aborting deploy." -ForegroundColor Red
                exit 1
            }
            Write-Host "CI passed!" -ForegroundColor Green
        } else {
            $ciConclusion = gh run list --workflow=ci.yml --limit=1 --json conclusion --jq ".[0].conclusion"
            if ($ciConclusion -ne "success") {
                Write-Host "Latest CI status: $ciConclusion - fix before deploying." -ForegroundColor Red
                exit 1
            }
            Write-Host "Latest CI passed." -ForegroundColor Green
        }
    }
}

Write-Host ""

# 1. Deploy backend (SSH only - push already done above)
if (-not $SkipBackend) {
    Write-Host ">>> BACKEND <<<" -ForegroundColor Magenta
    $backendArgs = @("-SkipPush")
    if ($SkipCI) { $backendArgs += "-SkipCI" }
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
