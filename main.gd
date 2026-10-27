extends Node2D
## Adriatic Uprising - 25-level Croatia liberation campaign.
## All sprites are procedural. Godot 4.x / GDScript 2.0.

const W := 720.0
const H := 960.0
const PLAYER_Y := 840.0
const BASE_SPEED := 295.0
const SPEED_STEP := 48.0
const SPIN_WARNING := 1.5
const SPIN_PROJECTILES := 48
const SPIN_GAP_PRIMARY := 0.125 # Slightly narrower than the previous 0.145
const SPIN_GAP_SECONDARY := 0.105 # Slightly narrower than the previous 0.12
const BULLET_SPEED := 820.0
const MAX_LEVEL := 25
const CITY_NAMES := ["ZADAR", "RIJEKA", "SPLIT", "OSIJEK", "ZAGREB"]
const CITY_POINTS := [Vector2(260, 455), Vector2(238, 357), Vector2(298, 573), Vector2(514, 352), Vector2(376, 309)]
const CITY_FLIGHT_SECONDS := 6.0
const HIGH_SCORE_FILE := "user://highscores.cfg"
const HIGH_SCORE_LIMIT := 10
const ABILITY_COOLDOWN := 10.0 # Starts after the shield expires
# Lower regular-enemy aggression; preserve existing boss attack choreography.
const REGULAR_ENEMY_FIRE_MIN := 0.90
const REGULAR_ENEMY_PROJECTILE_SPEED_FACTOR := 0.80
const BOSS_RED_PROJECTILE_SPEED_FACTOR := 0.88
const WAVE_DELAY := 5.0
const LEVEL_TRANSITION_SECONDS := 5.0 # Silent pause before showing the title
const LEVEL_TITLE_SECONDS := 3.5 # Enemies begin after the title is shown
const BOSS_INTRO_SECONDS := 3.8
const STORM_WARNING_SECONDS := 1.3
const STORM_PULSE_INTERVAL := 0.62
const STORM_BULLET_SPACING := 16.0 # Dense wall: no accidental dodge gaps between bullets
const STORM_SAFE_HALF_WIDTH := 39.0 # One deliberate corridor, about 78px wide
const ORB_COLORS := [Color(1.0, 0.28, 0.3), Color(0.3, 0.68, 1.0), Color(0.38, 1.0, 0.52), Color(1.0, 0.78, 0.22)]
const ENEMIES_PER_WAVE := 10
# Warblade-inspired pacing, not verified exact Warblade Classic stage counts.
# Two waves per normal level. Each wave contains 10, 15 or 20 enemies,
# preserving the original 20/20/30/30/40 total for missions 1..5.
const ENEMY_TOTAL_BY_CITY_STAGE := [20, 20, 30, 30, 40]
const BOSS_REWARD_SECONDS := 8.0
const CAMPAIGN_BASE := Vector2(492.0, 616.0)
const DOUBLE_DROP_CHANCE := 0.12
const DOUBLE_DROP_PITY_KILLS := 18
const EXTRA_DOUBLE_DROP_CHANCE := 0.055
const TRIPLE_DROP_CHANCE := 0.022
const MAX_WEAPON_PICKUPS_ON_SCREEN := 3
const BINDINGS_FILE := "user://controls.cfg" # Legacy save path, supported for migration
const CONTROL_SAVE_FOLDER := "AdriaticUprising"
const BIND_ACTIONS := ["MOVE LEFT", "MOVE RIGHT", "FIRE", "SHIELD", "PAUSE", "SHIP STATUS"]
const BIND_DEFAULT := [KEY_A, KEY_D, KEY_SPACE, KEY_R, KEY_P, KEY_TAB]
const BIND_RESTRICTED := [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_F2, KEY_F3, KEY_O, KEY_M, KEY_BRACKETLEFT, KEY_BRACKETRIGHT, KEY_COMMA, KEY_PERIOD]
const MENU_ITEMS := ["CONTINUE", "NEW GAME", "HIGH SCORES", "OPTIONS", "EXIT"]
const CAMPAIGN_SAVE_FILE := "user://campaign_save.cfg"
const CAMPAIGN_SAVE_VERSION := 1

var font: Font

# Short synthesized arcade samples. Generated once on startup, never in _draw().
# Each sound has a small voice pool so fast shooting does not interrupt itself.
const SFX_SAMPLE_RATE := 22050
const SFX_VOICE_POOL := 4
var sfx_streams: Dictionary = {}
var sfx_voices: Dictionary = {}
var sfx_next_voice: Dictionary = {}

# Original looping chiptune themes, rendered once at startup.
# No internet downloads or copyrighted music samples are needed.
const MUSIC_SAMPLE_RATE := 11025
const MUSIC_STEP_SECONDS := 0.25
const MUSIC_STEPS := 32 # 8-second seamless loop, 120 BPM / 16th-note grid
var music_streams: Dictionary = {}
var music_player: AudioStreamPlayer
var current_music := ""
var music_enabled := true
var music_volume := 0.35 # Linear 0..1
var sfx_volume := 0.75
var sfx_base_db: Dictionary = {}
var stars: Array[Vector2] = []

# ZADAR / RIJEKA - ANIMATED BACKGROUNDS
var bg_scroll_far := 0.0
var bg_scroll_mid := 0.0
var bg_scroll_near := 0.0

const BG_SPEED_FAR := 22.0
const BG_SPEED_MID := 48.0
const BG_SPEED_NEAR := 90.0

# Rijeka has its own seamless scrolling periods (multiples of object spacing).
var rijeka_water_scroll := 0.0
var rijeka_dock_scroll := 0.0
var rijeka_detail_scroll := 0.0
const RIJEKA_DOCK_SPACING := 270.0
const RIJEKA_DOCK_COUNT := 6
const RIJEKA_DOCK_PERIOD := RIJEKA_DOCK_SPACING * RIJEKA_DOCK_COUNT

# Split waterfront: independent looping layers with tile-aligned wrapping.
var split_water_scroll := 0.0
var split_coast_scroll := 0.0
var split_foam_scroll := 0.0
const SPLIT_COAST_SPACING := 290.0
const SPLIT_COAST_TILES := 6
const SPLIT_COAST_PERIOD := SPLIT_COAST_SPACING * SPLIT_COAST_TILES

# Osijek: drifting Drava water, lush riverbanks and bridges, all on seamless loops.
var osijek_water_scroll := 0.0
var osijek_bank_scroll := 0.0
var osijek_ripple_scroll := 0.0
const OSIJEK_BANK_SPACING := 320.0
const OSIJEK_BANK_TILES := 6
const OSIJEK_BANK_PERIOD := OSIJEK_BANK_SPACING * OSIJEK_BANK_TILES

# Zagreb final zone: ruined urban blocks, tram rails and smouldering rooftops.
# A single 6-tile loop avoids the abrupt background jumps fixed in Zadar.
var zagreb_city_scroll := 0.0
var zagreb_detail_scroll := 0.0
const ZAGREB_BLOCK_SPACING := 300.0
const ZAGREB_BLOCK_COUNT := 6
const ZAGREB_BLOCK_PERIOD := ZAGREB_BLOCK_SPACING * ZAGREB_BLOCK_COUNT

var player_x := 360.0
var lives := 3
var score := 0
var scrap := 0
var level := 1
var damage_level := 0 # 0 = single, 3 = double, 6 = triple; purchased instantly
var rate_level := 0
var speed_level := 0
var ability_level := 1 # 1/2/3 = 2/4/6 seconds
var ability_time := 0.0
var ability_cooldown := 0.0
var state := "main_menu" # main_menu, menu_confirm_new, menu_options, menu_highscores, city_select, city_flight, playing, intermission, boss_intro, shop, gameover, victory
var main_menu_selection := 0
var pending_campaign_save: Dictionary = {}
var save_available := false
var options_menu_selection := 0
var binding_selection := 0
var binding_capture := false
var binding_notice := ""
var bindings: Array[int] = []
var menu_anim_time := 0.0
var city_route: Array[int] = []
var selected_city := 0
var city_flight_time := 0.0
var briefing_city_index := 0
var boss_reward_time := 0.0
var boss_intro_time := 0.0
var level_transition_time := 0.0
var show_stats_modal := false
var game_paused := false
var pause_screen := "menu" # menu, options, bindings, confirm
var pause_menu_selection := 0
var pause_confirm_yes := false
var god_mode := false # Local QA toggle (O key), blocks actual life and weapon loss
var debug_level_menu := false
var show_performance_stats := false # F3 toggles an FPS/process-time diagnostic overlay
var debug_selected_level := 1
var debug_run := false # Debug skips never qualify for persistent High Scores.
var high_scores: Array[Dictionary] = []
var score_name_field: LineEdit
var awaiting_score_name := false
var new_personal_record := false
var enemies: Array[Dictionary] = []
var player_bullets: Array[Dictionary] = [] # Each shot stores pos and velocity
var enemy_bullets: Array[Vector2] = []
var radial_bullets: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var explosions: Array[Dictionary] = []
var fire_clock := 0.0
var fire_held := false
var enemy_fire_clock := 1.0
var spawn_clock := 0.0
var invulnerable := 0.0
var drift := 1.0
var boss: Dictionary = {}
var boss_active := false
var boss_fire_clock := 0.0
var boss_phase := 1
var boss_shields := 2 # Visible shield layers: 2 for lieutenants, 4 for Zone Guardian
var boss_shield_hp := 0.0
var boss_shield_max_hp := 0.0
const BOSS_SHIELD_HP_RATIO := 0.70
var boss_shield_round := 1
var storm_warning_time := 0.0
var storm_pulses_remaining := 0
var storm_pulse_time := 0.0
var storm_safe_lane := 4
var storm_pending := false # Wait for existing red bullets to finish before starting Storm
var collected_orb_mask := 0
var campaign_orbs_found_mask := 0 # Historical orb pickups for the ending; not consumed for extra lives
var victory_show_scores := false
var white_orb_collected := false # Final Zagreb guardian trophy, independent of four life-orb colors
# Final boss dialogue is triggered only when the player physically collects the white orb.
# Stage 1: crew report. Stage 2: captain's reply.
var final_dialogue_stage := 0
var final_dialogue_time := 0.0
const FINAL_DIALOGUE_LINE_SECONDS := 4.5
var boss_attack_index := 0
var boss_warning_time := 0.0
var boss_warning_x := 360.0
var spin_countdown := 0.0
var spin_rotation := 0.0
var level_time := 0.0
var kills := 0
var total_kills := 0 # Campaign-wide, does not reset between missions
var single_shot_kills_since_drop := 0
var active_multipliers: Array[Dictionary] = [] # Each pickup has its own expiry
var target_kills := 0
var waves_spawned := 0
var wave_path_ids: Array[int] = []
var boss_pending := false
var pre_boss_shop := false


func update_background(delta: float) -> void:
	bg_scroll_far = fposmod(bg_scroll_far + BG_SPEED_FAR * delta, 10.0 * 120.0)
	bg_scroll_mid = fposmod(bg_scroll_mid + BG_SPEED_MID * delta, 6.0 * 245.0)
	bg_scroll_near = fposmod(bg_scroll_near + BG_SPEED_NEAR * delta, 16.0 * 85.0)


func draw_zadar_background() -> void:
	# Deep Adriatic sea
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.025, 0.14, 0.24))

	# Distant moving water
	for i in range(10):
		var y := fposmod(float(i) * 120.0 + bg_scroll_far + 120.0, 10.0 * 120.0) - 120.0
		draw_rect(Rect2(0.0, y, W, 52.0), Color(0.08, 0.26, 0.38, 0.34))

	# Islands moving at medium speed
	# Six islands ensure the left/right pattern repeats identically after a loop.
	# Wrap only while an island is entirely off-screen: no visible teleport.
	for i in range(6):
		var y := fposmod(float(i) * 245.0 + bg_scroll_mid + 245.0, 6.0 * 245.0) - 245.0
		# Do not allocate island polygons if the entire island is off-screen.
		if y > H + 10.0 or y + 110.0 < -10.0:
			continue
		var x := 105.0 if i % 2 == 0 else 440.0

		var shadow := PackedVector2Array([
			Vector2(x - 78.0, y + 40.0),
			Vector2(x - 25.0, y),
			Vector2(x + 60.0, y + 12.0),
			Vector2(x + 99.0, y + 65.0),
			Vector2(x + 35.0, y + 105.0),
			Vector2(x - 68.0, y + 89.0)
		])

		draw_colored_polygon(shadow, Color(0.08, 0.24, 0.22))

		var island := PackedVector2Array([
			Vector2(x - 65.0, y + 36.0),
			Vector2(x - 21.0, y + 10.0),
			Vector2(x + 51.0, y + 22.0),
			Vector2(x + 82.0, y + 60.0),
			Vector2(x + 27.0, y + 91.0),
			Vector2(x - 52.0, y + 75.0)
		])

		draw_colored_polygon(island, Color(0.29, 0.40, 0.25))

		draw_line(
			Vector2(x - 55.0, y + 78.0),
			Vector2(x + 25.0, y + 95.0),
			Color(0.78, 0.84, 0.62, 0.45),
			3.0,
			true
		)

	# Fast-moving foam and surface waves
	for i in range(16):
		var y := fposmod(float(i) * 85.0 + bg_scroll_near + 85.0, 16.0 * 85.0) - 85.0
		if y > H + 10.0 or y + 20.0 < -10.0:
			continue
		var x := 40.0 + float((i * 127) % 540)

		draw_line(
			Vector2(x, y),
			Vector2(x + 82.0, y + 7.0),
			Color(0.68, 0.94, 1.0, 0.38),
			2.0,
			true
		)

		draw_line(
			Vector2(x + 18.0, y + 14.0),
			Vector2(x + 55.0, y + 17.0),
			Color(0.75, 0.97, 1.0, 0.23),
			1.5,
			true
		)
func update_rijeka_background(delta: float) -> void:
	# Three independent seamless layers; never reset while a tile is on-screen.
	rijeka_water_scroll = fposmod(rijeka_water_scroll + 24.0 * delta, 12.0 * 100.0)
	rijeka_dock_scroll = fposmod(rijeka_dock_scroll + 46.0 * delta, RIJEKA_DOCK_PERIOD)
	rijeka_detail_scroll = fposmod(rijeka_detail_scroll + 83.0 * delta, 20.0 * 70.0)


func draw_rijeka_background() -> void:
	# Stylized Rijeka port: dark Kvarner sea, container docks, cranes and cargo ships.
	# All decoration is visual only; no collision or gameplay changes.
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.027, 0.12, 0.19))
	# Slow current and reflected harbor lights.
	for i in range(12):
		var y := fposmod(float(i) * 100.0 + rijeka_water_scroll + 100.0, 1200.0) - 100.0
		if y > H or y + 45.0 < 0.0:
			continue
		draw_rect(Rect2(0.0, y, W, 28.0), Color(0.10, 0.27, 0.35, 0.27))
		draw_line(Vector2(230.0, y + 17.0), Vector2(415.0, y + 20.0), Color(0.28, 0.52, 0.59, 0.24), 2.0)

	# Repeating 270-pixel dock tiles; one complete cycle is 1620px.
	for i in range(RIJEKA_DOCK_COUNT):
		var y := fposmod(float(i) * RIJEKA_DOCK_SPACING + rijeka_dock_scroll + RIJEKA_DOCK_SPACING, RIJEKA_DOCK_PERIOD) - RIJEKA_DOCK_SPACING
		if y > H + 25.0 or y + 205.0 < -25.0:
			continue
		var left_dock := i % 2 == 0
		var dock_x := 0.0 if left_dock else W - 154.0
		var rim_x := 154.0 if left_dock else W - 154.0
		# Concrete pier and edge shading.
		draw_rect(Rect2(dock_x + 4.0, y + 20.0, 150.0, 181.0), Color(0.013, 0.045, 0.06, 0.38))
		draw_rect(Rect2(dock_x, y + 14.0, 150.0, 174.0), Color(0.21, 0.27, 0.30))
		draw_rect(Rect2(rim_x - 7.0 if left_dock else rim_x, y + 14.0, 7.0, 174.0), Color(0.70, 0.65, 0.42))
		for stripe in range(4):
			var sy := y + 33.0 + float(stripe) * 39.0
			draw_line(Vector2(dock_x + 14.0, sy), Vector2(dock_x + 136.0, sy), Color(0.11, 0.17, 0.21, 0.55), 2.0)
		# Two containers with top lighting and different industrial colours.
		var containers := [Color(0.63, 0.29, 0.19), Color(0.23, 0.48, 0.57)]
		for j in range(2):
			var bx := dock_x + (18.0 if j == 0 else 72.0)
			var by := y + 44.0 + (46.0 if j == 1 else 0.0)
			var paint: Color = containers[(i + j) % 2]
			draw_rect(Rect2(bx + 4.0, by + 5.0, 47.0, 72.0), Color(0.02, 0.05, 0.07, 0.35))
			draw_rect(Rect2(bx, by, 47.0, 72.0), paint)
			draw_rect(Rect2(bx, by, 47.0, 6.0), paint.lightened(0.25))
			for line_index in range(4):
				var lx := bx + 8.0 + float(line_index) * 9.0
				draw_line(Vector2(lx, by + 11.0), Vector2(lx, by + 66.0), paint.darkened(0.35), 2.0)
		# Quayside loading crane reaching over the water.
		var crane_base_x := 131.0 if left_dock else W - 131.0
		var crane_top := Vector2(crane_base_x, y + 12.0)
		var over_water_x := crane_base_x + (115.0 if left_dock else -115.0)
		draw_line(Vector2(crane_base_x, y + 166.0), crane_top, Color(0.15, 0.19, 0.23), 11.0)
		draw_line(Vector2(crane_base_x, y + 166.0), crane_top, Color(0.82, 0.69, 0.31), 6.0)
		draw_line(crane_top, Vector2(over_water_x, y + 25.0), Color(0.87, 0.74, 0.34), 7.0)
		draw_line(Vector2(over_water_x, y + 25.0), Vector2(over_water_x, y + 100.0), Color(0.16, 0.24, 0.29), 2.0)
		draw_rect(Rect2(over_water_x - 14.0, y + 100.0, 28.0, 10.0), Color(0.78, 0.61, 0.28))
		# Long cargo vessel, separate from dock geometry but on same looping tile.
		if i % 3 != 1:
			var ship_x := 344.0 if left_dock else 355.0
			var ship_y := y + 58.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(ship_x - 38.0, ship_y - 15.0), Vector2(ship_x + 38.0, ship_y - 15.0),
				Vector2(ship_x + 43.0, ship_y + 95.0), Vector2(ship_x, ship_y + 116.0),
				Vector2(ship_x - 43.0, ship_y + 95.0)
			]), Color(0.055, 0.11, 0.15))
			draw_rect(Rect2(ship_x - 29.0, ship_y + 1.0, 58.0, 83.0), Color(0.31, 0.39, 0.40))
			for box_i in range(3):
				draw_rect(Rect2(ship_x - 23.0, ship_y + 7.0 + box_i * 23.0, 46.0, 18.0), Color(0.21, 0.44, 0.52) if box_i % 2 == 0 else Color(0.64, 0.33, 0.21))
			draw_rect(Rect2(ship_x - 16.0, ship_y + 89.0, 32.0, 16.0), Color(0.83, 0.86, 0.80))
			# Wake, visible along the sides of moving vessel.
			draw_line(Vector2(ship_x - 49.0, ship_y + 104.0), Vector2(ship_x - 53.0, ship_y + 133.0), Color(0.65, 0.89, 0.94, 0.43), 2.0)
			draw_line(Vector2(ship_x + 49.0, ship_y + 104.0), Vector2(ship_x + 53.0, ship_y + 133.0), Color(0.65, 0.89, 0.94, 0.43), 2.0)

	# Near-surface highlights; these scroll fastest but remain subtle.
	for i in range(20):
		var y := fposmod(float(i) * 70.0 + rijeka_detail_scroll + 70.0, 1400.0) - 70.0
		if y > H + 8.0 or y + 12.0 < -8.0:
			continue
		var x := 170.0 + float((i * 109) % 370)
		draw_line(Vector2(x, y), Vector2(x + 54.0, y + 3.0), Color(0.52, 0.77, 0.83, 0.28), 2.0, true)


func update_split_background(delta: float) -> void:
	# Periods are exact multiples of spacing, preventing visible seams.
	split_water_scroll = fposmod(split_water_scroll + 21.0 * delta, 1200.0)
	split_coast_scroll = fposmod(split_coast_scroll + 44.0 * delta, SPLIT_COAST_PERIOD)
	split_foam_scroll = fposmod(split_foam_scroll + 76.0 * delta, 1400.0)


