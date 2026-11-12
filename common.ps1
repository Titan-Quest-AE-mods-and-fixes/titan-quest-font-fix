# Shared lookup for Titan Quest Anniversary Edition.
# The game itself is not part of this folder. Callers pass -Game, or the
# install is taken from the Steam library list.

function Find-TqGame([string]$Game) {
    if ($Game) {
        if (Test-Path (Join-Path $Game "Direct3D11.dll")) { return $Game }
        throw "Direct3D11.dll was not found in: $Game"
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    $steam = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    if ($steam) {
        $steam = $steam -replace '/', '\'
        $candidates.Add((Join-Path $steam "steamapps\common\Titan Quest Anniversary Edition"))
        $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            $text = Get-Content $vdf -Raw
            foreach ($m in [regex]::Matches($text, '"path"\s+"([^"]+)"')) {
                $root = $m.Groups[1].Value -replace '\\\\', '\'
                $candidates.Add((Join-Path $root "steamapps\common\Titan Quest Anniversary Edition"))
            }
        }
    }

    foreach ($path in $candidates) {
        if (Test-Path (Join-Path $path "Direct3D11.dll")) { return $path }
    }
    throw "Titan Quest Anniversary Edition was not found. Re-run with -Game `"D:\path\to\Titan Quest Anniversary Edition`"."
}
