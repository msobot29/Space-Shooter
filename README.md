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

## Random Double Shot pickups (latest)
- While the player only has **Single Shot**, each destroyed regular enemy has a **12% chance** to drop a blue **D (Double Shot)** pickup.
- To avoid unlucky runs leading into the mini-boss with only Single Shot, a drop is **guaranteed on the 18th eligible kill without a Double Shot drop**. Kill counts persist across missions; this guarantee concerns the *drop*, not automatically receiving the weapon. Players must physically collect it.
- Only one Double Shot pickup can be on screen at a time. If the player misses one, another may drop after later kills.
- The pickup falls at 230 px/s, is shown as a blue ring containing **D**, and immediately upgrades Single Shot to the existing permanent blue Double Shot. No Scrap is charged.
- **Between-level shop integration:** once Double Shot is picked up, the shop shows **Double Shot: OWNED** and charges the existing reduced price for upgrading to Triple Shot. Triple Shot is unaffected and remains lilac.
- If a Double Shot pickup is falling when the final enemy of a stage dies, stage completion waits until it is collected or has fallen off screen. This prevents the last kill's drop from disappearing on an immediate level transition.
- No weapon pickups spawn after Double Shot or Triple Shot has already been obtained. Existing Scrap, Score multiplier, boss mechanics and High Score calculation are unchanged.

### QA
1. Start with Single Shot and kill enemies: verify random blue D drops can appear, and a drop appears by the 18th eligible enemy kill at the latest.
2. Move the ship to collect D: Double Shot starts immediately, bullets are blue, and the shop later says OWNED.
3. Miss a D pickup: verify the game can generate another one on later kills.
4. Trigger D from the final enemy in a mission: verify the level waits for pickup collection or exit.
5. After owning Double Shot, verify no further D pickups appear and Triple Shot remains purchasable at its upgrade difference price.

## Weapon downgrade on life loss and safe reward transitions (latest)
- Each **actual life lost** reduces the player's weapon by one tier:
  - **Triple Shot (lilac) -> Double Shot (blue)**;
  - **Double Shot (blue) -> Single Shot (yellow)**;
  - **Single Shot stays Single Shot**.
- Damage successfully blocked by R Shield or the post-hit invulnerability window does **not** cost a life or downgrade the weapon. Speed, Rate of Fire, shield upgrade levels, score and Scrap are unaffected by the weapon penalty.
- The change affects the next fired volley immediately. Double Shot can be recovered through the existing random blue **D** pickup, or repurchased from the shop; Triple Shot can be regained in the shop.
- When the last enemy in a mission dies, the game **keeps the stage active until all falling collectibles are resolved**, rather than wiping them on the next-stage load. This applies to Scrap, x2/x4/x6 score multipliers and Double Shot pickups.
- A collectible resolves when picked up by the ship or after it falls off the bottom of the screen. The player can continue to move and collect rewards while waiting; a short **COLLECT DROPS** notice is shown.
- If a mission ends with a miniboss, the miniboss waits for remaining wave drops to resolve before spawning. After the miniboss is defeated, the same collection rule applies before transitioning to the next mission, the shop or the final High Score screen.
- The shop still only appears after missions 5 and 10; level progression and previously implemented difficulty balancing remain unchanged.

### QA smoke tests
1. Acquire Triple Shot; take one unshielded hit and confirm Double Shot, then another and confirm Single Shot. Check bullet colors and counts.
2. Take damage while R Shield or invulnerability is active: no life lost and no weapon downgrade.
3. Kill the last regular enemy while Scrap + a multiplier + Double Shot are falling: none should disappear, and the stage advances automatically only after all are collected or exit the bottom.
4. Repeat on mission 4 or 9: the miniboss should wait for wave drops, then start as normal.
5. Finish mission 5 or 10 with falling Scrap: the shop must wait until rewards resolve, and must reflect the final collected Scrap balance.
6. Verify P pause and TAB status freeze time while collectibles are falling.

