Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

if ($args.Count -gt 0) {
    $first = [string]$args[0]
    if ($first.ToLowerInvariant() -in @("-h", "--help", "help")) {
        Write-Host "Usage: npm run ai:auto:chat -- [tool=auto|codex|claude|agent] [strategy=auto|sequential|parallel] [optional first message]" -ForegroundColor Yellow
        Write-Host "Examples:"
        Write-Host "  npm run ai:auto:chat"
        Write-Host "  npm run ai:auto:chat -- tool=auto"
        Write-Host "  npm run ai:auto:chat -- strategy=parallel `"plan and implementation step by step`""
        exit 0
    }
}

$autoScript = Join-Path $repoRoot "scripts\ai-auto.ps1"
$forwardArgs = @("mode=chat") + $args

& $autoScript @forwardArgs
exit $LASTEXITCODE
