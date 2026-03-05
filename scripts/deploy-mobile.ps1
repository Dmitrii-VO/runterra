# Deploy mobile: tests -> build APK -> upload to Firebase App Distribution -> notify testers
# Usage: .\scripts\deploy-mobile.ps1 [release-notes]
#        .\scripts\deploy-mobile.ps1 -SkipTests
#        .\scripts\deploy-mobile.ps1 "Fix login" -SkipTests
#
# Version is auto-computed from the latest v* git tag + commit count since it.
# Release notes are auto-generated from git commits since the last tag.

param(
    [string]$ReleaseNotes = "",
    [switch]$SkipTests,
    [switch]$SkipFirebase
)

# Load repo-local .env files early (before reading $env:DEPLOY_* toggles).
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\\load-env.ps1" -ProjectRoot $ProjectRoot

# When invoked as "powershell -File script.ps1 -SkipFirebase", args may not bind; also support env (npm on Windows)
if ($args -contains "-SkipFirebase") { $SkipFirebase = $true }
if ($args -contains "-SkipTests") { $SkipTests = $true }
if ($env:DEPLOY_SKIP_FIREBASE -eq "1") { $SkipFirebase = $true }
$nonSwitchArgs = $args | Where-Object { $_ -notin @("-SkipFirebase", "-SkipTests") }
if ($nonSwitchArgs.Count -gt 0) { $ReleaseNotes = ($ReleaseNotes, $nonSwitchArgs) -join " " }

# Fix UTF-8 encoding for git output on Windows
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ConfigPath = Join-Path $ProjectRoot "scripts\app-distribution.config.json"
$ApkPath = Join-Path $ProjectRoot "mobile\build\app\outputs\flutter-apk\app-debug.apk"

Set-Location $ProjectRoot

# --- Version from git tags ---
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

# --- Clean release notes from git log ---
function Get-ReleaseNotesFromGit {
    param([string]$SinceTag)

    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    if ($SinceTag) {
        $commits = git log "$SinceTag..HEAD" --pretty=format:"%s" 2>$null
    } else {
        # No tag — take only the last 10 commits
        $commits = git log --pretty=format:"%s" -10 2>$null
    }
    $ErrorActionPreference = $prevPref
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commits)) {
        return "Release " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    }

    $lines = $commits -split "`n" | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { return $null }
        # Skip infrastructure/CI/deploy-only commits
        if ($line -match "^(Merge |Deploy:|Update deploy|ремонт скрипта|langgraph|CI |fix ci)") { return $null }
        # Skip lines with mojibake (double-encoded UTF-8: abnormally many capital Р/С chars)
        $mojibakeCount = ($line.ToCharArray() | Where-Object { $_ -eq [char]0x0420 -or $_ -eq [char]0x0421 }).Count
        if ($mojibakeCount -gt 4) { return $null }
        # Strip conventional commit prefixes: feat(scope):, fix:, chore:, etc.
        $line = $line -replace "^(feat|fix|chore|refactor|docs|style|test|perf|ci|build|revert)(\([^)]*\))?:\s*", ""
        # Strip technical artifacts: HTTP methods + paths, file paths, class/method names
        $line = $line -replace "\b(GET|POST|PUT|PATCH|DELETE)\s+/[^\s,;]*", ""
        $line = $line -replace "\b\w+Repository\.\w+", ""
        $line = $line -replace "\b\w+\.(routes|dto|entity|config)\.\w+", ""
        $line = $line -replace "Backend:\s*", ""
        $line = $line -replace "Mobile:\s*", ""
        # Strip leftover commas/semicolons at start/end
        $line = $line -replace "^[\s,;]+", ""
        $line = $line -replace "[\s,;]+$", ""
        if ([string]::IsNullOrWhiteSpace($line)) { return $null }
        # Capitalize first letter
        $line = $line.Substring(0,1).ToUpper() + $line.Substring(1)
        return "- $line"
    } | Where-Object { $_ -ne $null }

    if ($lines.Count -eq 0) {
        return "Release " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    }
    return $lines -join "`n"
}

# App Distribution release notes have a size limit; keep a conservative cap
# so deploy doesn't fail after a successful binary upload.
function Normalize-ReleaseNotes {
    param([string]$Notes)

    if ([string]::IsNullOrWhiteSpace($Notes)) { return $Notes }

    # Normalize line endings and trim.
    $text = ($Notes -replace "`r`n", "`n").Trim()

    # Keep a safe margin under typical API limits.
    $maxLen = 4000
    if ($text.Length -le $maxLen) { return $text }

    return ($text.Substring(0, $maxLen - 20) + "`n- ... (truncated)")
}

# --- Auto-bump patch version and create git tag ---
function Get-NextVersion {
    param([string]$Current)
    $parts = $Current -split '\.'
    while ($parts.Count -lt 3) { $parts += "0" }
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2] + 1
    return "$major.$minor.$patch"
}

