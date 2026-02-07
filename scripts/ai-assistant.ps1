if ($args.Count -lt 1) {
    Write-Host "Usage: ai-assistant.ps1 <codex|claude|agent> [tool args...]" -ForegroundColor Yellow
    exit 1
}

$Tool = "$($args[0])".ToLowerInvariant()
$ArgsForTool = @()
if ($args.Count -gt 1) {
    $ArgsForTool = $args[1..($args.Count - 1)]
}

if ($Tool -notin @("codex", "claude", "agent")) {
    Write-Host "Unknown tool '$Tool'. Expected: codex, claude, agent." -ForegroundColor Red
    exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Invoke-ClaudeSafely {
    param([string[]]$InnerArgs)

    # If ANTHROPIC_API_KEY is invalid in the current shell, Claude CLI fails.
    # Temporarily remove it so local Claude auth can be used.
    $savedAnthropicKey = $env:ANTHROPIC_API_KEY
    $hadAnthropicKey = -not [string]::IsNullOrEmpty($savedAnthropicKey)
    if ($hadAnthropicKey) {
        Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
    }

    try {
        & claude @InnerArgs
        exit $LASTEXITCODE
    }
    finally {
        if ($hadAnthropicKey) {
            $env:ANTHROPIC_API_KEY = $savedAnthropicKey
        }
    }
}

switch ($Tool) {
    "codex" {
        & codex @ArgsForTool
        exit $LASTEXITCODE
    }
    "agent" {
        & agent @ArgsForTool
        exit $LASTEXITCODE
    }
    "claude" {
        Invoke-ClaudeSafely -InnerArgs $ArgsForTool
    }
}
