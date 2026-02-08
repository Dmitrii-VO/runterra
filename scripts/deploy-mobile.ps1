# Deploy mobile: tests -> build APK -> upload to Firebase App Distribution -> notify testers
# Usage: .\scripts\deploy-mobile.ps1 [release-notes]
#        .\scripts\deploy-mobile.ps1 -SkipTests
#        .\scripts\deploy-mobile.ps1 "Fix login" -SkipTests

param(
    [string]$ReleaseNotes = "",
    [switch]$SkipTests,
    [switch]$SkipFirebase
)
# When invoked as "powershell -File script.ps1 -SkipFirebase", args may not bind; also support env (npm on Windows)
if ($args -contains "-SkipFirebase") { $SkipFirebase = $true }
if ($args -contains "-SkipTests") { $SkipTests = $true }
if ($env:DEPLOY_SKIP_FIREBASE -eq "1") { $SkipFirebase = $true }
$nonSwitchArgs = $args | Where-Object { $_ -notin @("-SkipFirebase", "-SkipTests") }
if ($nonSwitchArgs.Count -gt 0) { $ReleaseNotes = ($ReleaseNotes, $nonSwitchArgs) -join " " }

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ConfigPath = Join-Path $ProjectRoot "scripts\app-distribution.config.json"
$ApkPath = Join-Path $ProjectRoot "mobile\build\app\outputs\flutter-apk\app-debug.apk"

Set-Location $ProjectRoot

# 1. Read config (only needed when uploading to Firebase)
if (-not $SkipFirebase) {
    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Config not found: $ConfigPath. Create it with firebaseAppId and testers array."
        exit 1
    }
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $appId = $config.firebaseAppId
    $testers = $config.testers -join ","
}

if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
    $ReleaseNotes = "Release " + (Get-Date -Format "yyyy-MM-dd HH:mm")
}

Write-Host "=== 1. Tests ===" -ForegroundColor Cyan
if (-not $SkipTests) {
    Set-Location (Join-Path $ProjectRoot "mobile")
    flutter test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Set-Location $ProjectRoot
} else {
    Write-Host "Skipped (--SkipTests)" -ForegroundColor Yellow
}

Write-Host "`n=== 2. Build APK ===" -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "mobile")
flutter build apk --debug
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location $ProjectRoot

if (-not (Test-Path $ApkPath)) {
    Write-Error "APK not found: $ApkPath"
    exit 1
}

if ($SkipFirebase) {
    Write-Host "`n=== 3. Upload to Firebase App Distribution ===" -ForegroundColor Cyan
    Write-Host "Skipped (-SkipFirebase). APK built: $ApkPath" -ForegroundColor Yellow
    Write-Host "`nDone. Firebase upload skipped." -ForegroundColor Green
} else {
    Write-Host "`n=== 3. Upload to Firebase App Distribution ===" -ForegroundColor Cyan
    Write-Host "APK size: $([math]::Round((Get-Item $ApkPath).Length / 1MB, 2)) MB. Upload can take 5-15 min for large debug APK; progress may not show." -ForegroundColor Gray
    if ($env:FIREBASE_DEBUG) {
        Write-Host "FIREBASE_DEBUG is set - verbose Firebase CLI output enabled." -ForegroundColor Yellow
    }

    do {
        $rawConfirmUpload = Read-Host "Proceed with Firebase upload? (y/n)"
        if ($null -eq $rawConfirmUpload) {
            Write-Host "No interactive input available. Proceeding with 'y' in non-interactive mode." -ForegroundColor Yellow
            $confirmUpload = "y"
        } else {
            $confirmUpload = $rawConfirmUpload.Trim().ToLowerInvariant()
        }
        if ($confirmUpload -notin @("y", "yes", "n", "no")) {
            Write-Host "Please enter 'y' or 'n'." -ForegroundColor Yellow
        }
    } while ($confirmUpload -notin @("y", "yes", "n", "no"))

    if ($confirmUpload -in @("n", "no")) {
        Write-Host "Upload canceled by user. APK built: $ApkPath" -ForegroundColor Yellow
        Write-Host "Done. Firebase upload skipped." -ForegroundColor Green
        exit 0
    }

    firebase appdistribution:distribute $ApkPath `
        --app $appId `
        --release-notes $ReleaseNotes `
        --testers $testers

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "`nDone. Testers will receive an email: $testers" -ForegroundColor Green
}
