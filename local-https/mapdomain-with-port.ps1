Write-Output "This script assumes the following:"
Write-Output "0. caddy is installed and in path"
Write-Output "1. mkcert is installed and in path"
Write-Output "2. You don't have anything mapped to :80 in Caddyfile"
Write-Output "3. You don't have anything mapped to :443 in Caddyfile"
Write-Output "4. It drops the certificate file in the current directory"
Write-Output "5. You have administrator rights"

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

# Prompt for domain and port
$domain = Read-Host "Enter the domain"
$port = Read-Host "Enter the port"

# Validate the port
if (-not (IsValidPort -port $port)) {
    Write-Error "Invalid port number. Please enter a port number between 1 and 65535."
    exit
}

# Prompt for name (optional)
$name = Read-Host "Enter a name for the entry (optional, default to empty string)"

# Edit the hosts file
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$hostsEntry = @"
# $name related
127.0.0.1 $domain
# end of section
"@

# Prompt for the path of the Caddyfile
$caddyfilePath = Read-Host "Enter the path to the Caddyfile (or press Enter to use default)"
if (-not $caddyfilePath) {
    $caddyfilePath = "$env:USERPROFILE\portableExecutables\Caddyfile"
}

# Check if the Caddyfile exists
if (-not (Test-Path -Path $caddyfilePath)) {
    Write-Error "Caddyfile not found at $caddyfilePath. Exiting."
    exit
}

# Prompt for www subdomain redirection
$addWwwRedirect = Read-Host "Do you want to add www subdomain redirection? (yes/no, default to no)"
$addWwwRedirect = if ($addWwwRedirect -eq "yes") { $true } else { $false }

# Check if mkcert is available
if (-not (Get-Command mkcert -ErrorAction SilentlyContinue)) {
    Write-Error "mkcert is not installed. Please install mkcert and try again."
    exit
}

# Check if mkcert -install has been run
if (-not (Test-Path "$env:LOCALAPPDATA\mkcert")) {
    Write-Output "Running mkcert -install..."
    mkcert -install
}

# Generate certificates
Write-Output "Generating certificate for $domain..."
mkcert $domain

if ($addWwwRedirect) {
    Write-Output "Generating certificate for www.$domain..."
    mkcert "www.$domain"
}

# Edit the Caddyfile
$caddyfileEntry = @"
$domain {
    tls $domain.pem $domain-key.pem
    reverse_proxy localhost:$port
}
"@

if ($addWwwRedirect) {
    $caddyfileEntry += @"
www.$domain {
    redir https://$domain{uri} permanent
}
"@
    Write-Output "Added www.$domain to Caddyfile."
    $hostsEntry += @"
# $name related
127.0.0.1 www.$domain
# end of section
"@
        Write-Output "Adding www.$domain to Hosts file..."
}

Add-Content -Path $hostsPath -Value $hostsEntry
Write-Output "Hosts file updated."

Add-Content -Path $caddyfilePath -Value $caddyfileEntry
Write-Output "Caddyfile updated."

# Run caddy fmt
Write-Output "Running caddy fmt..."
caddy fmt --overwrite $caddyfilePath

Write-Output "Run the following command with admin privileges to start the Caddy server:"
Write-Output "caddy run --config $caddyfilePath"
