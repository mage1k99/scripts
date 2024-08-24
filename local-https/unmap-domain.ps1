Write-Output "This script will try to unmap the domain from Caddyfile and Hosts file."

Write-Output "This script assumes the following:"
Write-Output "1. caddy is installed and in path"
Write-Output "2. You are running as an administrator in windows"

# Check if the script is run as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script! Please re-run this script as an Administrator."
    exit
}

# Function to check if a port is valid
function IsValidPort {
    param (
        [int]$port
    )
    return ($port -ge 1 -and $port -le 65535)
}

$domain = Read-Host "Enter the domain"
$port = Read-Host "Enter the port"

# Validate the port
if (-not (IsValidPort -port $port)) {
    Write-Error "Invalid port number. Please enter a port number between 1 and 65535."
    exit
}

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$backupHostsPath = "$hostsPath.bak"
Copy-Item -Path $hostsPath -Destination $backupHostsPath -Force
Write-Output "Hosts file backed up to $backupHostsPath."

$hostsContent = Get-Content -Path $hostsPath
$newHostsContent = $hostsContent -notmatch "127.0.0.1 $domain"
Set-Content -Path $hostsPath -Value $newHostsContent
Write-Output "Hosts file updated."

# Remove the generated pem files
$certPath = "."
$certFiles = @("$domain.pem", "$domain-key.pem", "www.$domain.pem", "www.$domain-key.pem")
foreach ($certFile in $certFiles) {
    $certFilePath = Join-Path -Path $certPath -ChildPath $certFile
    if (Test-Path -Path $certFilePath) {
        Remove-Item -Path $certFilePath -Force
        Write-Output "Removed $certFilePath."
    }
}

Write-Output "Domain $domain removed."