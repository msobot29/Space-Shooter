# Adriatic Uprising / Space Shooter

Godot 4.x vertical arcade shooter prototype, inspired by the planned four-country Balkan campaign.

## Run
1. Open GitHub Desktop, **Fetch origin** and **Pull origin**.
2. Open the existing project folder in Godot 4.
3. Run with **F5**.

## Prototype missions
The first five missions are set in Croatia. Each mission starts with 10 enemies (five entering from the left and five from the right); a second wave of 10 arrives exactly 5 seconds later. Each wave randomly selects one of four curved entrance/flight paths. Enemies continue weaving after entering and return fire. Mission 4 has a mini-boss **after both waves are cleared** with shield hits, two phases, alternating spread volleys and a telegraphed aimed column (red warning zone). Finishing a mission opens the shop (except after level 5).

## Controls
- **A / D**, **Left / Right**: move horizontally
- **B**, **Space**, or **left mouse**: shoot
- **X**: activate invulnerability shield (2 seconds at level 1, 4 at level 2, 6 at level 3; 10-second cooldown starting only after invulnerability ends)
- **1**, **2**, **3**, **4** on the shop screen: purchase upgrades with Scrap (4 improves the X shield up to level 3)
- **Enter**: proceed to next level or restart after game over / victory

## Systems in this version
- 3 lives and temporary post-hit invulnerability
- Enemy bullets and procedural explosion effects
- Two timed 10-enemy waves per mission, each with random flight routes (20 opponents per mission)
- Guaranteed 25 Scrap per enemy kill plus collectible bonus Scrap drops (85% drop chance, worth 10 each)
- Weapon damage, fire rate and armor/invulnerability upgrades
- Mini-boss in level 4; 300 Scrap awarded for defeating it
- Active shield: initial level 1, upgrade costs 120 and 250 Scrap; resets on a new game, can be reactivated repeatedly after each full 10-second cooldown following the shield duration; ready at the start of each mission
- Score, Scrap and levels shown in the HUD

All graphics are procedural placeholders, no artwork downloads required.

## Known scope limitations
This is an early prototype. Scrap, upgrades and progress **do not save between sessions** yet.
The fifth level ends the current playable chapter demo; it is not the full 25-level Croatia campaign.
Changes are not yet tested in the Godot editor, so please report errors with the line number or a screenshot.

## Test checklist for the next run
1. Finish mission 1: 12 enemies defeated awards **at least 300 Scrap**, even without catching pickups.
2. In the shop press **4** once (120 Scrap); X should provide 4 seconds of invulnerability.
3. Complete mission 2 (16 enemies, at least 400 more Scrap), then buy X level 3 for 250 Scrap; verify 6-second duration.
4. Each X activation must finish before its 10-second cooldown begins.
5. On mission 4, dodge the new red target warning stripe; the boss alternates attack patterns.

## Wave test checklist
1. In mission 1 verify five enemies appear from each side (10 total).
2. Without finishing the first wave, verify a second group of ten starts arriving after 5 seconds.
3. Restart and compare flight paths: each wave randomly picks one of four patterns; directions vary between runs.
4. Clear all 20 enemies; only then should the shop open.
5. On mission 4 clear both waves, then fight the mini-boss; mission completion requires defeating it.