## Immediate next-stage transitions with persistent falling rewards (latest)
- Clearing the final enemy starts the next mission **immediately**, even when Scrap, score multipliers or Double Shot pickups remain on the screen. There is no longer a COLLECT DROPS wait state.
- All existing drops survive `start_level()` and retain their position. They continue to fall as soon as the next level is active; the player can collect them while fighting the next wave.
- Mini-bosses also launch after their wave ends without waiting for pickups to fall. Existing pickups stay visible and collectible during the boss fight.
- At the scheduled shop after missions 5 and 10, the shop overlay pauses normal gameplay, including falling drops. If there is another stage, remaining items resume falling when that stage begins. Items not yet collected do not count toward Scrap spendable in the shop.
- Only a completely new run clears lingering drops, along with all other run-specific state.
- On life loss, Triple still degrades to Double, and Double to Single.

### QA
1. Destroy the last enemy while multiple Scrap, multiplier, and Double Shot items are falling: the next level should launch at once and all items should continue their downward motion.
2. Collect a carried Scrap pickup in the following mission and verify Scrap increases exactly once.
3. On missions 4/9, check that the boss appears immediately after its wave, while any rewards continue falling.
4. Enter the mission-5 shop with pickups still on screen: purchases use collected Scrap only; after starting mission 6, leftover pickups continue falling.
5. Restart after Game Over: pickups from the former run must not remain.
This rule supersedes the previous README section requiring all drops to resolve before a transition.

## 10-second level introductions with falling rewards (latest)
- Between **regular mission transitions** (level 1 → 2, 2 → 3, etc.), a **10-second intermission** appears in place of immediately spawning enemies.
- A centered announcement shows **LEVEL 2**, **LEVEL 3** and so forth, plus an updating **STARTING IN N** countdown.
- The player may still steer their ship to gather leftover **Scrap, score multipliers and Double Shot pickups**. All existing drops keep falling and retain their positions, even as the new mission begins. They never gate or delay stage progression.
- No new enemies spawn or attack during the countdown. When the timer expires, the next mission starts automatically and the first enemy wave enters normally.
- The scheduled shop still opens at the end of levels 5 and 10. After buying upgrades and pressing ENTER after level 5, the same ten-second **LEVEL 6** introduction plays. The final shop after level 10 still goes directly to the victory/High Score screen.
- **P pause** and **TAB status** remain accessible during the intermission and freeze the countdown and falling pickups while active. This is separate from the shop screen.
- A completely new run begins with Level 1 immediately and no introductory countdown.

### QA
1. Clear level 1 with Scrap in flight: confirm a centered LEVEL 2 countdown of approximately 10 seconds, with all pickups still falling and collectible.
2. Move the ship during the countdown to collect a reward, and confirm the Scrap/multiplier/Double Shot updates immediately.
3. Confirm level 2 enemies start only after the countdown and existing drops that remain in view persist.
4. Pause with P during countdown; verify the number and falling rewards freeze, then resume.
5. After level 5 shop, press ENTER and verify LEVEL 6 intro; after level 10 shop, confirm victory/High Score rather than level 11.

## Stage transition timing — silent break, then title (latest)
The previous visible STARTING IN countdown has been **removed**. Between ordinary missions and after leaving the level-5 shop:
1. For the first **10 seconds**, no countdown or level title appears. The previous mission has ended, no enemies spawn, and the player can still move and collect any Scrap, Double Shot or multiplier pickups left on screen.
2. After those 10 seconds, a large centered **LEVEL 2**, **LEVEL 3**, etc. title appears. There is still **no numeric countdown**.
3. **3.5 seconds after the title first appears**, the next level begins and its first wave spawns.
This is a total **13.5-second transition** before enemy spawning. Pickups keep falling throughout both phases and carry over to the new level if still on screen. P/TAB freeze the transition; the shop still appears after levels 5 and 10, with the Level 6 introduction occurring after leaving the level-5 shop.

