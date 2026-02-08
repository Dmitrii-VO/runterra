Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$selectedTool = "auto"
$selectedStrategy = "auto"
$selectedMode = "orchestrate"
$printMode = $false
$promptTokens = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $args.Count; $i++) {
    $token = [string]$args[$i]
    switch ($token.ToLowerInvariant()) {
        "-print" { $printMode = $true; continue }
        "--print" { $printMode = $true; continue }
        "print" { $printMode = $true; continue }
        "-tool" {
            if ($i + 1 -ge $args.Count) { throw "Missing value for -tool" }
            $i++
            $selectedTool = [string]$args[$i]
            continue
        }
        "--tool" {
            if ($i + 1 -ge $args.Count) { throw "Missing value for --tool" }
            $i++
            $selectedTool = [string]$args[$i]
            continue
        }
        "-strategy" {
            if ($i + 1 -ge $args.Count) { throw "Missing value for -strategy" }
            $i++
            $selectedStrategy = [string]$args[$i]
            continue
        }
        "--strategy" {
            if ($i + 1 -ge $args.Count) { throw "Missing value for --strategy" }
            $i++
            $selectedStrategy = [string]$args[$i]
            continue
        }
        "-mode" {
            if ($i + 1 -ge $args.Count) { throw "Missing value for -mode" }
            $i++
            $selectedMode = [string]$args[$i]
            continue
        }
        "--mode" {
            if ($i + 1 -ge $args.Count) { throw "Missing value for --mode" }
            $i++
            $selectedMode = [string]$args[$i]
            continue
        }
        { $_ -like "tool=*" } {
            $selectedTool = $token.Substring(5)
            continue
        }
        { $_ -like "strategy=*" } {
            $selectedStrategy = $token.Substring(9)
            continue
        }
        { $_ -like "mode=*" } {
            $selectedMode = $token.Substring(5)
            continue
        }
        "--" {
            for ($j = $i + 1; $j -lt $args.Count; $j++) {
                [void]$promptTokens.Add([string]$args[$j])
            }
            $i = $args.Count
            continue
        }
        default {
            [void]$promptTokens.Add($token)
            continue
        }
    }
}

$selectedTool = $selectedTool.ToLowerInvariant()
$selectedStrategy = $selectedStrategy.ToLowerInvariant()
$selectedMode = $selectedMode.ToLowerInvariant()

if ($selectedTool -notin @("auto", "codex", "claude", "agent")) {
    throw "Invalid --tool. Allowed: auto, codex, claude, agent."
}

if ($selectedStrategy -notin @("auto", "sequential", "parallel")) {
    throw "Invalid --strategy. Allowed: auto, sequential, parallel."
}

if ($selectedMode -notin @("orchestrate", "single", "chat")) {
    throw "Invalid --mode. Allowed: orchestrate, single, chat."
}

$prompt = ($promptTokens -join " ").Trim()
if (($selectedMode -ne "chat") -and [string]::IsNullOrWhiteSpace($prompt)) {
    Write-Host "Usage: npm run ai:auto -- [print] [mode=orchestrate|single|chat] [tool=auto|codex|claude|agent] [strategy=auto|sequential|parallel] <your task>" -ForegroundColor Yellow
    exit 1
}

if ($selectedMode -eq "orchestrate") {
    $pythonExe = Join-Path $repoRoot "ai\.venv\Scripts\python.exe"
    $orchestratorScript = Join-Path $repoRoot "scripts\ai-langgraph-orchestrator.py"
    if ((Test-Path $pythonExe) -and (Test-Path $orchestratorScript)) {
        Write-Host "[ai:auto] mode=orchestrate tool=$selectedTool strategy=$selectedStrategy"
        & $pythonExe $orchestratorScript --tool $selectedTool --strategy $selectedStrategy $prompt
        if ($LASTEXITCODE -ne 0) {
            throw "LangGraph orchestrator failed (exit code $LASTEXITCODE). Use mode=single only if you explicitly want one-agent execution."
        }
        exit 0
    }
    throw "LangGraph runtime not found. Expected ai\\.venv\\Scripts\\python.exe and scripts\\ai-langgraph-orchestrator.py"
}

if ($selectedMode -eq "chat") {
    $pythonExe = Join-Path $repoRoot "ai\.venv\Scripts\python.exe"
    $orchestratorScript = Join-Path $repoRoot "scripts\ai-langgraph-orchestrator.py"
    if ((Test-Path $pythonExe) -and (Test-Path $orchestratorScript)) {
        Write-Host "[ai:auto] mode=chat tool=$selectedTool strategy=$selectedStrategy"
        $chatArgs = @($orchestratorScript, "--chat", "--tool", $selectedTool, "--strategy", $selectedStrategy)
        if (-not [string]::IsNullOrWhiteSpace($prompt)) {
            $chatArgs += @($prompt)
        }
        & $pythonExe @chatArgs
        exit $LASTEXITCODE
    }
    throw "LangGraph runtime not found. Expected ai\\.venv\\Scripts\\python.exe and scripts\\ai-langgraph-orchestrator.py"
}

