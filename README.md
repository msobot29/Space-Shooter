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
- **R**: activate invulnerability shield (2 seconds at level 1, 4 at level 2, 6 at level 3; 10-second cooldown starting only after invulnerability ends)
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

## Smooth enemy formations (latest)
- Each 10-enemy wave still enters from both sides (five left, five right), now with staggered entry timing and a 2.8-second smooth arrival.
- Four random flight-path variants remain; their post-entry sways start at zero displacement, preventing the earlier visible jumps at the path transition.
- Two **red armored crabs per side** enter each wave and remain closer to the player than the jellyfish and eels. They have 5 + level/3 HP and act as a defensive front line that intercepts upward fire before it reaches the rear ranks.
- Other enemies occupy the same firing lanes behind them; red crabs are tougher but can be destroyed to expose the formation.
- Test wave 1 and wave 2: no screen-crossing teleports; front-line red crabs absorb incoming shots, with the remaining sea creatures flying behind.

## Ship status modal (latest)
- Inspired by Warblade's S (speed) and B (bullets) status meters, adapted to this game's mechanics as **SPEED** and **FIRE** bars (our FIRE bar represents rate of fire, not Warblade's on-screen bullet capacity).
- Compact speed and fire-level bars now appear in the top-left HUD, without a large panel in the enemy flight area.
- Press **TAB** during gameplay to open the **SHIP STATUS** modal. Gameplay simulation pauses until TAB is pressed again.
- The modal shows current ship speed in pixels per second, speed upgrade level, shots per second, seconds between shots, fire-rate level, equipped weapon and shield level.
- The between-level shop also shows live speed (px/s) and firing rate (shots/s); values refresh as purchases are made.
- Shop costs remain 50 Scrap for every Extra Speed upgrade, 75 Scrap for every Rate of Fire upgrade and 1580 Scrap for direct Triple Shot (or 1040 after Double Shot).

### Test
1. Press TAB during a mission; check speed and shots/s; confirm enemies stop moving until TAB closes it.
2. Buy Extra Speed and Rate of Fire separately; verify their values increase in the shop and TAB panel on the next mission.
3. Confirm the five shop choices still respond to keys 1-5.

## Latest controls: shield and pause
- **R**: activate the shield when it is available; the 10-second cooldown still starts after it expires. **X no longer activates the shield.**
- **P**: pause or resume gameplay. A dedicated pause overlay displays while paused; enemies, projectiles, timers and cooldowns do not advance.
- **TAB**: open or close the Ship Status panel. P takes precedence and closes the status panel when entering pause.
- **B / Space / left mouse**: fire; **A / D** or arrow keys: move. Shop purchases retain keys 1–5.

### Test
1. On mission 1 press R: shield begins; X should do nothing.
2. Press P while enemies are flying or shield is active: all simulation time stops until P is pressed again.
3. Open TAB then press P to pause; close with P and confirm TAB can be used normally afterward.

## Fire input and staged upgrades (latest)
- Firing with **B**, **Space** or **left mouse** now triggers exactly one volley per new button press. Holding a fire control does not auto-repeat; release and press again for another shot. Fire Rate levels shorten the minimum interval between deliberate presses.
- **Extra Speed** still costs **50 Scrap** per upgrade and **Rate of Fire** still costs **75 Scrap** per upgrade. However, upgrading is stage-gated: after mission 1, tier 1 is available; after mission 2, tier 2; after mission 3, tier 3. Their fourth/final tier unlocks at campaign level 10, outside the current 5-level prototype. The shop labels unavailable tiers `LATER STAGE`; no Scrap is deducted for locked tiers.
- This ensures players cannot reach maximum ship speed or maximum fire rate within the first five missions, even with a large Scrap balance.

### QA
1. Hold B/Space/left mouse for several seconds: only one volley should fire. Release and press again: another volley.
2. Buy Fire Rate; repeated taps may fire faster, but holding remains single-volley.
3. With enough Scrap in the first shop, purchase speed and fire rate once each; a second purchase should be blocked until the next cleared level.
4. Verify final tier remains locked throughout the five-level demo and ship/shield/boss behavior is unchanged.

## Latest rule: no mission-based upgrade locks
- Extra Speed (50 Scrap per purchase) and Rate of Fire (75 Scrap per purchase) can now be bought whenever the player has the funds, regardless of mission number.
- Both retain their existing 4-level maximum for balance, but reaching it does not require a specific mission. Previous `LATER STAGE` restrictions are removed.
- Firing is still one volley per fresh press rather than automatic on holding the button.
- All weapon, shield and boss mechanics are unchanged. This rule supersedes the previous stage-gated upgrade note above.

## Latest economy balancing: progressively priced upgrades
Speed and Rate of Fire have no mission gate and may be bought whenever enough Scrap is available, but each successive tier is more expensive:

| Purchased level | Extra Speed cost | Rate of Fire cost |
|---|---:|---:|
| 1 | 100 Scrap | 125 Scrap |
| 2 | 260 Scrap | 325 Scrap |
| 3 | 520 Scrap | 650 Scrap |
| 4 (MAX) | 850 Scrap | 1,050 Scrap |
| **Total** | **1,730 Scrap** | **2,150 Scrap** |

The player receives a guaranteed 25 Scrap per kill (20 enemies per regular stage) plus optional 10-Scrap pickups, so maxing either stat right after stage 1 is unrealistic, but the player is free to save up or specialize. Shop text shows the next level's exact cost and MAX when fully upgraded. Prices do not depend on mission number. Existing direct Double/Triple Shot prices (540/1580), shield prices (900/1800) and boss balance remain the same. This table supersedes earlier fixed-price notes.

### QA
1. Finish stage 1: the next speed and fire rate purchase costs 100/125 Scrap respectively.
2. After each purchase verify that the displayed price rises to the next tier, with no mission-based lock.
3. Once four levels are bought the option shows MAX and no more Scrap is deducted.
4. Test that one press fires one volley, while holding down fire does not continuously shoot.

## Score multiplier pickups (latest)
- Every **30th enemy kill across the run**, a defeated regular enemy drops one randomly chosen **x2, x4 or x6 SCORE** pickup. The counter carries over between missions, so the first bonus usually appears partway through mission 2 (20 kills per mission).
- Multipliers activate **only when the ship collects the purple-gold pickup**; they are not automatic on the kill.
- Each collected multiplier lasts a random **10–15 seconds of active gameplay**. Different pickups have independent timers; when one expires, the remaining multiplier stays active.
- Active multipliers **add together** rather than multiply (x2 + x6 = x8). If none is active, the normal score multiplier is x1.
- The multiplier applies to points from regular kills (100 base) and boss defeat (2500 base), **not** to Scrap income.
- The HUD shows the combined SCORE multiplier and the longest remaining bonus timer. Shop screens, TAB status and P pause do not consume multiplier time. The bonus timer continues into later missions but pauses in the shop.
- Progress and active bonuses reset when the player starts a completely new run.
- A single drop appears at the location of each 30th killed enemy and falls toward the player like other pickups.

### Score multiplier QA
1. Kill 20 enemies in mission 1, then 10 in mission 2: the 30th kill must create exactly one random x2/x4/x6 pickup.
2. Collect the pickup; check the purple-gold HUD and kill an enemy while it is active (e.g. x4 should grant 400 score).
3. If a second bonus is picked up before the first expires, confirm additive stacking (x2 + x6 = x8).
4. Confirm expiry after 10–15 seconds of gameplay, and timers do not advance during P pause, TAB stats or the shop.
5. Confirm Scrap values and the boss's 200 HP remain unchanged.

## Projectile collision fix (latest)
- Player bullets use **continuous swept collision detection** along their entire per-frame motion, including the target's movement during the same frame. This prevents fast bullets from skipping across smaller moving enemies between frames.
- For multiple enemies on the path, the nearest collision is chosen by time of impact. Red front-line crabs intercept bullets before rear enemies when they overlap the bullet's path.
- Collision sizes now better match visible sprites: regular sea creatures use 29px combined hit radius; armored red crabs 33px; boss 69px.
- Every successful hit now produces a small impact flash, including nonlethal hits on tougher armored enemies. A destroyed enemy still produces its normal larger explosion, score, Scrap and drop rewards.
- All weapon types (single, double, Warblade-style triple fan) and boss shield/health are handled through the same continuous collision method.

### Test cases
1. Shoot a moving jellyfish or eel while it crosses the bullet stream; shots that visually pass through it should register.
2. Hit a red armored crab repeatedly: verify small impact flashes before it dies, without losing Scrap or score bookkeeping.
3. Shoot through an aligned formation: front crab should take the hit before creatures behind it.
4. Test Triple Shot against moving enemies and the 200-HP boss, including boss shield depletion.

Engine test still needs confirmation in Godot 4.

## Latest projectile colors and mini-boss 360 balance
- Single Shot player projectiles remain yellow.
- Double Shot projectiles and the shop label are now blue (`Color(0.25, 0.66, 1.0)`).
- Triple Shot projectiles and the shop label are now lilac (`Color(0.78, 0.55, 1.0)`). Each bullet stores its color when fired, so projectiles already in flight keep their color even if weapon state changes.
- The level-4 mini-boss's 360-degree attack still releases 48 evenly spaced projectile slots and keeps both dodge corridors, but the player-oriented angular half-gap narrows from 0.22 to 0.145 radians and the secondary half-gap from 0.19 to 0.12 radians. This means more shots remain in the ring and dodging requires better positioning, without removing the intentionally safe openings.
- Other boss parameters (200 HP, spin warning, projectile velocity, shield) remain unchanged.

### QA
1. Confirm Single Shot yellow, Double Shot blue, and Triple Shot lilac projectiles, including in-motion fan shots.
2. Confirm the mini-boss 360 ring has visibly narrower passages while still allowing skilled dodges.
3. Confirm regular hit detection, pause and shields still work.

## Persistent High Scores — Top 10 (latest)
- At GAME OVER or after clearing Croatia mission 5, the game displays a **Top 10 High Scores** leaderboard.
- If a completed run has a positive score high enough to make the local Top 10, an editable **pilot name** field appears. Type a name (up to 12 characters) and press **ENTER** to submit. A blank name is saved as **PILOT**.
- A run beating the previous number-one score displays **NEW HIGH SCORE!**; other qualifying scores display **TOP 10 QUALIFIED!**. After saving, press ENTER again to start a new run.
- Scores are sorted descending and capped at 10. A tie with the 10th place does not displace an existing score.
- Records are saved through Godot `ConfigFile` at **`user://highscores.cfg`** and loaded on launch. They survive game restarts on the same device/profile. They are *local*, not shared online, and each installation has its own leaderboard.
- The in-game HUD also shows **BEST** (highest stored score or current-run score, whichever is higher).
- Score multipliers already in place affect points awarded during gameplay and therefore the final leaderboard score.
- No account/login required, and the rest of the gameplay and economy remain unchanged.

### Suggested Godot test
1. Finish or lose a run with some points. Confirm that a name-entry field appears and the first high score saves.
2. Restart the game and lose another run; ensure the first result persists and the scores are correctly ordered.
3. Submit enough scores to exceed 10; verify that only the 10 highest remain, and a lower score does not prompt for a name.
4. Confirm ENTER submits the name first and only restarts after submission.
5. Verify the BEST number increases when you exceed the record and multiplier-boosted scores are saved.

## Shop cadence — every five levels (latest)
- The upgrade shop now appears **only after missions 5, 10, 15, ...**, not after each mission. Between those milestones, levels progress automatically as soon as the current mission is cleared.
- Scrap accumulates across the five-mission block, so the player can save and then make more meaningful upgrade choices. All progressive prices and existing upgrade limits remain unchanged.
- The current Croatia demo includes **only five missions**. After finishing mission 5, the shop opens so its milestone behavior can be tested. Press **ENTER - View results** to reach the victory screen, enter a qualifying Top 10 score and start another run. Purchases made there cannot affect further gameplay until additional missions are implemented.
- Once more levels are added and `MAX_LEVEL` is increased, the same `% 5` rule will also open the shop after missions 10, 15, 20, etc.; ENTER then launches the following mission except at the campaign end.
- This section supersedes older README descriptions saying that the shop opens after every completed level.

### QA
1. Clear missions 1–4: no shop should appear; each following level starts automatically.
2. Clear mission 5: shop appears; test pricing and upgrade purchases.
3. Press ENTER on the mission-5 shop: victory and persistent High Score / name entry appear, not mission 6.

## Croatia prototype expanded to 10 levels (latest)
The playable Croatia prototype now covers **missions 1–10**, while the long-term campaign roadmap remains unchanged.

**Progression**
- Missions **1–4** proceed one after another with no shop intermission.
- Mission **4** ends with the existing mini-boss (200 HP), then mission 5 starts.
- After **mission 5**, the between-stage shop opens. Scrap earned across the first five missions can now be spent on upgrades used in missions 6–10. Press ENTER to start mission 6.
- Missions **6–8** continue automatically; regular sea creatures gain some HP in the second half, with progressively faster (but bounded) enemy fire.
- Mission **9** includes another mini-boss encounter (270 HP), with the same recognizable 360-degree attack and two-phase behavior.
- After **mission 10**, the shop opens once more. Press **ENTER - View results** to finish the Croatia demo and submit a qualifying score to the persistent Top 10 board. Purchases at the final shop cannot be used until additional missions are added.

**Balance:** Red crabs stay in the forward shield formation; no arbitrary mission lock applies to purchases. The second half's enemy firing interval is limited to 0.56 seconds, and enemy HP rises gradually rather than every third level. Score multipliers still trigger every 30 cumulative kills across the entire run, and Shop/High Score/Pause functionality remains.

**QA smoke test**
1. Clear levels 1–4 and verify stage transitions are automatic and that boss appears after the waves on level 4.
2. Clear level 5: buy Speed or Rate of Fire, then press ENTER. Verify level 6 loads with the purchased stat.
3. Clear levels 6–8 and verify waves, hit detection, drops and score multipliers still function.
4. On level 9, verify the 270-HP mini-boss spawns after its two waves, then transition to level 10.
5. Clear level 10: shop appears, then ENTER shows victory + local Top 10 name entry, with no accidental level 11.
6. Confirm the P pause, R shield, TAB Ship Status and colored Double/Triple Shot remain usable.

This section supersedes earlier references to a five-level maximum in the README. The actual game logic has been updated, but the new 10-level progression still requires an in-engine Godot test.

## Unique formations and attack patterns: missions 6–10 (latest)
The Croatia second block now introduces distinct enemy arrangements and projectiles, rather than only boosting health and fire rate:

| Mission | Formation | Attack |
|---|---|---|
| 6 | Mirrored V wedge with armored crabs in front | Electric eels fire aimed green bolts; other enemies keep simple vertical shots |
| 7 | Tight paired columns with rear layers | Jellyfish fire a crossing pair of blue angled shots |
| 8 | Wide crescent, compact red forward guards | Red crabs launch a three-projectile orange fan |
| 9 | Wide pincer with flank positions | Eels fire two narrow green aimed bolts; the existing 270-HP mini-boss follows the waves |
| 10 | Crown formation, red guards shielding the center | Jellyfish fire paired purple-blue arcs, with aimed orange-red shots from other units |

**Design constraints:** Every wave still contains five enemies from each side, with **two red armored crabs per side in the foremost rows**. Existing smooth entrances and swept projectile hit-detection stay in place. Special bullets are launched only after attackers are on screen. Level-specific shots have colored projectile bodies so attacks are readable, and the player can dodge aimed fire. Damage, life loss, shield invulnerability and pause behavior use the existing bullet collision system. Shop remains after missions 5 and 10, with High Score after the last shop.

**QA checklist:** Play levels 6, 7, 8, 9, 10 to compare formations and bullet patterns. Confirm red crabs stay forward, entrance motion remains smooth, angled projectiles can be dodged or shielded with R, TAB/P freeze simulation, and the level-9 mini-boss and level-10 High Score sequence still trigger. Newly authored gameplay must be tested inside Godot 4 before release.