func draw_split_background() -> void:
	# Split: sunlit Adriatic, limestone quay, terracotta roofs and the Riva.
	# Entirely decorative, with no physics or enemy logic changes.
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.035, 0.22, 0.30))
	# Deep-water bands and subtle distant reflections.
	for i in range(12):
		var y := fposmod(float(i) * 100.0 + split_water_scroll + 100.0, 1200.0) - 100.0
		if y > H or y + 48.0 < 0.0:
			continue
		draw_rect(Rect2(0.0, y, W, 34.0), Color(0.12, 0.43, 0.49, 0.15))
		draw_line(Vector2(232.0, y + 16.0), Vector2(500.0, y + 18.0), Color(0.49, 0.84, 0.80, 0.15), 2.0)

	# Alternating waterfront blocks; all props move in the same seamless tile.
	for i in range(SPLIT_COAST_TILES):
		var y := fposmod(float(i) * SPLIT_COAST_SPACING + split_coast_scroll + SPLIT_COAST_SPACING, SPLIT_COAST_PERIOD) - SPLIT_COAST_SPACING
		if y > H + 25.0 or y + 255.0 < -25.0:
			continue
		var left_side := i % 2 == 0
		var edge := 150.0 if left_side else W - 150.0
		var building_x := 0.0 if left_side else W - 142.0
		# Stone coast foundation, shadow on the water and bright quay border.
		draw_rect(Rect2(building_x + (7.0 if left_side else -7.0), y + 14.0, 142.0, 228.0), Color(0.0, 0.06, 0.08, 0.28))
		draw_rect(Rect2(building_x, y + 7.0, 142.0, 223.0), Color(0.52, 0.49, 0.39))
		draw_rect(Rect2(edge - 10.0 if left_side else edge, y + 7.0, 10.0, 223.0), Color(0.82, 0.78, 0.60))
		# Limestone paving joints along the coastal promenade.
		for stone in range(5):
			var sy := y + 24.0 + float(stone) * 44.0
			draw_line(Vector2(building_x + 7.0, sy), Vector2(building_x + 132.0, sy), Color(0.39, 0.38, 0.32, 0.45), 1.5)
		# Terracotta roofs and warm plaster facades viewed from above.
		for house in range(2):
			var hx := building_x + (17.0 if house == 0 else 70.0)
			var hy := y + 22.0 + float(house) * 91.0
			draw_rect(Rect2(hx + 5.0, hy + 7.0, 52.0, 78.0), Color(0.12, 0.13, 0.13, 0.35))
			draw_rect(Rect2(hx, hy, 52.0, 78.0), Color(0.75, 0.66, 0.50))
			draw_colored_polygon(PackedVector2Array([
				Vector2(hx - 4.0, hy + 11.0), Vector2(hx + 26.0, hy - 5.0),
				Vector2(hx + 56.0, hy + 11.0), Vector2(hx + 56.0, hy + 67.0),
				Vector2(hx + 26.0, hy + 84.0), Vector2(hx - 4.0, hy + 67.0)
			]), Color(0.69, 0.31, 0.22) if (i + house) % 2 == 0 else Color(0.77, 0.42, 0.28))
			draw_line(Vector2(hx + 26.0, hy - 3.0), Vector2(hx + 26.0, hy + 83.0), Color(0.96, 0.65, 0.42, 0.52), 2.0)
		# Narrow pier extending from the Riva into open water.
		var pier_x := edge if left_side else edge - 96.0
		draw_rect(Rect2(pier_x, y + 187.0, 96.0, 22.0), Color(0.73, 0.67, 0.53))
		draw_line(Vector2(pier_x, y + 190.0), Vector2(pier_x + 96.0, y + 190.0), Color(0.94, 0.85, 0.67), 3.0)
		# White moored sailing boat with soft shadow and an unobtrusive wake.
		if i % 3 != 1:
			var boat_x := 330.0 if left_side else 400.0
			var boat_y := y + 83.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(boat_x, boat_y - 44.0), Vector2(boat_x - 15.0, boat_y + 20.0),
				Vector2(boat_x, boat_y + 46.0), Vector2(boat_x + 15.0, boat_y + 20.0)
			]), Color(0.06, 0.15, 0.19, 0.28))
			draw_colored_polygon(PackedVector2Array([
				Vector2(boat_x, boat_y - 51.0), Vector2(boat_x - 12.0, boat_y + 14.0),
				Vector2(boat_x, boat_y + 38.0), Vector2(boat_x + 12.0, boat_y + 14.0)
			]), Color(0.88, 0.90, 0.80))
			draw_line(Vector2(boat_x, boat_y - 28.0), Vector2(boat_x, boat_y + 30.0), Color(0.25, 0.43, 0.48), 2.0)
			draw_line(Vector2(boat_x - 19.0, boat_y + 28.0), Vector2(boat_x - 24.0, boat_y + 57.0), Color(0.78, 0.96, 0.94, 0.32), 2.0)
			draw_line(Vector2(boat_x + 19.0, boat_y + 28.0), Vector2(boat_x + 24.0, boat_y + 57.0), Color(0.78, 0.96, 0.94, 0.32), 2.0)

	# Light foam bands float above the water, separate from the coastline.
	for i in range(20):
		var y := fposmod(float(i) * 70.0 + split_foam_scroll + 70.0, 1400.0) - 70.0
		if y > H + 10.0 or y + 16.0 < -10.0:
			continue
		var x := 178.0 + float((i * 137) % 355)
		draw_line(Vector2(x, y), Vector2(x + 66.0, y + 4.0), Color(0.78, 0.96, 0.89, 0.28), 2.0, true)
		draw_line(Vector2(x + 23.0, y + 11.0), Vector2(x + 51.0, y + 13.0), Color(0.91, 0.96, 0.84, 0.16), 1.0, true)


func update_osijek_background(delta: float) -> void:
	# Always wrap at an exact multiple of the element spacing: no visible snaps.
	osijek_water_scroll = fposmod(osijek_water_scroll + 19.0 * delta, 1200.0)
	osijek_bank_scroll = fposmod(osijek_bank_scroll + 43.0 * delta, OSIJEK_BANK_PERIOD)
	osijek_ripple_scroll = fposmod(osijek_ripple_scroll + 72.0 * delta, 1400.0)


func draw_osijek_background() -> void:
	# Osijek: Drava river, shaded green embankments, pedestrian bridges and foliage.
	# Pure background artwork: no added nodes, collisions or gameplay modifications.
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.055, 0.205, 0.225))
	# Wide calm-current patches, repeated seamlessly.
	for i in range(12):
		var y := fposmod(float(i) * 100.0 + osijek_water_scroll + 100.0, 1200.0) - 100.0
		if y > H + 5.0 or y + 54.0 < -5.0:
			continue
		draw_rect(Rect2(0.0, y, W, 48.0), Color(0.12, 0.35, 0.32, 0.18))
		draw_line(Vector2(208.0, y + 18.0), Vector2(512.0, y + 19.0), Color(0.46, 0.72, 0.58, 0.14), 2.0)
	# Each tile is 320px high, and all decorations for that tile move together.
	for i in range(OSIJEK_BANK_TILES):
		var y := fposmod(float(i) * OSIJEK_BANK_SPACING + osijek_bank_scroll + OSIJEK_BANK_SPACING, OSIJEK_BANK_PERIOD) - OSIJEK_BANK_SPACING
		if y > H + 30.0 or y + 320.0 < -30.0:
			continue
		var left := i % 2 == 0
		# Two river banks, with different shades for a little top-down depth.
		for side in range(2):
			var on_left := side == 0
			var edge_x := 139.0 if on_left else W - 139.0
			var land_x := 0.0 if on_left else W - 139.0
			draw_rect(Rect2(land_x, y + 8.0, 139.0, 300.0), Color(0.16, 0.31, 0.16))
			draw_rect(Rect2(land_x, y + 14.0, 139.0, 278.0), Color(0.22, 0.39, 0.19))
			draw_rect(Rect2(edge_x - 11.0 if on_left else edge_x, y + 8.0, 11.0, 300.0), Color(0.43, 0.49, 0.29))
			# Embankment walkway with paving, visible from above.
			var walk_x := 110.0 if on_left else W - 119.0
			draw_rect(Rect2(walk_x, y + 14.0, 9.0, 278.0), Color(0.64, 0.60, 0.46))
			for k in range(6):
				var tree_y := y + 37.0 + float(k) * 47.0
				var tree_x := 36.0 + float((i * 13 + k * 19) % 52) if on_left else W - 36.0 - float((i * 11 + k * 17) % 52)
				draw_circle(Vector2(tree_x + 5.0, tree_y + 7.0), 20.0, Color(0.035, 0.12, 0.07, 0.30))
				draw_circle(Vector2(tree_x, tree_y), 19.0, Color(0.09, 0.28, 0.12))
				draw_circle(Vector2(tree_x - 5.0, tree_y - 4.0), 12.0, Color(0.20, 0.47, 0.20))
		# A long bridge every second tile. It travels with this exact tile.
		if i % 2 == 0:
			var bridge_y := y + 184.0
			draw_rect(Rect2(103.0, bridge_y + 9.0, 514.0, 25.0), Color(0.02, 0.08, 0.09, 0.32))
			draw_rect(Rect2(103.0, bridge_y, 514.0, 20.0), Color(0.58, 0.61, 0.55))
			draw_line(Vector2(103.0, bridge_y + 2.0), Vector2(617.0, bridge_y + 2.0), Color(0.88, 0.85, 0.70), 3.0)
			draw_line(Vector2(103.0, bridge_y + 18.0), Vector2(617.0, bridge_y + 18.0), Color(0.24, 0.32, 0.31), 3.0)
			for j in range(9):
				var bx := 130.0 + float(j) * 56.0
				draw_line(Vector2(bx, bridge_y - 1.0), Vector2(bx, bridge_y + 19.0), Color(0.80, 0.82, 0.74), 2.0)
		else:
			# Reed beds along the river edge on tiles without a bridge.
			var reeds_x := 145.0 if left else W - 145.0
			for reed in range(7):
				var ry := y + 30.0 + float(reed) * 39.0
				draw_line(Vector2(reeds_x - 4.0, ry + 11.0), Vector2(reeds_x + 7.0, ry - 8.0), Color(0.47, 0.61, 0.26, 0.72), 2.0)
	# Subtle close water glints, scrolling independently from the bridges.
	for i in range(20):
		var y := fposmod(float(i) * 70.0 + osijek_ripple_scroll + 70.0, 1400.0) - 70.0
		if y > H + 10.0 or y + 12.0 < -10.0:
			continue
		var x := 178.0 + float((i * 127) % 340)
		draw_line(Vector2(x, y), Vector2(x + 52.0, y + 2.0), Color(0.61, 0.88, 0.73, 0.24), 2.0, true)


func update_zagreb_background(delta: float) -> void:
	# Both periodic layers wrap only after their full tile sets, never mid-scene.
	zagreb_city_scroll = fposmod(zagreb_city_scroll + 43.0 * delta, ZAGREB_BLOCK_PERIOD)
	zagreb_detail_scroll = fposmod(zagreb_detail_scroll + 24.0 * delta, 1440.0)


func draw_zagreb_background() -> void:
	# Zagreb during the invasion: dark asphalt, tram tracks, damaged rooftops,
	# courtyard trees, distant smoke and a handful of warning beacons.
	# Presentation only. No new physics objects or gameplay entities.
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.085, 0.095, 0.13))
	# Central boulevard and rails, designed to scroll smoothly under the ship.
	draw_rect(Rect2(255.0, 0.0, 210.0, H), Color(0.14, 0.155, 0.175))
	draw_rect(Rect2(261.0, 0.0, 5.0, H), Color(0.29, 0.30, 0.30))
	draw_rect(Rect2(454.0, 0.0, 5.0, H), Color(0.29, 0.30, 0.30))
	draw_line(Vector2(322.0, 0.0), Vector2(322.0, H), Color(0.47, 0.45, 0.35, 0.65), 2.0)
	draw_line(Vector2(397.0, 0.0), Vector2(397.0, H), Color(0.47, 0.45, 0.35, 0.65), 2.0)
	# Distant shifting clouds / low-contrast smoke shadows.
	for cloud in range(12):
		var cloud_y := fposmod(float(cloud) * 120.0 + zagreb_detail_scroll + 120.0, 1440.0) - 120.0
		if cloud_y > H + 65.0 or cloud_y < -90.0:
			continue
		var cloud_x := 60.0 + float((cloud * 173) % 585)
		draw_circle(Vector2(cloud_x, cloud_y), 50.0, Color(0.23, 0.24, 0.28, 0.08))
		draw_circle(Vector2(cloud_x + 28.0, cloud_y + 18.0), 39.0, Color(0.27, 0.26, 0.29, 0.08))
	# Street furniture and left/right masonry repeat as a complete 1800px cycle.
	for block in range(ZAGREB_BLOCK_COUNT):
		var block_y := fposmod(float(block) * ZAGREB_BLOCK_SPACING + zagreb_city_scroll + ZAGREB_BLOCK_SPACING, ZAGREB_BLOCK_PERIOD) - ZAGREB_BLOCK_SPACING
		if block_y > H + 30.0 or block_y + ZAGREB_BLOCK_SPACING < -30.0:
			continue
		for side in range(2):
			var on_left := side == 0
			var building_x := 18.0 if on_left else 483.0
			var facade := Color(0.30, 0.31, 0.33) if block % 2 == 0 else Color(0.35, 0.29, 0.28)
			var roof := Color(0.47, 0.24, 0.21) if block % 3 != 0 else Color(0.31, 0.34, 0.36)
			# Offset shadow provides depth without sprites or per-frame allocation of textures.
			draw_rect(Rect2(building_x + 12.0, block_y + 31.0, 221.0, 231.0), Color(0.015, 0.02, 0.035, 0.42))
			draw_rect(Rect2(building_x, block_y + 20.0, 218.0, 227.0), facade)
			draw_rect(Rect2(building_x + 9.0, block_y + 28.0, 198.0, 210.0), roof)
			draw_rect(Rect2(building_x + 21.0, block_y + 42.0, 173.0, 180.0), Color(0.38, 0.21, 0.20, 0.65))
			for window_row in range(4):
				for window_column in range(3):
					var win_x := building_x + 38.0 + float(window_column) * 55.0
					var win_y := block_y + 52.0 + float(window_row) * 42.0
					var broken := (block + side + window_row * 3 + window_column) % 5 == 0
					draw_rect(Rect2(win_x, win_y, 16.0, 20.0), Color(0.065, 0.10, 0.13) if broken else Color(0.57, 0.58, 0.53))
			# Scorched roof corner and exposed beams; all fixed to the same tile.
			if (block + side) % 3 == 0:
				var burn_x := building_x + (151.0 if on_left else 36.0)
				draw_colored_polygon(PackedVector2Array([
					Vector2(burn_x, block_y + 34.0),
					Vector2(burn_x + 39.0, block_y + 43.0),
					Vector2(burn_x + 31.0, block_y + 79.0),
					Vector2(burn_x - 5.0, block_y + 70.0)
				]), Color(0.08, 0.075, 0.085))
				draw_line(Vector2(burn_x + 6.0, block_y + 48.0), Vector2(burn_x + 25.0, block_y + 69.0), Color(0.63, 0.31, 0.16), 3.0)
			else:
				# Small rooftop planter for depth / variation.
				draw_rect(Rect2(building_x + 86.0, block_y + 103.0, 43.0, 35.0), Color(0.18, 0.25, 0.20))
				draw_circle(Vector2(building_x + 108.0, block_y + 118.0), 14.0, Color(0.20, 0.34, 0.19))
		# Road crossing and zebra stripes are attached to the same tile period.
		var crossing_y := block_y + 270.0
		draw_rect(Rect2(265.0, crossing_y - 2.0, 190.0, 4.0), Color(0.24, 0.25, 0.25))
		for stripe in range(7):
			draw_rect(Rect2(282.0 + float(stripe) * 24.0, crossing_y + 6.0, 12.0, 27.0), Color(0.70, 0.67, 0.55, 0.50))
		# Tram rail sleepers / paving marks.
		for sleeper in range(5):
			var sleeper_y := block_y + 25.0 + float(sleeper) * 55.0
			draw_rect(Rect2(318.0, sleeper_y, 84.0, 4.0), Color(0.37, 0.35, 0.33, 0.48))
		# A warning lamp flashes gently on a building roof, not on the HUD.
		if block % 2 == 0:
			var beacon_x := 223.0 if block % 4 == 0 else 496.0
			var beacon_y := block_y + 26.0
			var brightness := 0.50 + 0.38 * sin(level_time * 4.2 + float(block))
			draw_circle(Vector2(beacon_x, beacon_y), 5.0, Color(1.0, 0.22, 0.13, brightness))


func draw_player_ship_25d(pos: Vector2) -> void:
	
	# Shadow
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(5, -24),
		pos + Vector2(-30, 23),
		pos + Vector2(5, 17),
		pos + Vector2(35, 23)
	]), Color(0.0, 0.0, 0.0, 0.32))

	# Dark lower hull
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -30),
		pos + Vector2(-18, 8),
		pos + Vector2(-10, 20),
		pos + Vector2(0, 12),
		pos + Vector2(10, 20),
		pos + Vector2(18, 8)
	]), Color(0.08, 0.24, 0.42))

	# Main blue hull
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -34),
		pos + Vector2(-20, 10),
		pos + Vector2(-9, 18),
		pos + Vector2(0, 10),
		pos + Vector2(9, 18),
		pos + Vector2(20, 10)
	]), Color(0.30, 0.78, 1.0))

	# Left wing
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-20, 8),
		pos + Vector2(-36, 25),
		pos + Vector2(-11, 15)
	]), Color(0.18, 0.56, 0.90))

	# Right wing
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(20, 8),
		pos + Vector2(36, 25),
		pos + Vector2(11, 15)
	]), Color(0.18, 0.56, 0.90))

	# Cockpit
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -10),
		pos + Vector2(-8, 4),
		pos + Vector2(0, 10),
		pos + Vector2(8, 4)
	]), Color(0.10, 0.23, 0.45))

	draw_circle(pos, 5.5, Color(0.72, 0.95, 1.0))

	# Metallic highlights
	draw_line(
		pos + Vector2(0, -28),
		pos + Vector2(0, 12),
		Color(0.88, 1.0, 1.0, 0.55),
		2.0,
		true
	)

	# Animated engine flames
	var flame_shift := sin(Time.get_ticks_msec() * 0.02) * 2.0

	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-7, 18),
		pos + Vector2(0, 32 + flame_shift),
		pos + Vector2(7, 18)
	]), Color(1.0, 0.72, 0.22, 0.95))

	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-4, 18),
		pos + Vector2(0, 26 + flame_shift * 0.7),
		pos + Vector2(4, 18)
	]), Color(1.0, 0.93, 0.45, 0.95))

# ENEMY 2.5D VISUALS - presentation only; no gameplay or hitbox changes.
# The colors, highlights and cast shadows simulate depth in our Node2D game.
func draw_jellyfish_25d(pos: Vector2) -> void:
	var sway := sin(level_time * 3.5 + pos.x * 0.012)
	var pulse := sin(level_time * 4.0 + pos.x * 0.008)
	# Soft water shadow, then animated translucent tentacles behind the bell.
	draw_circle(pos + Vector2(7.0, 12.0), 23.0, Color(0.0, 0.05, 0.11, 0.23))
	for t in range(-2, 3):
		var root := pos + Vector2(float(t) * 8.0, 4.0)
		var tip := pos + Vector2(float(t) * 8.0 + sway * (5.0 + absf(float(t)) * 2.0), 34.0 + pulse * 2.0)
		var mid := (root + tip) * 0.5 + Vector2(-sway * 4.0, 0.0)
		draw_line(root, mid, Color(0.11, 0.45, 0.68, 0.85), 6.0, true)
		draw_line(mid, tip, Color(0.49, 0.91, 1.0, 0.85), 3.0, true)
		draw_circle(tip, 2.2, Color(0.65, 0.98, 1.0, 0.78))
	# Layered dome suggests glasslike volume; size stays near old collision area.
	var crown := pos + Vector2(0.0, -7.0 + pulse * 1.5)
	draw_circle(crown + Vector2(1.5, 3.5), 24.0, Color(0.06, 0.30, 0.53, 0.95))
	draw_circle(crown, 22.0, Color(0.24, 0.67, 0.92, 0.94))
	draw_circle(crown + Vector2(-5.0, -6.0), 14.0, Color(0.58, 0.88, 1.0, 0.75))
	draw_circle(crown + Vector2(-9.0, -11.0), 5.0, Color(0.91, 1.0, 1.0, 0.84))
	draw_arc(crown, 23.0, PI + 0.12, TAU - 0.12, 24, Color(0.76, 0.97, 1.0, 0.95), 2.8, true)
	draw_line(pos + Vector2(-17.0, 8.0), pos + Vector2(18.0, 8.0), Color(0.78, 0.96, 1.0, 0.72), 3.0, true)


func draw_crab_25d(pos: Vector2) -> void:
	var claw_motion := sin(level_time * 4.8 + pos.x * 0.015) * 3.0
	# Offset shadow and rear legs produce a raised armored body.
	draw_circle(pos + Vector2(5.0, 9.0), 26.0, Color(0.0, 0.03, 0.07, 0.35))
	for side in [-1.0, 1.0]:
		for n in range(3):
			var y := -11.0 + float(n) * 12.0
			draw_line(pos + Vector2(side * 15.0, y), pos + Vector2(side * 28.0, y + 9.0), Color(0.34, 0.08, 0.10), 6.0, true)
		# Red armored pincers and their contrasting reflective edges.
		var claw := pos + Vector2(side * 27.0, 5.0 + claw_motion * side)
		draw_line(pos + Vector2(side * 15.0, 6.0), claw, Color(0.55, 0.12, 0.11), 9.0, true)
		draw_circle(claw, 10.0, Color(0.59, 0.11, 0.12))
		draw_circle(claw + Vector2(-3.0, -4.0), 6.5, Color(1.0, 0.44, 0.25))
		draw_line(claw + Vector2(0.0, 1.0), claw + Vector2(side * 8.0, 10.0), Color(1.0, 0.57, 0.36), 4.0, true)
	# Carapace has a shaded rim, elevated top and chitin plates.
	draw_circle(pos + Vector2(1.5, 4.0), 23.0, Color(0.39, 0.07, 0.12))
	draw_circle(pos + Vector2(0.0, -1.0), 21.0, Color(0.81, 0.20, 0.16))
	draw_circle(pos + Vector2(-5.0, -7.0), 13.0, Color(1.0, 0.43, 0.28))
	draw_arc(pos + Vector2(0.0, -1.0), 20.0, PI + 0.38, TAU - 0.42, 22, Color(1.0, 0.68, 0.43), 3.0, true)
	draw_line(pos + Vector2(-16.0, 7.0), pos + Vector2(16.0, 7.0), Color(0.49, 0.08, 0.12), 4.0, true)
	draw_circle(pos + Vector2(-7.0, -4.0), 2.2, Color(0.23, 0.07, 0.12))
	draw_circle(pos + Vector2(7.0, -4.0), 2.2, Color(0.23, 0.07, 0.12))


func draw_eel_25d(pos: Vector2) -> void:
	var wiggle := sin(level_time * 7.5 + pos.x * 0.015) * 6.0
	var tail := pos + Vector2(-22.0, 18.0 + wiggle)
	var spine := pos + Vector2(-7.0, 13.0 - wiggle * 0.35)
	var middle := pos + Vector2(7.0, 3.0 + wiggle * 0.45)
	var head := pos + Vector2(13.0, -17.0)
	# Consistent 2D depth through a darker offset silhouette.
	var shade := Vector2(5.0, 6.0)
	draw_line(tail + shade, spine + shade, Color(0.02, 0.15, 0.11, 0.38), 24.0, true)
	draw_line(spine + shade, middle + shade, Color(0.02, 0.15, 0.11, 0.38), 24.0, true)
	draw_line(middle + shade, head + shade, Color(0.02, 0.15, 0.11, 0.38), 23.0, true)
	for segment in range(3):
		var a := tail if segment == 0 else (spine if segment == 1 else middle)
		var b := spine if segment == 0 else (middle if segment == 1 else head)
		draw_line(a, b, Color(0.13, 0.35, 0.09), 21.0, true)
		draw_line(a + Vector2(-3.0, -3.0), b + Vector2(-3.0, -3.0), Color(0.48, 0.91, 0.18), 13.0, true)
		draw_line(a + Vector2(-5.0, -5.0), b + Vector2(-5.0, -5.0), Color(0.83, 1.0, 0.38, 0.68), 3.0, true)
	draw_circle(head, 12.0, Color(0.30, 0.68, 0.12))
	draw_circle(head + Vector2(-3.0, -4.0), 8.0, Color(0.71, 1.0, 0.23))
	draw_circle(head + Vector2(-4.0, -5.0), 2.8, Color.WHITE)
	draw_circle(head + Vector2(-4.0, -5.0), 1.3, Color(0.08, 0.17, 0.06))
	# Short electrical arcs flicker without adding projectiles or damage.
	var spark := sin(level_time * 11.0 + pos.x * 0.04)
	if spark > 0.55:
		draw_polyline(PackedVector2Array([
			middle + Vector2(-8.0, -13.0),
			middle + Vector2(-1.0, -19.0),
			middle + Vector2(4.0, -13.0),
			middle + Vector2(10.0, -18.0)
		]), Color(0.77, 1.0, 0.49, 0.88), 2.0, true)



