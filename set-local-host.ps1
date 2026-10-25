$ErrorActionPreference = 'Stop'
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$hostsText = [IO.File]::ReadAllText($hostsPath)
if ($hostsText -match '(?m)^\s*(?!#)\S+\s+(?:[^#\r\n]*\s)?searxng\.test(?:\s|$)') {
    if ($hostsText -notmatch '(?m)^\s*127\.0\.0\.1\s+searxng\.test\s*(?:#.*)?$') {
        throw 'An existing searxng.test entry needs manual review.'
    }
} else {
    $backupPath = "$hostsPath.searxng-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item -LiteralPath $hostsPath -Destination $backupPath
    [IO.File]::AppendAllText($hostsPath, "`r`n127.0.0.1 searxng.test # SearXNG local test`r`n", [Text.Encoding]::ASCII)
}
ipconfig /flushdns | Out-Null
