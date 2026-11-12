# Titan Quest Anniversary Edition 2.10.21415
# Direct3D11.dll — keep UI text after the font atlas fills up.
#
# Two edits, both checked against Direct3D11.original.dll so a second run
# does not stack on itself:
#   1. Default atlas 1024x1024 becomes 2048x2048.
#   2. A glyph that still falls outside the atlas no longer requests a wipe
#      of every glyph already drawn.
#
# This script does not contain the game. It edits a Direct3D11.dll that is
# already installed, and keeps the untouched file as Direct3D11.original.dll
# beside it. That backup stays on the player's machine.
param(
    [string]$Game
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$Game = Find-TqGame $Game
$Dll = Join-Path $Game "Direct3D11.dll"
$Backup = Join-Path $Game "Direct3D11.original.dll"
$ExpectedLength = 583680

# File offsets for image base 0x10000000, .text raw 0x400 / RVA 0x1000.
$AtlasOff = 0x64599
$WipeOff = 0x631FE
$AtlasOriginal = [byte[]](0xBE, 0x00, 0x04, 0x00, 0x00)
$AtlasPatched = [byte[]](0xBE, 0x00, 0x08, 0x00, 0x00)
$WipeOriginal = [byte[]](0xC6, 0x86, 0x90, 0x00, 0x00, 0x00, 0x01)
$WipePatched = [byte[]](0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90)

function Test-Bytes([byte[]]$data, [int]$offset, [byte[]]$expect) {
    for ($i = 0; $i -lt $expect.Length; $i++) {
        if ($data[$offset + $i] -ne $expect[$i]) { return $false }
    }
    return $true
}

if (Get-Process TQ -ErrorAction SilentlyContinue) {
    throw "Close Titan Quest before patching Direct3D11.dll."
}

if (-not (Test-Path $Backup)) {
    $current = [IO.File]::ReadAllBytes($Dll)
    if ($current.Length -ne $ExpectedLength) {
        throw "Direct3D11.dll size is $($current.Length), expected $ExpectedLength for build 2.10.21415."
    }
    if (-not (Test-Bytes $current $AtlasOff $AtlasOriginal) -or -not (Test-Bytes $current $WipeOff $WipeOriginal)) {
        throw "Direct3D11.dll does not match build 2.10.21415 at the patch sites, and no original backup exists."
    }
    Copy-Item $Dll $Backup
}

$bytes = [IO.File]::ReadAllBytes($Backup)
if ($bytes.Length -ne $ExpectedLength) {
    throw "Backup size is $($bytes.Length), expected $ExpectedLength."
}
if (-not (Test-Bytes $bytes $AtlasOff $AtlasOriginal)) {
    throw "Backup atlas bytes at 0x$($AtlasOff.ToString('X')) are not the 2.10.21415 original."
}
if (-not (Test-Bytes $bytes $WipeOff $WipeOriginal)) {
    throw "Backup wipe bytes at 0x$($WipeOff.ToString('X')) are not the 2.10.21415 original."
}

[Array]::Copy($AtlasPatched, 0, $bytes, $AtlasOff, $AtlasPatched.Length)
[Array]::Copy($WipePatched, 0, $bytes, $WipeOff, $WipePatched.Length)
[IO.File]::WriteAllBytes($Dll, $bytes)

"Patched $Dll"
"  atlas 1024 -> 2048 at file 0x$($AtlasOff.ToString('X')) (RVA 0x65199)"
"  atlas wipe disabled at file 0x$($WipeOff.ToString('X')) (RVA 0x63DFE)"
"Original kept as Direct3D11.original.dll next to the game. It is not part of this repository."