# Presentation-only 2.5D boss artwork. Boss movement, shield charges, hitboxes,
# projectile patterns, HP and rewards stay in the unchanged gameplay functions.
func draw_boss_25d(pos: Vector2) -> void:
	if level == MAX_LEVEL:
		draw_zone_guardian_25d(pos)
	else:
		draw_city_lieutenant_25d(pos, city_name())


func rotate_polygon_points(points: Array[Vector2], center: Vector2, angle: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(center + (point - center).rotated(angle))
	return result


func draw_city_lieutenant_25d(pos: Vector2, city: String) -> void:
	# Four distinct silhouettes and color palettes without any gameplay changes.
	var shell := Color(0.12, 0.48, 0.51)
	var rim := Color(0.37, 0.92, 0.85)
	var armor := Color(0.17, 0.31, 0.39)
	match city:
		"ZADAR":
			shell = Color(0.14, 0.58, 0.61)
			rim = Color(0.53, 0.96, 0.93)
			armor = Color(0.10, 0.30, 0.42)
		"RIJEKA":
			shell = Color(0.37, 0.48, 0.68)
			rim = Color(0.69, 0.84, 1.0)
			armor = Color(0.17, 0.24, 0.40)
		"SPLIT":
			shell = Color(0.70, 0.38, 0.22)
			rim = Color(1.0, 0.76, 0.40)
			armor = Color(0.36, 0.19, 0.17)
		"OSIJEK":
			shell = Color(0.32, 0.59, 0.23)
			rim = Color(0.71, 0.96, 0.43)
			armor = Color(0.19, 0.32, 0.22)
	# Diffuse ground shadow and thick faceted armored shell.
	draw_circle(pos + Vector2(7.0, 13.0), 67.0, Color(0.0, 0.02, 0.06, 0.34))
	draw_circle(pos + Vector2(0.0, 6.0), 65.0, armor.darkened(0.30))
	draw_circle(pos, 60.0, shell)
	draw_arc(pos, 61.0, PI * 1.1, TAU * 0.95, 28, rim, 5.0)
	# Four outer armored flippers (different shape per lieutenant).
	for side in [-1.0, 1.0]:
		var blade := PackedVector2Array([
			pos + Vector2(side * 42.0, -14.0),
			pos + Vector2(side * 83.0, -40.0),
			pos + Vector2(side * 74.0, 15.0),
			pos + Vector2(side * 44.0, 34.0)
		])
		draw_colored_polygon(blade, armor)
		draw_line(pos + Vector2(side * 47.0, -10.0), pos + Vector2(side * 76.0, -30.0), rim, 3.0, true)
	# Visible pseudo-3D plates around the core.
	for plate in range(6):
		var angle := float(plate) * TAU / 6.0 + spin_rotation * 0.16
		var offset := Vector2(cos(angle), sin(angle)) * 43.0
		draw_circle(pos + offset + Vector2(2, 5), 14.0, armor.darkened(0.37))
		draw_circle(pos + offset, 12.0, armor)
		draw_circle(pos + offset + Vector2(-3, -4), 5.0, rim.darkened(0.12))
	# Each city has a small unmistakable accent.
	match city:
		"ZADAR":
			for spike in [-1.0, 1.0]:
				draw_line(pos + Vector2(spike * 16.0, -31.0), pos + Vector2(spike * 25.0, -79.0), rim, 8.0, true)
		"RIJEKA":
			for fin in [-1.0, 1.0]:
				draw_line(pos + Vector2(fin * 24.0, 19.0), pos + Vector2(fin * 43.0, 70.0), rim, 8.0, true)
		"SPLIT":
			draw_arc(pos, 74.0, 0.2, PI - 0.2, 22, rim, 5.0)
		"OSIJEK":
			for horn in [-1.0, 1.0]:
				draw_line(pos + Vector2(horn * 26.0, -29.0), pos + Vector2(horn * 44.0, -66.0), rim, 8.0, true)
	# Existing shield state drives only the light color, not collision logic.
	var core_light := Color(0.26, 0.83, 1.0) if boss_shields > 0 else Color(1.0, 0.29, 0.30)
	draw_circle(pos + Vector2(3, 5), 26.0, armor.darkened(0.5))
	draw_circle(pos, 23.0, core_light)
	draw_circle(pos + Vector2(-7, -8), 8.0, Color(1.0, 1.0, 1.0, 0.72))
	# Every shield hit strips one visible shell from the lieutenant.
	# Two rings correspond to the two existing shield hit points.
	for shield_layer in range(boss_shields):
		var layer_radius := 70.0 + float(shield_layer) * 7.0
		var layer_alpha := 0.92 - float(shield_layer) * 0.17
		draw_arc(pos, layer_radius, 0.0, TAU, 48, Color(0.32, 0.89, 1.0, layer_alpha), 3.5)


func draw_zone_guardian_25d(pos: Vector2) -> void:
	# Large final boss, visually distinct from the four city lieutenants.
	# Main silhouette stays inside the existing ~108 px projectile hit radius
	# except for decorative outer armor; physics remains unchanged.
	var dark := Color(0.07, 0.13, 0.23)
	var steel := Color(0.17, 0.38, 0.51)
	var glow := Color(0.38, 0.91, 1.0)
	# Before Adriatic Storm the Guardian now performs a full in-place spin while
	# the red warning orb flashes exactly three times.
	var pre_attack_spin := level == MAX_LEVEL and storm_warning_time > 0.0 and storm_pulses_remaining > 0
	var body_rotation := 0.0
	var flash_on := false
	if pre_attack_spin:
		var storm_progress := clampf(1.0 - storm_warning_time / STORM_WARNING_SECONDS, 0.0, 1.0)
		body_rotation = TAU * storm_progress
		flash_on = int(floor(storm_progress * 6.0)) % 2 == 0
	draw_circle(pos + Vector2(9, 15), 111.0, Color(0.0, 0.02, 0.08, 0.37))
	draw_circle(pos, 108.0, dark)
	draw_arc(pos, 107.0, 0.0, TAU, 48, glow.darkened(0.25), 8.0)
	for segment in range(8):
		var angle := float(segment) * TAU / 8.0 + spin_rotation * 0.19 + body_rotation
		var direction := Vector2(cos(angle), sin(angle))
		var anchor := pos + direction * 79.0
		draw_line(pos + direction * 47.0, anchor, steel, 17.0, true)
		draw_circle(anchor + Vector2(3.0, 5.0), 18.0, dark)
		draw_circle(anchor, 15.0, steel)
		draw_circle(anchor + Vector2(-4.0, -5.0), 6.0, glow)
	# Angular inner hull, layered to suggest height and machinery.
	var hull_outer: Array[Vector2] = [
		pos + Vector2(0, -69), pos + Vector2(-65, -10),
		pos + Vector2(-48, 47), pos + Vector2(0, 70),
		pos + Vector2(48, 47), pos + Vector2(65, -10)
	]
	draw_colored_polygon(rotate_polygon_points(hull_outer, pos, body_rotation), steel)
	var hull_inner: Array[Vector2] = [
		pos + Vector2(0, -57), pos + Vector2(-40, -8),
		pos + Vector2(-30, 34), pos + Vector2(0, 49),
		pos + Vector2(30, 34), pos + Vector2(40, -8)
	]
	draw_colored_polygon(rotate_polygon_points(hull_inner, pos, body_rotation), Color(0.11, 0.25, 0.39))
	draw_line(pos + Vector2(-33, -12).rotated(body_rotation), pos + Vector2(0, -48).rotated(body_rotation), glow, 4.0, true)
	draw_line(pos + Vector2(33, -12).rotated(body_rotation), pos + Vector2(0, -48).rotated(body_rotation), glow, 4.0, true)
	var core_glow := glow if boss_shields > 0 else Color(1.0, 0.35, 0.40)
	draw_circle(pos + Vector2(4, 7).rotated(body_rotation), 32.0, dark)
	draw_circle(pos, 29.0, core_glow)
	draw_circle(pos + Vector2(-9, -10).rotated(body_rotation), 11.0, Color(0.92, 0.99, 1.0))
	# Red warning orb used to telegraph Adriatic Storm.
	var orb_pos := pos + Vector2(0.0, -82.0).rotated(body_rotation)
	var orb_shadow := pos + Vector2(3.0, -77.0).rotated(body_rotation)
	var orb_color := Color(0.62, 0.12, 0.18)
	var orb_halo := Color(0.95, 0.12, 0.18, 0.16)
	if pre_attack_spin:
		orb_color = Color(1.0, 0.15, 0.18) if flash_on else Color(0.68, 0.12, 0.18)
		orb_halo = Color(1.0, 0.2, 0.24, 0.42 if flash_on else 0.18)
	draw_circle(orb_shadow, 13.0, dark)
	if pre_attack_spin:
		draw_circle(orb_pos, 24.0, orb_halo)
	draw_circle(orb_pos, 10.0, orb_color)
	draw_circle(orb_pos + Vector2(-3.0, -4.0).rotated(body_rotation), 3.5, Color(1.0, 0.82, 0.82, 0.85))
	# Each of the four shield hit points corresponds to a removable energy layer.
	# Second shield phase adds the four rings back automatically at half HP.
	for shield_layer in range(boss_shields):
		var layer_radius := 113.0 + float(shield_layer) * 7.0
		var layer_alpha := 0.90 - float(shield_layer) * 0.13
		draw_arc(pos, layer_radius, 0.0, TAU, 64, Color(0.36, 0.88, 1.0, layer_alpha), 3.5)

func city_name() -> String:
	var slot := clampi(int((level - 1) / 5), 0, 4)
	return CITY_NAMES[city_route[slot]] if slot < city_route.size() else CITY_NAMES[slot]

func city_mission() -> int:
	return ((level - 1) % 5) + 1

func waves_for_level() -> int:
	if level == MAX_LEVEL:
		return 0 # The final Zone Guardian is a standalone boss fight.
	return 2

func enemies_per_wave() -> int:
	if level == MAX_LEVEL:
		return 0
	return int(ENEMY_TOTAL_BY_CITY_STAGE[city_mission() - 1] / 2)

func make_arcade_sound(kind: String) -> AudioStreamWAV:
	# PCM16 mono, entirely offline generated. No external sound files required.
	var duration := 0.095
	var start_hz := 680.0
	var end_hz := 250.0
	var amp := 0.29
	match kind:
		"shoot":
			duration = 0.075
			start_hz = 1100.0
			end_hz = 410.0
			amp = 0.21
		"double_shoot":
			duration = 0.11
			start_hz = 990.0
			end_hz = 365.0
			amp = 0.19
		"triple_shoot":
			duration = 0.145
			start_hz = 835.0
			end_hz = 215.0
			amp = 0.21
		"shield_hit":
			duration = 0.11
			start_hz = 1450.0
			end_hz = 620.0
			amp = 0.25
		"storm_charge":
			duration = 1.28
			start_hz = 95.0
			end_hz = 320.0
			amp = 0.30
		"hit":
			duration = 0.065
			start_hz = 340.0
			end_hz = 120.0
			amp = 0.19
		"destroy":
			duration = 0.19
			start_hz = 190.0
			end_hz = 45.0
			amp = 0.32
		"pickup":
			duration = 0.16
			start_hz = 550.0
			end_hz = 1100.0
			amp = 0.20
		"hurt":
			duration = 0.24
			start_hz = 320.0
			end_hz = 65.0
			amp = 0.36
		"boss":
			duration = 0.38
			start_hz = 270.0
			end_hz = 48.0
			amp = 0.38
	var frames := int(duration * float(SFX_SAMPLE_RATE))
	var pcm := PackedByteArray()
	pcm.resize(frames * 2)
	var phase := 0.0
	for i in range(frames):
		var t := float(i) / float(frames)
		var hz := lerpf(start_hz, end_hz, t)
		phase += TAU * hz / float(SFX_SAMPLE_RATE)
		var envelope := pow(1.0 - t, 1.8) * minf(1.0, t * 45.0)
		var wave := sin(phase)
		if kind == "double_shoot":
			# Two rapid retro chirps in a single reusable audio sample.
			wave = sin(phase * (1.0 if t < 0.50 else 1.32))
			envelope *= 0.50 + 0.50 * absf(sin(t * TAU * 2.0))
		elif kind == "triple_shoot":
			wave = 0.62 * sin(phase) + 0.38 * sin(phase * 1.95)
			envelope *= 0.48 + 0.52 * absf(sin(t * TAU * 3.0))
		elif kind == "shield_hit":
			wave = 0.52 * sin(phase) + 0.48 * sin(phase * 2.71)
		elif kind == "storm_charge":
			# Three bright pulses over a rising low-frequency charging hum.
			wave = 0.72 * sin(phase) + 0.28 * sin(phase * 3.0)
			envelope = (0.22 + 0.78 * t) * (0.40 + 0.60 * pow(absf(sin(t * TAU * 3.0)), 8.0))
		elif kind == "destroy" or kind == "boss" or kind == "hurt":
			wave = 0.65 * sin(phase) + 0.35 * sin(phase * 2.37)
		var sample := clampi(int(wave * envelope * amp * 32767.0), -32767, 32767)
		pcm.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SFX_SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	return stream


func music_note_hz(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)


func generate_retro_music(theme: String) -> AudioStreamWAV:
	# Three original 8-second chiptune arrangements at 120 BPM.
	# Frequencies and envelopes are sampled into 16-bit WAV once, not per frame.
	var lead: Array[int] = []
	var bass: Array[int] = []
	var tempo_amp := 0.24
	match theme:
		"menu":
			lead = [72, -1, 76, 79, 76, -1, 74, 72, 71, -1, 74, 76, 79, -1, 76, 74,
				72, -1, 76, 79, 83, -1, 79, 76, 74, -1, 72, 74, 76, -1, 71, -1]
			bass = [45, 45, 48, 48, 43, 43, 41, 41]
		"stage":
			lead = [76, -1, 79, 83, 81, -1, 79, 76, 74, -1, 76, 79, 76, -1, 72, 74,
				76, -1, 79, 83, 86, -1, 83, 79, 81, -1, 79, 76, 74, 76, 72, -1]
			bass = [40, 40, 43, 40, 45, 45, 43, 40]
		"boss":
			lead = [64, 67, 70, -1, 64, 67, 72, 70, 63, 66, 69, -1, 63, 66, 73, 69,
				64, 67, 70, 76, 75, 70, 67, -1, 63, 66, 69, 75, 73, 69, 66, -1]
			bass = [40, 40, 39, 39, 38, 38, 35, 35]
		"victory":
			lead = [72, -1, 76, 79, 84, -1, 79, 76, 77, -1, 81, 84, 88, -1, 84, 81,
				79, -1, 83, 86, 91, 88, 86, 83, 84, -1, 88, 91, 96, -1, 91, -1]
			bass = [48, 48, 53, 53, 55, 55, 48, 48]
	var total_frames := int(float(MUSIC_STEPS) * MUSIC_STEP_SECONDS * float(MUSIC_SAMPLE_RATE))
	var pcm := PackedByteArray()
	pcm.resize(total_frames * 2)
	var lead_phase := 0.0
	var bass_phase := 0.0
	for i in range(total_frames):
		var sec := float(i) / float(MUSIC_SAMPLE_RATE)
		var step_f := sec / MUSIC_STEP_SECONDS
		var step_index := mini(MUSIC_STEPS - 1, int(step_f))
		var step_pos := step_f - float(step_index)
		var note := lead[step_index]
		var lead_signal := 0.0
		if note >= 0:
			lead_phase += TAU * music_note_hz(note) / float(MUSIC_SAMPLE_RATE)
			var note_envelope := minf(1.0, step_pos * 23.0) * pow(1.0 - step_pos, 0.55)
			lead_signal = (1.0 if sin(lead_phase) >= 0.0 else -1.0) * 0.17 * note_envelope
		var bass_note := bass[(step_index / 4) % bass.size()]
		bass_phase += TAU * music_note_hz(bass_note) / float(MUSIC_SAMPLE_RATE)
		var beat_pos := fposmod(step_f, 4.0) / 4.0
		var bass_envelope := pow(1.0 - beat_pos, 1.2)
		var bass_signal := sin(bass_phase) * 0.22 * bass_envelope
		# Soft, unpitched synthetic hi-hat from two clashing partials.
		var hat_pos := fposmod(step_f, 2.0) / 2.0
		var hat_envelope := pow(1.0 - hat_pos, 13.0)
		var hat_signal := sin(sec * TAU * 1900.0) * sin(sec * TAU * 2710.0) * 0.05 * hat_envelope
		var sample := clampi(int((lead_signal + bass_signal + hat_signal) * tempo_amp * 32767.0), -32767, 32767)
		pcm.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_frames
	return stream


func setup_retro_music() -> void:
	for theme in ["menu", "stage", "boss", "victory"]:
		music_streams[theme] = generate_retro_music(theme)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = linear_to_db(music_volume)
	add_child(music_player)


func update_retro_music() -> void:
	if music_player == null:
		return
	var needed := ""
	if state in ["main_menu", "menu_confirm_new", "menu_options", "menu_highscores", "menu_bindings"]:
		needed = "menu"
	elif state in ["playing", "intermission", "boss_intro", "boss_rewards"]:
		needed = "boss" if boss_active or state in ["boss_intro", "boss_rewards"] else "stage"
	elif state == "victory":
		needed = "victory"
	if not music_enabled or needed.is_empty():
		music_player.stop()
		current_music = ""
		return
	if current_music != needed:
		current_music = needed
		music_player.stream = music_streams[needed]
		music_player.play()
	music_player.stream_paused = game_paused or show_stats_modal or debug_level_menu
	music_player.volume_db = -80.0 if music_volume <= 0.0 else linear_to_db(music_volume)


func update_sound_volumes() -> void:
	for kind in sfx_voices:
		var players: Array[AudioStreamPlayer] = sfx_voices[kind]
		for player in players:
			player.volume_db = -80.0 if sfx_volume <= 0.0 else float(sfx_base_db[kind]) + linear_to_db(sfx_volume)
	if music_player != null:
		music_player.volume_db = -80.0 if music_volume <= 0.0 else linear_to_db(music_volume)


func setup_arcade_audio() -> void:
	for kind in ["shoot", "double_shoot", "triple_shoot", "shield_hit", "storm_charge", "hit", "destroy", "pickup", "hurt", "boss"]:
		var sample := make_arcade_sound(kind)
		sfx_streams[kind] = sample
		var players: Array[AudioStreamPlayer] = []
		var voice_count := 1 if kind == "storm_charge" else SFX_VOICE_POOL
		for voice in range(voice_count):
			var player := AudioStreamPlayer.new()
			player.stream = sample
			player.volume_db = -14.0 if kind in ["shoot", "double_shoot", "triple_shoot", "hit"] else (-12.0 if kind == "shield_hit" else -9.0)
			sfx_base_db[kind] = player.volume_db
			add_child(player)
			players.append(player)
		sfx_voices[kind] = players
		sfx_next_voice[kind] = 0


func play_arcade_sfx(kind: String) -> void:
	if not sfx_voices.has(kind):
		return
	var players: Array[AudioStreamPlayer] = sfx_voices[kind]
	var voice_index: int = sfx_next_voice[kind]
	players[voice_index].play()
	sfx_next_voice[kind] = (voice_index + 1) % players.size()


func binding_name(key: int) -> String:
	return OS.get_keycode_string(key)


func reset_bindings() -> void:
	bindings.clear()
	for key in BIND_DEFAULT:
		bindings.append(int(key))


func controls_save_path() -> String:
	# Stable across Godot project-name changes and Windows exported builds.
	return OS.get_data_dir().path_join(CONTROL_SAVE_FOLDER).path_join("controls.cfg")


func load_bindings_from_path(path: String) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return false
	var loaded: Array[int] = []
	if cfg.has_section_key("keyboard", "key_0"):
		for i in range(BIND_ACTIONS.size()):
			loaded.append(int(cfg.get_value("keyboard", "key_%d" % i, 0)))
	else:
		# Compatible with the older typed-Array save.
		var previous: Variant = cfg.get_value("keyboard", "bindings", [])
		if not previous is Array or previous.size() != BIND_ACTIONS.size():
			return false
		for item in previous:
			loaded.append(int(item))
	for key in loaded:
		if key <= 0 or BIND_RESTRICTED.has(key):
			return false
	for i in range(loaded.size()):
		if loaded.count(loaded[i]) > 1:
			return false
	bindings = loaded
	return true


func save_bindings() -> bool:
	var path := controls_save_path()
	var directory := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_warning("Cannot create keyboard settings folder: %s" % directory)
		return false
	var cfg := ConfigFile.new()
	for i in range(bindings.size()):
		cfg.set_value("keyboard", "key_%d" % i, bindings[i])
	var result := cfg.save(path)
	if result != OK:
		push_warning("Could not save keyboard settings to %s (error %d)" % [path, result])
		return false
	return true


func load_bindings() -> void:
	reset_bindings()
	if load_bindings_from_path(controls_save_path()):
		return
	# Migrate settings from user:// when the project's display name changed.
	var legacy: Array[String] = [
		BINDINGS_FILE,
		OS.get_data_dir().path_join("Godot").path_join("app_userdata").path_join("Space Shooter").path_join("controls.cfg"),
		OS.get_data_dir().path_join("Godot").path_join("app_userdata").path_join("Adriatic Uprising").path_join("controls.cfg")
	]
	for old_path in legacy:
		if load_bindings_from_path(old_path):
			save_bindings()
			return


func key_down(action: int) -> bool:
	return Input.is_physical_key_pressed(bindings[action])


func draw_bindings_menu() -> void:
	draw_menu_background()
	draw_rect(Rect2(64, 96, 592, 780), Color(0.04, 0.09, 0.18, 0.98))
	text_at("KEYBOARD CONTROLS", 165, 158, 34, Color(0.64, 0.94, 1.0))
	text_at("ENTER TO CHANGE THE SELECTED KEY", 150, 199, 18)
	for i in range(BIND_ACTIONS.size() + 2):
		var y := 229.0 + float(i) * 65.0
		draw_rect(Rect2(100, y, 520, 52), Color(0.13, 0.44, 0.69) if i == binding_selection else Color(0.07, 0.14, 0.24))
		var caption: String = ""
		if i < BIND_ACTIONS.size():
			caption = "%s: %s" % [BIND_ACTIONS[i], binding_name(bindings[i])]
		elif i == BIND_ACTIONS.size():
			caption = "RESET TO DEFAULTS"
		else:
			caption = "BACK"
		text_at(caption, 126, y + 34, 22)
	if binding_capture:
		draw_rect(Rect2(92, 759, 537, 96), Color(0.12, 0.26, 0.40))
		text_at("PRESS NEW KEY FOR %s" % BIND_ACTIONS[binding_selection], 115, 799, 18)
		text_at("ESC TO CANCEL", 268, 833, 18)
	else:
		text_at(binding_notice if not binding_notice.is_empty() else "UP/DOWN SELECT  ENTER CHANGE  ESC BACK", 114, 803, 17, Color(0.71, 0.96, 0.79))
		text_at("ESC, ENTER AND GLOBAL HOTKEYS ARE RESERVED", 123, 832, 16)


func _ready() -> void:
	setup_arcade_audio()
	setup_retro_music()
	update_sound_volumes()
	randomize()
	font = ThemeDB.fallback_font
	load_high_scores()
	load_bindings()
	read_campaign_save()
	main_menu_selection = 0 if save_available else 1
	score_name_field = LineEdit.new()
	score_name_field.position = Vector2(226, 724)
	score_name_field.size = Vector2(268, 43)
	score_name_field.placeholder_text = "Your pilot name"
	score_name_field.max_length = 12
	score_name_field.text_submitted.connect(_on_score_name_submitted)
	add_child(score_name_field)
	score_name_field.hide()
	for i in range(110):
		stars.append(Vector2(randf_range(0.0, W), randf_range(0.0, H)))
	state = "main_menu"
	queue_redraw()


func read_campaign_save() -> void:
	pending_campaign_save.clear()
	save_available = false
	var config := ConfigFile.new()
	if config.load(CAMPAIGN_SAVE_FILE) != OK:
		return
	if int(config.get_value("campaign", "version", -1)) != CAMPAIGN_SAVE_VERSION:
		return
	var checkpoint_state := String(config.get_value("campaign", "checkpoint", ""))
	if not checkpoint_state in ["city_select", "playing", "shop", "pre_boss_shop", "pre_boss"]:
		return
	var saved_level := int(config.get_value("campaign", "level", 0))
	var saved_lives := int(config.get_value("campaign", "lives", 0))
	var route_value: Variant = config.get_value("campaign", "city_route", [])
	if saved_level < 1 or saved_level > MAX_LEVEL or saved_lives <= 0 or not route_value is Array:
		return
	var validated_route: Array[int] = []
	for raw_city in route_value:
		var city_id := int(raw_city)
		if city_id < 0 or city_id > 4 or validated_route.has(city_id):
			return
		validated_route.append(city_id)
	if validated_route.size() > 5:
		return
	# Level 1 and city_select can be saved before choosing any city.
	if checkpoint_state != "city_select" and validated_route.is_empty():
		return
	pending_campaign_save = {
		"checkpoint": checkpoint_state,
		"level": saved_level,
		"lives": saved_lives,
		"score": int(config.get_value("campaign", "score", 0)),
		"scrap": int(config.get_value("campaign", "scrap", 0)),
		"damage_level": int(config.get_value("campaign", "damage_level", 0)),
		"rate_level": int(config.get_value("campaign", "rate_level", 0)),
		"speed_level": int(config.get_value("campaign", "speed_level", 0)),
		"ability_level": int(config.get_value("campaign", "ability_level", 1)),
		"collected_orb_mask": int(config.get_value("campaign", "collected_orb_mask", 0)),
		"campaign_orbs_found_mask": int(config.get_value("campaign", "campaign_orbs_found_mask", 0)),
		"white_orb_collected": bool(config.get_value("campaign", "white_orb_collected", false)),
		"total_kills": int(config.get_value("campaign", "total_kills", 0)),
		"city_route": validated_route
	}
	save_available = true


func save_campaign_checkpoint(checkpoint_state: String) -> void:
	# Checkpoints are written at mission starts, city selection and shops.
	# DEBUG sessions are never saved or submitted to High Scores.
	if debug_run or not checkpoint_state in ["city_select", "playing", "shop", "pre_boss_shop", "pre_boss"]:
		return
	var config := ConfigFile.new()
	config.set_value("campaign", "version", CAMPAIGN_SAVE_VERSION)
	config.set_value("campaign", "checkpoint", checkpoint_state)
	config.set_value("campaign", "level", level)
	config.set_value("campaign", "lives", lives)
	config.set_value("campaign", "score", score)
	config.set_value("campaign", "scrap", scrap)
	config.set_value("campaign", "damage_level", damage_level)
	config.set_value("campaign", "rate_level", rate_level)
	config.set_value("campaign", "speed_level", speed_level)
	config.set_value("campaign", "ability_level", ability_level)
	config.set_value("campaign", "collected_orb_mask", collected_orb_mask)
	config.set_value("campaign", "campaign_orbs_found_mask", campaign_orbs_found_mask)
	config.set_value("campaign", "white_orb_collected", white_orb_collected)
	config.set_value("campaign", "total_kills", total_kills)
	config.set_value("campaign", "city_route", city_route)
	var save_result := config.save(CAMPAIGN_SAVE_FILE)
	if save_result != OK:
		push_warning("Could not save campaign checkpoint: %d" % save_result)
	else:
		read_campaign_save()


func erase_campaign_save() -> void:
	if FileAccess.file_exists(CAMPAIGN_SAVE_FILE):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMPAIGN_SAVE_FILE))
		if error != OK:
			push_warning("Could not remove old campaign save: %d" % error)
	read_campaign_save()


