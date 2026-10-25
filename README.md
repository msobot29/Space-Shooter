# Adriatic Uprising / Space Shooter

Godot 4.x vertical arcade shooter prototype, inspired by the planned four-country Balkan campaign.

## Run
1. Open GitHub Desktop, **Fetch origin** and **Pull origin**.
2. Open the existing project folder in Godot 4.
3. Run with **F5**.

## Prototype missions
The first five missions are set in Croatia. Each mission starts with 10 enemies (five entering from the left and five from the right); a second wave of 10 arrives exactly 5 seconds later. Each wave randomly selects one of four curved entrance/flight paths. Enemies continue weaving after entering and return fire. Mission 4 has a mini-boss **after both waves are cleared** with shield hits, two phases, spread volleys, a telegraphed aimed column (red warning zone), and a telegraphed 360-degree spin attack. Finishing a mission opens the shop (except after level 5).

## Controls
- **A / D**, **Left / Right**: move horizontally
- **B**, **Space**, or **left mouse**: shoot
- **X**: activate invulnerability shield (2 seconds at level 1, 4 at level 2, 6 at level 3; 10-second cooldown starting only after invulnerability ends)
- **1**, **2**, **3**, **4** in the shop: purchase weapon upgrades, fire rate, X shield, and ship speed. Every three weapon purchases unlock the next shot tier.
- **Enter**: proceed to next level or restart after game over / victory

## Systems in this version
- 3 lives and temporary post-hit invulnerability
- Three distinct procedural sea creatures: dual-shot jellyfish, tougher armored crabs, and evasive zigzagging electric eels (eel body rendered as thick connected segments, avoiding the invisible self-intersecting polygon bug)
- Enemy bullets and procedural explosion effects
- Two timed 10-enemy waves per mission, each with random flight routes (20 opponents per mission)
- Guaranteed 25 Scrap per enemy kill plus collectible bonus Scrap drops (85% drop chance, worth 10 each)
- Weapon progression: buy weapon upgrade 3 times for Double Shot (2 parallel bullets); buy 3 more times for Triple Shot (3 bullets in a wide fan: left -22°, center straight, right +22°). Weapon damage also increases with each purchase, capped at level 6. Fire rate and X shield are independent.
- Mini-boss in level 4; 300 Scrap awarded for defeating it
- Active shield: initial level 1, upgrade costs 900 and 1800 Scrap; resets on a new game, can be reactivated repeatedly after each full 10-second cooldown following the shield duration; ready at the start of each mission
- Score, Scrap and levels shown in the HUD

All graphics are procedural placeholders, no artwork downloads required.

## Known scope limitations
This is an early prototype. Scrap, upgrades and progress **do not save between sessions** yet.
The fifth level ends the current playable chapter demo; it is not the full 25-level Croatia campaign.
Changes are not yet tested in the Godot editor, so please report errors with the line number or a screenshot.

## Test checklist for the next run
1. Finish mission 1: 20 enemies defeated award **at least 500 Scrap**, even without catching pickups.
2. In the shop save at least 900 Scrap and press **3** once; X should provide 4 seconds of invulnerability.
3. Complete mission 2 (20 enemies, at least 500 more Scrap), then buy X level 3 with **3** for 1800 Scrap; verify 6-second duration.
4. Each X activation must finish before its 10-second cooldown begins.
5. On mission 4, dodge the new red target warning stripe; the boss alternates attack patterns.

## Wave test checklist
1. In mission 1 verify five enemies appear from each side (10 total).
2. Without finishing the first wave, verify a second group of ten starts arriving after 5 seconds.
3. Restart and compare flight paths: each wave randomly picks one of four patterns; directions vary between runs.
4. Clear all 20 enemies; only then should the shop open.
5. On mission 4 clear both waves, then fight the mini-boss; mission completion requires defeating it.

## New test checklist
- Shop displays **1 Damage**, **2 Fire rate**, **3 X Shield**, **4 Ship speed**; no Armor purchase.
- Key **3** buys X Shield level 2 for 120 Scrap and level 3 for 1800 Scrap.
- Jellyfish fire two offset bullets, crabs have extra HP, and electric eels weave faster.
- Both waves still contain 10 enemies; mini-boss still begins after both waves in mission 4.

## Shield economy update
Shield Lv1 is unlocked by default (2 seconds). Lv2 costs 900 Scrap (4 seconds), and Lv3 costs 1800 Scrap (6 seconds). It is intentional that buying the maximum shield upgrade after mission 1 is no longer possible. The cooldown remains 10 seconds **after** protection ends. Test higher tiers later in the campaign; the five-level demo may not provide enough Scrap for both upgrades unless the player saves it.

