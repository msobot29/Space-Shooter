# Adriatic Uprising / Space Shooter

Godot 4.x vertical arcade shooter prototype, inspired by the planned four-country Balkan campaign.

## Run
1. Open GitHub Desktop, **Fetch origin** and **Pull origin**.
2. Open the existing project folder in Godot 4.
3. Run with **F5**.

## Prototype missions
The first five missions are set in Croatia. Missions 1–3 and 5 feature enemy formations and return fire. Mission 4 has a mini-boss with shield hits, two phases, and multiple projectiles. Finishing a mission opens the shop (except after level 5).

## Controls
- **A / D**, **Left / Right**: move horizontally
- **Space** or **left mouse**: shoot
- **1**, **2**, **3** on the shop screen: purchase upgrades with Scrap
- **Enter**: proceed to next level or restart after game over / victory

## Systems in this version
- 3 lives and temporary post-hit invulnerability
- Enemy bullets and procedural explosion effects
- Scrap drops, collected by flying over them
- Weapon damage, fire rate and armor/invulnerability upgrades
- Mini-boss in level 4; 300 Scrap awarded for defeating it
- Score, Scrap and levels shown in the HUD

All graphics are procedural placeholders, no artwork downloads required.

## Known scope limitations
This is an early prototype. Scrap, upgrades and progress **do not save between sessions** yet.
The fifth level ends the current playable chapter demo; it is not the full 25-level Croatia campaign.
No local Godot runtime was available for automated validation, so please report errors with the line number or a screenshot.