### Verification
- Clear level 1, ensure there is **no countdown** and no level-title overlay during the first 10 seconds.
- Confirm LEVEL 2 appears only after ~10 seconds, then the next wave begins ~3.5 seconds later.
- Repeat after level 5 shop, verifying LEVEL 6 timing.
- Verify Scrap/bonus pickup collection works while waiting and that P/TAB pause both timing phases.
This section supersedes the earlier README wording describing a visible STARTING IN countdown.

## Croatia campaign: 25 levels, five cities (latest specification)
**The Croatia chapter now covers 25 levels — exactly five missions for each of five major Croatian cities.** The campaign order is designed to finish with liberation of Zagreb, rather than follow population rank:
- **Zadar: levels 1–5**
- **Rijeka: levels 6–10**
- **Split: levels 11–15**
- **Osijek: levels 16–20**
- **Zagreb: levels 21–25**

The city name appears in the live HUD and in the centered next-level introduction. Existing controls, the ten-second silent intermission followed by a 3.5-second city/level title, persistent falling rewards, local High Scores, colored weapons, weapon loss on damage, and shop controls remain in place.

**City bosses:** Each fifth level ends with a guardian after its normal two waves: 5 (Zadar, 200 HP), 10 (Rijeka, 270 HP), 15 (Split, 340 HP), 20 (Osijek, 410 HP). **Level 25 ends with the Croatia campaign FINAL BOSS in Zagreb (650 HP, four initial shield charges, faster movement and firing, faster 360-degree bullets)**. These bosses currently reuse the established procedural boss art and attack families; unique visual designs and new final-boss abilities are future polish rather than implemented content.

**Shop and victory:** The normal upgrade shop opens after each city guardian at 5, 10, 15, 20, and 25. For cities 1–4, pressing ENTER in the shop launches the regular level transition to the next city; after defeating Zagreb's level-25 boss, the last shop leads to the **CROATIA LIBERATED!** victory/Top 10 leaderboard screen. It no longer ends at level 10. Only one Croatia playthrough is 25 stages; no further countries are implemented yet.

**Patterns and difficulty:** The existing five advanced formations/attack types now rotate within each city after Zadar (city-local missions 1–5). Regular enemies slowly gain health by chapter with a cap on HP scaling, and aimed-special projectile speed is capped to avoid unlimited speed increases at high levels. More unique enemies, city-specific backgrounds, environmental art, and final boss visuals remain on the roadmap.

### QA for expanded campaign
1. Confirm HUD/introductions identify Zadar 1–5, Rijeka 6–10, Split 11–15, Osijek 16–20, Zagreb 21–25.
2. Confirm bosses trigger **only** on 5/10/15/20/25, and the level-25 boss is visibly labeled FINAL BOSS with 650 HP and four shields.
3. Confirm the shop opens after every fifth level and that level 25 leads to victory/Top 10 rather than level 26.
4. Test falling pickups during transitions and the shop-to-city transition, and check that weapon downgrades and boss health decrement remain correct.
5. Godot 4 end-to-end testing and balancing are required before calling the 25-level campaign production-ready.

## HUD lives icon, lieutenant intro, and no frozen transition shots (latest)
- The top-left lives display now uses a small **blue ship icon × N** instead of literal **LIVES N**; Scrap remains next to it and the BEST counter stays on the right.
- Every city guardian now receives a dedicated **3.8-second lieutenant announcement** after the last regular enemy is destroyed:
  **THE GUARDIAN OF THIS ZONE / HAS SENT HIS LIEUTENANT / TO DEAL WITH YOU**.
  The guardian mini-boss does **not** appear or shoot until that announcement has finished. This applies to boss stages 5, 10, 15, 20 and 25, including the final Zagreb encounter.
- During the lieutenant announcement, the player can move and catch leftover falling Scrap, Double Shot and multiplier rewards. P and TAB still freeze the announcement/rewards.
- **Frozen player projectile fix:** firing is disabled in both the between-level intermission and the boss announcement. The player's fire-button held state is still updated so keeping B/Space/mouse pressed cannot create an unintended shot when the next wave starts. Movement and rewards are unaffected; combat shooting remains edge-triggered and works again when battle resumes.
- Existing player projectiles are cleared upon entry to a level intermission or boss announcement. Player weapon level and other upgrades are not reset by these transitions.

