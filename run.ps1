# run.ps1 — Windows helper to run bash scripts via Git Bash
# Usage: .\run.ps1 <script> [args]
# Example: .\run.ps1 deploy
#          .\run.ps1 health-check BLUE
#          .\run.ps1 rollback
#          .\run.ps1 status

param(
    [Parameter(Mandatory)][string]$Script,
    [string[]]$Args
)

$env:MSYS_NO_PATHCONV = "1"

$bash = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $bash)) {
    Write-Error "Git Bash not found. Install Git for Windows: https://git-scm.com"
    exit 1
}

$scriptPath = "./scripts/$Script.sh"
if (-not (Test-Path $scriptPath)) {
    Write-Error "Script not found: $scriptPath"
    Write-Host "Available scripts: deploy, rollback, status, health-check, switch-traffic"
    exit 1
}

& $bash $scriptPath @Args