func continue_campaign() -> void:
	read_campaign_save()
	if not save_available:
		return
	var data: Dictionary = pending_campaign_save
	level = clampi(int(data["level"]), 1, MAX_LEVEL)
	lives = maxi(1, int(data["lives"]))
	score = maxi(0, int(data["score"]))
	scrap = maxi(0, int(data["scrap"]))
	damage_level = clampi(int(data["damage_level"]), 0, 6)
	rate_level = clampi(int(data["rate_level"]), 0, 4)
	speed_level = clampi(int(data["speed_level"]), 0, 4)
	ability_level = clampi(int(data["ability_level"]), 1, 3)
	collected_orb_mask = int(data["collected_orb_mask"])
	campaign_orbs_found_mask = int(data.get("campaign_orbs_found_mask", 0))
	white_orb_collected = bool(data["white_orb_collected"])
	total_kills = maxi(0, int(data["total_kills"]))
	city_route.clear()
	for city_index in data["city_route"]:
		city_route.append(int(city_index))
	debug_run = false
	game_paused = false
	show_stats_modal = false
	debug_level_menu = false
	god_mode = false
	awaiting_score_name = false
	drops.clear()
	active_multipliers.clear()
	enemies.clear()
	player_bullets.clear()
	enemy_bullets.clear()
	radial_bullets.clear()
	boss.clear()
	boss_active = false
	player_x = W * 0.5
	var checkpoint := String(data["checkpoint"])
	if checkpoint == "pre_boss_shop":
		open_pre_boss_shop()
	elif checkpoint == "pre_boss":
		start_level(true)
	elif checkpoint == "shop":
		# Legacy save from releases where the shop was AFTER the guardian.
		state = "shop"
		pre_boss_shop = false
	elif checkpoint == "city_select":
		show_city_map()
	else:
		# A saved in-progress level restarts at its beginning, never mid-wave.
		start_level()
	queue_redraw()


func city_selectable(city_index: int) -> bool:
	if city_index < 0 or city_index >= 5 or city_route.has(city_index):
		return false
	return city_index != 4 or city_route.size() == 4


func show_mission_briefing(city_index: int) -> void:
	if not city_selectable(city_index):
		return
	selected_city = city_index
	briefing_city_index = city_index
	state = "mission_briefing"
	queue_redraw()


func start_city_flight(city_index: int) -> void:
	if not city_selectable(city_index):
		return
	selected_city = city_index
	city_route.append(city_index)
	city_flight_time = 0.0
	state = "city_flight"
	game_paused = false
	show_stats_modal = false
	queue_redraw()


func show_city_map() -> void:
	state = "city_select"
	for city_index in range(5):
		if city_selectable(city_index):
			selected_city = city_index
			break
	save_campaign_checkpoint("city_select")
	queue_redraw()


func start_new_campaign() -> void:
	erase_campaign_save()
	god_mode = false
	lives = 3
	score = 0
	scrap = 0
	total_kills = 0
	single_shot_kills_since_drop = 0
	active_multipliers.clear()
	debug_run = false
	city_route.clear()
	selected_city = 0
	collected_orb_mask = 0
	campaign_orbs_found_mask = 0
	victory_show_scores = false
	white_orb_collected = false
	final_dialogue_stage = 0
	final_dialogue_time = 0.0
	drops.clear()
	enemies.clear()
	player_bullets.clear()
	enemy_bullets.clear()
	radial_bullets.clear()
	explosions.clear()
	boss.clear()
	boss_active = false
	level = 1
	damage_level = 0
	rate_level = 0
	speed_level = 0
	ability_level = 1
	ability_time = 0.0
	ability_cooldown = 0.0
	game_paused = false
	show_stats_modal = false
	awaiting_score_name = false
	new_personal_record = false
	player_x = W * 0.5
	if score_name_field != null:
		score_name_field.hide()
		score_name_field.release_focus()
	show_city_map()


func cycle_city(direction: int) -> void:
	for offset in range(1, 6):
		var next_city := posmod(selected_city + direction * offset, 5)
		if city_selectable(next_city):
			selected_city = next_city
			break


func _unhandled_input(event: InputEvent) -> void:
	if state != "city_select" or debug_level_menu:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for city_index in range(CITY_POINTS.size()):
			if city_selectable(city_index) and event.position.distance_to(CITY_POINTS[city_index]) <= 34.0:
				show_mission_briefing(city_index)
				get_viewport().set_input_as_handled()
				break


func draw_balkan_relief() -> void:
	# Original illustrative relief, not precision elevation or administrative GIS.
	draw_rect(Rect2(0, 0, W, H), Color(0.026, 0.09, 0.17))
	for wave in range(17):
		var water_line := PackedVector2Array()
		for step in range(13):
			water_line.append(Vector2(17.0 + float(step) * 24.0, 210.0 + float(wave) * 37.0 + sin(float(step) * 0.7 + float(wave)) * 5.0))
		draw_polyline(water_line, Color(0.16, 0.35, 0.49, 0.34), 1.1, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(255, 179), Vector2(398, 180), Vector2(537, 219),
		Vector2(662, 280), Vector2(682, 417), Vector2(639, 548),
		Vector2(585, 671), Vector2(545, 804), Vector2(495, 785),
		Vector2(458, 698), Vector2(387, 621), Vector2(328, 585),
		Vector2(288, 518), Vector2(265, 451), Vector2(229, 371),
		Vector2(254, 316), Vector2(246, 240)]), Color(0.29, 0.42, 0.29))
	draw_colored_polygon(PackedVector2Array([
		Vector2(269, 236), Vector2(459, 216), Vector2(594, 296),
		Vector2(531, 371), Vector2(356, 347)]), Color(0.44, 0.54, 0.34))
	draw_colored_polygon(PackedVector2Array([
		Vector2(287, 401), Vector2(360, 376), Vector2(441, 444),
		Vector2(540, 600), Vector2(531, 719), Vector2(474, 675),
		Vector2(398, 570), Vector2(311, 519)]), Color(0.54, 0.48, 0.32))
	for ridge in range(7):
		var shift := float(ridge) * 13.0
		draw_polyline(PackedVector2Array([
			Vector2(294.0 + shift, 393.0 + shift),
			Vector2(345.0 + shift, 439.0 + shift),
			Vector2(399.0 + shift, 497.0 + shift),
			Vector2(460.0 + shift, 574.0 + shift)]), Color(0.85, 0.78, 0.55, 0.42), 1.6, true)
	for island in [Vector2(210, 404), Vector2(222, 474), Vector2(246, 533), Vector2(259, 578)]:
		draw_circle(island, 7.0, Color(0.60, 0.61, 0.42))
	draw_polyline(PackedVector2Array([Vector2(316, 314), Vector2(398, 335), Vector2(493, 371), Vector2(574, 386)]), Color(0.31, 0.68, 0.84), 2.5, true)
	text_at("ADRIATIC SEA", 42, 628, 18, Color(0.52, 0.76, 0.9))
	text_at("DINARIC ALPS", 400, 540, 17, Color(0.95, 0.87, 0.67))
	text_at("BALKAN PENINSULA", 422, 754, 17, Color(0.9, 0.94, 0.83))
	if city_route.is_empty():
		draw_circle(CAMPAIGN_BASE, 9.0, Color(0.43, 1.0, 0.68))
		text_at("INLAND AIRBASE", 505, 635, 14, Color(0.63, 1.0, 0.78))


func draw_city_map() -> void:
	draw_balkan_relief()
	draw_rect(Rect2(18, 27, 684, 145), Color(0.025, 0.065, 0.14, 0.94))
	text_at("ADRIATIC UPRISING", 127, 77, 35, Color(0.95, 0.97, 1.0))
	text_at("SELECT THE NEXT CITY TO LIBERATE", 115, 118, 22, Color(0.65, 0.95, 1.0))
	text_at("LIBERATED: %d/5" % city_route.size(), 277, 153, 17, Color(0.9, 0.82, 0.56))
	if not city_route.is_empty():
		var origin_city: Vector2 = CITY_POINTS[city_route[city_route.size() - 1]]
		draw_arc(origin_city, 26.0, 0.0, TAU, 28, Color(0.41, 0.94, 1.0), 3.0)
		text_at("SHIP", origin_city.x + 14.0, origin_city.y + 29.0, 14, Color(0.60, 0.93, 1.0))
	for city_index in range(5):
		# Zagreb's marker and name do not exist until four cities are liberated.
		if city_index == 4 and city_route.size() < 4:
			continue
		var point: Vector2 = CITY_POINTS[city_index]
		var finished := city_route.has(city_index)
		var chosen := city_selectable(city_index) and selected_city == city_index
		var tint := Color(0.38, 1.0, 0.61) if finished else Color(1.0, 0.83, 0.32)
		draw_circle(point, 11.0, tint)
		draw_arc(point, 21.0 if chosen else 15.0, 0.0, TAU, 28, Color(0.44, 0.91, 1.0) if chosen else tint, 3.0)
		var label_offset := Vector2(-102, -20) if city_index == 1 else Vector2(18, -13)
		text_at(String(CITY_NAMES[city_index]) + (" [FREE]" if finished else ""), point.x + label_offset.x, point.y + label_offset.y, 17, tint)
	if city_route.size() == 4:
		draw_rect(Rect2(64, 777, 592, 66), Color(0.20, 0.08, 0.20, 0.94))
		text_at("TIME TO FREE THE ZONE", 134, 819, 31, Color(1.0, 0.80, 0.41))
	else:
		text_at("CLICK CITY / LEFT-RIGHT TO CHOOSE / ENTER TO FLY", 42, 828, 19, Color(0.94, 0.96, 1.0))
	text_at("6-SECOND FLIGHT TO SELECTED CITY", 160, 873, 18, Color(0.7, 0.88, 1.0))


func draw_mission_briefing() -> void:
	# A short story briefing before the existing 6-second flight.
	# Nothing is committed to the campaign route until the player confirms deployment.
	draw_balkan_relief()
	draw_rect(Rect2(33.0, 55.0, 654.0, 838.0), Color(0.025, 0.07, 0.14, 0.96))
	draw_rect(Rect2(33.0, 55.0, 654.0, 6.0), Color(0.33, 0.84, 1.0))
	text_at("MISSION BRIEFING", 171, 117, 36, Color(0.57, 0.94, 1.0))
	var city := String(CITY_NAMES[briefing_city_index])
	var city_title_width := font.get_string_size(city, HORIZONTAL_ALIGNMENT_LEFT, -1, 49).x
	text_at(city, (W - city_title_width) * 0.5, 191, 49, Color(1.0, 0.92, 0.66))
	var descriptions := [
		["ADRIATIC APPROACH", "Hostile sea creatures control the Zadar coast.", "Clear the airspace and protect the evacuation route.", "Destroy the lieutenant guarding the final sector."],
		["HARBOR BLOCKADE", "Invaders have occupied Rijeka's industrial port.", "Break their formations above the docks.", "Eliminate the guardian to restore port access."],
		["COASTAL RESISTANCE", "Split's waterfront is under enemy occupation.", "Push through the attacking formations.", "Defeat the guardian and secure the coastline."],
		["DRAVA DEFENSE", "Enemy forces are approaching Osijek along the Drava.", "Keep the bridges and river corridor clear.", "Defeat the guardian and free the city."],
		["FINAL OPERATION", "The Zone Guardian awaits above Zagreb.", "Its shields are reinforced and the Adriatic Storm", "can only be survived by finding a gap or using R shield."]
	]
	var mission: Array = descriptions[briefing_city_index]
	text_at(String(mission[0]), 100, 271, 26, Color(0.62, 0.94, 1.0))
	draw_line(Vector2(100.0, 286.0), Vector2(620.0, 286.0), Color(0.28, 0.70, 0.88, 0.6), 2.0)
	for line_index in range(3):
		text_at(String(mission[line_index + 1]), 77, 352 + line_index * 48, 18, Color(0.91, 0.96, 1.0))
	draw_rect(Rect2(79, 527, 562, 170), Color(0.06, 0.14, 0.25, 0.97))
	text_at("MISSION OBJECTIVES", 215, 569, 25, Color(1.0, 0.86, 0.49))
	if briefing_city_index == 4:
		text_at("- Defeat the final Zone Guardian", 109, 615, 21)
		text_at("- Recover the mysterious white orb", 109, 654, 21)
	else:
		text_at("- Survive 5 levels in this city", 109, 615, 21)
		text_at("- Defeat the lieutenant and collect its orb", 109, 654, 20)
	draw_rect(Rect2(109, 751, 502, 65), Color(0.15, 0.46, 0.73, 0.95))
	text_at("ENTER - DEPLOY", 259, 795, 26, Color.WHITE)
	text_at("ESC - RETURN TO MAP", 226, 854, 19, Color(0.65, 0.87, 1.0))


func draw_city_flight() -> void:
	draw_balkan_relief()
	var destination: Vector2 = CITY_POINTS[selected_city]
	var fraction := clampf(city_flight_time / CITY_FLIGHT_SECONDS, 0.0, 1.0)
	var eased := fraction * fraction * (3.0 - 2.0 * fraction)
	var departure := CAMPAIGN_BASE
	if city_route.size() >= 2:
		departure = CITY_POINTS[city_route[city_route.size() - 2]]
	var ship_pos := departure.lerp(destination, eased)
	draw_line(departure, destination, Color(0.60, 0.90, 1.0, 0.6), 3.0, true)
	draw_circle(departure, 9.0, Color(0.43, 1.0, 0.68))
	draw_circle(destination, 15.0, Color(1.0, 0.78, 0.3))
	var ship_shape := PackedVector2Array([
		ship_pos + Vector2(0, -23), ship_pos + Vector2(-17, 15),
		ship_pos + Vector2(0, 7), ship_pos + Vector2(17, 15)])
	draw_colored_polygon(ship_shape, Color(0.24, 0.82, 1.0))
	draw_circle(ship_pos + Vector2(0, 2), 5.0, Color(1.0, 0.91, 0.3))
	draw_rect(Rect2(38, 35, 644, 93), Color(0.02, 0.07, 0.15, 0.95))
	text_at("FLYING TO " + String(CITY_NAMES[selected_city]), 119, 96, 35, Color(0.90, 0.96, 1.0))


func draw_menu_background() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.015, 0.05, 0.11))
	for star in stars:
		var offset := fposmod(star.y + menu_anim_time * 10.0 + star.x * 0.02, H)
		draw_circle(Vector2(star.x, offset), 1.5, Color(0.48, 0.72, 1.0, 0.58))
	for stripe in range(7):
		var y := 126.0 + float(stripe) * 118.0 + sin(menu_anim_time * 0.7 + float(stripe)) * 10.0
		draw_rect(Rect2(0.0, y, W, 38.0), Color(0.08, 0.18, 0.30, 0.17))


func draw_main_menu() -> void:
	draw_menu_background()
	var title_glow := 0.76 + 0.24 * sin(menu_anim_time * 2.1)
	draw_rect(Rect2(70, 86, 580, 210), Color(0.03, 0.08, 0.17, 0.92))
	draw_rect(Rect2(70, 86, 580, 6), Color(0.23, 0.84, 1.0))
	text_at("ADRIATIC", 168, 164, 48, Color(0.55, 0.93, 1.0, title_glow))
	text_at("UPRISING", 170, 221, 50, Color(0.95, 0.98, 1.0))
	text_at("RETRO BALKAN ARCADE CAMPAIGN", 166, 264, 20, Color(0.72, 0.9, 1.0))
	var demo_ship := Vector2(565.0 + sin(menu_anim_time * 0.7) * 14.0, 165.0 + cos(menu_anim_time * 1.3) * 8.0)
	draw_player_ship_25d(demo_ship)
	for item_index in range(MENU_ITEMS.size()):
		var top := 372.0 + float(item_index) * 82.0
		var active := item_index == main_menu_selection
		var disabled := item_index == 0 and not save_available
		draw_rect(Rect2(182.0, top, 356.0, 58.0), Color(0.16, 0.44, 0.71, 0.95) if active and not disabled else Color(0.07, 0.13, 0.24, 0.94))
		if active:
			draw_rect(Rect2(176.0, top - 5.0, 368.0, 68.0), Color(0.27, 0.86, 1.0, 0.18))
		var label: String = "CONTINUE (NO SAVE)" if disabled else String(MENU_ITEMS[item_index])
		text_at(label, 215.0, top + 37.0, 26, Color(0.45, 0.52, 0.62) if disabled else (Color.WHITE if active else Color(0.75, 0.88, 1.0)))
	var progress_text: String = "SAVED: LEVEL %d   |   %d CITIES REACHED" % [int(pending_campaign_save["level"]), pending_campaign_save["city_route"].size()] if save_available else "NEW GAME: START FROM THE BALKAN WAR MAP"
	text_at(progress_text, 110, 828, 18, Color(0.72, 0.92, 0.78))
	text_at("UP/DOWN - CHOOSE    ENTER - CONFIRM", 153, 865, 20, Color(0.90, 0.96, 1.0))
	text_at("M / [ ] / , .  AUDIO CONTROLS", 208, 903, 16, Color(0.70, 0.85, 0.98))


