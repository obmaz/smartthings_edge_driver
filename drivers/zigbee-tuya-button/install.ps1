#Requires -Version 5.1
#
# powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target dev
#
# install.ps1 -- Windows (PowerShell) port of install.sh.
#
# Packages, assigns, and installs the Edge driver, then tails its logs. Run
# from a shell where the SmartThings CLI (`smartthings`) is on PATH and you are
# logged in (`smartthings login`).
#
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target dev
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target prd

# DEV
# https://bestow-regional.api.smartthings.com/invite/BxlrxQ835YMP

# PRD
# https://bestow-regional.api.smartthings.com/invite/Q1jPbWZXad2L

param(
    [ValidateSet('dev', 'prd')]
    [string] $Target = 'prd'
)

$ErrorActionPreference = 'Stop'

# Run relative to this script so "." resolves no matter where it is invoked
# from.
Set-Location -Path $PSScriptRoot

$driverId   = '95b94182-0102-47ce-acef-553cbd8aa6d6'
$channels   = @{
    dev = '715733f3-8cac-451d-8164-a3ae65a4a7cd'
    prd = '699fefe6-7b99-40b2-acfd-662ed510a84d'
}
$channel    = $channels[$Target]
$hub        = 'b5434d2c-cd4e-4bde-a91b-d419ee72c55e'
$hubAddress = '192.168.10.189'

Write-Host "Deploy target: $Target"
Write-Host "Channel ID:    $channel"

# Run a smartthings command and abort the script if it fails (the `set -e`
# behavior for the deploy steps). Native non-zero exits do NOT throw on their
# own in PowerShell, so we check $LASTEXITCODE explicitly.
function Invoke-Required {
    param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $StArgs)
    & smartthings @StArgs
    if ($LASTEXITCODE -ne 0) {
        throw "smartthings $($StArgs -join ' ') failed (exit $LASTEXITCODE)"
    }
}

# Invoke-Required edge:drivers:uninstall $driverId --hub $hub
Invoke-Required edge:drivers:package . --channel $channel --hub $hub
Invoke-Required edge:channels:assign $driverId --channel $channel
Invoke-Required edge:drivers:install $driverId --channel $channel --hub $hub
& smartthings edge:drivers:logcat $driverId "--hub-address=$hubAddress"
