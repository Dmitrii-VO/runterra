# Deploy mobile release to RuStore: tests -> build release APK/AAB -> create draft -> upload -> submit for moderation
# Usage: .\scripts\deploy-rustore.ps1 [release-notes]
#        .\scripts\deploy-rustore.ps1 -SkipTests
#        .\scripts\deploy-rustore.ps1 "Fix login" -ArtifactType apk
#        .\scripts\deploy-rustore.ps1 -ArtifactType aab -SkipCommit

param(
    [string]$ReleaseNotes = "",
    [switch]$SkipTests,
    [ValidateSet("apk", "aab")]
    [string]$ArtifactType = "apk",
    [switch]$SkipCommit,
    [switch]$SkipTag
)

if ($PSVersionTable.PSEdition -ne "Core") {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
    if (-not $pwsh) {
        throw "deploy-rustore.ps1 requires PowerShell 7+ (pwsh). Install pwsh or run the script with pwsh."
    }

    $forwardArgs = @()
    if ($PSBoundParameters.ContainsKey("ReleaseNotes") -and -not [string]::IsNullOrWhiteSpace($ReleaseNotes)) { $forwardArgs += $ReleaseNotes }
    if ($SkipTests) { $forwardArgs += "-SkipTests" }
    if ($ArtifactType -ne "apk") { $forwardArgs += @("-ArtifactType", $ArtifactType) }
    if ($SkipCommit) { $forwardArgs += "-SkipCommit" }
    if ($SkipTag) { $forwardArgs += "-SkipTag" }

    & $pwsh -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @forwardArgs
    exit $LASTEXITCODE
}

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\\load-env.ps1" -ProjectRoot $ProjectRoot

# Support npm/PowerShell invocation quirks and env-based toggles.
if ($args -contains "-SkipTests") { $SkipTests = $true }
if ($args -contains "-SkipCommit") { $SkipCommit = $true }
if ($args -contains "-SkipTag") { $SkipTag = $true }
if ($env:RUSTORE_SKIP_TESTS -eq "1") { $SkipTests = $true }
if ($env:RUSTORE_SKIP_COMMIT -eq "1") { $SkipCommit = $true }
if ($env:RUSTORE_SKIP_TAG -eq "1") { $SkipTag = $true }
if ($env:RUSTORE_ARTIFACT_TYPE -in @("apk", "aab")) { $ArtifactType = $env:RUSTORE_ARTIFACT_TYPE }
$nonSwitchArgs = $args | Where-Object { $_ -notin @("-SkipTests", "-SkipCommit", "-SkipTag", "-ArtifactType", "apk", "aab") }
if ($nonSwitchArgs.Count -gt 0) { $ReleaseNotes = ($ReleaseNotes, $nonSwitchArgs) -join " " }

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$RuStoreBaseUrl = "https://public-api.rustore.ru/public/v1"
$PublicToken = $env:RUSTORE_PUBLIC_TOKEN
$RuStoreKeyId = $env:RUSTORE_KEY_ID
$RuStorePrivateKey = $env:RUSTORE_PRIVATE_KEY
$PackageName = if ([string]::IsNullOrWhiteSpace($env:RUSTORE_PACKAGE_NAME)) { "com.runterra.runterra" } else { $env:RUSTORE_PACKAGE_NAME.Trim() }
$AppType = if ([string]::IsNullOrWhiteSpace($env:RUSTORE_APP_TYPE)) { "MAIN" } else { $env:RUSTORE_APP_TYPE.Trim() }
$PublishType = if ([string]::IsNullOrWhiteSpace($env:RUSTORE_PUBLISH_TYPE)) { "MANUAL" } else { $env:RUSTORE_PUBLISH_TYPE.Trim() }
$PublishDateTime = $env:RUSTORE_PUBLISH_DATE_TIME
$ModerInfo = $env:RUSTORE_MODER_INFO
$PriorityUpdate = if ([string]::IsNullOrWhiteSpace($env:RUSTORE_PRIORITY_UPDATE)) { "0" } else { $env:RUSTORE_PRIORITY_UPDATE.Trim() }
$MinAndroidVersion = if ([string]::IsNullOrWhiteSpace($env:RUSTORE_MIN_ANDROID_VERSION)) { 8 } else { [int]$env:RUSTORE_MIN_ANDROID_VERSION }
$AndroidKeystorePath = $env:ANDROID_KEYSTORE_PATH
$AndroidKeystorePassword = $env:ANDROID_KEYSTORE_PASSWORD
$AndroidKeyAlias = $env:ANDROID_KEY_ALIAS
$AndroidKeyPassword = $env:ANDROID_KEY_PASSWORD