func draw_new_game_confirmation() -> void:
	draw_main_menu()
	draw_rect(Rect2(80.0, 300.0, 560.0, 280.0), Color(0.035, 0.085, 0.16, 0.98))
	draw_rect(Rect2(80.0, 300.0, 560.0, 6.0), Color(1.0, 0.68, 0.28))
	text_at("START A NEW CAMPAIGN?", 132, 365, 28, Color(1.0, 0.88, 0.62))
	text_at("Your existing campaign save will be replaced.", 103, 411, 18, Color(0.88, 0.94, 1.0))
	text_at("ENTER - CONFIRM", 206, 477, 24, Color(0.55, 1.0, 0.7))
	text_at("ESC - CANCEL", 235, 525, 22, Color(0.65, 0.86, 1.0))


func draw_options_menu(in_game: bool = false) -> void:
	draw_menu_background()
	draw_rect(Rect2(64, 88, 592, 788), Color(0.04, 0.09, 0.18, 0.96))
	draw_rect(Rect2(64, 88, 592, 6), Color(0.29, 0.86, 1.0))
	text_at("OPTIONS", 268, 145, 38, Color(0.93, 0.98, 1.0))
	var entries := [
		"MUSIC: %s" % ("ON" if music_enabled else "OFF"),
		"MUSIC VOLUME: %d%%" % int(music_volume * 100.0),
		"SFX VOLUME: %d%%" % int(sfx_volume * 100.0),
		"PERFORMANCE HUD: %s" % ("ON" if show_performance_stats else "OFF"),
		"KEYBOARD CONTROLS",
		"BACK"
	]
	for item_index in range(entries.size()):
		var y := 210.0 + float(item_index) * 72.0
		var active := item_index == options_menu_selection
		draw_rect(Rect2(118.0, y, 482.0, 54.0), Color(0.15, 0.42, 0.69, 0.95) if active else Color(0.07, 0.13, 0.23, 0.95))
		text_at(entries[item_index], 144.0, y + 34.0, 22, Color.WHITE if active else Color(0.78, 0.9, 1.0))
	text_at("LEFT/RIGHT CHANGES VALUES  |  ENTER TOGGLE / BACK", 98, 674, 17, Color(0.80, 0.93, 1.0))
	text_at("ESC - RETURN TO PAUSE MENU" if in_game else "ESC - RETURN TO MAIN MENU", 180, 703, 17, Color(0.62, 0.90, 1.0))
	draw_rect(Rect2(104, 736, 514, 112), Color(0.05, 0.11, 0.21, 0.95))
	text_at("CONTROLS", 285, 772, 24, Color(1.0, 0.86, 0.47))
	text_at("CUSTOMIZE YOUR KEYBOARD IN KEYBOARD CONTROLS", 108, 807, 17, Color(0.88, 0.95, 1.0))
	text_at("F2 DEBUG  F3 FPS  O GOD MODE", 180, 835, 17, Color(0.76, 0.88, 1.0))


func draw_high_scores_screen() -> void:
	draw_menu_background()
	draw_leaderboard()
	text_at("ESC / ENTER - BACK TO MAIN MENU", 180, 855, 18, Color(0.70, 0.92, 1.0))


func jump_to_debug_level() -> void:
	# Start the chosen level immediately, skipping intermission and shop.
	# Retain current equipment and God Mode so the target can be tested easily.
	debug_run = true
	debug_level_menu = false
	# Debug run uses canonical city order regardless of campaign route.
	city_route.clear()
	for city_index in range(5):
		city_route.append(city_index)
	level = clampi(debug_selected_level, 1, MAX_LEVEL)
	lives = maxi(lives, 3)
	drops.clear()
	active_multipliers.clear()
	collected_orb_mask = 0
	campaign_orbs_found_mask = 0
	white_orb_collected = false
	final_dialogue_stage = 0
	final_dialogue_time = 0.0
	total_kills = 0
	single_shot_kills_since_drop = 0
	score = 0
	scrap = 0
	fire_held = true # Require a fresh fire-key press after closing the menu.
	start_level()


func draw_debug_level_menu() -> void:
	# Five columns = five cities; each column lists that city's five missions.
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.0, 0.02, 0.07, 0.86))
	draw_rect(Rect2(42.0, 205.0, 636.0, 550.0), Color(0.06, 0.12, 0.24, 0.98))
	text_at("DEBUG LEVEL SELECT [F2]", 139, 260, 30, Color(0.45, 0.95, 1.0))
	for city_index in range(5):
		var start_x := 83.0 + float(city_index) * 122.0
		text_at(String(CITY_NAMES[city_index]), start_x, 315, 16, Color(0.96, 0.80, 0.45))
		for city_stage in range(5):
			var stage_number := city_index * 5 + city_stage + 1
			var top := 336.0 + float(city_stage) * 55.0
			var active := stage_number == debug_selected_level
			draw_rect(Rect2(start_x - 10.0, top, 105.0, 45.0), Color(0.14, 0.48, 0.72) if active else Color(0.10, 0.20, 0.35))
			text_at("LVL %02d" % stage_number, start_x + 5.0, top + 30.0, 20, Color.WHITE if active else Color(0.74, 0.85, 0.95))
	var selected_city := String(CITY_NAMES[clampi(int((debug_selected_level - 1) / 5), 0, 4)])
	text_at("SELECTED: %s - LEVEL %d" % [selected_city, debug_selected_level], 172, 661, 23, Color(1.0, 0.9, 0.48))
	text_at("LEFT/RIGHT: CITY     UP/DOWN: LEVEL", 130, 702, 18, Color(0.8, 0.91, 1.0))
	text_at("ENTER: START     ESC / F2: CLOSE", 145, 730, 18, Color(0.65, 0.97, 0.8))


func start_level(resume_boss: bool = false) -> void:
	state = "playing"
	show_stats_modal = false
	game_paused = false
	awaiting_score_name = false
	new_personal_record = false
	if score_name_field != null:
		score_name_field.hide()
	score_name_field.release_focus()
	enemies.clear()
	player_bullets.clear()
	enemy_bullets.clear()
	radial_bullets.clear()
	# Keep falling rewards across stages; they continue falling in the new mission.
	explosions.clear()
	boss.clear()
	boss_active = false
	boss_pending = level % 5 == 0 # Guardians at 5/10/15/20/25; final shop follows the boss
	pre_boss_shop = false
	boss_intro_time = 0.0
	boss_reward_time = 0.0
	final_dialogue_stage = 0
	final_dialogue_time = 0.0
	waves_spawned = 0
	wave_path_ids.clear()
	boss_phase = 1
	boss_shields = 4 if level == MAX_LEVEL else 2
	boss_shield_hp = 0.0
	boss_shield_max_hp = 0.0
	boss_shield_round = 1
	storm_warning_time = 0.0
	storm_pulses_remaining = 0
	storm_pulse_time = 0.0
	storm_pending = false
	boss_attack_index = 0
	boss_warning_time = 0.0
	boss_warning_x = W / 2.0
	spin_countdown = 0.0
	spin_rotation = 0.0
	drift = 1.0
	fire_clock = 0.0
	fire_held = false
	enemy_fire_clock = 1.1
	boss_fire_clock = 1.0
	spawn_clock = 0.0
	invulnerable = 1.0
	ability_time = 0.0
	ability_cooldown = 0.0 # Ready again at the beginning of a mission.
	level_time = 0.0
	kills = 0
	target_kills = waves_for_level() * enemies_per_wave()
	if resume_boss:
		# Resuming after the shop must NOT show a second shop.
		begin_boss_intro()
		save_campaign_checkpoint("pre_boss")
	elif level == MAX_LEVEL:
		# Final guardian starts immediately; its shop comes AFTER the fight.
		begin_boss_intro()
		save_campaign_checkpoint("playing")
	else:
		spawn_wave()
		save_campaign_checkpoint("playing")
	queue_redraw()

func begin_level_transition() -> void:
	# Preserve falling rewards during the silent break and level-title intro.
	state = "intermission"
	level_transition_time = LEVEL_TRANSITION_SECONDS + LEVEL_TITLE_SECONDS
	# Checkpoint the next mission before the between-level countdown.
	save_campaign_checkpoint("playing")
	player_bullets.clear()
	enemy_bullets.clear()
	radial_bullets.clear()
	explosions.clear()
	queue_redraw()

func spawn_wave() -> void:
	# Exactly two waves for every regular mission, preserving the stage total.
	# Each wave contains mirrored groups plus additional balanced pairs.
	waves_spawned += 1
	var path_id := randi_range(0, 3)
	# Later missions rotate entry patterns, but keep the same smooth motion.
	wave_path_ids.append(path_id)
	var formation_size := int(enemies_per_wave() / 2)
	for side in range(2):
		for unit_index in range(formation_size):
			var index := unit_index % 5
			var group_index := int(unit_index / 5)
			var left := side == 0
			var is_guard := index < 2
			var kind := 1 if is_guard else (0 if index == 2 or index == 4 else 2)
			var lane := index if is_guard else (index - 2) % 2
			var formation_x := (155.0 + float(lane) * 120.0) if left else (565.0 - float(lane) * 120.0)
			var row_y := (505.0 + float(index) * 45.0) if is_guard else (250.0 + float(index - 2) * 67.0)
			# Five distinct formations for missions 6-10, with armored crabs always
			# in the lower/front rows to protect the lighter enemies.
			if level >= 6:
				match city_mission():
					1: # V wedge: mirrored guards at the tip, back-line on wings.
						formation_x = (160.0 + float(lane) * 115.0) if left else (560.0 - float(lane) * 115.0)
						row_y = (505.0 + float(lane) * 46.0) if is_guard else (280.0 + float(index - 2) * 45.0)
					2: # Tight double columns: layered defenders and rear units.
						formation_x = (205.0 + float(lane) * 58.0) if left else (515.0 - float(lane) * 58.0)
						row_y = (485.0 + float(lane) * 55.0) if is_guard else (265.0 + float(index - 2) * 65.0)
					3: # Crescent: wider rear wings and a compact red shield.
						formation_x = (170.0 + float(lane) * 130.0) if left else (550.0 - float(lane) * 130.0)
						row_y = (515.0 + float(lane) * 35.0) if is_guard else (265.0 + absf(float(index - 3)) * 65.0)
					4: # Pincer: each side approaches around the screen edges.
						formation_x = (120.0 + float(lane) * 100.0) if left else (600.0 - float(lane) * 100.0)
						row_y = (505.0 + float(lane) * 40.0) if is_guard else (240.0 + float(index - 2) * 58.0)
					5: # Crown: shield in the middle, rear units spanning the field.
						formation_x = (210.0 + float(lane) * 65.0) if left else (510.0 - float(lane) * 65.0)
						row_y = (520.0 + float(lane) * 40.0) if is_guard else (275.0 + float(index - 2) * 48.0)
			# Slightly offset additional groups so that 15/20-unit formations
			# do not completely overlap the first ten units.
			var group_shift := float(group_index) * (27.0 if left else -27.0)
			var target_pos := Vector2(clampf(formation_x + group_shift, 72.0, W - 72.0), row_y - float(group_index) * 34.0 + float(waves_spawned - 1) * 20.0)
			var start_pos := Vector2(-85.0 - float(index) * 35.0 if left else W + 85.0 + float(index) * 35.0, 110.0 + float(index) * 38.0)
			enemies.append({
				"pos": start_pos,
				"prev_pos": start_pos,
				"start": start_pos,
				"target": target_pos,
				"age": 0.0,
				"delay": float(index) * 0.19 + float(side) * 0.07 + float(group_index) * 0.85,
				"path": path_id,
				"side": -1.0 if left else 1.0,
				"offset": float(index) * 0.26,
				"hp": 3 if is_guard and level <= 5 else (5 + mini(int((level - 1) / 5), 4) if is_guard else 2 + mini(int((level - 1) / 5), 4)),
				"kind": kind
			})

func move_enemy(enemy: Dictionary, delta: float) -> void:
	enemy["prev_pos"] = enemy["pos"]
	# Continuous path: no offset jumps when an enemy finishes entering.
	var age: float = float(enemy["age"]) + delta
	enemy["age"] = age
	var flight_time := age - float(enemy["delay"])
	if flight_time <= 0.0:
		return
	var entrance_time := 2.8
	var fraction := clampf(flight_time / entrance_time, 0.0, 1.0)
	var eased := fraction * fraction * (3.0 - 2.0 * fraction)
	var source: Vector2 = enemy["start"]
	var target: Vector2 = enemy["target"]
	var side: float = enemy["side"]
	var offset: float = enemy["offset"]
	var route: int = enemy["path"]
	var position := source.lerp(target, eased)
	if fraction < 1.0:
		# Each entrance arc starts and finishes at zero displacement.
		var arc := sin(PI * fraction)
		match route:
			0:
				position.y -= arc * 65.0
			1:
				position.y += arc * 70.0
			2:
				position.x += side * sin(TAU * fraction) * 65.0
			3:
				position.x -= side * arc * 70.0
	else:
		# Sway starts at zero, so there's no visible teleport when formations settle.
		var t := flight_time - entrance_time
		var sway := sin(t * (1.05 if int(enemy["kind"]) == 1 else 1.55))
		var vertical := sin(t * 1.25)
		match route:
			0:
				position.x += sway * 32.0
				position.y += vertical * 14.0
			1:
				position.x += sway * 42.0
				position.y += vertical * 18.0
			2:
				position.x += sway * 48.0
				position.y += vertical * 16.0
			3:
				position.x += side * sway * 38.0
				position.y += vertical * 13.0
		if int(enemy["kind"]) == 2:
			position.x += sin(t * 3.5) * 13.0
		elif int(enemy["kind"]) == 1:
			position.y += sin(t * 0.9) * 7.0
	position.x = clampf(position.x, -360.0, W + 360.0)
	position.y = clampf(position.y, 55.0, 650.0)
	enemy["pos"] = position

func begin_boss_reward_time() -> void:
	# Every guardian, including Zagreb's final boss, leaves an orb.
	# Give players time to collect it before showing the shop.
	state = "boss_rewards"
	boss_reward_time = BOSS_REWARD_SECONDS
	enemy_bullets.clear()
	radial_bullets.clear()
	player_bullets.clear()
	fire_held = true
	queue_redraw()


func open_pre_boss_shop() -> void:
	# Shop after the last regular enemy and before the city guardian.
	state = "shop"
	pre_boss_shop = true
	game_paused = false
	show_stats_modal = false
	enemy_bullets.clear()
	radial_bullets.clear()
	player_bullets.clear()
	fire_held = true
	save_campaign_checkpoint("pre_boss_shop")
	queue_redraw()


func leave_pre_boss_shop() -> void:
	pre_boss_shop = false
	begin_boss_intro()
	save_campaign_checkpoint("pre_boss")
	queue_redraw()


func begin_boss_intro() -> void:
	# Give the player a readable story warning before the lieutenant arrives.
	boss_pending = false
	state = "boss_intro"
	boss_intro_time = BOSS_INTRO_SECONDS
	player_bullets.clear()
	enemy_bullets.clear()
	radial_bullets.clear()
	fire_held = false
	queue_redraw()

func launch_boss() -> void:
	boss_pending = false
	boss_active = true
	enemy_bullets.clear()
	# Each liberated city has a stronger guardian; Zagreb is the final fight.
	var boss_hp := 1000.0 if level == MAX_LEVEL else 200.0 + float(int((level - 1) / 5)) * 70.0
	boss = {"pos": Vector2(W / 2.0, 155.0), "prev_pos": Vector2(W / 2.0, 155.0), "hp": boss_hp, "max_hp": boss_hp, "direction": 1.0}
	boss_shield_max_hp = float(boss_hp) * BOSS_SHIELD_HP_RATIO
	boss_shield_hp = boss_shield_max_hp
	boss_shields = 4 if level == MAX_LEVEL else 2
	boss_fire_clock = 1.4
	spin_countdown = 0.0
	spin_rotation = 0.0


func _process(delta: float) -> void:
	update_retro_music()
	if state in ["main_menu", "menu_confirm_new", "menu_options", "menu_highscores", "menu_bindings"]:
		menu_anim_time += delta
		queue_redraw()
		return
	if debug_level_menu or game_paused or show_stats_modal:
		queue_redraw()
		return
	
	if state in ["playing", "intermission", "boss_intro", "boss_rewards"]:
		if city_name() == "ZADAR":
			update_background(delta)
		elif city_name() == "RIJEKA":
			update_rijeka_background(delta)
		elif city_name() == "SPLIT":
			update_split_background(delta)
		elif city_name() == "OSIJEK":
			update_osijek_background(delta)
		elif city_name() == "ZAGREB":
			update_zagreb_background(delta)


	if state == "mission_briefing":
		queue_redraw()
		return
	if state == "city_flight":
		city_flight_time += delta
		if city_flight_time >= CITY_FLIGHT_SECONDS:
			level = (city_route.size() - 1) * 5 + 1
			start_level()
		queue_redraw()
		return
	if state == "city_select":
		queue_redraw()
		return
	if state == "boss_rewards":
		update_player(delta)
		update_bullets(delta)
		update_pickups(delta)
		update_multiplier_timers(delta)
		update_effects(delta)
		boss_reward_time = maxf(0.0, boss_reward_time - delta)
		if final_dialogue_stage > 0:
			final_dialogue_time = maxf(0.0, final_dialogue_time - delta)
			if final_dialogue_time <= 0.0:
				if final_dialogue_stage == 1:
					final_dialogue_stage = 2
					final_dialogue_time = FINAL_DIALOGUE_LINE_SECONDS
				else:
					final_dialogue_stage = 0
		if boss_reward_time <= 0.0 and final_dialogue_stage == 0:
			complete_level()
		queue_redraw()
		return
	if state == "intermission" or state == "boss_intro":
		# Let old rewards fall and remain collectible during both types of intro.
		update_player(delta)
		if state == "intermission":
			# Keep player shots flying normally during the level wait.
			# No enemies exist here; update_bullets removes shots offscreen.
			update_bullets(delta)
		update_pickups(delta)
		update_multiplier_timers(delta)
		update_effects(delta)
		if state == "intermission":
			level_transition_time = maxf(0.0, level_transition_time - delta)
			if level_transition_time <= 0.0:
				start_level()
		else:
			boss_intro_time = maxf(0.0, boss_intro_time - delta)
			if boss_intro_time <= 0.0:
				state = "playing"
				launch_boss()
		queue_redraw()
		return
	if state != "playing":
		queue_redraw()
		return
	level_time += delta
	invulnerable = maxf(0.0, invulnerable - delta)
	if ability_time > 0.0:
		ability_time = maxf(0.0, ability_time - delta)
		if ability_time <= 0.0:
			ability_cooldown = ABILITY_COOLDOWN
	elif ability_cooldown > 0.0:
		ability_cooldown = maxf(0.0, ability_cooldown - delta)
	if waves_spawned < waves_for_level() and level_time >= float(waves_spawned) * WAVE_DELAY:
		spawn_wave()
	update_player(delta)
	update_enemies(delta)
	update_boss(delta)
	update_bullets(delta)
	update_pickups(delta)
	update_multiplier_timers(delta)
	update_effects(delta)
	if lives <= 0:
		finish_run(false)
	elif waves_spawned == waves_for_level() and enemies.is_empty():
		# Stage flow must never wait for collectibles. Existing Scrap and bonuses
		# stay in drops and carry into the next mission as falling objects.
		if boss_active:
			if boss.is_empty():
				begin_boss_reward_time()
		elif boss_pending:
			open_pre_boss_shop()
		else:
			complete_level()
	queue_redraw()

func update_player(delta: float) -> void:
	var move := 0.0
	if key_down(0):
		move -= 1.0
	if key_down(1):
		move += 1.0
	player_x = clampf(player_x + clampf(move, -1.0, 1.0) * (BASE_SPEED + speed_level * SPEED_STEP) * delta, 28.0, W - 28.0)
	fire_clock = maxf(0.0, fire_clock - delta)
	var pressed := key_down(2) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	# Shooting remains available between levels; bullets are updated even
	# while the next wave has not started. Boss announcements stay non-combat.
	# Keep edge-triggered shots: holding the key does not repeat volleys.
	if (state == "playing" or state == "intermission" or state == "boss_rewards") and pressed and not fire_held and fire_clock <= 0.0:
		fire_weapon()
		fire_clock = maxf(0.12, 0.34 - rate_level * 0.05)
	fire_held = pressed

func weapon_projectile_color() -> Color:
	if damage_level >= 6:
		return Color(0.78, 0.55, 1.0) # Lilac: Triple Shot
	if damage_level >= 3:
		return Color(0.25, 0.66, 1.0) # Blue: Double Shot
	return Color(1.0, 0.92, 0.25) # Yellow: Single Shot

func add_player_bullet(offset_x: float, angle_degrees: float) -> void:
	# Negative angle goes left; positive angle goes right, with up as the forward axis.
	var radians := deg_to_rad(angle_degrees)
	var velocity := Vector2(sin(radians), -cos(radians)) * BULLET_SPEED
	player_bullets.append({"pos": Vector2(player_x + offset_x, PLAYER_Y - 34.0), "velocity": velocity, "color": weapon_projectile_color()})

func fire_weapon() -> void:
	if damage_level >= 6:
		play_arcade_sfx("triple_shoot")
	elif damage_level >= 3:
		play_arcade_sfx("double_shoot")
	else:
		play_arcade_sfx("shoot")
	# Warblade-inspired wide fan: center flies up, outer shots diverge.
	if damage_level >= 6:
		add_player_bullet(-17.0, -22.0)
		add_player_bullet(0.0, 0.0)
		add_player_bullet(17.0, 22.0)
	elif damage_level >= 3:
		add_player_bullet(-17.0, 0.0)
		add_player_bullet(17.0, 0.0)
	else:
		add_player_bullet(0.0, 0.0)

func weapon_label() -> String:
	if damage_level >= 6:
		return "TRIPLE SHOT MAX"
	if damage_level >= 3:
		return "DOUBLE SHOT %d/3" % [damage_level - 3]
	return "SINGLE SHOT %d/3" % damage_level

func next_weapon_label() -> String:
	if damage_level >= 6:
		return "MAX"
	if damage_level >= 3:
		return "Triple at %d/3" % [damage_level - 3]
	return "Double at %d/3" % damage_level

func update_enemies(delta: float) -> void:
	if boss_active:
		return
	for i in range(enemies.size()):
		move_enemy(enemies[i], delta)
	enemy_fire_clock -= delta
	if enemy_fire_clock <= 0.0 and not enemies.is_empty():
		# Attack only after a unit is clearly on screen: no invisible off-screen fire.
		var candidates: Array[Dictionary] = []
		for enemy in enemies:
			var position: Vector2 = enemy["pos"]
			if position.x > 40.0 and position.x < W - 40.0 and position.y > 110.0:
				candidates.append(enemy)
		if not candidates.is_empty():
			var attacker: Dictionary = candidates.pick_random()
			var source: Vector2 = attacker["pos"] + Vector2(0, 25)
			var kind: int = int(attacker["kind"])
			if level <= 5:
				enemy_bullets.append(source)
				if kind == 0:
					enemy_bullets.append(source + Vector2(22, 0))
			else:
				fire_advanced_enemy_pattern(source, kind)
		enemy_fire_clock = maxf(REGULAR_ENEMY_FIRE_MIN, 1.85 - float(level) * 0.055)

