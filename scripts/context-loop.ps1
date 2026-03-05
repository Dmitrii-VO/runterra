param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("start", "plan", "checkpoint", "restore", "done", "prune")]
    [string]$Action,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$InputArgs
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$planPath = Join-Path $projectRoot "PLAN.md"
$todoPath = Join-Path $projectRoot "TODO.md"
$decisionsPath = Join-Path $projectRoot "DECISIONS.md"
$evidencePath = Join-Path $projectRoot "EVIDENCE.md"
$restorePath = Join-Path $projectRoot "RESTORE.md"
$archiveRoot = Join-Path $projectRoot ".tmp/context-loop"

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

function Read-FileOrDefault {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Default = ""
    )
    if (Test-Path $Path) {
        return Get-Content -Path $Path -Raw -Encoding UTF8
    }
    return $Default
}

function Get-SectionText {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Heading
    )
    if (-not (Test-Path $Path)) {
        return ""
    }

    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    $escaped = [Regex]::Escape($Heading)
    $pattern = "(?ms)^##\s+$escaped\s*\r?\n(.*?)(?=^\s*##\s+|\z)"
    $match = [Regex]::Match($content, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return ""
}

function Get-LastNonEmptyLines {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Count = 8
    )
    if (-not (Test-Path $Path)) {
        return @()
    }
    return (Get-Content -Path $Path -Encoding UTF8 |
        Where-Object { $_.Trim().Length -gt 0 } |
        Select-Object -Last $Count)
}

function Ensure-ContextFiles {
    if (-not (Test-Path $planPath)) {
        Write-Utf8File -Path $planPath -Content @"
# No active session

Run npm run ctx:start -- "<task>" to begin.
"@
    }
    if (-not (Test-Path $todoPath)) {
        Write-Utf8File -Path $todoPath -Content "# Session TODO`n"
    }
    if (-not (Test-Path $decisionsPath)) {
        Write-Utf8File -Path $decisionsPath -Content "# Decisions`n"
    }
    if (-not (Test-Path $evidencePath)) {
        Write-Utf8File -Path $evidencePath -Content "# Evidence`n"
    }
}

function New-RestorePacket {
    Ensure-ContextFiles

    $task = Get-SectionText -Path $planPath -Heading "Task"
    if ([string]::IsNullOrWhiteSpace($task)) {
        $task = "No active task"
    }

    $stage = Get-SectionText -Path $planPath -Heading "Current Stage"
    if ([string]::IsNullOrWhiteSpace($stage)) {
        $stage = "not set"
    }

    $nextAction = Get-SectionText -Path $planPath -Heading "Next Action"
    if ([string]::IsNullOrWhiteSpace($nextAction)) {
        $nextAction = "not set"
    }

    $openTodo = @()
    if (Test-Path $todoPath) {
        $openTodo = Get-Content -Path $todoPath -Encoding UTF8 |
            Where-Object { $_ -match "^- \[ \]" } |
            Select-Object -First 8
    }

    $recentDecisions = Get-LastNonEmptyLines -Path $decisionsPath -Count 8
    $recentEvidence = Get-LastNonEmptyLines -Path $evidencePath -Count 8

    $openTodoText = if ($openTodo.Count -gt 0) { $openTodo -join "`n" } else { "- none" }
    $decisionsText = if ($recentDecisions.Count -gt 0) { $recentDecisions -join "`n" } else { "- none" }
    $evidenceText = if ($recentEvidence.Count -gt 0) { $recentEvidence -join "`n" } else { "- none" }

    $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"

    $packet = @"
# Restore Packet

Generated: $generatedAt

## Task
$task

## Current Stage
$stage

## Open TODO (top 8)
$openTodoText

## Recent Decisions
$decisionsText

## Recent Evidence
$evidenceText

## Next Action
$nextAction

## Recovery Checklist
1. Read PLAN.md, TODO.md, DECISIONS.md, EVIDENCE.md.
2. Continue from Next Action.
3. If context is still noisy, run /clear and then npm run ctx:restore.
"@

    Write-Utf8File -Path $restorePath -Content $packet
}

