# Windows test build — Adriatic Uprising

This repository contains the Godot 4 game source. The Windows .exe must be exported using Godot and matching export templates.

## Automatic GitHub build (no local export required)

1. Open https://github.com/msobot29/Space-Shooter/actions/workflows/windows-build.yml while signed in to GitHub.
2. Click **Run workflow**, keep the **main** branch selected and confirm.
3. Open the resulting run. When its status is **Success**, scroll to **Artifacts**.
4. Download **AdriaticUprising-Windows-Alpha**. Extract the artifact ZIP to get `AdriaticUprising.exe`.
5. Test the EXE on Windows and then send a ZIP of it to your friend.

This automation uses Godot 4.7.2 and matching Windows export template. If the workflow fails, inspect the job log or export manually with the steps below. A workflow file is not itself an executable.

## Export a single Windows executable

1. Open the project in **Godot 4.7.2** (or the matching Godot version you use).
2. Use **Editor > Manage Export Templates** and download/install the templates for that exact editor version.
3. Run the game once with **F5** and confirm that there are no errors.
4. Open **Project > Export** and select the existing **Windows Desktop** preset. If it is not displayed, add a Windows Desktop preset.
5. Check **Architecture: x86_64** and **Embed PCK: ON**. This embeds game resources into one .exe.
6. Make an empty **build** folder in your local project if it does not exist.
7. Click **Export Project** (not Export PCK/ZIP), choose `build/AdriaticUprising.exe`, and **turn off "Export With Debug"**.
8. Run the resulting `.exe` on your own Windows PC before sharing it.
9. ZIP `AdriaticUprising.exe` and send it to your friend. They should extract the ZIP and launch the EXE.

If embedding is unavailable, leave the separate `.pck` alongside the `.exe` and include both files in the ZIP.

## QA smoke test

- Main Menu: Continue / New Game / Options / High Scores.
- Options: rebind LEFT and RIGHT to arrow keys, play, then restart and confirm settings persist.
- Levels 1 and 5: two enemy waves, shop and first guardian.
- Level 21: Zagreb background and difficulty.
- Level 25: final guardian shield phases, Adriatic Storm, white orb and finale.
- In a normal run, exit mid-level and verify Continue restarts from the checkpoint.
- Test with the debug F2 menu, but debug runs intentionally do not write High Scores.

No completed Windows executable is included in this repository until it is exported with Godot.

For further details: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html