function Get-KeywordScore {
    param(
        [string]$Text,
        [string[]]$Keywords
    )
    $score = 0
    foreach ($kw in $Keywords) {
        if ($Text.Contains($kw)) {
            $score++
        }
    }
    return $score
}

function Test-ToolAvailable {
    param([string]$ToolName)
    return $null -ne (Get-Command $ToolName -ErrorAction SilentlyContinue)
}

$lower = $prompt.ToLowerInvariant()

$codeKeywords = @(
    "bug", "error", "stack trace", "refactor", "compile", "build",
    "test", "typescript", "python", "flutter", "api", "endpoint",
    "database", "migration", "sql", "ci", "fix", "debug", "code",
    ".ts", ".tsx", ".py", ".dart", "npm", "pytest", "flutter test"
)

$analysisKeywords = @(
    "architecture", "tradeoff", "rfc", "adr", "plan", "design",
    "compare", "alternatives", "research", "evaluate",
    "pros and cons", "decision", "strategy", "roadmap"
)

$parallelKeywords = @(
    "parallel", "in parallel", "compare", "alternatives",
    "several", "multiple", "a/b", "independent subtasks"
)

$sequentialKeywords = @(
    "step by step", "sequential", "in order",
    "first", "then", "dependency", "dependent"
)

$codeScore = Get-KeywordScore -Text $lower -Keywords $codeKeywords
$analysisScore = Get-KeywordScore -Text $lower -Keywords $analysisKeywords
$parallelScore = Get-KeywordScore -Text $lower -Keywords $parallelKeywords
$sequentialScore = Get-KeywordScore -Text $lower -Keywords $sequentialKeywords

if ($selectedTool -eq "auto") {
    if ($lower.Contains("cursor") -or $lower.Contains("agent mode")) {
        $selectedTool = "agent"
    }
    elseif ($codeScore -ge ($analysisScore + 1)) {
        $selectedTool = "codex"
    }
    elseif ($analysisScore -ge ($codeScore + 1)) {
        $selectedTool = "claude"
    }
    else {
        $selectedTool = "codex"
    }
}

if (-not (Test-ToolAvailable -ToolName $selectedTool)) {
    foreach ($fallback in @("codex", "agent", "claude")) {
        if (Test-ToolAvailable -ToolName $fallback) {
            $selectedTool = $fallback
            break
        }
    }
}

if ($selectedStrategy -eq "auto") {
    if ($parallelScore -gt $sequentialScore) {
        $selectedStrategy = "parallel"
    }
    else {
        $selectedStrategy = "sequential"
    }
}

$selectedModel = ""
switch ($selectedTool) {
    "codex" {
        $selectedModel = "gpt-5.3-codex"
    }
    "claude" {
        if ($analysisScore -ge 3) {
            $selectedModel = "opus"
        }
        else {
            $selectedModel = "sonnet"
        }
    }
    "agent" {
        if ($codeScore -ge $analysisScore) {
            $selectedModel = "gpt-5.2"
        }
        else {
            $selectedModel = "sonnet-4.5-thinking"
        }
    }
}

$executionPolicyText = ""
if ($selectedStrategy -eq "parallel") {
    $executionPolicyText = @"
Execution policy:
1. Decompose into independent and dependent subtasks.
2. Execute independent subtasks in parallel whenever tools allow it.
3. Execute dependent subtasks sequentially.
4. Show a short plan first and label each step as [P] or [S].
5. End with concise results and concrete next actions.
"@
}
else {
    $executionPolicyText = @"
Execution policy:
1. Decompose into dependent subtasks.
2. Execute subtasks sequentially in dependency order.
3. If subtasks become independent, execute those in parallel.
4. Show a short plan first and label each step as [S] or [P].
5. End with concise results and concrete next actions.
"@
}

$finalPrompt = @"
$executionPolicyText

User task:
$prompt
"@

$launcher = Join-Path $repoRoot "scripts\ai-assistant.ps1"
$launchArgs = @($selectedTool)

switch ($selectedTool) {
    "codex" {
        $launchArgs += @("-m", $selectedModel)
        if ($printMode) {
            $launchArgs += @("exec", $finalPrompt)
        }
        else {
            $launchArgs += @($finalPrompt)
        }
    }
    "claude" {
        $launchArgs += @("--model", $selectedModel)
        if ($printMode) {
            $launchArgs += @("-p", $finalPrompt)
        }
        else {
            $launchArgs += @($finalPrompt)
        }
    }
    "agent" {
        $launchArgs += @("--model", $selectedModel)
        if ($printMode) {
            $launchArgs += @("--print", $finalPrompt)
        }
        else {
            $launchArgs += @($finalPrompt)
        }
    }
}

Write-Host "[ai:auto] tool=$selectedTool model=$selectedModel strategy=$selectedStrategy codeScore=$codeScore analysisScore=$analysisScore"

& $launcher @launchArgs
exit $LASTEXITCODE
