# Load environment variables from repo-local .env files.
# This keeps secrets/config close to the project (e.g. on D:\) and avoids relying on C:\Users\...\* configs.
#
# Supported files (first wins on duplicates):
# - .env.local
# - .env
#
# Format:
#   KEY=value
#   export KEY=value
# Lines starting with # are ignored.

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

function Set-EnvVarFromLine {
    param([string]$Line)

    $trimmed = $Line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) { return }
    if ($trimmed.StartsWith("#")) { return }

    $m = [regex]::Match($trimmed, '^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$')
    if (-not $m.Success) { return }

    $key = $m.Groups[1].Value
    $value = $m.Groups[2].Value.Trim()

    # Strip surrounding quotes.
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    # Set for current process; do not echo secrets.
    Set-Item -Path ("Env:{0}" -f $key) -Value $value
}

$candidates = @(
    (Join-Path $ProjectRoot ".env.local"),
    (Join-Path $ProjectRoot ".env")
)

foreach ($path in $candidates) {
    if (-not (Test-Path $path)) { continue }
    try {
        $lines = Get-Content -Path $path -ErrorAction Stop
        foreach ($line in $lines) {
            Set-EnvVarFromLine -Line $line
        }
    } catch {
        Write-Warning "Failed to load env file: $path ($($_.Exception.Message))"
    }
}

