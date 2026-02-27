# Deploy Wear OS: build APK -> upload to Firebase App Distribution
# Usage: .\scripts\deploy-wear.ps1
#        .\scripts\deploy-wear.ps1 -Force          # skip change detection
#        .\scripts\deploy-wear.ps1 -SkipFirebase   # build only, no upload

param(
    [switch]$Force,
    [switch]$SkipFirebase
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\\load-env.ps1" -ProjectRoot $ProjectRoot

# Support env-var and positional overrides (same pattern as deploy-mobile.ps1)
if ($args -contains "-Force") { $Force = $true }
if ($args -contains "-SkipFirebase") { $SkipFirebase = $true }
if ($env:DEPLOY_SKIP_FIREBASE -eq "1") { $SkipFirebase = $true }

# Fix UTF-8 encoding for git output on Windows
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ConfigPath  = Join-Path $ProjectRoot "scripts\app-distribution.config.json"
$WearDir     = Join-Path $ProjectRoot "wear"
# Support both Groovy (build.gradle) and Kotlin DSL (build.gradle.kts)
$GradlePath  = if (Test-Path (Join-Path $WearDir "android\app\build.gradle.kts")) {
    Join-Path $WearDir "android\app\build.gradle.kts"
} else {
    Join-Path $WearDir "android\app\build.gradle"
}
$ApkPath     = Join-Path $WearDir "build\app\outputs\flutter-apk\app-debug.apk"

Set-Location $ProjectRoot

# --- Version from git tags (same logic as deploy-mobile.ps1) ---
function Get-VersionFromGit {
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $latestTag = git describe --tags --match "v*" --abbrev=0 2>$null
    $describeExitCode = $LASTEXITCODE
    if ($describeExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($latestTag)) {
        $version = "0.1.0"
        $commitCount = [int](git rev-list --count HEAD 2>$null)
        if ($LASTEXITCODE -ne 0) { $commitCount = 1 }
        $ErrorActionPreference = $prevPref
        return @{ Version = $version; BuildNumber = $commitCount; Tag = $null }
    }
    $version = $latestTag -replace "^v", ""
    $commitCount = [int](git rev-list --count "$latestTag..HEAD" 2>$null)
    if ($LASTEXITCODE -ne 0) { $commitCount = 0 }
    $ErrorActionPreference = $prevPref
    return @{ Version = $version; BuildNumber = $commitCount; Tag = $latestTag }
}

# --- Check for changes in wear/ since last tag ---
$versionInfo = Get-VersionFromGit
$buildName   = $versionInfo.Version
$buildNumber = $versionInfo.BuildNumber
$latestTag   = $versionInfo.Tag

if (-not $Force) {
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    if ($latestTag) {
        $wearChanges = git log "$latestTag..HEAD" --oneline -- wear/ 2>$null
    } else {
        # If no tags, check only the last 10 commits to avoid deploying ancient code
        $wearChanges = git log -n 10 --oneline -- wear/ 2>$null
    }
    $ErrorActionPreference = $prevPref

    if ([string]::IsNullOrWhiteSpace($wearChanges)) {
        $tagLabel = if ($latestTag) { $latestTag } else { "beginning" }
        Write-Host "No wear changes since $tagLabel, skipping." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "=== Version ===" -ForegroundColor Cyan
$tagDisplay = if ($latestTag) { $latestTag } else { "(none, using default 0.1.0)" }
Write-Host "  Tag:     $tagDisplay" -ForegroundColor White
Write-Host "  Version: $buildName+$buildNumber" -ForegroundColor White

# --- Verify wear/ is a Flutter project ---
if (-not (Test-Path $GradlePath)) {
    Write-Host ""
    Write-Host "ERROR: wear/ does not appear to be a Flutter project (missing android/app/build.gradle[.kts])." -ForegroundColor Red
    Write-Host ""
    Write-Host "To scaffold the Wear OS Flutter project:" -ForegroundColor Yellow
    Write-Host "  1. cd $ProjectRoot" -ForegroundColor White
    Write-Host "  2. flutter create --platforms android --org com.runterra wear" -ForegroundColor White
    Write-Host "  3. Adjust wear/android/app/build.gradle.kts: set applicationId to com.runterra.mobile" -ForegroundColor White
    Write-Host "  4. Commit wear/ and re-run deploy." -ForegroundColor White
    exit 1
}

# --- Read Firebase config (only when uploading) ---
if (-not $SkipFirebase) {
    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Config not found: $ConfigPath"
        exit 1
    }
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $wearAppId = $config.firebaseWearAppId
    $testers   = $config.testers -join ","

    if ([string]::IsNullOrWhiteSpace($wearAppId)) {
        Write-Host ""
        Write-Host "ERROR: firebaseWearAppId is not set in scripts/app-distribution.config.json." -ForegroundColor Red
        Write-Host ""
        Write-Host "To configure Firebase for Wear OS:" -ForegroundColor Yellow
        Write-Host "  1. Open Firebase Console -> your project -> Add app -> Android" -ForegroundColor White
        Write-Host "     Package name: com.runterra.mobile  (must match applicationId in wear/android/app/build.gradle)" -ForegroundColor White
        Write-Host "     Nickname: Runterra Wear OS" -ForegroundColor White
        Write-Host "  2. Copy the App ID from App Settings (format: 1:718457871498:android:XXXXXXXX)" -ForegroundColor White
        Write-Host "  3. Add to scripts/app-distribution.config.json:" -ForegroundColor White
        Write-Host '     "firebaseWearAppId": "1:718457871498:android:XXXXXXXX"' -ForegroundColor White
        exit 1
    }
}

# --- 1. pub get ---
Write-Host "`n=== 1. flutter pub get ===" -ForegroundColor Cyan
Set-Location $WearDir
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location $ProjectRoot

# --- 2. Build APK ---
Write-Host "`n=== 2. Build Wear APK ($buildName+$buildNumber) ===" -ForegroundColor Cyan
Set-Location $WearDir
flutter build apk --debug --build-name=$buildName --build-number=$buildNumber
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location $ProjectRoot

if (-not (Test-Path $ApkPath)) {
    Write-Error "APK not found after build: $ApkPath"
    exit 1
}

# --- 3. Firebase upload ---
if ($SkipFirebase) {
    Write-Host "`n=== 3. Upload to Firebase App Distribution ===" -ForegroundColor Cyan
    Write-Host "Skipped (-SkipFirebase). APK built: $ApkPath" -ForegroundColor Yellow
    Write-Host "`nDone. Firebase upload skipped." -ForegroundColor Green
} else {
    Write-Host "`n=== 3. Upload to Firebase App Distribution ===" -ForegroundColor Cyan
    Write-Host "APK size: $([math]::Round((Get-Item $ApkPath).Length / 1MB, 2)) MB" -ForegroundColor Gray

    do {
        $rawConfirm = Read-Host "Proceed with Firebase upload? (y/n)"
        if ($null -eq $rawConfirm) {
            Write-Host "No interactive input available. Proceeding with 'y'." -ForegroundColor Yellow
            $confirm = "y"
        } else {
            $confirm = $rawConfirm.Trim().ToLowerInvariant()
        }
        if ($confirm -notin @("y", "yes", "n", "no")) {
            Write-Host "Please enter 'y' or 'n'." -ForegroundColor Yellow
        }
    } while ($confirm -notin @("y", "yes", "n", "no"))

    if ($confirm -in @("n", "no")) {
        Write-Host "Upload canceled. APK built: $ApkPath" -ForegroundColor Yellow
        Write-Host "Done. Firebase upload skipped." -ForegroundColor Green
        exit 0
    }

    $firebaseArgs = @(
        "appdistribution:distribute",
        $ApkPath,
        "--app", $wearAppId,
        "--release-notes", "Wear OS $buildName+$buildNumber",
        "--testers", $testers
    )

    # Auth: prefer GOOGLE_APPLICATION_CREDENTIALS; fallback FIREBASE_TOKEN
    $useToken = $false
    $savedFirebaseToken = $null
    if (-not [string]::IsNullOrWhiteSpace($env:GOOGLE_APPLICATION_CREDENTIALS)) {
        $saPath = $env:GOOGLE_APPLICATION_CREDENTIALS
        if (Test-Path $saPath) {
            Write-Host "Using service account: $saPath" -ForegroundColor Gray
        } else {
            Write-Host "GOOGLE_APPLICATION_CREDENTIALS points to missing file: $saPath" -ForegroundColor Yellow
            $useToken = -not [string]::IsNullOrWhiteSpace($env:FIREBASE_TOKEN)
        }
    } else {
        $useToken = -not [string]::IsNullOrWhiteSpace($env:FIREBASE_TOKEN)
    }
    if ($useToken) {
        $firebaseArgs += @("--token", $env:FIREBASE_TOKEN)
    } else {
        $savedFirebaseToken = $env:FIREBASE_TOKEN
        $env:FIREBASE_TOKEN = $null
    }

    $firebaseOutput = @()
    try {
        firebase @firebaseArgs 2>&1 | Tee-Object -Variable firebaseOutput
    } finally {
        if (-not $useToken -and $null -ne $savedFirebaseToken) {
            $env:FIREBASE_TOKEN = $savedFirebaseToken
        }
    }

    $firebaseExit = $LASTEXITCODE
    if ($firebaseExit -ne 0) {
        $firebaseText = ($firebaseOutput | Out-String)
        $uploadedOk  = $firebaseText -match "(?im)^\+\s+uploaded new release .* successfully!\s*$"
        $notesFailed = $firebaseText -match "(?im)failed to update release notes"

        if ($uploadedOk -and $notesFailed) {
            Write-Host ""
            Write-Host "WARNING: Binary uploaded successfully, but release notes update failed." -ForegroundColor Yellow
            Write-Host "You can update release notes manually in the Firebase console." -ForegroundColor Yellow
        } else {
            exit $firebaseExit
        }
    }

    Write-Host "`nDone ($buildName+$buildNumber). Testers: $testers" -ForegroundColor Green
}
