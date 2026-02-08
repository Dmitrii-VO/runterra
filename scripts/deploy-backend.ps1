# Deploy backend: push to git -> SSH to server -> run update.sh
# Usage: .\scripts\deploy-backend.ps1
#        .\scripts\deploy-backend.ps1 -SkipCI

param(
    [switch]$SkipCI,
    [switch]$SkipGitCheck
)
if ($args -contains "-SkipCI") { $SkipCI = $true }
if ($args -contains "-SkipGitCheck") { $SkipGitCheck = $true }
if ($env:DEPLOY_SKIP_CI -eq "1") { $SkipCI = $true; $SkipGitCheck = $true }

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SSHHost = "runterra"
$RemoteScript = "~/runterra/backend/update.sh"

Set-Location $ProjectRoot

Write-Host "=== 1. Check git status ===" -ForegroundColor Cyan
$status = git status --porcelain
$allowUncommitted = $SkipGitCheck -or $SkipCI
if ($status) {
    if ($allowUncommitted) {
        Write-Host "Uncommitted changes detected (skipped for local deploy):" -ForegroundColor Yellow
        Write-Host $status
    } else {
        Write-Host "Uncommitted changes detected:" -ForegroundColor Yellow
        Write-Host $status
        Write-Host ""
        Write-Host "Commit your changes first, or they won't be deployed." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "=== 2. Push to origin ===" -ForegroundColor Cyan
$ahead = git rev-list --count "@{u}..HEAD" 2>$null
if ($ahead -gt 0) {
    Write-Host "Pushing $ahead commit(s)..."
    git push
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    
    if (-not $SkipCI) {
        Write-Host "`n=== 2.1. Waiting for GitHub Actions CI ===" -ForegroundColor Cyan
        Write-Host "Waiting for CI workflow to start..."
        Start-Sleep -Seconds 5
        
        # Get the latest run ID for the current branch
        $branch = git branch --show-current
        $runId = gh run list --branch $branch --limit 1 --json databaseId --jq ".[0].databaseId"
        
        if (-not $runId) {
            Write-Host "Could not find CI run for branch $branch" -ForegroundColor Red
            exit 1
        }
        
        # Wait for CI workflow and check result
        Write-Host "Monitoring CI run $runId (this may take a few minutes)..."
        gh run watch $runId --exit-status
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nCI FAILED! Aborting deploy." -ForegroundColor Red
            Write-Host "Check the errors: gh run view --web" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "CI passed!" -ForegroundColor Green
    } else {
        Write-Host "Skipping CI check (-SkipCI)." -ForegroundColor Yellow
    }
} else {
    Write-Host "Already up to date with origin."
    
    if (-not $SkipCI) {
        # Check that the latest CI passed (wait if still running)
        Write-Host "Checking latest CI status..."
        $ciStatus = gh run list --workflow=ci.yml --limit=1 --json status,conclusion --jq ".[0].status"
        
        if ($ciStatus -eq "in_progress" -or $ciStatus -eq "queued") {
            Write-Host "CI is still running, waiting for completion..." -ForegroundColor Yellow
            $runId = gh run list --workflow=ci.yml --limit=1 --json databaseId --jq ".[0].databaseId"
            gh run watch $runId --exit-status
            if ($LASTEXITCODE -ne 0) {
                Write-Host "`nCI FAILED! Aborting deploy." -ForegroundColor Red
                Write-Host "Check the errors: gh run view --web" -ForegroundColor Yellow
                exit 1
            }
            Write-Host "CI passed!" -ForegroundColor Green
        } else {
            $ciConclusion = gh run list --workflow=ci.yml --limit=1 --json conclusion --jq ".[0].conclusion"
            if ($ciConclusion -ne "success") {
                Write-Host "Latest CI status: $ciConclusion" -ForegroundColor Red
                Write-Host "CI must pass before deploying. Fix the issues first." -ForegroundColor Yellow
                exit 1
            }
            Write-Host "Latest CI passed." -ForegroundColor Green
        }
    } else {
        Write-Host "Skipping CI check (-SkipCI)." -ForegroundColor Yellow
    }
}

Write-Host "`n=== 3. SSH: update backend on server ===" -ForegroundColor Cyan
Write-Host "Running: ssh $SSHHost `"$RemoteScript`""
ssh $SSHHost $RemoteScript
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nBackend deployed successfully!" -ForegroundColor Green
