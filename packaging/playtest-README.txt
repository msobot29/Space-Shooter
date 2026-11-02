ADRIATIC UPRISING - WINDOWS x86_64 PLAYTEST

LAUNCH
Extract the entire ZIP, then run AdriaticUprising_Playtest.exe.
Keep any accompanying .pck beside the EXE. No Godot editor is required.
Unsigned test build; not a production release.

DEFAULT CONTROLS (verified against main.gd)
A / D: move left / right.
Space or left mouse button: fire. Release and press again for another shot;
holding fire does not repeat shots.
R: activate shield when ready.
P: pause. Escape: pause menu / back, depending on the screen.
TAB: toggle Ship Status without pausing gameplay or music.
Arrow keys and Enter: menu and map navigation / confirmation.
Enter or Space: confirm mission briefing. Enter: continue from shop.
Shop: 1 Speed, 2 Rate of Fire, 3 Double Shot, 4 Triple Shot, 5 Shield,
6 Arc Lightning, 7 Plasma Cannon (last two unlock in Bosnia).
M: toggle music during gameplay; return to main menu on map/in shop.
[ / ]: music volume. Comma / period: sound effects volume.
OPTIONS > KEYBOARD CONTROLS: change bindings. Saved bindings may differ.

CAMPAIGN AND SAVES
Croatia: levels 1-25. Bosnia and Herzegovina: levels 26-50.
Continue loads the latest automatic checkpoint, not the exact mid-combat frame.
New Game can replace existing campaign progress; use Continue to resume.
Playtest saves/logs: %APPDATA%\AdriaticUprising\Playtest\
This stable playtest profile is separate from the development game's saves.
Developer/older shared-profile progress is never imported automatically.
An existing playtest campaign remains available through Continue after updates.
Controls: %APPDATA%\AdriaticUprising\controls.cfg

KNOWN LIMITATIONS
CI checks regression suites and this player EXE's headless startup. A separate
release QA executable tests campaign save/restart using the same game code.
It does not verify GPU rendering, sound, physical input or all 50 levels played
end to end. Please test those interactively. Existing F2/F3/F4 and O test
shortcuts remain in gameplay code; avoid them for normal playtesting.
Debug runs skip normal campaign/high-score saves; O toggles invulnerability.

BUG REPORTS
Send the build commit below, Windows/GPU details, level/city, exact steps,
expected and actual result, frequency, and screenshots/video to the person
who supplied this build. Note custom controls and any debug shortcuts used.
For Continue issues, attach a COPY of campaign_save.cfg and logs from the
save folder. Preserve your original saves.
