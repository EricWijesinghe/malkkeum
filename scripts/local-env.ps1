# Dot-source to load scripts/local.env (gitignored, see local.env.example) into this process.
# Same rules as scripts/env.sh: plain KEY=VALUE lines, no expansion, variables already set win.
$localEnv = Join-Path $PSScriptRoot 'local.env'
if (Test-Path -LiteralPath $localEnv) {
  foreach ($line in Get-Content -LiteralPath $localEnv) {
    if ($line -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { continue }
    $key = $Matches[1]; $value = $Matches[2].Trim('"')
    if (-not [Environment]::GetEnvironmentVariable($key)) { Set-Item -Path "env:$key" -Value $value }
  }
}