### QA checklist
1. Verify the upper-left HUD reads [tiny blue ship] **x3 SCRAP ...** at the start, and x2 after taking one actual life loss.
2. During a normal intermission after any cleared level, repeatedly press fire: no blue/yellow/lilac frozen shots should build up in front of the ship. After enemies arrive, firing must work normally on a fresh press.
3. Clear all waves on stage 5: verify the announced sentence stays visible for about 3.8 seconds, with no early boss attack, then the guardian appears.
4. Move and catch a falling reward during the announcement; confirm it counts and resumes normally on P unpause.
5. Check regular boss and final boss after the announcement and verify shop and next level transitions still work.

## Firing during between-level waiting periods (latest)
- The player **can shoot during the silent 10-second gap and the following 3.5-second LEVEL title**, while moving and collecting falling rewards.
- Player bullets are now updated normally during this intermission, travel upward and disappear when off-screen rather than freezing around the ship.
- Shooting keeps its existing single-volley-per-fresh-press behavior, bullet colors and upgraded fire rate.
- The separate 3.8-second city-guardian/lieutenant announcement remains non-combat with shooting disabled. P and TAB still pause the intermission, including bullets and falling rewards.
- When the next level starts, its existing start/reset logic clears any bullets remaining from the transition so gameplay begins cleanly.

### QA
1. Finish a non-shop level and repeatedly tap B/Space in the 10-second silent wait and LEVEL title: all bullets must move upward, never form a frozen cluster.
2. Confirm shooting does not auto-repeat when B/Space is held down.
3. Confirm bonus pickup collection, P pause, and next-wave timing still work.
4. On a city guardian stage, confirm boss-announcement shots are disabled and restart correctly after the boss appears.

## QA God Mode hotkey (latest)
- Press **O** at any time to toggle **GOD MODE** ON/OFF for local testing. A green **GOD MODE [O]** message appears in the upper-right HUD when enabled.
- While enabled, enemy shots and collisions cannot remove a life, nor can they trigger the associated one-tier weapon downgrade. Existing R shield mechanics, weapon pickups, Scrap, score, enemies and bosses continue to operate normally.
- Press O again to restore normal damage. Toggle is in-memory for the current game process (it is not stored with High Scores).
- This is a **testing convenience**, not a balanced player ability; disable it when evaluating real difficulty or high-score fairness.
- QA: Turn O on, take several enemy projectiles and confirm lives and weapon tier remain unchanged; turn it off and take one unshielded hit after any temporary invulnerability expires, confirming normal life loss and weapon degradation.

## Croatia campaign balance, life orbs and Zagreb final boss (latest)
- **Inter-level timing:** silent break shortened by five seconds, from 10 to **5 seconds**. The centered city/LEVEL title still appears for **3.5 seconds** afterward. New enemies start after **8.5 seconds total** (except when a milestone shop is open). No countdown numbers are shown. Firing during the wait still works, and falling pickups persist.
- **Regular enemy Scrap reduced:** the guaranteed kill reward is now **12 Scrap** (was 25), and the common falling Scrap item is worth **5 Scrap** (was 10). Chance for the pickup remains 85%, score/score multipliers and the **300 Scrap boss defeat reward** are unchanged. This deliberately changes the economy; shop affordability should be retested across a whole 25-level run.
- **Mini-boss 360 spread:** primary avoidance gap half-angle reduced from 0.145 to **0.125 radians**; secondary from 0.12 to **0.105 radians**. Warning and player shield mechanics remain.
- **Life orbs:** city mini-boss lieutenants drop one collectible colored orb each: **red (level 5), blue (level 10), green (level 15), yellow (level 20)**. The four small circles in the HUD indicate which colors have been collected. When **all four different colors** have been physically collected in the same run, the player gets **+1 life**. The orb collection resets after the award, and again on a fresh run. Missing any orb means no extra-life reward. Orbs fall like other drops and can carry through the shop and next-level intro.
- **Zagreb level 25:** redesigned **large Zone Guardian** with **1,000 HP**, enlarged art/collision radius, and **two distinct shield rounds**. It starts with four shield hits to break through; at half HP (500 HP), it activates another four-hit shield, once. Shield attacks still consume incoming shots.
- **Final boss special: ADRIATIC STORM:** periodically telegraphs dangerous vertical firing lanes for **1.3 seconds**, leaving one open corridor roughly two lanes away from the player's location when warning starts. Then launches **three staggered volleys** in the blocked lanes, spaced by **0.62 seconds**. The safe lane is the same for each volley in that storm, so observation and prompt movement enable dodging. Visual warnings and distinct cyan projectiles mark the attack. Existing spin, spread and targeted attacks continue in the boss's rotation.
- **Scope:** the first four bosses remain normal city guardian mini-bosses. The level-25 guardian is the campaign-ending zone boss and does not spawn another collectible life orb.