func launch_enemy_shot(origin: Vector2, velocity: Vector2, tint: Color) -> void:
	radial_bullets.append({"pos": origin, "velocity": velocity * REGULAR_ENEMY_PROJECTILE_SPEED_FACTOR, "color": tint})

func fire_advanced_enemy_pattern(origin: Vector2, kind: int) -> void:
	# Distinct, readable attacks for the second five-mission block.
	var aim := (Vector2(player_x, PLAYER_Y) - origin).normalized()
	var speed := minf(360.0, 270.0 + float(level - 6) * 5.0)
	match city_mission():
		1: # Electric eels: a single accurately aimed green bolt.
			if kind == 2:
				launch_enemy_shot(origin, aim * speed, Color(0.5, 1.0, 0.35))
			else:
				enemy_bullets.append(origin)
		2: # Double columns: paired crossing blue bolts.
			if kind == 0:
				launch_enemy_shot(origin, aim.rotated(-0.19) * speed, Color(0.38, 0.84, 1.0))
				launch_enemy_shot(origin, aim.rotated(0.19) * speed, Color(0.38, 0.84, 1.0))
			else:
				enemy_bullets.append(origin)
		3: # Crescent: three-way orange fan only from armored guards.
			if kind == 1:
				for angle in [-0.27, 0.0, 0.27]:
					launch_enemy_shot(origin, aim.rotated(angle) * speed, Color(1.0, 0.64, 0.3))
			else:
				enemy_bullets.append(origin)
		4: # Pincer: two narrow targeted lanes, including the miniboss's guards.
			if kind == 2:
				for angle in [-0.11, 0.11]:
					launch_enemy_shot(origin, aim.rotated(angle) * speed, Color(0.65, 1.0, 0.48))
			else:
				enemy_bullets.append(origin)
		5: # Crown: alternating narrow paired fire and aimed pulses.
			if kind == 0:
				for angle in [-0.22, 0.22]:
					launch_enemy_shot(origin, aim.rotated(angle) * speed, Color(0.65, 0.72, 1.0))
			else:
				launch_enemy_shot(origin, aim * speed, Color(1.0, 0.56, 0.44))

func update_boss(delta: float) -> void:
	if not boss_active or boss.is_empty():
		return
	var pos: Vector2 = boss["pos"]
	boss["prev_pos"] = pos
	var direction: float = boss["direction"]
	pos.x += direction * ((135.0 if boss_phase == 1 else 195.0) if level == MAX_LEVEL else (100.0 if boss_phase == 1 else 165.0)) * delta
	if pos.x >= W - 110.0 or pos.x <= 110.0:
		direction *= -1.0
	pos.x = clampf(pos.x, 110.0, W - 110.0)
	# Boss dives toward the player while winding up the radial attack.
	pos.y = move_toward(pos.y, 395.0 if spin_countdown > 0.0 else 155.0, 230.0 * delta)
	boss["pos"] = pos
	boss["direction"] = direction
	# Let every previously fired red projectile reach the player or leave the
	# screen naturally. Do not spawn more reds while waiting for Storm.
	if level == MAX_LEVEL and storm_pending:
		if enemy_bullets.is_empty():
			storm_pending = false
			begin_adriatic_storm()
		return
	# Zagreb's regular red attacks must not advance during Adriatic Storm.
	if level != MAX_LEVEL or (storm_warning_time <= 0.0 and storm_pulses_remaining <= 0):
		boss_fire_clock -= delta
	# Zagreb final boss: storm warning is visible before three successive volleys.
	if level == MAX_LEVEL and (storm_warning_time > 0.0 or storm_pulses_remaining > 0):
		if storm_warning_time > 0.0:
			storm_warning_time = maxf(0.0, storm_warning_time - delta)
		else:
			storm_pulse_time -= delta
			if storm_pulse_time <= 0.0:
				fire_adriatic_storm_pulse()
				storm_pulses_remaining -= 1
				storm_pulse_time = STORM_PULSE_INTERVAL
				if storm_pulses_remaining == 0:
					# Brief recovery before the Guardian resumes ordinary red shots.
					boss_fire_clock = maxf(boss_fire_clock, 1.4)
		return
	# 360-degree spin telegraph. The radial barrage is released when the rotation ends.
	if spin_countdown > 0.0:
		spin_rotation += TAU * delta / SPIN_WARNING
		spin_countdown = maxf(0.0, spin_countdown - delta)
		if spin_countdown == 0.0:
			fire_radial_barrage(pos)
		return
	# Rotate through spread, 360 spin, aimed shot: spin happens every 3 attacks.
	var previous_warning := boss_warning_time
	boss_warning_time = maxf(0.0, boss_warning_time - delta)
	if previous_warning > 0.0 and boss_warning_time <= 0.0:
		# Final Guardian: a single telegraphed red projectile; lieutenants retain three.
		var aimed_lanes := [0] if level == MAX_LEVEL else [-1, 0, 1]
		for lane in aimed_lanes:
			enemy_bullets.append(Vector2(boss_warning_x + lane * 22.0, pos.y + 38.0))
	if boss_fire_clock <= 0.0:
		if level == MAX_LEVEL and boss_attack_index % 4 == 3:
			# Never erase a red shot in mid-flight just because Storm is next.
			# All red shots finish before the special attack starts.
			if enemy_bullets.is_empty():
				begin_adriatic_storm()
			else:
				storm_pending = true
		elif boss_attack_index % 3 == 0:
			# Final Guardian fires three red shots, instead of five.
			var spread_lanes := [-1, 0, 1] if level == MAX_LEVEL else [-2, -1, 0, 1, 2]
			for lane in spread_lanes:
				enemy_bullets.append(pos + Vector2(lane * 42.0, 38.0))
		elif boss_attack_index % 3 == 2:
			boss_warning_x = player_x
			boss_warning_time = 0.7
		else:
			if level == MAX_LEVEL:
				# Final Guardian does NOT use 360-degree barrages.
				# Replace the old spin turn with a telegraphed aimed shot.
				boss_warning_x = player_x
				boss_warning_time = 0.7
			else:
				spin_countdown = SPIN_WARNING
				spin_rotation = 0.0
				# The lieutenant's radial volley begins after the warning.
		boss_attack_index += 1
		boss_fire_clock = (1.20 if boss_phase == 1 else 0.98) if level == MAX_LEVEL else (1.5 if boss_phase == 1 else 1.2)
	if level == MAX_LEVEL and boss_shield_round == 1 and boss_shields == 0 and float(boss["hp"]) <= 500.0:
		# Distinct second shield round at half health, once only.
		boss_shield_round = 2
		boss_shields = 4
		boss_shield_hp = boss_shield_max_hp
	if boss_phase == 1 and float(boss["hp"]) <= float(boss["max_hp"]) * 0.475:
		boss_phase = 2

func begin_adriatic_storm() -> void:
	# The safe lane is two columns away from the player: reachable after warning.
	var player_lane := clampi(int(round((player_x - 40.0) / 80.0)), 0, 8)
	storm_safe_lane = clampi(player_lane + (2 if player_lane <= 4 else -2), 0, 8)
	# Any earlier red shots have already finished before reaching this method.
	# Clearing here made red bullets suddenly vanish halfway down the screen.
	# No leftover aimed-warning volley during the Adriatic Storm telegraph.
	boss_warning_time = 0.0
	spin_countdown = 0.0
	# Pause ordinary red-shot cooldown while the Storm is active.
	boss_fire_clock = maxf(boss_fire_clock, 1.4)
	storm_warning_time = STORM_WARNING_SECONDS
	play_arcade_sfx("storm_charge")
	storm_pulses_remaining = 3
	storm_pulse_time = 0.0


func fire_adriatic_storm_pulse() -> void:
	# Solid curtain of close-spaced bullets, with ONE intentionally open corridor.
	# The 16px horizontal spacing is smaller than the player's 52px collision diameter.
	# This prevents the player from squeezing through any other part of the wall.
	var safe_x := 40.0 + float(storm_safe_lane) * 80.0
	for column in range(45):
		var bullet_x := 8.0 + float(column) * STORM_BULLET_SPACING
		if absf(bullet_x - safe_x) < STORM_SAFE_HALF_WIDTH:
			continue
		radial_bullets.append({
			"pos": Vector2(bullet_x, 195.0),
			"velocity": Vector2(0.0, 420.0),
			"color": Color(0.42, 0.85, 1.0)
		})


func fire_radial_barrage(origin: Vector2) -> void:
	# 360-degree ring with two deliberate, wider dodge corridors.
	# Aim one corridor near the player and offset another to provide a choice.
	var aimed_angle := (Vector2(player_x, PLAYER_Y) - origin).angle()
	var second_gap := aimed_angle + 0.62
	for i in range(SPIN_PROJECTILES):
		var angle := TAU * float(i) / float(SPIN_PROJECTILES)
		var near_player_gap := absf(wrapf(angle - aimed_angle, -PI, PI)) < SPIN_GAP_PRIMARY
		var secondary_gap := absf(wrapf(angle - second_gap, -PI, PI)) < SPIN_GAP_SECONDARY
		if near_player_gap or secondary_gap:
			continue
		var speed := (390.0 if boss_phase == 1 else 450.0) if level == MAX_LEVEL else (350.0 if boss_phase == 1 else 410.0)
		var velocity := Vector2(cos(angle), sin(angle)) * speed
		radial_bullets.append({"pos": origin, "velocity": velocity})

func swept_hit_fraction(from_pos: Vector2, to_pos: Vector2, target_before: Vector2, target_after: Vector2, radius: float) -> float:
	# Continuous collision detection: check bullet travel RELATIVE to enemy motion.
	# Returns the earliest entry fraction [0..1], or -1 if it misses.
	var start: Vector2 = from_pos - target_before
	var movement: Vector2 = (to_pos - from_pos) - (target_after - target_before)
	var a: float = movement.length_squared()
	var c: float = start.length_squared() - radius * radius
	if c <= 0.0:
		return 0.0
	if a <= 0.00001:
		return -1.0
	var b: float = 2.0 * start.dot(movement)
	var discriminant: float = b * b - 4.0 * a * c
	if discriminant < 0.0:
		return -1.0
	var t: float = (-b - sqrt(discriminant)) / (2.0 * a)
	return t if t >= 0.0 and t <= 1.0 else -1.0

func update_bullets(delta: float) -> void:
	for i in range(player_bullets.size() - 1, -1, -1):
		var bullet: Dictionary = player_bullets[i]
		var previous: Vector2 = bullet["pos"]
		var shot: Vector2 = previous + Vector2(bullet["velocity"]) * delta
		bullet["pos"] = shot
		var target_index := -1
		var first_hit := 2.0
		var boss_hit := false
		if boss_active and not boss.is_empty():
			var boss_previous: Vector2 = boss.get("prev_pos", boss["pos"])
			var boss_current: Vector2 = boss["pos"]
			var boss_radius := 108.0 if level == MAX_LEVEL else 69.0
			var hit_t := swept_hit_fraction(previous, shot, boss_previous, boss_current, boss_radius)
			if hit_t >= 0.0:
				boss_hit = true
				first_hit = hit_t
		elif not boss_active:
			# Use earliest collision along the path, not array order. Red front guards
			# intercept shots aimed at enemies behind them.
			for j in range(enemies.size()):
				var enemy: Dictionary = enemies[j]
				var target_previous: Vector2 = enemy.get("prev_pos", enemy["pos"])
				var target_current: Vector2 = enemy["pos"]
				var hit_radius := 33.0 if int(enemy["kind"]) == 1 else 29.0
				var hit_t := swept_hit_fraction(previous, shot, target_previous, target_current, hit_radius)
				if hit_t >= 0.0 and hit_t < first_hit:
					first_hit = hit_t
					target_index = j
		var hit := boss_hit or target_index >= 0
		if hit:
			# Shield has its own electric crackle; normal impacts stay quieter.
			play_arcade_sfx("shield_hit" if boss_hit and boss_shield_hp > 0.0 else "hit")
			var impact := previous.lerp(shot, first_hit)
			explosions.append({"pos": impact, "time": 0.16})
			if boss_hit:
				if god_mode:
					# QA one-shot: bypass both shield rounds and defeat any boss instantly.
					boss_shields = 0
					boss_shield_hp = 0.0
					boss_shield_round = 2
					boss["hp"] = 0.0
				elif boss_shield_hp > 0.0:
					# Shield HP is 70% of the boss's max HP. Each hit removes
					# weapon damage from the shield, not an entire ring.
					boss_shield_hp = maxf(0.0, boss_shield_hp - (2.0 + damage_level))
					var total_layers := 4 if level == MAX_LEVEL else 2
					boss_shields = ceili(float(total_layers) * boss_shield_hp / boss_shield_max_hp) if boss_shield_hp > 0.0 else 0
				else:
					boss["hp"] = maxf(0.0, float(boss["hp"]) - (2.0 + damage_level))
				if boss_shields == 0 and float(boss["hp"]) <= 0.0:
					play_arcade_sfx("boss")
					score += 2500 * score_multiplier()
					scrap += 300
					if level == MAX_LEVEL:
						drop_white_orb(Vector2(boss["pos"]))
					else:
						drop_life_orb(Vector2(boss["pos"]))
					boss.clear()
			else:
				# QA one-shot keeps normal kills, Scrap, drops and score bookkeeping.
				enemies[target_index]["hp"] = 0 if god_mode else int(enemies[target_index]["hp"]) - (1 + damage_level)
				if int(enemies[target_index]["hp"]) <= 0:
					play_arcade_sfx("destroy")
					var enemy_pos: Vector2 = enemies[target_index]["pos"]
					enemies.remove_at(target_index)
					kills += 1
					total_kills += 1
					try_drop_double_shot(enemy_pos)
					score += 100 * score_multiplier()
					if total_kills % 30 == 0:
						drop_score_multiplier(enemy_pos)
					scrap += 12
					explosions.append({"pos": enemy_pos, "time": 0.3})
					if randf() < 0.85:
						drop_scrap(enemy_pos, 1)
		if hit or shot.y < -20.0 or shot.x < -25.0 or shot.x > W + 25.0:
			player_bullets.remove_at(i)
	for i in range(radial_bullets.size() - 1, -1, -1):
		var bullet: Dictionary = radial_bullets[i]
		var pos: Vector2 = bullet["pos"] + Vector2(bullet["velocity"]) * delta
		bullet["pos"] = pos
		if pos.x < -25.0 or pos.x > W + 25.0 or pos.y < -25.0 or pos.y > H + 25.0:
			radial_bullets.remove_at(i)
		elif pos.distance_to(Vector2(player_x, PLAYER_Y)) < 26.0:
			radial_bullets.remove_at(i)
			take_damage()
	for i in range(enemy_bullets.size() - 1, -1, -1):
		enemy_bullets[i].y += (240.0 + level * 18.0) * (BOSS_RED_PROJECTILE_SPEED_FACTOR if boss_active else REGULAR_ENEMY_PROJECTILE_SPEED_FACTOR) * delta
		if enemy_bullets[i].y > H + 20.0:
			enemy_bullets.remove_at(i)
		elif enemy_bullets[i].distance_to(Vector2(player_x, PLAYER_Y)) < 24.0:
			enemy_bullets.remove_at(i)
			take_damage()

func take_damage() -> void:
	if god_mode or invulnerable > 0.0 or ability_time > 0.0:
		return
	lives -= 1
	play_arcade_sfx("hurt")
	# Weapon power drops exactly one tier on each actual life lost.
	# Triple -> Double -> Single; shields/invulnerability prevent the loss.
	if damage_level >= 6:
		damage_level = 3
	elif damage_level >= 3:
		damage_level = 0
	invulnerable = 1.7
	explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.45})

func drop_scrap(pos: Vector2, amount: int) -> void:
	for i in range(amount):
		drops.append({"pos": pos + Vector2(randf_range(-25.0, 25.0), randf_range(-20.0, 20.0)), "value": 5 if amount == 1 else 10})

func drop_life_orb(pos: Vector2) -> void:
	# Four guardian lieutenants grant four uniquely colored parts of one life.
	var orb_index := int(level / 5) - 1
	if orb_index < 0 or orb_index >= 4:
		return
	drops.append({
		"pos": Vector2(clampf(pos.x, 65.0, W - 65.0), 350.0),
		"kind": "life_orb",
		"orb_index": orb_index,
		"fall_speed": 120.0
	})


func drop_white_orb(pos: Vector2) -> void:
	# The final Zone Guardian leaves a unique white trophy orb.
	drops.append({
		"pos": Vector2(clampf(pos.x, 65.0, W - 65.0), 350.0),
		"kind": "white_orb",
		"fall_speed": 100.0
	})


func collect_life_orb(orb_index: int) -> void:
	var bit := 1 << orb_index
	if (collected_orb_mask & bit) != 0:
		return
	collected_orb_mask |= bit
	campaign_orbs_found_mask |= bit
	if collected_orb_mask == 15:
		lives += 1
		collected_orb_mask = 0 # Start a new four-color collection.
		explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.5})


func pending_weapon_pickups() -> int:
	var count := 0
	for pickup in drops:
		if pickup.get("kind", "scrap") in ["double_shot", "triple_shot"]:
			count += 1
	return count


func try_drop_double_shot(pos: Vector2) -> void:
	# Weapon drops continue even when Double and Triple are already unlocked.
	if pending_weapon_pickups() >= MAX_WEAPON_PICKUPS_ON_SCREEN:
		return
	var kind := ""
	if damage_level < 3:
		single_shot_kills_since_drop += 1
		if randf() < DOUBLE_DROP_CHANCE or single_shot_kills_since_drop >= DOUBLE_DROP_PITY_KILLS:
			kind = "double_shot"
	else:
		var chance := randf()
		if chance < TRIPLE_DROP_CHANCE:
			kind = "triple_shot"
		elif chance < TRIPLE_DROP_CHANCE + EXTRA_DOUBLE_DROP_CHANCE:
			kind = "double_shot"
	if kind.is_empty():
		return
	single_shot_kills_since_drop = 0
	drops.append({"kind": kind, "pos": pos, "fall_speed": 205.0})


func score_multiplier() -> int:
	# Stack additively: x2 plus x6 results in x8, never x12.
	var total := 0
	for bonus in active_multipliers:
		total += int(bonus["factor"])
	return maxi(1, total)

func multiplier_time_left() -> float:
	var remaining := 0.0
	for bonus in active_multipliers:
		remaining = maxf(remaining, float(bonus["time"]))
	return remaining

func drop_score_multiplier(pos: Vector2) -> void:
	var factor: int = [2, 4, 6].pick_random()
	drops.append({
		"pos": pos,
		"kind": "multiplier",
		"factor": factor,
		"fall_speed": 135.0
	})

func update_multiplier_timers(delta: float) -> void:
	for i in range(active_multipliers.size() - 1, -1, -1):
		active_multipliers[i]["time"] = float(active_multipliers[i]["time"]) - delta
		if float(active_multipliers[i]["time"]) <= 0.0:
			active_multipliers.remove_at(i)

func update_pickups(delta: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		var pos: Vector2 = drops[i]["pos"]
		pos.y += float(drops[i].get("fall_speed", 115.0)) * delta
		drops[i]["pos"] = pos
		if pos.distance_to(Vector2(player_x, PLAYER_Y)) < 34.0:
			play_arcade_sfx("pickup")
			if drops[i].get("kind", "scrap") == "double_shot":
				if damage_level < 3:
					damage_level = 3
					single_shot_kills_since_drop = 0
				else:
					if rate_level >= 4:
						score += 10000
					else:
						rate_level += 1
				explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.32})
			elif drops[i].get("kind", "scrap") == "triple_shot":
				if damage_level < 6:
					damage_level = 6
				else:
					if rate_level >= 4:
						score += 10000
					else:
						rate_level += 1
				explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.32})
			elif drops[i].get("kind", "scrap") == "life_orb":
				collect_life_orb(int(drops[i]["orb_index"]))
			elif drops[i].get("kind", "scrap") == "white_orb":
				white_orb_collected = true
				if level == MAX_LEVEL and state == "boss_rewards":
					final_dialogue_stage = 1
					final_dialogue_time = FINAL_DIALOGUE_LINE_SECONDS
					# Allow both lines to be read even if orb is collected very late.
					boss_reward_time = maxf(boss_reward_time, FINAL_DIALOGUE_LINE_SECONDS * 2.0)
				explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.5})
			elif drops[i].get("kind", "scrap") == "multiplier":
				active_multipliers.append({
					"factor": int(drops[i]["factor"]),
					"time": randf_range(10.0, 15.0)
				})
			else:
				scrap += int(drops[i]["value"])
			drops.remove_at(i)
		elif pos.y > H:
			drops.remove_at(i)

func update_effects(delta: float) -> void:
	for i in range(explosions.size() - 1, -1, -1):
		explosions[i]["time"] = float(explosions[i]["time"]) - delta
		if float(explosions[i]["time"]) <= 0.0:
			explosions.remove_at(i)

func complete_level() -> void:
	# Keep the final guardian shop after combat and city map after lieutenants.
	if level >= MAX_LEVEL:
		state = "shop"
		pre_boss_shop = false
		save_campaign_checkpoint("shop")
	elif level % 5 == 0:
		show_city_map()
	else:
		# Advance automatically with the established silent pause and title.
		# Checkpoint the next level so Continue still restores progress.
		level += 1
		begin_level_transition()


func compare_high_scores(a: Dictionary, b: Dictionary) -> bool:
	return int(a["score"]) > int(b["score"])

func load_high_scores() -> void:
	high_scores.clear()
	var config := ConfigFile.new()
	if config.load(HIGH_SCORE_FILE) != OK:
		return
	var stored: Variant = config.get_value("leaderboard", "entries", [])
	if not stored is Array:
		return
	for item in stored:
		if not item is Dictionary:
			continue
		if not item.has("name") or not item.has("score"):
			continue
		var points := maxi(0, int(item["score"]))
		var pilot := String(item["name"]).strip_edges().substr(0, 12)
		if points > 0 and not pilot.is_empty():
			high_scores.append({"name": pilot, "score": points})
	high_scores.sort_custom(compare_high_scores)
	if high_scores.size() > HIGH_SCORE_LIMIT:
		high_scores.resize(HIGH_SCORE_LIMIT)

func save_high_scores() -> void:
	var config := ConfigFile.new()
	config.set_value("leaderboard", "entries", high_scores)
	var error := config.save(HIGH_SCORE_FILE)
	if error != OK:
		push_warning("Could not save local high scores: %d" % error)

func qualifies_for_high_scores(points: int) -> bool:
	return points > 0 and (high_scores.size() < HIGH_SCORE_LIMIT or points > int(high_scores[HIGH_SCORE_LIMIT - 1]["score"]))

