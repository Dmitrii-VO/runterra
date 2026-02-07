Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Test-ToolCommand {
    param(
        [string]$Name
    )
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        Write-Host "[FAIL] $Name is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
    Write-Host "[OK] $Name found: $($cmd.Source)" -ForegroundColor Green
    return $true
}

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )
    try {
        & $Action
        Write-Host "[OK] $Label" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FAIL] ${Label}: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

$allGood = $true

$allGood = (Test-ToolCommand "codex") -and $allGood
$allGood = (Test-ToolCommand "claude") -and $allGood
$allGood = (Test-ToolCommand "agent") -and $allGood

if (-not $allGood) {
    exit 1
}

$allGood = (Invoke-Step "codex login status" { codex login status | Out-Host }) -and $allGood
$allGood = (Invoke-Step "agent whoami" { agent whoami | Out-Host }) -and $allGood
$allGood = (Invoke-Step "claude smoke check" {
    # Use launcher to avoid failing on invalid global ANTHROPIC_API_KEY.
    & (Join-Path $repoRoot "scripts\\ai-assistant.ps1") claude -p "Reply exactly: CLAUDE_OK" | Out-Host
}) -and $allGood

if ($allGood) {
    Write-Host "All assistants are ready in this repo." -ForegroundColor Green
    exit 0
}

exit 1
