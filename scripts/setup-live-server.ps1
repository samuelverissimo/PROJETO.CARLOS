<#
setup-live-server.ps1
Uso: abra PowerShell como Administrador na raiz do workspace e execute:
  .\scripts\setup-live-server.ps1

O script cria (se necessário) .vscode/settings.json com as configurações do Live Server,
adiciona uma regra de firewall para a porta 5500 e imprime endereços IP locais para compartilhar.
#>

# Require running from workspace root for path logic
$cwd = (Get-Location).Path
$vscodeDir = Join-Path $cwd '.vscode'
$settingsPath = Join-Path $vscodeDir 'settings.json'

if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null }

$settings = @{
    "liveServer.settings.useLocalIp" = $true
    "liveServer.settings.host" = "0.0.0.0"
    "liveServer.settings.port" = 5500
}

$json = $settings | ConvertTo-Json -Depth 4

# write or update settings.json
Set-Content -Path $settingsPath -Value $json -Encoding UTF8
Write-Host "Written: $settingsPath"

# Firewall rule
$ruleName = 'Allow Live Server 5500'
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort 5500 -Protocol TCP -Action Allow | Out-Null
    Write-Host "Firewall rule created: $ruleName"
} else {
    Write-Host "Firewall rule already exists: $ruleName"
}

# Get IPv4 addresses (exclude loopback and APIPA)
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*' } | Select-Object -ExpandProperty IPAddress -ErrorAction SilentlyContinue

if ($ips) {
    Write-Host "Local addresses you can share (if on same LAN):"
    foreach ($ip in $ips) { Write-Host "  http://$ip:5500" }
} else {
    Write-Host "No suitable IPv4 address found. If you're using Live Share, use the Shared Server proxy instead."
}

Write-Host ""
Write-Host "Next steps:" 
Write-Host "- Start Live Server in VS Code (restart if already running)."
Write-Host "- Start a Live Share session and in the Live Share pane -> 'Shared Servers' -> Add port 5500."
Write-Host "- Copy the 'Open in Browser' / 'Copy Link' from the shared server and send it to your partner."
Write-Host "- Alternatively, run: npx live-server --host=0.0.0.0 --port=5500 (requires Node.js)"