func finish_run(won: bool) -> void:
	if not debug_run:
		erase_campaign_save()
	state = "victory" if won else "gameover"
	victory_show_scores = false
	new_personal_record = score > 0 and (high_scores.is_empty() or score > int(high_scores[0]["score"]))
	awaiting_score_name = not debug_run and qualifies_for_high_scores(score)
	if awaiting_score_name:
		score_name_field.text = ""
		score_name_field.show()
		score_name_field.grab_focus()

func _on_score_name_submitted(player_name: String) -> void:
	if not awaiting_score_name:
		return
	var clean_name := player_name.strip_edges().substr(0, 12)
	if clean_name.is_empty():
		clean_name = "PILOT"
	high_scores.append({"name": clean_name, "score": score})
	high_scores.sort_custom(compare_high_scores)
	if high_scores.size() > HIGH_SCORE_LIMIT:
		high_scores.resize(HIGH_SCORE_LIMIT)
	save_high_scores()
	awaiting_score_name = false
	score_name_field.hide()
	score_name_field.release_focus()
	if state == "gameover":
		# Defer transition to avoid ENTER activating a Main Menu item.
		call_deferred("return_to_main_menu")
	queue_redraw()

func return_to_main_menu() -> void:
	awaiting_score_name = false
	if score_name_field != null:
		score_name_field.hide()
		score_name_field.release_focus()
	game_paused = false
	pause_screen = "menu"
	show_stats_modal = false
	debug_level_menu = false
	victory_show_scores = false
	read_campaign_save()
	main_menu_selection = 0 if save_available else 1
	state = "main_menu"
	queue_redraw()

func draw_campaign_finale() -> void:
	# Dedicated Croatia ending. Underlying leaderboard is available with H.
	draw_menu_background()
	draw_rect(Rect2(54.0, 47.0, 612.0, 849.0), Color(0.035, 0.075, 0.15, 0.96))
	draw_rect(Rect2(54.0, 47.0, 612.0, 6.0), Color(0.40, 0.96, 0.73))
	text_at("CROATIA LIBERATED!", 118.0, 119.0, 37, Color(0.53, 1.0, 0.72))
	text_at("CAMPAIGN COMPLETE  -  25/25", 160.0, 158.0, 21, Color(0.78, 0.91, 1.0))
	# Five liberated sectors are shown in canonical campaign order.
	for city_index in range(5):
		var top := 185.0 + float(city_index) * 57.0
		draw_rect(Rect2(92.0, top, 536.0, 47.0), Color(0.07, 0.18, 0.23, 0.97))
		draw_circle(Vector2(116.0, top + 23.0), 8.0, Color(0.44, 1.0, 0.66))
		text_at(String(CITY_NAMES[city_index]), 143.0, top + 32.0, 23, Color(0.92, 0.97, 1.0))
		text_at("LIBERATED", 458.0, top + 31.0, 18, Color(0.57, 1.0, 0.77))
	text_at("RECOVERED GUARDIAN ORBS", 151.0, 524.0, 22, Color(0.96, 0.88, 0.64))
	for orb_index in range(4):
		var orb_position := Vector2(218.0 + float(orb_index) * 95.0, 568.0)
		var found := (campaign_orbs_found_mask & (1 << orb_index)) != 0
		draw_circle(orb_position, 24.0, ORB_COLORS[orb_index].darkened(0.15) if found else Color(0.16, 0.24, 0.31))
		draw_circle(orb_position + Vector2(-6.0, -7.0), 7.0, Color(1.0, 1.0, 1.0, 0.73) if found else Color(0.35, 0.43, 0.49))
	# Separate white trophy orb from the Zone Guardian.
	var trophy_position := Vector2(360.0, 638.0)
	draw_circle(trophy_position, 26.0, Color(0.90, 0.98, 1.0) if white_orb_collected else Color(0.16, 0.24, 0.31))
	draw_circle(trophy_position + Vector2(-7.0, -8.0), 8.0, Color(1.0, 1.0, 1.0, 0.94) if white_orb_collected else Color(0.35, 0.43, 0.49))
	text_at("WHITE ORB SECURED" if white_orb_collected else "WHITE ORB NOT RECOVERED", 207.0, 684.0, 19, Color(0.81, 0.94, 1.0))
	text_at("FINAL SCORE: %d" % score, 201.0, 737.0, 29, Color(1.0, 0.87, 0.47))
	text_at("ENEMIES DEFEATED: %d" % total_kills, 212.0, 770.0, 19, Color(0.82, 0.92, 1.0))
	draw_rect(Rect2(91.0, 788.0, 538.0, 62.0), Color(0.09, 0.18, 0.29, 0.93))
	text_at("HQ: The coast is free. The orb remains a mystery.", 110.0, 817.0, 17, Color(0.78, 0.97, 0.88))
	text_at("Our mission is complete. Return to base.", 153.0, 839.0, 17, Color(0.78, 0.97, 0.88))
	text_at("H - HIGH SCORES     ENTER - MAIN MENU", 153.0, 882.0, 18, Color(0.64, 0.91, 1.0))


func draw_leaderboard() -> void:
	draw_rect(Rect2(75, 208, 570, 605), Color(0.04, 0.09, 0.20, 0.97))
	text_at("TOP 10 HIGH SCORES", 175, 258, 30, Color(1.0, 0.85, 0.42))
	text_at("RANK      PILOT               SCORE", 118, 306, 18, Color(0.60, 0.80, 1.0))
	for index in range(HIGH_SCORE_LIMIT):
		var y := 343 + index * 32
		if index < high_scores.size():
			var item: Dictionary = high_scores[index]
			text_at("%02d" % (index + 1), 122, y, 18, Color(0.78, 0.86, 1.0))
			text_at(String(item["name"]), 223, y, 18, Color(0.88, 1.0, 0.85))
			text_at("%d" % int(item["score"]), 486, y, 18, Color(1.0, 0.91, 0.55))
		else:
			text_at("%02d        ---" % (index + 1), 122, y, 18, Color(0.38, 0.48, 0.62))
	if awaiting_score_name:
		text_at("NEW HIGH SCORE!" if new_personal_record else "TOP 10 QUALIFIED!", 235, 698, 23, Color(0.50, 1.0, 0.72))
		text_at("Enter name and press ENTER", 213, 792, 19, Color(0.75, 0.91, 1.0))
	elif state == "menu_highscores":
		text_at("LOCAL HALL OF FAME", 238, 738, 22, Color(1.0, 0.87, 0.60))
		text_at("ENTER / ESC - Back", 248, 781, 21, Color(0.55, 0.89, 1.0))
	else:
		text_at("Your score: %d" % score, 254, 738, 22, Color(1.0, 0.87, 0.60))
		text_at("ENTER - Main Menu", 245, 781, 21, Color(0.55, 0.89, 1.0))

const DOUBLE_SHOT_PRICE := 540
const TRIPLE_SHOT_PRICE := 1580

# Progressive Scrap costs balance upgrades without mission-based restrictions.
# Total for MAX speed: 1730; total for MAX fire rate: 2150.
const SPEED_UPGRADE_COSTS := [100, 260, 520, 850]
const FIRE_UPGRADE_COSTS := [125, 325, 650, 1050]

func upgrade_cost(kind: int) -> int:
	match kind:
		1: return SPEED_UPGRADE_COSTS[mini(speed_level, 3)]
		2: return FIRE_UPGRADE_COSTS[mini(rate_level, 3)]
		3: return DOUBLE_SHOT_PRICE
		4: return TRIPLE_SHOT_PRICE - (DOUBLE_SHOT_PRICE if damage_level >= 3 else 0)
		5: return 900 if ability_level == 1 else 1800
	return 99999

func buy_upgrade(kind: int) -> void:
	var capped := (kind == 1 and speed_level >= 4) or (kind == 2 and rate_level >= 4) or (kind == 3 and damage_level >= 3) or (kind == 4 and damage_level >= 6) or (kind == 5 and ability_level >= 3)
	if capped or scrap < upgrade_cost(kind):
		return
	scrap -= upgrade_cost(kind)
	match kind:
		1: speed_level += 1
		2: rate_level += 1
		3: damage_level = 3
		4: damage_level = 6
		5: ability_level += 1
	if state == "shop":
		save_campaign_checkpoint("pre_boss_shop" if pre_boss_shop else "shop")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if state == "menu_bindings" or (game_paused and pause_screen == "bindings"):
		if binding_capture:
			if event.keycode == KEY_ESCAPE:
				binding_capture = false
				binding_notice = "CANCELLED"
			else:
				var key: int = int(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
				if key <= 0 or BIND_RESTRICTED.has(key):
					binding_notice = "KEY RESERVED"
				elif bindings.has(key) and bindings[binding_selection] != key:
					binding_notice = "KEY ALREADY USED"
				else:
					bindings[binding_selection] = key
					var saved := save_bindings()
					binding_capture = false
					binding_notice = ("SAVED: %s" % binding_name(key)) if saved else "SAVE FAILED - CHECK USER FOLDER"
		else:
			match event.keycode:
				KEY_UP:
					binding_selection = posmod(binding_selection - 1, BIND_ACTIONS.size() + 2)
				KEY_DOWN:
					binding_selection = posmod(binding_selection + 1, BIND_ACTIONS.size() + 2)
				KEY_ESCAPE:
					if game_paused:
						pause_screen = "options"
					else:
						state = "menu_options"
				KEY_ENTER, KEY_KP_ENTER:
					if binding_selection < BIND_ACTIONS.size():
						binding_capture = true
						binding_notice = ""
					elif binding_selection == BIND_ACTIONS.size():
						reset_bindings()
						binding_notice = "DEFAULTS RESTORED" if save_bindings() else "SAVE FAILED"
					else:
						if game_paused:
							pause_screen = "options"
						else:
							state = "menu_options"
		queue_redraw()
		return
	# ESC opens a proper pause menu instead of leaving or unpausing directly.
	if state in ["playing", "intermission", "boss_intro", "boss_rewards"] and event.keycode == KEY_ESCAPE:
		if not game_paused:
			game_paused = true
			show_stats_modal = false
			pause_screen = "menu"
			pause_menu_selection = 0
		elif pause_screen == "menu":
			game_paused = false
		elif pause_screen == "confirm":
			pause_screen = "menu"
		else:
			pause_screen = "menu"
		queue_redraw()
		return
	if game_paused and pause_screen == "confirm":
		if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			pause_confirm_yes = not pause_confirm_yes
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			if pause_confirm_yes:
				# Do NOT write a checkpoint: resume from the last autosave only.
				return_to_main_menu()
			else:
				pause_screen = "menu"
		queue_redraw()
		return
	if game_paused and pause_screen == "menu":
		match event.keycode:
			KEY_UP, KEY_LEFT:
				pause_menu_selection = posmod(pause_menu_selection - 1, 3)
			KEY_DOWN, KEY_RIGHT:
				pause_menu_selection = posmod(pause_menu_selection + 1, 3)
			KEY_ENTER, KEY_KP_ENTER:
				match pause_menu_selection:
					0:
						game_paused = false
					1:
						pause_screen = "options"
						options_menu_selection = 0
					2:
						pause_screen = "confirm"
						pause_confirm_yes = false # NO is always the safe default.
		queue_redraw()
		return
	if game_paused and pause_screen == "options" and event.keycode == KEY_M:
		return # Keep the menu focused; music can be toggled from Options.
	# M is the safe exit at checkpoint screens; it must precede Music M.
	if event.keycode == KEY_M and state in ["city_select", "shop"]:
		return_to_main_menu()
		return
	# Sound controls work from gameplay, shop and map (even while paused).
	if event.keycode == KEY_M:
		music_enabled = not music_enabled
		update_retro_music()
		queue_redraw()
		return
	if event.keycode == KEY_BRACKETLEFT:
		music_volume = maxf(0.0, music_volume - 0.1)
		update_sound_volumes()
		queue_redraw()
		return
	if event.keycode == KEY_BRACKETRIGHT:
		music_volume = minf(1.0, music_volume + 0.1)
		update_sound_volumes()
		queue_redraw()
		return
	if event.keycode == KEY_COMMA:
		sfx_volume = maxf(0.0, sfx_volume - 0.1)
		update_sound_volumes()
		queue_redraw()
		return
	if event.keycode == KEY_PERIOD:
		sfx_volume = minf(1.0, sfx_volume + 0.1)
		update_sound_volumes()
		queue_redraw()
		return
	# F3: display actual frame rate and frame duration for diagnosing hitches.
	if event.keycode == KEY_F3:
		show_performance_stats = not show_performance_stats
		queue_redraw()
		return
	# F2 is accessible from gameplay, shop, victory, and test intermissions.
	if event.keycode == KEY_F2 and not state in ["main_menu", "menu_confirm_new", "menu_options", "menu_highscores", "menu_bindings"]:
		debug_level_menu = not debug_level_menu
		if debug_level_menu:
			debug_selected_level = level
		queue_redraw()
		return
	if debug_level_menu:
		match event.keycode:
			KEY_ESCAPE:
				debug_level_menu = false
			KEY_UP:
				debug_selected_level = maxi(1, debug_selected_level - 1)
			KEY_DOWN:
				debug_selected_level = mini(MAX_LEVEL, debug_selected_level + 1)
			KEY_LEFT:
				debug_selected_level = maxi(1, debug_selected_level - 5)
			KEY_RIGHT:
				debug_selected_level = mini(MAX_LEVEL, debug_selected_level + 5)
			KEY_ENTER, KEY_KP_ENTER:
				jump_to_debug_level()
		queue_redraw()
		return
	if state == "menu_confirm_new":
		if event.keycode == KEY_ESCAPE:
			state = "main_menu"
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			start_new_campaign()
		queue_redraw()
		return
	if state == "main_menu":
		match event.keycode:
			KEY_UP, KEY_LEFT:
				main_menu_selection = posmod(main_menu_selection - 1, MENU_ITEMS.size())
			KEY_DOWN, KEY_RIGHT:
				main_menu_selection = posmod(main_menu_selection + 1, MENU_ITEMS.size())
			KEY_ENTER, KEY_KP_ENTER:
				match main_menu_selection:
					0:
						continue_campaign()
					1:
						if save_available:
							state = "menu_confirm_new"
						else:
							start_new_campaign()
					2:
						state = "menu_highscores"
					3:
						state = "menu_options"
						options_menu_selection = 0
					4:
						get_tree().quit()
		queue_redraw()
		return
	if state == "menu_highscores":
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			state = "main_menu"
		queue_redraw()
		return
	if state == "menu_options" or (game_paused and pause_screen == "options"):
		match event.keycode:
			KEY_ESCAPE:
				if game_paused:
					pause_screen = "menu"
				else:
					state = "main_menu"
			KEY_UP:
				options_menu_selection = posmod(options_menu_selection - 1, 6)
			KEY_DOWN:
				options_menu_selection = posmod(options_menu_selection + 1, 6)
			KEY_LEFT:
				match options_menu_selection:
					0:
						music_enabled = not music_enabled
					1:
						music_volume = maxf(0.0, music_volume - 0.1)
						update_sound_volumes()
					2:
						sfx_volume = maxf(0.0, sfx_volume - 0.1)
						update_sound_volumes()
					3:
						show_performance_stats = not show_performance_stats
			KEY_RIGHT:
				match options_menu_selection:
					0:
						music_enabled = not music_enabled
					1:
						music_volume = minf(1.0, music_volume + 0.1)
						update_sound_volumes()
					2:
						sfx_volume = minf(1.0, sfx_volume + 0.1)
						update_sound_volumes()
					3:
						show_performance_stats = not show_performance_stats
			KEY_ENTER, KEY_KP_ENTER:
				match options_menu_selection:
					0:
						music_enabled = not music_enabled
					3:
						show_performance_stats = not show_performance_stats
					4:
						if game_paused:
							pause_screen = "bindings"
						else:
							state = "menu_bindings"
						binding_selection = 0
						binding_notice = ""
					5:
						if game_paused:
							pause_screen = "menu"
						else:
							state = "main_menu"
		queue_redraw()
		return
	if state == "city_select":
		if event.keycode == KEY_M or event.keycode == KEY_ESCAPE:
			return_to_main_menu()
			return
		match event.keycode:
			KEY_LEFT, KEY_UP:
				cycle_city(-1)
			KEY_RIGHT, KEY_DOWN:
				cycle_city(1)
			KEY_ENTER, KEY_KP_ENTER:
				show_mission_briefing(selected_city)
		queue_redraw()
		return
	if state == "mission_briefing":
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				start_city_flight(briefing_city_index)
			KEY_ESCAPE:
				show_city_map()
		queue_redraw()
		return
	# Test-only invulnerability hotkey: available in any game state.
	if event.keycode == KEY_O:
		god_mode = not god_mode
		queue_redraw()
		return
	if state == "shop":
		if event.keycode == KEY_M or event.keycode == KEY_ESCAPE:
			return_to_main_menu()
			return
		match event.keycode:
			KEY_1: buy_upgrade(1)
			KEY_2: buy_upgrade(2)
			KEY_3: buy_upgrade(3)
			KEY_4: buy_upgrade(4)
			KEY_5: buy_upgrade(5)

			KEY_ENTER, KEY_KP_ENTER:
				if pre_boss_shop:
					leave_pre_boss_shop()
				elif level >= MAX_LEVEL:
					finish_run(true)
				else:
					show_city_map()
	elif state == "playing" or state == "intermission" or state == "boss_intro" or state == "boss_rewards":
		if event.physical_keycode == bindings[4] or event.keycode == bindings[4]:
			pause_screen = "menu"
			pause_menu_selection = 0
			game_paused = not game_paused
			if game_paused:
				show_stats_modal = false
		elif game_paused:
			return
		elif event.physical_keycode == bindings[5] or event.keycode == bindings[5]:
			show_stats_modal = not show_stats_modal
		elif show_stats_modal:
			return
		elif (event.physical_keycode == bindings[3] or event.keycode == bindings[3]) and ability_time <= 0.0 and ability_cooldown <= 0.0:
			ability_time = float(ability_level * 2)
			ability_cooldown = 0.0
	elif state == "gameover" or state == "victory":
		if awaiting_score_name:
			return
		if state == "victory":
			if event.keycode == KEY_H:
				victory_show_scores = not victory_show_scores
			elif event.keycode == KEY_ESCAPE and victory_show_scores:
				victory_show_scores = false
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				if victory_show_scores:
					victory_show_scores = false
				else:
					state = "main_menu"
		else:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_ESCAPE:
				return_to_main_menu()
	queue_redraw()

func text_at(value: String, x: float, y: float, size: int = 22, color: Color = Color.WHITE) -> void:
	draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_stat_meter(name: String, current: int, maximum: int, x: float, y: float, bar_color: Color) -> void:
	# Warblade-inspired compact ship status bars, adapted to our own upgrades.
	text_at("%s %d/%d" % [name, current, maximum], x, y, 17, Color(0.83, 0.89, 1.0))
	draw_rect(Rect2(x + 119, y - 13, 110, 11), Color(0.16, 0.21, 0.31))
	if current > 0:
		draw_rect(Rect2(x + 119, y - 13, 110.0 * float(current) / float(maximum), 11), bar_color)

func equipped_weapon_name() -> String:
	if damage_level >= 6:
		return "TRIPLE"
	if damage_level >= 3:
		return "DOUBLE"
	return "SINGLE"

func shots_per_second() -> float:
	return 1.0 / maxf(0.12, 0.34 - float(rate_level) * 0.05)

func draw_ship_status_modal() -> void:
	# Status overview opened with TAB; simulation pauses while viewing it.
	draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.02, 0.06, 0.70))
	draw_rect(Rect2(95, 255, 530, 426), Color(0.06, 0.12, 0.23, 0.98))
	draw_rect(Rect2(95, 255, 530, 8), Color(0.24, 0.72, 1.0))
	text_at("SHIP STATUS", 245, 319, 34, Color(0.95, 0.98, 1.0))
	text_at("S - SPEED", 126, 379, 23, Color(0.35, 0.76, 1.0))
	draw_stat_meter("LEVEL", speed_level, 4, 127, 411, Color(0.24, 0.7, 1.0))
	text_at("%d px/s    (+%d each upgrade)" % [int(BASE_SPEED + speed_level * SPEED_STEP), int(SPEED_STEP)], 128, 443, 19)
	text_at("F - RATE OF FIRE", 126, 496, 23, Color(1.0, 0.55, 0.45))
	draw_stat_meter("LEVEL", rate_level, 4, 127, 528, Color(1.0, 0.38, 0.3))
	text_at("%.2f shots/s    (%.2fs between shots)" % [shots_per_second(), 1.0 / shots_per_second()], 128, 560, 18)
	text_at("WEAPON: %s  |  SHIELD Lv.%d" % [equipped_weapon_name(), ability_level], 126, 612, 20, Color(0.70, 0.95, 0.8))
	text_at("%s - CLOSE / RESUME" % binding_name(bindings[5]), 230, 652, 19, Color(0.80, 0.91, 1.0))

func draw_final_orb_speech() -> void:
	# A readable two-part conversation anchored above the moving player ship.
	# Bubble stays within the game window when the player is near screen edges.
	if final_dialogue_stage == 0 or state != "boss_rewards" or level != MAX_LEVEL:
		return
	var bubble_width := 460.0
	var bubble_height := 128.0
	var bubble_x := clampf(player_x - bubble_width * 0.5, 14.0, W - bubble_width - 14.0)
	var bubble_y := PLAYER_Y - 205.0
	var bubble_color := Color(0.05, 0.16, 0.27, 0.96)
	draw_rect(Rect2(bubble_x, bubble_y, bubble_width, bubble_height), bubble_color)
	draw_rect(Rect2(bubble_x, bubble_y, bubble_width, 4.0), Color(0.38, 0.85, 1.0))
	var pointer := PackedVector2Array([
		Vector2(clampf(player_x, bubble_x + 22.0, bubble_x + bubble_width - 22.0) - 13.0, bubble_y + bubble_height),
		Vector2(clampf(player_x, bubble_x + 22.0, bubble_x + bubble_width - 22.0) + 13.0, bubble_y + bubble_height),
		Vector2(player_x, bubble_y + bubble_height + 18.0)
	])
	draw_colored_polygon(pointer, bubble_color)
	if final_dialogue_stage == 1:
		text_at("CREW:", bubble_x + 18.0, bubble_y + 28.0, 20, Color(0.46, 0.9, 1.0))
		text_at("Sir, we have picked up an orb.", bubble_x + 18.0, bubble_y + 58.0, 19)
		text_at("It is giving off some kind", bubble_x + 18.0, bubble_y + 85.0, 19)
		text_at("of energy!", bubble_x + 18.0, bubble_y + 112.0, 19)
	else:
		text_at("CAPTAIN:", bubble_x + 18.0, bubble_y + 28.0, 20, Color(1.0, 0.83, 0.43))
		text_at("Put it inside the isolated box.", bubble_x + 18.0, bubble_y + 58.0, 19)
		text_at("We will examine it later", bubble_x + 18.0, bubble_y + 85.0, 19)
		text_at("back at HQ.", bubble_x + 18.0, bubble_y + 112.0, 19)