$ReleaseApkPath = Join-Path $ProjectRoot "mobile\build\app\outputs\flutter-apk\app-release.apk"
$ReleaseAabPath = Join-Path $ProjectRoot "mobile\build\app\outputs\bundle\release\app-release.aab"

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
        return @{ Version = $version; BuildNumber = [Math]::Max($commitCount, 1); Tag = $null }
    }
    $version = $latestTag -replace "^v", ""
    $commitCount = [int](git rev-list --count HEAD 2>$null)
    if ($LASTEXITCODE -ne 0) { $commitCount = 1 }
    $ErrorActionPreference = $prevPref
    return @{ Version = $version; BuildNumber = [Math]::Max($commitCount, 1); Tag = $latestTag }
}

function Get-NextVersion {
    param([string]$Current)
    $parts = $Current -split '\.'
    while ($parts.Count -lt 3) { $parts += "0" }
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2] + 1
    return "$major.$minor.$patch"
}

function Get-ReleaseNotesFromGit {
    param([string]$SinceTag)

    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    if ($SinceTag) {
        $commits = git log "$SinceTag..HEAD" --pretty=format:"%s" 2>$null
    } else {
        $commits = git log --pretty=format:"%s" -10 2>$null
    }
    $ErrorActionPreference = $prevPref
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commits)) {
        return "Release " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    }

    $lines = $commits -split "`n" | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { return $null }
        if ($line -match "^(Merge |Deploy:|Update deploy|ремонт скрипта|langgraph|CI |fix ci)") { return $null }
        $line = $line -replace "^(feat|fix|chore|refactor|docs|style|test|perf|ci|build|revert)(\([^)]*\))?:\s*", ""
        $line = $line -replace "\b(GET|POST|PUT|PATCH|DELETE)\s+/[^\s,;]*", ""
        $line = $line -replace "\b\w+Repository\.\w+", ""
        $line = $line -replace "\b\w+\.(routes|dto|entity|config)\.\w+", ""
        $line = $line -replace "Backend:\s*", ""
        $line = $line -replace "Mobile:\s*", ""
        $line = $line -replace "^[\s,;]+", ""
        $line = $line -replace "[\s,;]+$", ""
        if ([string]::IsNullOrWhiteSpace($line)) { return $null }
        return "- " + $line.Substring(0,1).ToUpper() + $line.Substring(1)
    } | Where-Object { $_ -ne $null }

    if ($lines.Count -eq 0) {
        return "Release " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    }
    return $lines -join "`n"
}

function Normalize-ReleaseNotes {
    param(
        [string]$Notes,
        [int]$MaxLen = 5000
    )

    if ([string]::IsNullOrWhiteSpace($Notes)) { return $Notes }
    $text = ($Notes -replace "`r`n", "`n").Trim()
    if ($text.Length -le $MaxLen) { return $text }
    return ($text.Substring(0, $MaxLen - 20) + "`n- ... (truncated)")
}

function ConvertTo-RuStoreBody {
    param($Body)
    return ($Body | ConvertTo-Json -Depth 10 -Compress)
}

function Get-RuStoreErrorMessage {
    param([System.Exception]$Exception)

    if ($Exception.Data -and $Exception.Data.Contains("RuStoreMessage")) {
        return [string]$Exception.Data["RuStoreMessage"]
    }

    if ($Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($Exception.Response.GetResponseStream())
            $responseText = $reader.ReadToEnd()
            if (-not [string]::IsNullOrWhiteSpace($responseText)) {
                try {
                    $json = $responseText | ConvertFrom-Json
                    if ($json.message) { return $json.message }
                    return $responseText
                } catch {
                    return $responseText
                }
            }
        } catch {
        }
    }
    return $Exception.Message
}

function Get-HttpStatusCodeFromException {
    param([System.Exception]$Exception)

    if ($Exception.Response -and $Exception.Response.StatusCode) {
        return [int]$Exception.Response.StatusCode
    }
    return $null
}