switch ($Action) {
    "start" {
        $force = $InputArgs -contains "--force"
        $taskArgs = $InputArgs | Where-Object { $_ -ne "--force" }
        $task = ($taskArgs -join " ").Trim()
        if ([string]::IsNullOrWhiteSpace($task)) {
            $task = "Task description is missing"
        }

        if ((Test-Path $planPath) -and -not $force) {
            $existingPlan = Get-Content -Path $planPath -Raw -Encoding UTF8
            if ($existingPlan -notmatch "No active session") {
                Write-Error "Active session already exists. Use npm run ctx:done first or re-run with --force."
                exit 1
            }
        }

        $startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"

        Write-Utf8File -Path $planPath -Content @"
# Active Session Plan

## Task
$task

## Scope
- Define the minimal affected area before implementation.

## Constraints
- Keep changes minimal and verifiable.
- Prefer JIT file reading and avoid bulk exploration.

## Current Stage
1) Gather context

## Next Action
Open up to 5 relevant files (~200 lines each), capture findings in EVIDENCE.md.
"@

        Write-Utf8File -Path $todoPath -Content @"
# Session TODO

- [ ] Capture baseline and affected files
- [ ] Implement changes in small validated steps
- [ ] Run verification commands and store key evidence
- [ ] Update docs/progress.md if behavior changed
"@

        Write-Utf8File -Path $decisionsPath -Content @"
# Decisions

- [$startedAt] Session started: $task
"@

        Write-Utf8File -Path $evidencePath -Content @"
# Evidence

- [$startedAt] Session initialized.
"@

        New-RestorePacket
        Write-Output "Context loop started."
        Write-Output "Files initialized: PLAN.md, TODO.md, DECISIONS.md, EVIDENCE.md, RESTORE.md"
    }
    "plan" {
        Ensure-ContextFiles
        $task = Get-SectionText -Path $planPath -Heading "Task"
        if ([string]::IsNullOrWhiteSpace($task)) {
            $task = "No active task"
        }

        $todoLines = if (Test-Path $todoPath) { Get-Content -Path $todoPath -Encoding UTF8 } else { @() }
        $totalTodo = ($todoLines | Where-Object { $_ -match "^- \[( |x)\]" }).Count
        $doneTodo = ($todoLines | Where-Object { $_ -match "^- \[x\]" }).Count
        $openTodo = ($todoLines | Where-Object { $_ -match "^- \[ \]" }).Count
        $nextAction = Get-SectionText -Path $planPath -Heading "Next Action"
        if ([string]::IsNullOrWhiteSpace($nextAction)) {
            $nextAction = "not set"
        }

        Write-Output "Task: $task"
        Write-Output "TODO: done $doneTodo / total $totalTodo (open $openTodo)"
        Write-Output "Next action: $nextAction"
    }
    "checkpoint" {
        New-RestorePacket
        Write-Output "Restore packet refreshed: RESTORE.md"
    }
    "restore" {
        New-RestorePacket
        Get-Content -Path $restorePath -Encoding UTF8
    }
    "prune" {
        Ensure-ContextFiles

        if (Test-Path $evidencePath) {
            $evidenceLines = Get-Content -Path $evidencePath -Encoding UTF8
            $header = @("# Evidence", "")
            $signals = $evidenceLines | Where-Object { $_ -match "^- " }
            $trimmed = $signals | Select-Object -Last 120
            $newEvidence = @($header + $trimmed) -join "`n"
            Write-Utf8File -Path $evidencePath -Content $newEvidence
        }

        if (Test-Path $todoPath) {
            $todoLines = Get-Content -Path $todoPath -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
            Write-Utf8File -Path $todoPath -Content ($todoLines -join "`n")
        }

        New-RestorePacket
        Write-Output "Context pruned (EVIDENCE/TODO) and restore packet updated."
    }
    "done" {
        Ensure-ContextFiles
        if (-not (Test-Path $archiveRoot)) {
            New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
        }

        $archiveDir = Join-Path $archiveRoot ("session-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

        foreach ($file in @($planPath, $todoPath, $decisionsPath, $evidencePath, $restorePath)) {
            if (Test-Path $file) {
                Copy-Item -Path $file -Destination $archiveDir -Force
            }
        }

        Write-Utf8File -Path $planPath -Content @"
# No active session

Run npm run ctx:start -- "<task>" to begin.
"@

        Write-Utf8File -Path $todoPath -Content "# Session TODO`n`nNo active session."
        Write-Utf8File -Path $decisionsPath -Content "# Decisions`n`nNo active session."
        Write-Utf8File -Path $evidencePath -Content "# Evidence`n`nNo active session."
        Write-Utf8File -Path $restorePath -Content "# Restore Packet`n`nNo active session."

        Write-Output "Session archived to: $archiveDir"
        Write-Output "Context loop closed."
    }
}