### Suggested Godot QA
1. Complete a regular level; confirm approximately five silent seconds followed by 3.5 seconds of the city/LEVEL title (no countdown).
2. Verify each kill gives 12 Scrap and a collected standard Scrap item gives 5; confirm shop costs still feel attainable.
3. Test regular 360° avoidance lanes and R shield on city lieutenants.
4. Beat level 5/10/15/20 mini-bosses, collecting each colored orb; HUD must track red/blue/green/yellow, and +1 life happens **only after the fourth distinct orb is collected**. Miss one to verify no award. Ensure orbs persist through the shop.
5. On level 25, confirm **1,000 HP**, four shield hits at spawn, shield recharge at 500 HP, large collision target, and a real visible/adaptable safe corridor during Adriatic Storm.
6. Confirm the zone boss defeat still leads to the final shop, then CROATIA LIBERATED / persistent High Score.
Code changes are committed, but gameplay and Godot parser correctness still need in-editor testing.

## God Mode: one-shot test damage (latest)
- Press **O** to turn God Mode on or off. In addition to invulnerability, a **single player bullet hit** now defeats any regular enemy or mini-boss, including the level-25 final Zone Guardian with 1,000 HP.
- In God Mode, boss shield charges (including both rounds on level 25) are bypassed, so one projectile ends the encounter rather than consuming a shield first.
- Normal kill score, Scrap and life-orb drops still run; this is useful for checking the 25-level campaign quickly.
- The HUD reads **GOD MODE / ONE SHOT [O]** while active. When O is switched off, normal weapon damage, boss shield mechanics and life loss apply immediately.
- QA: Enable O on an armored crab and the level-5 boss, verify a single projectile kills each. Repeat against the level-25 Zone Guardian, confirm final shop/victory works. Turn O off and verify normal HP reductions and shields.
- This is a local development/testing shortcut, not intended for fair leaderboard scoring.

## F2 DEBUG LEVEL SELECT (latest)
- Press **F2** while playing, in level intermissions, boss introductions, the shop, Game Over, or victory to open a **debug level-selection screen**. Game simulation, projectiles, rewards and timers freeze while the selector is open.
- The selector displays all **25 levels in five city columns** (Zadar 1–5, Rijeka 6–10, Split 11–15, Osijek 16–20, Zagreb 21–25), highlights the selected stage and shows its city.
- **UP / DOWN**: move to the previous/next level. **LEFT / RIGHT**: move by five levels (previous/next city). **ENTER**: immediately launch the chosen level, with no preceding shop or intro delay. **ESC / F2**: close the selector and return to the previous state.
- When jumping, all current enemy waves, boss, projectiles and falling collectibles are cleared by the normal stage-start reset plus a debug cleanup. The player keeps the current speed/fire/weapon/shield upgrades and the **O God Mode** toggle. Lives are restored to at least three; score, Scrap, score multipliers, and four-orb progress reset.
- Stage jumps are flagged **DEBUG RUN**, and results from such a run **cannot enter the persistent Top 10 leaderboard**. Starting a fresh ordinary game from Game Over/victory resets the debug flag.
- This selector is meant only for local QA to quickly inspect late levels, milestone shops and the level-25 Zagreb guardian.

