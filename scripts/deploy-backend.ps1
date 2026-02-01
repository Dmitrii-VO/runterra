# Deploy backend: push to git -> SSH to server -> run update.sh
# Usage: .\scripts\deploy-backend.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SSHHost = "runterra"
$RemoteScript = "~/runterra/backend/update.sh"

Set-Location $ProjectRoot

Write-Host "=== 1. Check git status ===" -ForegroundColor Cyan
$status = git status --porcelain
if ($status) {
    Write-Host "Uncommitted changes detected:" -ForegroundColor Yellow
    Write-Host $status
    Write-Host ""
    Write-Host "Commit your changes first, or they won't be deployed." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== 2. Push to origin ===" -ForegroundColor Cyan
$ahead = git rev-list --count "@{u}..HEAD" 2>$null
if ($ahead -gt 0) {
    Write-Host "Pushing $ahead commit(s)..."
    git push
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "Already up to date with origin."
}

Write-Host "`n=== 3. SSH: update backend on server ===" -ForegroundColor Cyan
Write-Host "Running: ssh $SSHHost `"$RemoteScript`""
ssh $SSHHost $RemoteScript
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nBackend deployed successfully!" -ForegroundColor Green