$versionInfo = Get-VersionFromGit
$nextVersion = Get-NextVersion -Current $versionInfo.Version
$newTag = "v$nextVersion"

Write-Host "=== Version ===" -ForegroundColor Cyan
Write-Host "  Previous:     $($versionInfo.Version)" -ForegroundColor Gray
Write-Host "  Next:         $nextVersion  (tag: $newTag)" -ForegroundColor White

git tag $newTag 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  WARNING: Could not create tag $newTag (already exists?). Using existing." -ForegroundColor Yellow
}

$buildName = $nextVersion
$buildNumber = 1
Write-Host "  Build:        $buildName+$buildNumber" -ForegroundColor White

if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
    $ReleaseNotes = Get-ReleaseNotesFromGit -SinceTag $versionInfo.Tag
    Write-Host "`n=== Release notes (auto-generated) ===" -ForegroundColor Cyan
    Write-Host $ReleaseNotes -ForegroundColor White
    Write-Host ""

    $editChoice = Read-Host "Accept release notes? (y = accept, e = edit, c = cancel)"
    if ($null -eq $editChoice) { $editChoice = "y" }
    $editChoice = $editChoice.Trim().ToLowerInvariant()

    if ($editChoice -eq "c") {
        Write-Host "Deploy canceled." -ForegroundColor Yellow
        exit 0
    }
    if ($editChoice -eq "e") {
        Write-Host "Enter release notes (end with empty line):" -ForegroundColor Yellow
        $customLines = @()
        while ($true) {
            $inputLine = Read-Host
            if ([string]::IsNullOrWhiteSpace($inputLine)) { break }
            $customLines += $inputLine
        }
        if ($customLines.Count -gt 0) {
            $ReleaseNotes = $customLines -join "`n"
        }
        Write-Host "Updated release notes:" -ForegroundColor Cyan
        Write-Host $ReleaseNotes -ForegroundColor White
    }
} else {
    Write-Host "`n=== Release notes (manual) ===" -ForegroundColor Cyan
    Write-Host $ReleaseNotes -ForegroundColor White
}

$ReleaseNotes = Normalize-ReleaseNotes -Notes $ReleaseNotes

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

Write-Host "`n=== 1. Tests ===" -ForegroundColor Cyan
if (-not $SkipTests) {
    Set-Location (Join-Path $ProjectRoot "mobile")
    flutter test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Set-Location $ProjectRoot
} else {
    Write-Host "Skipped (--SkipTests)" -ForegroundColor Yellow
}

Write-Host "`n=== 2. Build APK ($buildName+$buildNumber) ===" -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "mobile")
flutter build apk --debug --build-name=$buildName --build-number=$buildNumber
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

    $firebaseArgs = @(
        "appdistribution:distribute",
        $ApkPath,
        "--app", $appId,
        "--release-notes", $ReleaseNotes,
        "--testers", $testers
    )

    # Auth: prefer GOOGLE_APPLICATION_CREDENTIALS (service account JSON path) to avoid deprecation warning.
    # Fallback: FIREBASE_TOKEN from `firebase login:ci` (deprecated in future firebase-tools).
    # Do NOT print tokens.
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
        # Firebase CLI auto-reads FIREBASE_TOKEN from env; clear it so it uses GOOGLE_APPLICATION_CREDENTIALS only.
        $savedFirebaseToken = $env:FIREBASE_TOKEN
        $env:FIREBASE_TOKEN = $null
    }

    # Capture output to detect "upload succeeded, release notes failed" and not fail the whole deploy.
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
        $uploadedOk = $firebaseText -match "(?im)^\\+\\s+uploaded new release .* successfully!\\s*$"
        $notesFailed = $firebaseText -match "(?im)failed to update release notes"

        if ($uploadedOk -and $notesFailed) {
            Write-Host "" 
            Write-Host "WARNING: Release binary was uploaded successfully, but updating release notes failed." -ForegroundColor Yellow
            Write-Host "You can update release notes manually in the Firebase console for this release." -ForegroundColor Yellow
        } else {
            exit $firebaseExit
        }
    }

    Write-Host "`nDone ($buildName+$buildNumber). Testers will receive an email: $testers" -ForegroundColor Green

    # Auto-sync APP_VERSION on server so existing users see the update dialog.
    Write-Host "`n=== 4. Sync APP_VERSION on server ($buildName) ===" -ForegroundColor Cyan
    try {
        ssh runterra "sed -i 's/^APP_VERSION=.*/APP_VERSION=$buildName/' /home/user1/runterra/backend/.env && sudo systemctl restart runterra-backend"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  APP_VERSION=$buildName set on server and backend restarted." -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Failed to update APP_VERSION on server. Update manually: APP_VERSION=$buildName" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  WARNING: SSH failed. Update manually: APP_VERSION=$buildName" -ForegroundColor Yellow
    }
}
