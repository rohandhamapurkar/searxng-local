$ErrorActionPreference = 'Stop'
$configDirectory = Join-Path $PSScriptRoot 'config'
$settingsPath = Join-Path $configDirectory 'settings.yml'
if (Test-Path -LiteralPath $settingsPath) {
    Write-Output 'Existing config/settings.yml preserved.'
    return
}
$secretBytes = New-Object byte[] 32
$generator = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $generator.GetBytes($secretBytes) } finally { $generator.Dispose() }
$secret = [BitConverter]::ToString($secretBytes).Replace('-', '').ToLowerInvariant()
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'settings.yml.example'))
New-Item -ItemType Directory -Force -Path $configDirectory | Out-Null
[IO.File]::WriteAllText($settingsPath, $template.Replace('REPLACE_WITH_RANDOM_SECRET', $secret), (New-Object Text.UTF8Encoding($false)))
Write-Output 'Created config/settings.yml with a random instance secret.'