### Smoke test
1. Press F2 at level 1: all 25 stages and five city headings should appear; game simulation freezes.
2. Select level 25 using RIGHT/UP/DOWN and press ENTER: Zagreb level 25 begins immediately. Turn on O to one-shot the final guardian after its intro.
3. Press F2 while paused and close it via ESC: original paused state remains.
4. Press F2 in the shop and jump to level 6; shop should disappear and selected stage start instantly.
5. Finish a debug-jump run: no new Top 10 entry should be saved.
6. Restart normally after a completed run, and verify standard high-score qualification is available again.
Code was updated through GitHub; confirm operation in the Godot 4 editor before release.

## Campaign map and Zagreb unlock (latest)
- On a new normal game, show an **interactive, procedurally illustrated Balkan relief map** before Level 1. The artistic map includes the Adriatic Sea, stylized mountain contour lines and elevation bands, islands, and waterways. It is illustrative artwork, **not a georeferenced or accurately traced geographic/topographic dataset**.
- Player chooses the first city freely among **Zadar, Rijeka, Split and Osijek**. Click an available city's marker, or cycle choices with LEFT/RIGHT (UP/DOWN also works) and confirm with ENTER. **Zagreb has no marker or label and cannot be chosen** until the other four cities are liberated.
- Selection triggers a **six-second ship-flight animation** on the map: the ship travels from a staging position toward the chosen city. At destination, that city's five missions begin directly, no initial level countdown.
- Each city keeps its normal five missions and a guardian at the fifth. After defeating the guardian and leaving the upgrade shop with ENTER, return to the map to select any **remaining** city. Previously liberated cities display a green **[FREE]** label and cannot be selected again.
- After four different cities have been cleared and the fourth city's shop is exited, the map reveals **ZAGREB** for the first time, with **TIME TO FREE THE ZONE** prominently displayed. Select Zagreb and take a six-second flight to begin the final block, **levels 21–25**. Level 25 still concludes in the 1,000-HP Zone Guardian fight; the final shop leads to victory and High Scores.
- A dynamic **city_route** determines the order of four freely selected Croatian cities, then Zagreb. Global level numbers remain **1–25** in completion order; the HUD and title use the city name associated with that current block, regardless of selection order.
- The F2 debug selector remains available and uses a fixed canonical city ordering when jumping directly to a numbered test level; it is independent of the normal campaign map. Debug runs remain excluded from Top 10.
- Starting an entirely new run after Game Over or victory clears prior route progress and opens the campaign map again.

### QA
1. Start a new run: see relief map with four cities; **no Zagreb text or marker** anywhere.
2. Select Rijeka (or another non-default city) via mouse or arrow/ENTER: verify six-second map flight, then LEVEL 1–5 labeled RIJEKA.
3. Defeat boss in level 5: shop opens; ENTER returns to map, where Rijeka is marked free. Choose another available city, verify its five stages use levels 6–10 and keep purchased upgrades.
4. Repeat for the third and fourth cities, ensuring no city can be selected twice.
5. After fourth boss and shop: verify Zagreb marker is **unlocked and visible**, message **TIME TO FREE THE ZONE** appears. Select it, fly six seconds, play levels 21–25 and fight final Zone Guardian.
6. Check F2 debug level skipping, restart/game over reset, remaining drops after shop and Top 10 behavior.
Godot 4 runtime verification is required before release.