## Weapon progression test checklist
1. Start with one bullet per shot (weapon 0/3).
2. Buy weapon damage three times using shop key **1** to unlock two bullets per shot (Double Shot).
3. Buy weapon damage three more times to unlock three bullets per shot in a wide fan (Triple Shot).
4. After level 6 the shop displays `TRIPLE SHOT MAX` and takes no more Scrap for weapon purchases.
5. Single and Double Shot remain straight; Triple Shot fires center straight and two side bullets at ±22°. B and Space controls work as before. Prices rise by 100 Scrap per weapon purchase (80, 180, 280, 380, 480, 580).

Note: This 5-level demo may not provide enough Scrap to buy six weapon upgrades and shield upgrades in the same run. A full campaign will make longer progression possible.

## Warblade-inspired Triple Shot
At weapon upgrade 6, the outer projectiles spread **22 degrees** left/right while the central projectile goes straight up, increasing coverage and reducing the chance that all three projectiles hit one small target. Double Shot keeps two parallel forward projectiles. Shot positions, velocity and collision are handled per projectile. Test the spread at level 6.

## Movement, fire-rate and boss spin update
- Initial ship movement is **295 px/s** (was 470); shop key **4** buys up to four speed levels, +48 px/s each, costing 120 / 250 / 380 / 510 Scrap.
- Initial firing interval is **0.34 s** (was 0.22); rate upgrades shorten it by 0.05 s per level, down to **0.14 s** at level 4 (effective floor 0.12 s).
- Mission-4 mini-boss now periodically dives toward the player and rotates a full 360 degrees during a **1.5 s** warning, then attempts a **48-slot** radial projectile ring, leaving two deliberately wider dodge corridors. One gap is oriented toward the player's position when the ring is fired and a second is offset by about 36 degrees. A distinct purple-pink circle and on-screen warning signal the attack. Activating X Shield remains useful, but players can also dodge through the gaps with precise positioning. The boss now has **160 HP** (was 90) and enters phase 2 at 75 HP. The 360 attack repeats every three volleys (spread, spin, aimed), with shorter gaps between attack sequences.
- X Shield duration and its 10-second cooldown after deactivation have not changed.

### Test checklist
1. Verify the initial ship and fire rate are slower.
2. Buy ship speed using **4** and observe higher horizontal movement speed in the next mission.
3. Buy Fire Rate using **2** and observe faster shooting.
4. On mission 4, observe the red aimed warning and the separate pink 360-degree warning, boss dive/spin, and radial attack.
5. Confirm X Shield blocks the radial projectiles when timed correctly.

Godot editor validation remains pending.

## Boss balance update
- HP: 160 (previously 90); second phase starts at 75 HP.
- Special 360 spin now happens regularly every three attack decisions: spread -> spin -> aimed attack, repeating. Attack interval: 1.5 seconds in phase 1 / 1.2 seconds in phase 2, excluding 1.5-second spin warning.
- 48 radial projectile slots with two open corridors to enable skillful dodging. Projectile speed 350 px/s (phase 1), 410 px/s (phase 2).
- Test both escaping through the gaps and blocking with X Shield. Gaps are intended to improve chances, not guarantee safety.

## Current shop layout
Keys: 1 Extra Speed, 2 Rate of Fire, 3 Double Shot, 4 Triple Shot, 5 Shield Upgrade.
Double Shot requires three purchases; then Triple Shot requires three more purchases. Boss health is now 200 HP, with phase two starting at 95 HP. This section supersedes earlier shop key mappings and HP numbers above.

## Latest shop rule: direct weapon purchases
Double Shot and Triple Shot are now **single-purchase unlocks**, with no intermediate weapon levels or prerequisite.
- **3 Double Shot:** costs **540 Scrap** and immediately unlocks two parallel bullets.
- **4 Triple Shot:** costs **1980 Scrap** if bought directly from Single Shot, immediately unlocking three fan-spread bullets.
- If Double Shot is already owned, Triple Shot costs **1440 Scrap** (the difference), so the total cost is identical in either purchase order.
- Once Triple Shot is purchased, Double Shot is marked owned too and neither can be bought again.
- Existing speed, fire-rate, shield prices, boss HP (200) and shield cooldown remain unchanged.
The shop displays the actual purchase price and owned status. This section supersedes previous descriptions of needing three purchases for each shot type.
