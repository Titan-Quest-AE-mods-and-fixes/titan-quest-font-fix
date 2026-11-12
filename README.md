# Missing UI text after a portal — Direct3D11.dll patch

Unofficial bugfix notes. Titan Quest Anniversary Edition is a game by THQ Nordic and is not included here.

Build: **2.10.21415**, file `Direct3D11.dll` (583,680 bytes), which the player already has installed.
Close the game before applying. This patch changes only that file. `Engine.dll` is left alone.

## What breaks

All interface text is drawn from one glyph atlas. With no font override (`systemfont` empty, and `g_pcFontOverride` unset) that atlas is **1024×1024**. Cyrillic (`Fonts/Arial_Russian.fnt`, `Fonts/Times_EE.fnt`) at `ScaleUI = high` and 4K fills it after a handful of zone changes. Each portal adds new location names.

When the next glyph does not fit, the packer compares the cursor with the atlas width and height (RVA `0x6396C` and `0x63978`) and jumps to RVA `0x63DFE`:

```
C6 86 90 00 00 00 01     mov byte [esi+0x90], 1
```

The flag at `+0x90` means "wipe the atlas". The next glyph upload drops the list of characters already drawn and, while the flag is set, calls RVA `0x63E50`, which fills the texture with zeros and uploads it to the GPU. The flag is then cleared. Nothing repacks the old glyphs. From that moment every label is gone, including the main menu, until the process is restarted. How many portals it takes varies, because it depends on which new characters have already been seen.

DirectX 9 does not use this path. `Direct3D.dll` exports `ResetRenderDevice`. `Direct3D11.dll` does not.

## What the patch changes

Both edits are in `.text`. They contain no absolute addresses, so the relocation table is left as it is.

1. RVA `0x65199`, file offset `0x64599`. Initial atlas size.

   Was `BE 00 04 00 00` (`mov esi, 0x400`; that value becomes both width and height, 1024).
   Now `BE 00 08 00 00` (`mov esi, 0x800`: **2048×2048**, 16 MB).
   If `g_pcFontOverride` is set later, the existing 4096×2048 branch is unchanged.

2. RVA `0x63DFE`, file offset `0x631FE`. The wipe request.

   The seven bytes `C6 86 90 00 00 00 01` are replaced with `90 90 90 90 90 90 90`.
   The "glyph is outside the atlas" jumps still land here and leave the packer, but `+0x90` is no longer set. Text that is already on screen stays. Only the glyph that did not fit is skipped.

## How to apply

The scripts look up the install through Steam. If the game is in a folder Steam does not list, pass it explicitly:

```
powershell -File Font_fix\apply.ps1
powershell -File Font_fix\apply.ps1 -Game "D:\Games\Titan Quest Anniversary Edition"
```

The script refuses to run while `TQ.exe` is open. The first run saves `Direct3D11.original.dll` beside the game, on that computer, and every later run patches that original, so a second run does not stack the patch on itself. The backup is listed in `.gitignore` and must not be committed.

Restore the file:

```
powershell -File Font_fix\restore.ps1
```

Verifying the game files in Steam replaces `Direct3D11.dll` with the store original. Run `apply.ps1` again after that. `Direct3D11.original.dll` can stay where the game is installed.

A proper fix belongs in the renderer: when a glyph does not fit, grow the atlas or repack into a new texture, and swap it in only after `CreateTexture` succeeds. Do not blank the live atlas and drop the glyph list. Details for the developers are in `developer_report.txt`.

## What may be published

Publish this folder: the scripts, `README.md`, `developer_report.txt`, and `LICENSE`. Do not publish `Direct3D11.dll` or `Direct3D11.original.dll`. The game EULA allows non-commercial sharing of SDK mods, and it forbids making the game or parts of it available to the public. These notes are not the game. The byte sequences in the script are only the check that the installed file is build 2.10.21415.