function Invoke-RuStoreJson {
    param(
        [ValidateSet("GET", "POST", "DELETE")]
        [string]$Method,
        [string]$Path,
        $Body = $null
    )

    $headers = @{
        "Public-Token" = $PublicToken
        "Accept" = "application/json"
    }

    $params = @{
        Method = $Method
        Uri = "$RuStoreBaseUrl$Path"
        Headers = $headers
        ContentType = "application/json; charset=utf-8"
    }

    if ($null -ne $Body) {
        $params.Body = (ConvertTo-RuStoreBody -Body $Body)
    }

    try {
        return Invoke-RestMethod @params
    } catch {
        $message = Get-RuStoreErrorMessage -Exception $_.Exception
        $_.Exception.Data["RuStoreMessage"] = "RuStore API $Method $Path failed: $message"
        throw $_.Exception
    }
}

function Invoke-RuStoreDiagnostics {
    param([string]$PackageName)

    Write-Host "" 
    Write-Host "=== RuStore access diagnostics ===" -ForegroundColor Yellow

    $checks = @(
        @{ Name = "App access list"; Path = "/application/$PackageName/developer?pageSize=20" },
        @{ Name = "Version list"; Path = "/application/$PackageName/version?page=0&size=1" }
    )

    foreach ($check in $checks) {
        try {
            $null = Invoke-RuStoreJson -Method "GET" -Path $check.Path
            Write-Host "  OK: $($check.Name)" -ForegroundColor Green
        } catch {
            $statusCode = Get-HttpStatusCodeFromException -Exception $_.Exception
            $message = Get-RuStoreErrorMessage -Exception $_.Exception
            if ($statusCode) {
                Write-Host "  FAIL: $($check.Name) -> HTTP ${statusCode}: $message" -ForegroundColor Red
            } else {
                Write-Host "  FAIL: $($check.Name) -> $message" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "Interpretation:" -ForegroundColor Yellow
    Write-Host "  - If 'App access list' is 403/404, the key likely has no access to package $PackageName." -ForegroundColor Yellow
    Write-Host "  - If access list is OK but create-draft is 403, the key likely lacks release-management permissions." -ForegroundColor Yellow
}

function Invoke-RuStoreUpload {
    param(
        [string]$Path,
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        throw "Artifact not found: $FilePath"
    }

    $curlArgs = @(
        "--silent",
        "--show-error",
        "--fail-with-body",
        "--request", "POST",
        "--header", "Public-Token: $PublicToken",
        "--header", "Accept: application/json",
        "--form", "file=@$FilePath",
        "$RuStoreBaseUrl$Path"
    )

    $raw = & curl.exe @curlArgs
    if ($LASTEXITCODE -ne 0) {
        throw "RuStore upload failed for $FilePath"
    }
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try {
        return $raw | ConvertFrom-Json
    } catch {
        return $raw
    }
}

function Get-RuStoreTimestamp {
    $now = [DateTimeOffset]::UtcNow
    return $now.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")
}

function Get-PrivateKeyBytes {
    param([string]$PrivateKeyValue)

    if ([string]::IsNullOrWhiteSpace($PrivateKeyValue)) {
        throw "RUSTORE_PRIVATE_KEY is empty."
    }

    $normalized = $PrivateKeyValue.Trim()
    $normalized = $normalized -replace "\\r\\n", "`n"
    $normalized = $normalized -replace "\\n", "`n"
    $normalized = $normalized -replace "\\r", "`r"

    if ($normalized -match "-----BEGIN (?:RSA )?PRIVATE KEY-----") {
        $base64Body = $normalized `
            -replace "-----BEGIN (?:RSA )?PRIVATE KEY-----", "" `
            -replace "-----END (?:RSA )?PRIVATE KEY-----", "" `
            -replace "\s", ""
        if ([string]::IsNullOrWhiteSpace($base64Body)) {
            throw "RUSTORE_PRIVATE_KEY PEM body is empty."
        }
        try {
            return [Convert]::FromBase64String($base64Body)
        } catch {
            throw "RUSTORE_PRIVATE_KEY PEM body is not valid Base64."
        }
    }

    $base64Value = ($normalized -replace "\s", "")
    try {
        return [Convert]::FromBase64String($base64Value)
    } catch {
        throw "RUSTORE_PRIVATE_KEY is neither valid Base64 nor PEM."
    }
}

function New-RsaFromPrivateKey {
    param(
        [byte[]]$PrivateKeyBytes,
        [string]$PrivateKeyText = ""
    )

    $rsa = [System.Security.Cryptography.RSA]::Create()
    $bytesRead = 0

    if (-not [string]::IsNullOrWhiteSpace($PrivateKeyText) -and $PrivateKeyText -match "-----BEGIN (?:RSA )?PRIVATE KEY-----") {
        try {
            $rsa.ImportFromPem($PrivateKeyText)
            return $rsa
        } catch {
        }
    }

    try {
        $null = $rsa.ImportPkcs8PrivateKey($PrivateKeyBytes, [ref]$bytesRead)
        return $rsa
    } catch {
    }

    try {
        $null = $rsa.ImportRSAPrivateKey($PrivateKeyBytes, [ref]$bytesRead)
        return $rsa
    } catch {
        $rsa.Dispose()
        throw "Unsupported private key format. Expected PEM, PKCS8, or PKCS1 RSA private key."
    }
}

function Get-RuStorePublicToken {
    if (-not [string]::IsNullOrWhiteSpace($PublicToken)) {
        return $PublicToken
    }

    if ([string]::IsNullOrWhiteSpace($RuStoreKeyId) -or [string]::IsNullOrWhiteSpace($RuStorePrivateKey)) {
        throw "Provide either RUSTORE_PUBLIC_TOKEN or both RUSTORE_KEY_ID and RUSTORE_PRIVATE_KEY."
    }

    $normalizedPrivateKeyText = $RuStorePrivateKey.Trim()
    $normalizedPrivateKeyText = $normalizedPrivateKeyText -replace "\\r\\n", "`n"
    $normalizedPrivateKeyText = $normalizedPrivateKeyText -replace "\\n", "`n"
    $normalizedPrivateKeyText = $normalizedPrivateKeyText -replace "\\r", "`r"
    $privateKeyBytes = Get-PrivateKeyBytes -PrivateKeyValue $RuStorePrivateKey

    $timestamp = Get-RuStoreTimestamp
    $message = [System.Text.Encoding]::UTF8.GetBytes("$RuStoreKeyId$timestamp")

    $rsa = $null
    try {
        $rsa = New-RsaFromPrivateKey -PrivateKeyBytes $privateKeyBytes -PrivateKeyText $normalizedPrivateKeyText
        $signatureBytes = $rsa.SignData(
            $message,
            [System.Security.Cryptography.HashAlgorithmName]::SHA512,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        )
        $signature = [Convert]::ToBase64String($signatureBytes)
    } catch {
        throw "Failed to parse/sign with RUSTORE_PRIVATE_KEY. $_"
    } finally {
        if ($rsa) { $rsa.Dispose() }
    }

    try {
        $authResponse = Invoke-RestMethod -Method POST `
            -Uri "https://public-api.rustore.ru/public/auth" `
            -ContentType "application/json; charset=utf-8" `
            -Body (@{
                keyId = $RuStoreKeyId
                timestamp = $timestamp
                signature = $signature
            } | ConvertTo-Json -Compress)
    } catch {
        $message = Get-RuStoreErrorMessage -Exception $_.Exception
        throw "RuStore auth failed: $message"
    }

    $jwe = $authResponse.body.jwe
    if ([string]::IsNullOrWhiteSpace($jwe)) {
        throw "RuStore auth succeeded but JWE token is missing in response."
    }

    return $jwe
}

function Get-AndroidSigningConfig {
    $keyPropsPath = Join-Path $ProjectRoot "mobile\android\key.properties"
    $props = @{
        StoreFile = $AndroidKeystorePath
        StorePassword = $AndroidKeystorePassword
        KeyAlias = $AndroidKeyAlias
        KeyPassword = $AndroidKeyPassword
        Source = "env"
    }

    if (Test-Path $keyPropsPath) {
        $props.Source = $keyPropsPath
        $lines = Get-Content $keyPropsPath
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) { continue }
            $parts = $trimmed -split "=", 2
            if ($parts.Count -ne 2) { continue }
            $name = $parts[0].Trim()
            $value = $parts[1].Trim()
            switch ($name) {
                "storeFile" { $props.StoreFile = $value }
                "storePassword" { $props.StorePassword = $value }
                "keyAlias" { $props.KeyAlias = $value }
                "keyPassword" { $props.KeyPassword = $value }
            }
        }
    }

    return $props
}

function Test-AndroidSigningConfig {
    param($Signing)

    $missing = @()
    if ([string]::IsNullOrWhiteSpace($Signing.StoreFile)) { $missing += "storeFile / ANDROID_KEYSTORE_PATH" }
    if ([string]::IsNullOrWhiteSpace($Signing.StorePassword)) { $missing += "storePassword / ANDROID_KEYSTORE_PASSWORD" }
    if ([string]::IsNullOrWhiteSpace($Signing.KeyAlias)) { $missing += "keyAlias / ANDROID_KEY_ALIAS" }
    if ([string]::IsNullOrWhiteSpace($Signing.KeyPassword)) { $missing += "keyPassword / ANDROID_KEY_PASSWORD" }
    if ($missing.Count -gt 0) {
        throw "Android release signing is incomplete. Missing: $($missing -join ", ")."
    }

    $resolvedStoreFile = $Signing.StoreFile
    if (-not [System.IO.Path]::IsPathRooted($resolvedStoreFile)) {
        $resolvedStoreFile = Join-Path (Join-Path $ProjectRoot "mobile\android") $resolvedStoreFile
    }
    $resolvedStoreFile = [System.IO.Path]::GetFullPath($resolvedStoreFile)

    if (-not (Test-Path $resolvedStoreFile)) {
        throw "Android keystore file not found: $resolvedStoreFile"
    }

    $keytoolPath = (Get-Command keytool -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
    if (-not $keytoolPath) {
        throw "keytool is not available in PATH. Install a JDK or add keytool to PATH."
    }

    $keytoolOutput = & $keytoolPath -list -v -keystore $resolvedStoreFile -storepass $Signing.StorePassword -alias $Signing.KeyAlias -keypass $Signing.KeyPassword 2>&1
    if ($LASTEXITCODE -ne 0) {
        $message = ($keytoolOutput | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($message)) { $message = "keytool validation failed." }
        throw "Android keystore validation failed: $message"
    }

    return @{
        StoreFile = $resolvedStoreFile
        StorePassword = $Signing.StorePassword
        KeyAlias = $Signing.KeyAlias
        KeyPassword = $Signing.KeyPassword
        Source = $Signing.Source
        KeytoolPath = $keytoolPath
    }
}

$PublicToken = Get-RuStorePublicToken

if ($PublishType -notin @("MANUAL", "INSTANTLY", "DELAYED")) {
    throw "RUSTORE_PUBLISH_TYPE must be one of: MANUAL, INSTANTLY, DELAYED."
}

if ($PublishType -eq "DELAYED" -and [string]::IsNullOrWhiteSpace($PublishDateTime)) {
    throw "RUSTORE_PUBLISH_DATE_TIME is required when RUSTORE_PUBLISH_TYPE=DELAYED."
}

if ($PriorityUpdate -notmatch "^[0-5]$") {
    throw "RUSTORE_PRIORITY_UPDATE must be an integer from 0 to 5."
}

$buildGradlePath = Join-Path $ProjectRoot "mobile\android\app\build.gradle"
if (Test-Path $buildGradlePath) {
    $buildGradleText = Get-Content $buildGradlePath -Raw
    if ($buildGradleText -match '(?s)buildTypes\s*\{.*?release\s*\{.*?signingConfig\s+signingConfigs\.debug') {
        Write-Warning "mobile/android/app/build.gradle currently signs release builds with signingConfigs.debug. RuStore upload may only work if the app in RuStore already uses the same signature."
    }
}

$versionInfo = Get-VersionFromGit
$nextVersion = Get-NextVersion -Current $versionInfo.Version
$newTag = "v$nextVersion"
$buildName = $nextVersion
$buildNumber = $versionInfo.BuildNumber
$androidSigning = Test-AndroidSigningConfig -Signing (Get-AndroidSigningConfig)

Write-Host "=== RuStore deploy ===" -ForegroundColor Magenta
Write-Host "  Package:      $PackageName" -ForegroundColor White
Write-Host "  Artifact:     $ArtifactType" -ForegroundColor White
Write-Host "  Publish type: $PublishType" -ForegroundColor White
Write-Host "  Version:      $buildName+$buildNumber" -ForegroundColor White
Write-Host "  Auth:         $(if ($env:RUSTORE_PUBLIC_TOKEN) { 'static token' } else { 'keyId/privateKey -> JWE' })" -ForegroundColor White

if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
    $ReleaseNotes = Get-ReleaseNotesFromGit -SinceTag $versionInfo.Tag
    Write-Host "`n=== Release notes (auto-generated) ===" -ForegroundColor Cyan
    Write-Host $ReleaseNotes -ForegroundColor White
} else {
    Write-Host "`n=== Release notes (manual) ===" -ForegroundColor Cyan
    Write-Host $ReleaseNotes -ForegroundColor White
}

$ReleaseNotes = Normalize-ReleaseNotes -Notes $ReleaseNotes -MaxLen 5000

Write-Host "  Signing:      $($androidSigning.StoreFile)" -ForegroundColor White
Write-Host "  Key alias:    $($androidSigning.KeyAlias)" -ForegroundColor White

Write-Host "`n=== 1. Tests ===" -ForegroundColor Cyan
if (-not $SkipTests) {
    Set-Location (Join-Path $ProjectRoot "mobile")
    flutter test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Set-Location $ProjectRoot
} else {
    Write-Host "Skipped (--SkipTests)" -ForegroundColor Yellow
}

Write-Host "`n=== 2. Build release artifact ===" -ForegroundColor Cyan
Set-Location (Join-Path $ProjectRoot "mobile")
if ($ArtifactType -eq "aab") {
    flutter build appbundle --release --build-name=$buildName --build-number=$buildNumber
} else {
    flutter build apk --release --build-name=$buildName --build-number=$buildNumber
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location $ProjectRoot

$artifactPath = if ($ArtifactType -eq "aab") { $ReleaseAabPath } else { $ReleaseApkPath }
if (-not (Test-Path $artifactPath)) {
    throw "Release artifact not found: $artifactPath"
}

Write-Host "`n=== 3. Create RuStore draft ===" -ForegroundColor Cyan
$draftBody = @{
    appType = $AppType
    publishType = $PublishType
    whatsNew = $ReleaseNotes
    minAndroidVersion = $MinAndroidVersion
}
if (-not [string]::IsNullOrWhiteSpace($ModerInfo)) {
    $draftBody.moderInfo = $ModerInfo
}
if ($PublishType -eq "DELAYED") {
    $draftBody.publishDateTime = $PublishDateTime
}

$draftResponse = $null
try {
    $draftResponse = Invoke-RuStoreJson -Method "POST" -Path "/application/$PackageName/version" -Body $draftBody
} catch {
    $statusCode = Get-HttpStatusCodeFromException -Exception $_.Exception
    if ($statusCode -eq 403) {
        Invoke-RuStoreDiagnostics -PackageName $PackageName
    }
    throw
}
$versionId = $draftResponse.body
if (-not $versionId -and $draftResponse.content.versionId) {
    $versionId = $draftResponse.content.versionId
}
if (-not $versionId) {
    throw "RuStore draft created but versionId is missing in response."
}
Write-Host "Draft versionId: $versionId" -ForegroundColor Green

Write-Host "`n=== 4. Upload artifact ===" -ForegroundColor Cyan
if ($ArtifactType -eq "aab") {
    $uploadResponse = Invoke-RuStoreUpload -Path "/application/$PackageName/version/$versionId/aab" -FilePath $artifactPath
} else {
    $uploadResponse = Invoke-RuStoreUpload -Path "/application/$PackageName/version/$versionId/apk?servicesType=Unknown&isMainApk=true" -FilePath $artifactPath
}
if ($uploadResponse -and $uploadResponse.code -and $uploadResponse.code -ne "OK") {
    throw "RuStore upload failed: $($uploadResponse.message)"
}
Write-Host "Uploaded: $artifactPath" -ForegroundColor Green

if ($SkipCommit) {
    Write-Host "`n=== 5. Submit for moderation ===" -ForegroundColor Cyan
    Write-Host "Skipped (--SkipCommit). Draft remains in RuStore with versionId=$versionId." -ForegroundColor Yellow
} else {
    Write-Host "`n=== 5. Submit for moderation ===" -ForegroundColor Cyan
    $commitResponse = Invoke-RuStoreJson -Method "POST" -Path "/application/$PackageName/version/$versionId/commit?priorityUpdate=$PriorityUpdate"
    if ($commitResponse.code -and $commitResponse.code -ne "OK") {
        throw "RuStore moderation submit failed: $($commitResponse.message)"
    }
    Write-Host "Version $versionId submitted for moderation." -ForegroundColor Green
}

if (-not $SkipTag) {
    $existingTag = git tag --list $newTag
    if ([string]::IsNullOrWhiteSpace($existingTag)) {
        git tag $newTag
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Created local git tag: $newTag" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Failed to create local git tag $newTag." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Tag already exists: $newTag" -ForegroundColor Yellow
    }
}

Write-Host "`nDone. RuStore artifact uploaded: $artifactPath" -ForegroundColor Green
if (-not $SkipCommit) {
    Write-Host "RuStore draft $versionId is now under moderation." -ForegroundColor Green
}
