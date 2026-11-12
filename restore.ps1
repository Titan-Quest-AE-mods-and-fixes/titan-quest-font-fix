# Restores Direct3D11.dll from Direct3D11.original.dll beside the game.
# The backup is created by apply.ps1 on the player's machine. It is not in this repository.
param(
    [string]$Game
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$Game = Find-TqGame $Game
$Dll = Join-Path $Game "Direct3D11.dll"
$Backup = Join-Path $Game "Direct3D11.original.dll"
if (Get-Process TQ -ErrorAction SilentlyContinue) {
    throw "Close Titan Quest before restoring Direct3D11.dll."
}
if (-not (Test-Path $Backup)) { throw "Backup not found: $Backup" }
Copy-Item $Backup $Dll -Force
"Restored $Dll from Direct3D11.original.dll"