func _draw() -> void:
	if state == "menu_confirm_new":
		draw_new_game_confirmation()
		return
	if state == "main_menu":
		draw_main_menu()
		if show_performance_stats:
			var fps_menu := Engine.get_frames_per_second()
			var frame_ms_menu := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			draw_rect(Rect2(474.0, 236.0, 231.0, 65.0), Color(0.025, 0.06, 0.13, 0.94))
			text_at("FPS %d" % fps_menu, 492.0, 264.0, 23, Color(0.52, 1.0, 0.63) if fps_menu >= 55 else Color(1.0, 0.58, 0.43))
			text_at("CPU frame %.1f ms [F3]" % frame_ms_menu, 490.0, 288.0, 15, Color(0.84, 0.91, 1.0))
		return
	if state == "menu_options":
		draw_options_menu()
		if show_performance_stats:
			var fps_options := Engine.get_frames_per_second()
			var frame_ms_options := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			draw_rect(Rect2(474.0, 236.0, 231.0, 65.0), Color(0.025, 0.06, 0.13, 0.94))
			text_at("FPS %d" % fps_options, 492.0, 264.0, 23, Color(0.52, 1.0, 0.63) if fps_options >= 55 else Color(1.0, 0.58, 0.43))
			text_at("CPU frame %.1f ms [F3]" % frame_ms_options, 490.0, 288.0, 15, Color(0.84, 0.91, 1.0))
		return
	if state == "menu_bindings":
		draw_bindings_menu()
		return
	if state == "menu_highscores":
		draw_high_scores_screen()
		if show_performance_stats:
			var fps_scores := Engine.get_frames_per_second()
			var frame_ms_scores := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			draw_rect(Rect2(474.0, 236.0, 231.0, 65.0), Color(0.025, 0.06, 0.13, 0.94))
			text_at("FPS %d" % fps_scores, 492.0, 264.0, 23, Color(0.52, 1.0, 0.63) if fps_scores >= 55 else Color(1.0, 0.58, 0.43))
			text_at("CPU frame %.1f ms [F3]" % frame_ms_scores, 490.0, 288.0, 15, Color(0.84, 0.91, 1.0))
		return
	
	var is_playfield := state in ["playing", "intermission", "boss_intro", "boss_rewards"]
	var has_animated_port := is_playfield and city_name() in ["ZADAR", "RIJEKA", "SPLIT", "OSIJEK", "ZAGREB"]
	if has_animated_port:
		if city_name() == "ZADAR":
			draw_zadar_background()
		elif city_name() == "RIJEKA":
			draw_rijeka_background()
		elif city_name() == "SPLIT":
			draw_split_background()
		elif city_name() == "OSIJEK":
			draw_osijek_background()
		else:
			draw_zagreb_background()

	# Both animated backdrops are opaque; skip ornamental stars behind them.
	if not has_animated_port:
		for star in stars:
			draw_circle(star, 1.5, Color(0.45, 0.65, 0.9, 0.55))
	text_at("%s LVL %d/%d WAVE %d/%d SCORE %d" % [city_name(), level, MAX_LEVEL, waves_spawned, waves_for_level(), score], 20, 35, 18)
	# The same little blue ship silhouette used for the player represents lives.
	var life_icon := PackedVector2Array([Vector2(36, 43), Vector2(24, 67), Vector2(36, 62), Vector2(48, 67)])
	draw_colored_polygon(life_icon, Color(0.2, 0.8, 1.0))
	draw_circle(Vector2(36, 58), 3.2, Color(1.0, 0.9, 0.3))
	text_at("x%d     SCRAP %d" % [lives, scrap], 61, 66, 21, Color(0.8, 0.95, 0.7))
	text_at("BEST %d" % maxi(score, int(high_scores[0]["score"]) if not high_scores.is_empty() else 0), 480, 66, 19, Color(1.0, 0.88, 0.5))
	if debug_run:
		text_at("DEBUG RUN", 570, 132, 16, Color(1.0, 0.65, 0.35))
	if god_mode:
		text_at("GOD MODE / ONE SHOT [O]", 440, 101, 17, Color(0.35, 1.0, 0.68))
	for orb_i in range(4):
		var orb_color: Color = ORB_COLORS[orb_i]
		draw_circle(Vector2(360.0 + float(orb_i) * 24.0, 59.0), 8.0, orb_color if (collected_orb_mask & (1 << orb_i)) != 0 else Color(0.2, 0.25, 0.34))
	# Fifth slot tracks only the final white Zone Guardian trophy.
	draw_circle(Vector2(456.0, 59.0), 9.0, Color.WHITE if white_orb_collected else Color(0.2, 0.25, 0.34))
	if ability_time > 0.0:
		text_at("R SHIELD: %.1fs" % ability_time, 20, 96, 19, Color(0.3, 1.0, 1.0))
	elif ability_cooldown > 0.0:
		text_at("R RECHARGE: %.1fs" % ability_cooldown, 20, 96, 19, Color(0.9, 0.75, 0.5))
	else:
		text_at("R SHIELD READY (Lv.%d)" % ability_level, 20, 96, 19, Color(0.4, 1.0, 0.7))
	# Compact Warblade-inspired S/F status indicators; no large box obscuring enemies.
	draw_rect(Rect2(14, 111, 291, 82), Color(0.05, 0.11, 0.2, 0.80))
	draw_stat_meter("SPEED", speed_level, 4, 25, 135, Color(0.24, 0.7, 1.0))
	draw_stat_meter("FIRE", rate_level, 4, 25, 162, Color(1.0, 0.38, 0.3))
	text_at("%s - SHIP STATUS" % binding_name(bindings[5]), 27, 183, 14, Color(0.7, 0.85, 0.98))
	if not active_multipliers.is_empty():
		draw_rect(Rect2(385, 168, 316, 65), Color(0.17, 0.10, 0.26, 0.90))
		text_at("SCORE x%d" % score_multiplier(), 399, 195, 24, Color(1.0, 0.85, 0.35))
		text_at("%.1fs remaining" % multiplier_time_left(), 400, 220, 17, Color(0.95, 0.85, 1.0))
	if state == "playing" or state == "intermission" or state == "boss_intro" or state == "boss_rewards":
		if invulnerable <= 0.0 or int(Time.get_ticks_msec() / 100) % 2 == 0:
			
			draw_player_ship_25d(Vector2(player_x, PLAYER_Y))

		if ability_time > 0.0:
			draw_arc(Vector2(player_x, PLAYER_Y), 43.0, 0.0, TAU, 48, Color(0.3, 0.95, 1.0, 0.95), 5.0)
	for bullet in player_bullets:
		var shot_pos: Vector2 = bullet["pos"]
		var shot_velocity: Vector2 = bullet["velocity"]
		var direction := shot_velocity.normalized()
		draw_line(shot_pos - direction * 11.0, shot_pos + direction * 11.0, bullet.get("color", Color(1.0, 0.92, 0.25)), 6.0, true)
	for shot in enemy_bullets:
		draw_circle(shot, 7.0, Color(1.0, 0.3, 0.18))
	for bullet in radial_bullets:
		var radial_pos: Vector2 = bullet["pos"]
		if radial_pos.x < -10.0 or radial_pos.x > W + 10.0 or radial_pos.y < -10.0 or radial_pos.y > H + 10.0:
			continue
		draw_circle(radial_pos, 9.0, bullet.get("color", Color(1.0, 0.35, 0.65)))
		draw_circle(radial_pos, 4.0, Color(1.0, 0.88, 0.7))
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
		# Visibility check affects rendering only: off-screen enemies still fly,
		# shoot, take damage and count toward level completion as before.
		if pos.x < -58.0 or pos.x > W + 58.0 or pos.y < -58.0 or pos.y > H + 58.0:
			continue
		match int(enemy["kind"]):
			0:
				draw_jellyfish_25d(pos)
			1:
				draw_crab_25d(pos)
			2:
				draw_eel_25d(pos)
	if boss_active and not boss.is_empty():
		var pos: Vector2 = boss["pos"]
		draw_boss_25d(pos)
		if spin_countdown > 0.0:
			draw_arc(pos, 106.0, 0.0, TAU, 64, Color(1.0, 0.25, 0.65, 0.9), 5.0)
			text_at("360 ATTACK!  R SHIELD!", 201, 230, 25, Color(1.0, 0.5, 0.65))
		if level != MAX_LEVEL and boss_warning_time > 0.0:
			# Keep the regular lieutenants' aimed-shot telegraph; hide it for the final Guardian.
			draw_rect(Rect2(boss_warning_x - 25.0, 215.0, 50.0, H - 295.0), Color(1.0, 0.16, 0.1, 0.16))
			draw_line(Vector2(boss_warning_x, 215.0), Vector2(boss_warning_x, H - 80.0), Color(1.0, 0.35, 0.25, 0.7), 2.0)
		# HP remains the main red bar. Separate shield HP segments sit directly below it.
		draw_rect(Rect2(150, 85, 420, 12), Color(0.25, 0.25, 0.35))
		draw_rect(Rect2(150, 85, 420 * clampf(float(boss["hp"]) / float(boss["max_hp"]), 0.0, 1.0), 12), Color(0.9, 0.25, 0.3))
		var shield_max := 4 if level == MAX_LEVEL else 2
		var shield_segment_width := 420.0 / float(shield_max)
		var shield_fraction := clampf(boss_shield_hp / maxf(1.0, boss_shield_max_hp), 0.0, 1.0)
		draw_rect(Rect2(150, 102, 420, 9), Color(0.09, 0.19, 0.31))
		for shield_segment in range(shield_max):
			var segment_left := 150.0 + float(shield_segment) * shield_segment_width
			var segment_fill := clampf(shield_fraction * float(shield_max) - float(shield_segment), 0.0, 1.0)
			draw_rect(Rect2(segment_left + 2.0, 103.0, shield_segment_width - 4.0, 7.0), Color(0.12, 0.24, 0.36))
			if segment_fill > 0.0:
				draw_rect(Rect2(segment_left + 2.0, 103.0, (shield_segment_width - 4.0) * segment_fill, 7.0), Color(0.27, 0.83, 1.0))
		var shield_hp_text := "%d/%d" % [ceili(boss_shield_hp), ceili(boss_shield_max_hp)]
		var boss_status := "ZONE GUARDIAN | SHIELD %d/2: %s HP" % [boss_shield_round, shield_hp_text] if level == MAX_LEVEL else "CITY GUARDIAN | SHIELD: %s HP" % shield_hp_text
		text_at(boss_status, 155, 135, 18)
	for drop in drops:
		var pos: Vector2 = drop["pos"]
		if drop.get("kind", "scrap") == "multiplier":
			draw_circle(pos, 21.0, Color(0.75, 0.32, 0.97))
			draw_arc(pos, 20.0, 0.0, TAU, 28, Color(1.0, 0.84, 0.3), 3.0)
			text_at("x%d" % int(drop["factor"]), pos.x - 15.0, pos.y + 7.0, 22, Color.WHITE)
		elif drop.get("kind", "scrap") == "white_orb":
			draw_circle(pos, 23.0, Color(0.5, 0.78, 1.0, 0.55))
			draw_circle(pos, 17.0, Color(1.0, 1.0, 1.0))
			draw_circle(pos + Vector2(-5.0, -6.0), 6.0, Color(0.77, 0.93, 1.0))
		elif drop.get("kind", "scrap") == "life_orb":
			var orb_color: Color = ORB_COLORS[int(drop["orb_index"])]
			draw_circle(pos, 19.0, orb_color.darkened(0.45))
			draw_circle(pos, 13.0, orb_color)
			draw_circle(pos + Vector2(-4.0, -5.0), 4.0, Color(1.0, 1.0, 1.0, 0.9))
		elif drop.get("kind", "scrap") == "double_shot":
			# Smaller cube pickup with two parallel blue bars, matching the Double Shot look.
			draw_rect(Rect2(pos.x - 14.0, pos.y - 14.0, 28.0, 28.0), Color(0.07, 0.24, 0.48))
			draw_rect(Rect2(pos.x - 12.0, pos.y - 12.0, 24.0, 24.0), Color(0.10, 0.33, 0.62))
			draw_rect(Rect2(pos.x - 14.0, pos.y - 14.0, 28.0, 3.0), Color(0.43, 0.83, 1.0))
			draw_rect(Rect2(pos.x - 14.0, pos.y + 11.0, 28.0, 3.0), Color(0.04, 0.14, 0.28))
			draw_rect(Rect2(pos.x - 9.0, pos.y - 8.0, 4.0, 16.0), Color(0.72, 0.96, 1.0))
			draw_rect(Rect2(pos.x + 5.0, pos.y - 8.0, 4.0, 16.0), Color(0.72, 0.96, 1.0))
		elif drop.get("kind", "scrap") == "triple_shot":
			# Purple pickup with three vertical bars.
			draw_rect(Rect2(pos.x - 16.0, pos.y - 15.0, 32.0, 30.0), Color(0.22, 0.09, 0.42))
			draw_rect(Rect2(pos.x - 13.0, pos.y - 12.0, 26.0, 24.0), Color(0.50, 0.27, 0.75))
			for bar_x in [-9.0, -2.0, 5.0]:
				draw_rect(Rect2(pos.x + bar_x, pos.y - 8.0, 4.0, 16.0), Color(0.93, 0.79, 1.0))
		else:
			draw_circle(pos, 9.0, Color(0.95, 0.82, 0.25))
			draw_circle(pos, 4.0, Color(0.45, 0.3, 0.08))
	for effect in explosions:
		var pos: Vector2 = effect["pos"]
		draw_arc(pos, 30.0 * float(effect["time"]) / 0.3 + 8.0, 0, TAU, 20, Color(1.0, 0.68, 0.2), 4.0)
	if state == "boss_intro":
		# Separate lieutenant announcement instead of an abrupt boss spawn.
		draw_rect(Rect2(42, 338, 636, 190), Color(0.08, 0.07, 0.17, 0.94))
		draw_rect(Rect2(42, 338, 636, 5), Color(0.8, 0.36, 0.94))
		if level == MAX_LEVEL:
			text_at("THE GUARDIAN HAS COME", 136, 405, 29, Color(1.0, 0.91, 0.9))
			text_at("TO DEAL WITH YOU", 198, 448, 29, Color(1.0, 0.74, 0.77))
			text_at("PERSONALLY", 259, 492, 33, Color(1.0, 0.53, 0.62))
		else:
			text_at("THE GUARDIAN OF THIS ZONE", 85, 403, 29, Color(0.95, 0.85, 1.0))
			text_at("HAS SENT HIS LIEUTENANT", 103, 445, 28, Color(0.95, 0.85, 1.0))
			text_at("TO DEAL WITH YOU", 207, 487, 29, Color(1.0, 0.65, 0.75))
	if state == "intermission" and level_transition_time <= LEVEL_TITLE_SECONDS:
		# First 10 seconds are silent; only show the level title near wave entry.
		draw_rect(Rect2(144, 369, 432, 114), Color(0.04, 0.10, 0.23, 0.87))
		draw_rect(Rect2(144, 369, 432, 4), Color(0.25, 0.73, 1.0))
		var level_title := "%s - LEVEL %d" % [city_name(), level]
		var title_size := 35
		var title_width := font.get_string_size(level_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
		text_at(level_title, (W - title_width) / 2.0, 442, title_size, Color(0.92, 0.97, 1.0))
	if state == "boss_rewards" and level == MAX_LEVEL:
		# Keep this message visible even before the white orb is collected.
		draw_rect(Rect2(156.0, 205.0, 408.0, 63.0), Color(0.06, 0.16, 0.23, 0.88))
		text_at("ZONE LIBERATED", 195, 249, 33, Color(0.61, 1.0, 0.74))
		draw_final_orb_speech()
	if state == "shop":
		draw_rect(Rect2(52, 190, 616, 555), Color(0.07, 0.12, 0.23, 0.96))
		text_at("PRE-BOSS SHOP - %s" % city_name() if pre_boss_shop else "%s LIBERATED!" % city_name(), 136, 250, 27)
		text_at("SCRAP: %d" % scrap, 250, 296, 26, Color(0.95, 0.85, 0.3))
		if speed_level >= 4:
			text_at("1 - Extra Speed: MAX", 105, 353, 22)
		else:
			text_at("1 - Extra Speed Lv.%d/4  (%d)" % [speed_level, upgrade_cost(1)], 105, 353, 22)
		if rate_level >= 4:
			text_at("2 - Rate of Fire: MAX", 105, 407, 22)
		else:
			text_at("2 - Rate of Fire Lv.%d/4 (%d)" % [rate_level, upgrade_cost(2)], 105, 407, 22)
		if damage_level >= 3:
			text_at("3 - Double Shot: OWNED", 105, 461, 22, Color(0.25, 0.66, 1.0))
		else:
			text_at("3 - Double Shot (%d Scrap)" % upgrade_cost(3), 105, 461, 22, Color(0.25, 0.66, 1.0))
		if damage_level >= 6:
			text_at("4 - Triple Shot: OWNED", 105, 515, 22, Color(0.78, 0.55, 1.0))
		else:
			text_at("4 - Triple Shot (%d Scrap)" % upgrade_cost(4), 105, 515, 22, Color(0.78, 0.55, 1.0))
		if ability_level >= 3:
			text_at("5 - Shield Upgrade: MAX", 105, 569, 22)
		else:
			text_at("5 - Shield Upgrade Lv.%d/3 (%d)" % [ability_level, upgrade_cost(5)], 105, 569, 22)
		# In-shop ship stats are live and update immediately after a purchase.
		text_at("SHIP SPEED  %d px/s  Lv.%d/4" % [int(BASE_SPEED + speed_level * SPEED_STEP), speed_level], 105, 616, 17, Color(0.55, 0.83, 1.0))
		text_at("FIRE RATE  %.2f shots/s  Lv.%d/4" % [shots_per_second(), rate_level], 105, 640, 17, Color(1.0, 0.65, 0.5))
		text_at("%s SHOT  |  SHIELD Lv.%d/3" % [equipped_weapon_name(), ability_level], 105, 664, 17, Color(0.6, 0.96, 0.76))
		text_at("ENTER - FACE THE GUARDIAN" if pre_boss_shop else ("ENTER - View results" if level >= MAX_LEVEL else "ENTER - Next mission"), 137, 707, 24, Color(0.4, 0.9, 1.0))
		text_at("M / ESC - MAIN MENU (SAVED)", 163, 729, 16, Color(0.74, 0.95, 0.79))
	elif state == "gameover" or state == "victory":
		if state == "victory" and not awaiting_score_name and not victory_show_scores:
			draw_campaign_finale()
		else:
			draw_leaderboard()
			if state == "victory":
				text_at("CROATIA LIBERATED!", 186, 174, 29, Color(0.45, 1.0, 0.7))
			else:
				text_at("GAME OVER", 258, 174, 29, Color(1.0, 0.35, 0.4))
	if state in ["playing", "intermission", "boss_intro", "boss_rewards", "shop"]:
		text_at("M music %s [%d%%]  [ ] volume   , . SFX [%d%%]" % ["ON" if music_enabled else "OFF", int(music_volume * 100.0), int(sfx_volume * 100.0)], 19, H - 42, 15, Color(0.74, 0.90, 1.0))
	if show_stats_modal and (state == "playing" or state == "intermission" or state == "boss_intro" or state == "boss_rewards"):
		draw_ship_status_modal()
	if game_paused and state in ["playing", "intermission", "boss_intro", "boss_rewards"]:
		draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.02, 0.06, 0.78))
		if pause_screen == "options":
			draw_options_menu(true)
		elif pause_screen == "bindings":
			draw_bindings_menu()
		elif pause_screen == "confirm":
			draw_rect(Rect2(65, 319, 590, 308), Color(0.06, 0.11, 0.23, 0.99))
			draw_rect(Rect2(65, 319, 590, 5), Color(0.97, 0.57, 0.30))
			text_at("ARE YOU SURE?", 203, 381, 34, Color(1.0, 0.85, 0.70))
			text_at("If you leave now, all unsaved", 114, 435, 22)
			text_at("progress will be lost.", 218, 468, 22)
			text_at("Your last checkpoint stays saved.", 139, 508, 18, Color(0.69, 0.89, 1.0))
			for choice in range(2):
				var selected := pause_confirm_yes == (choice == 0)
				var x := 157.0 + float(choice) * 226.0
				draw_rect(Rect2(x, 533, 185, 55), Color(0.68, 0.25, 0.25) if selected and choice == 0 else (Color(0.15, 0.50, 0.45) if selected else Color(0.12, 0.19, 0.29)))
				text_at("YES" if choice == 0 else "NO", x + 66.0, 571, 26, Color.WHITE)
		else:
			draw_rect(Rect2(122, 285, 476, 374), Color(0.06, 0.12, 0.23, 0.99))
			draw_rect(Rect2(122, 285, 476, 5), Color(0.28, 0.78, 1.0))
			text_at("GAME PAUSED", 222, 358, 35, Color(0.9, 0.96, 1.0))
			for i in range(3):
				var label: String = ["RESUME", "OPTIONS", "MAIN MENU"][i]
				var y := 391.0 + float(i) * 65.0
				draw_rect(Rect2(173, y, 375, 52), Color(0.17, 0.48, 0.67) if pause_menu_selection == i else Color(0.09, 0.17, 0.29))
				text_at(label, 268 if i != 2 else 254, y + 34, 25)
			text_at("ARROWS / ENTER SELECT   ESC RESUME", 160, 623, 16, Color(0.73, 0.88, 1.0))
	text_at("MOVE %s/%s  FIRE %s  SHIELD %s  PAUSE %s" % [binding_name(bindings[0]), binding_name(bindings[1]), binding_name(bindings[2]), binding_name(bindings[3]), binding_name(bindings[4])], 14, H - 22, 16, Color(0.65, 0.8, 0.95))
	if state == "city_select":
		draw_city_map()
	elif state == "mission_briefing":
		draw_mission_briefing()
	elif state == "city_flight":
		draw_city_flight()
	if debug_level_menu:
		draw_debug_level_menu()
	if show_performance_stats:
		var fps := Engine.get_frames_per_second()
		var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		draw_rect(Rect2(474.0, 236.0, 231.0, 65.0), Color(0.025, 0.06, 0.13, 0.94))
		text_at("FPS %d" % fps, 492.0, 264.0, 23, Color(0.52, 1.0, 0.63) if fps >= 55 else Color(1.0, 0.58, 0.43))
		text_at("CPU frame %.1f ms [F3]" % frame_ms, 490.0, 288.0, 15, Color(0.84, 0.91, 1.0))