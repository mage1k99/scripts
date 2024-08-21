# Map domain with Local

This will be useful when testing out things with https enabled. This script will install a certificate for the requested domain.

## What does this does?

- Adds entry to hosts file to map the given domain with 127.0.0.1
- Uses `mkcert` to generate a self signed certificate for the given domain
- Edits the caddy file to map the domain with the given port and mentions to use the generated certificate.
- Optionally this script will ask if you want to generate one for www subdomain redirection to actual domain


## Requirements
- Caddy installed and available in path
- mkcert installed and available in path

## How to use

1. Cd to the directory where the script is located in a privileged shell/admin powershell
2. Run `./mapdomain-with-port.ps1`