## Campaign flights, lieutenant orb collection and enemy-wave scale (latest)
- The **first flight** now starts at an **inland staging airbase** at the stylized map coordinate (492, 616), rather than off the western sea edge. The ship visibly flies **six seconds** toward the first selected city.
- **After liberating a city**, the player still visits the upgrade shop and returns to the map. Once they select the next available city, the six-second flight **starts at the previous liberated city's marker** and ends at the newly selected city. This applies to all four intermediate travel segments, including the final trip to Zagreb. The map highlights the current ship location when choosing the next city.
- All five cities and Zagreb's hidden-until-four-free unlock system remain unchanged, as do the city selection controls and F2 debug test menu.
- **City-lieutenant reward window:** after defeating the guardian at levels **5/10/15/20**, the game enters an **8-second COLLECT THE ORB** phase *before the shop opens*. The player can steer, fire, and physically collect the four-color orb and other drops. Any missed drop still follows the normal fall/offscreen rule; the timer advances independently, so the shop opens after the window ends even if some other rewards remain. P/TAB pause the collection period. The level-25 Zone Guardian still takes the player straight to the final shop on defeat.
- **Warblade-inspired enemy volume:** regular stages have *20, 20, 30, 30, 40* enemies within each 5-level city block, composed of respectively *2, 2, 3, 3, 4* successive mirrored formations of **10 enemies each**. The city guardian spawns after regular waves are defeated. **Level 25 is a boss-only mission**, consistent with Warblade's large boss at each twenty-fifth level.
- The wave composition, armored-crab front guards, weapon economy and combat controls are retained. The HUD now displays the correct dynamic **WAVE i/N**, including 0/0 on the standalone final boss level.

### Source fidelity note
Reference guides for Warblade document its four-stage mission structure, different formation types, and boss at every 25th level. They do **not** supply a complete independently verified exact number of small enemies on each stage of Classic mode. Warblade Time Trial descriptions commonly report 20–40 enemies, but Time Trial is not Classic. **The 20/20/30/30/40 curve above is therefore our own Warblade-inspired balance choice, not a claim to replicate Warblade Classic's exact level-by-level counts.** If verified Classic counts become available, replace the curve with those values.

### Godot QA
1. On a new run, select Split: verify the blue ship starts on inland terrain and flies from the staging airbase to Split for six seconds.
2. Complete Split's guardian and collect the orb during the full eight-second post-boss window; confirm the shop **does not** appear prematurely.
3. Leave the shop, select Rijeka on the map, and verify the ship flight starts at Split rather than the original airbase.
4. Test the 20/20/30/30/40 enemies-per-city progression and stage wave HUD; verify each subsequent wave arrives and the mission only advances after all scheduled enemies are defeated.
5. Unlock Zagreb after the fourth city and check the flight departs from that fourth city's location, then verify mission 25 launches the **1,000 HP final boss without regular enemy waves**.
6. Test F2 jumping, O God Mode one-shot, orb collection, score multipliers, shop upgrades and no frozen bullets in transitions.
Godot 4 parser/runtime verification is required after pulling this change.

## Final Zone Guardian: unique pre-fight warning and white orb (latest)
- **Level 25** uses its own three-line pre-boss announcement: **THE GUARDIAN HAS COME / TO DEAL WITH YOU / PERSONALLY**, replacing the ordinary lieutenant warning. It is reserved for the Zone Guardian; levels 5/10/15/20 still use the lieutenant announcement.
- Defeating the final boss now **always spawns a large, bright white collectible orb**, including when using **O GOD MODE / ONE SHOT**.
- Following the final boss's defeat, the player gets the same **eight-second, movement-enabled collection period** as after ordinary city bosses. The screen reads **ZONE GUARDIAN DEFEATED! / COLLECT THE WHITE ORB** before opening the final shop and victory flow.
- The fifth HUD indicator turns **white** only when the orb is physically collected; it resets when starting a new run or using F2 to test a different level.
- The **white trophy orb** is distinct from the four colored lieutenant life-orbs; it is not required for, and does not grant, the four-color extra life. Other core gameplay mechanics remain unchanged.

### QA
1. F2 → level 25: verify *THE GUARDIAN HAS COME TO DEAL WITH YOU PERSONALLY*, not lieutenant dialogue.
2. Use O to one-shot the final boss: its white orb must drop despite shield bypass.
3. Move into the orb during the eight-second reward period: the fifth HUD dot should become white, then the final shop should appear.
4. Verify levels 5/10/15/20 still use lieutenant text and drop red/blue/green/yellow orbs and do not trigger the white orb.
