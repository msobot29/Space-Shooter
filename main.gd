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
const WAVE_DELAY := 5.0
const LEVEL_TRANSITION_SECONDS := 5.0 # Silent pause before showing the title
const LEVEL_TITLE_SECONDS := 3.5 # Enemies begin after the title is shown
const BOSS_INTRO_SECONDS := 3.8
const STORM_WARNING_SECONDS := 1.3
const STORM_PULSE_INTERVAL := 0.62
const ORB_COLORS := [Color(1.0, 0.28, 0.3), Color(0.3, 0.68, 1.0), Color(0.38, 1.0, 0.52), Color(1.0, 0.78, 0.22)]
const ENEMIES_PER_WAVE := 10
# Warblade-inspired pacing, not verified exact Warblade Classic stage counts.
# 20/30/40 enemies per stage, launched as successive ten-enemy formations.
const ENEMY_WAVES_BY_CITY_STAGE := [2, 2, 3, 3, 4]
const BOSS_REWARD_SECONDS := 8.0
const CAMPAIGN_BASE := Vector2(492.0, 616.0)
const DOUBLE_DROP_CHANCE := 0.12
const DOUBLE_DROP_PITY_KILLS := 18

var font: Font
var stars: Array[Vector2] = []

# ZADAR - ANIMATED BACKGROUND
var bg_scroll_far := 0.0
var bg_scroll_mid := 0.0
var bg_scroll_near := 0.0

const BG_SPEED_FAR := 22.0
const BG_SPEED_MID := 48.0
const BG_SPEED_NEAR := 90.0

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
var state := "city_select" # city_select, city_flight, playing, intermission, boss_intro, shop, gameover, victory
var city_route: Array[int] = []
var selected_city := 0
var city_flight_time := 0.0
var boss_reward_time := 0.0
var boss_intro_time := 0.0
var level_transition_time := 0.0
var show_stats_modal := false
var game_paused := false
var god_mode := false # Local QA toggle (O key), blocks actual life and weapon loss
var debug_level_menu := false
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
var boss_shields := 2
var boss_shield_round := 1
var storm_warning_time := 0.0
var storm_pulses_remaining := 0
var storm_pulse_time := 0.0
var storm_safe_lane := 4
var collected_orb_mask := 0
var white_orb_collected := false # Final Zagreb guardian trophy, independent of four life-orb colors
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


func update_background(delta: float) -> void:
	bg_scroll_far = fposmod(bg_scroll_far + BG_SPEED_FAR * delta, H)
	bg_scroll_mid = fposmod(bg_scroll_mid + BG_SPEED_MID * delta, H)
	bg_scroll_near = fposmod(bg_scroll_near + BG_SPEED_NEAR * delta, H)


func draw_zadar_background() -> void:
	# Deep Adriatic sea
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.025, 0.14, 0.24))

	# Distant moving water
	for i in range(10):
		var y := fposmod(float(i) * 120.0 + bg_scroll_far, H + 120.0) - 120.0
		draw_rect(Rect2(0.0, y, W, 52.0), Color(0.08, 0.26, 0.38, 0.34))

	# Islands moving at medium speed
	for i in range(5):
		var y := fposmod(float(i) * 245.0 + bg_scroll_mid, H + 245.0) - 245.0
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
		var y := fposmod(float(i) * 85.0 + bg_scroll_near, H + 85.0) - 85.0
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

func city_name() -> String:
	var slot := clampi(int((level - 1) / 5), 0, 4)
	return CITY_NAMES[city_route[slot]] if slot < city_route.size() else CITY_NAMES[slot]

func city_mission() -> int:
	return ((level - 1) % 5) + 1

func waves_for_level() -> int:
	# Warblade Classic's exact stage-by-stage enemy totals are not verified.
	# Our ten-unit mirrored groups scale from 20 to 40 enemies per stage.
	if level == MAX_LEVEL:
		return 0 # Classic Warblade level 25 is a standalone boss fight.
	return ENEMY_WAVES_BY_CITY_STAGE[city_mission() - 1]

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	load_high_scores()
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
	state = "city_select"
	queue_redraw()


func city_selectable(city_index: int) -> bool:
	if city_index < 0 or city_index >= 5 or city_route.has(city_index):
		return false
	return city_index != 4 or city_route.size() == 4


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
	queue_redraw()


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
				start_city_flight(city_index)
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
	white_orb_collected = false
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


func start_level() -> void:
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
	boss_pending = level % 5 == 0 # City guardian every 5 levels; final boss at 25
	boss_intro_time = 0.0
	boss_reward_time = 0.0
	waves_spawned = 0
	wave_path_ids.clear()
	boss_phase = 1
	boss_shields = 4 if level == MAX_LEVEL else 2
	boss_shield_round = 1
	storm_warning_time = 0.0
	storm_pulses_remaining = 0
	storm_pulse_time = 0.0
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
	target_kills = waves_for_level() * ENEMIES_PER_WAVE
	if level == MAX_LEVEL:
		# Zone Guardian battle: no ordinary enemy waves before the boss.
		begin_boss_intro()
	else:
		spawn_wave()
	queue_redraw()

func begin_level_transition() -> void:
	# Preserve falling rewards during the silent break and level-title intro.
	state = "intermission"
	level_transition_time = LEVEL_TRANSITION_SECONDS + LEVEL_TITLE_SECONDS
	player_bullets.clear()
	enemy_bullets.clear()
	radial_bullets.clear()
	explosions.clear()
	queue_redraw()

func spawn_wave() -> void:
	# Two mirrored groups of five, with red crabs always guarding the front line.
	waves_spawned += 1
	var path_id := randi_range(0, 3)
	# Later missions rotate entry patterns, but keep the same smooth motion.
	wave_path_ids.append(path_id)
	for side in range(2):
		for index in range(5):
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
			# More than two waves need only a modest shift, not an ever-lower
			# formation that collides with the player's flight lane.
			var target_pos := Vector2(formation_x, row_y + float((waves_spawned - 1) % 2) * 20.0)
			var start_pos := Vector2(-85.0 - float(index) * 35.0 if left else W + 85.0 + float(index) * 35.0, 110.0 + float(index) * 38.0)
			enemies.append({
				"pos": start_pos,
				"prev_pos": start_pos,
				"start": start_pos,
				"target": target_pos,
				"age": 0.0,
				"delay": float(index) * 0.19 + float(side) * 0.07,
				"path": path_id,
				"side": -1.0 if left else 1.0,
				"offset": float(index) * 0.26,
				"hp": 5 + mini(int((level - 1) / 5), 4) if is_guard else 2 + mini(int((level - 1) / 5), 4),
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
	boss_fire_clock = 1.4
	spin_countdown = 0.0
	spin_rotation = 0.0


func _process(delta: float) -> void:
	if debug_level_menu or game_paused or show_stats_modal:
		queue_redraw()
		return
	
	if city_name() == "ZADAR" and state in [
		"playing",
		"intermission",
		"boss_intro",
		"boss_rewards"
	]:
		update_background(delta)


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
		if boss_reward_time <= 0.0:
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
			begin_boss_intro()
		else:
			complete_level()
	queue_redraw()

func update_player(delta: float) -> void:
	var move := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A):
		move -= 1.0
	if Input.is_key_pressed(KEY_D):
		move += 1.0
	player_x = clampf(player_x + clampf(move, -1.0, 1.0) * (BASE_SPEED + speed_level * SPEED_STEP) * delta, 28.0, W - 28.0)
	fire_clock = maxf(0.0, fire_clock - delta)
	var pressed := Input.is_key_pressed(KEY_B) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
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
		enemy_fire_clock = maxf(0.56, 1.43 - float(level) * 0.085)

func launch_enemy_shot(origin: Vector2, velocity: Vector2, tint: Color) -> void:
	radial_bullets.append({"pos": origin, "velocity": velocity, "color": tint})

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
		for lane in range(-1, 2):
			enemy_bullets.append(Vector2(boss_warning_x + lane * 22.0, pos.y + 38.0))
	if boss_fire_clock <= 0.0:
		if level == MAX_LEVEL and boss_attack_index % 4 == 3:
			begin_adriatic_storm()
		elif boss_attack_index % 3 == 0:
			for lane in range(-2, 3):
				enemy_bullets.append(pos + Vector2(lane * 42.0, 38.0))
		elif boss_attack_index % 3 == 2:
			boss_warning_x = player_x
			boss_warning_time = 0.7
		else:
			spin_countdown = SPIN_WARNING
			spin_rotation = 0.0
			# The next volley begins only after the warning and rotation.
		boss_attack_index += 1
		boss_fire_clock = (1.20 if boss_phase == 1 else 0.98) if level == MAX_LEVEL else (1.5 if boss_phase == 1 else 1.2)
	if level == MAX_LEVEL and boss_shield_round == 1 and boss_shields == 0 and float(boss["hp"]) <= 500.0:
		# Distinct second shield round at half health, once only.
		boss_shield_round = 2
		boss_shields = 4
	if boss_phase == 1 and float(boss["hp"]) <= float(boss["max_hp"]) * 0.475:
		boss_phase = 2

func begin_adriatic_storm() -> void:
	# The safe lane is two columns away from the player: reachable after warning.
	var player_lane := clampi(int(round((player_x - 40.0) / 80.0)), 0, 8)
	storm_safe_lane = clampi(player_lane + (2 if player_lane <= 4 else -2), 0, 8)
	storm_warning_time = STORM_WARNING_SECONDS
	storm_pulses_remaining = 3
	storm_pulse_time = 0.0


func fire_adriatic_storm_pulse() -> void:
	# One clear corridor across all three barrages; remaining lanes are dangerous.
	for lane in range(9):
		if lane == storm_safe_lane:
			continue
		var origin := Vector2(40.0 + float(lane) * 80.0, 195.0)
		radial_bullets.append({
			"pos": origin,
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
			var impact := previous.lerp(shot, first_hit)
			explosions.append({"pos": impact, "time": 0.16})
			if boss_hit:
				if god_mode:
					# QA one-shot: bypass both shield rounds and defeat any boss instantly.
					boss_shields = 0
					boss_shield_round = 2
					boss["hp"] = 0.0
				elif boss_shields > 0:
					boss_shields -= 1
				else:
					boss["hp"] = maxf(0.0, float(boss["hp"]) - (2.0 + damage_level))
				if boss_shields == 0 and float(boss["hp"]) <= 0.0:
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
		enemy_bullets[i].y += (240.0 + level * 18.0) * delta
		if enemy_bullets[i].y > H + 20.0:
			enemy_bullets.remove_at(i)
		elif enemy_bullets[i].distance_to(Vector2(player_x, PLAYER_Y)) < 24.0:
			enemy_bullets.remove_at(i)
			take_damage()

func take_damage() -> void:
	if god_mode or invulnerable > 0.0 or ability_time > 0.0:
		return
	lives -= 1
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
	if collected_orb_mask == 15:
		lives += 1
		collected_orb_mask = 0 # Start a new four-color collection.
		explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.5})


func has_double_shot_drop() -> bool:
	for pickup in drops:
		if pickup.get("kind", "scrap") == "double_shot":
			return true
	return false

func try_drop_double_shot(pos: Vector2) -> void:
	# Limited to the single-shot stage; no duplicate Double Shot pickups.
	if damage_level >= 3 or has_double_shot_drop():
		return
	single_shot_kills_since_drop += 1
	if randf() < DOUBLE_DROP_CHANCE or single_shot_kills_since_drop >= DOUBLE_DROP_PITY_KILLS:
		single_shot_kills_since_drop = 0
		drops.append({
			"kind": "double_shot",
			"pos": pos,
			"fall_speed": 230.0
		})

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
			if drops[i].get("kind", "scrap") == "double_shot":
				if damage_level < 3:
					damage_level = 3 # Permanent unlock: shop now shows OWNED.
					single_shot_kills_since_drop = 0
					explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.32})
			elif drops[i].get("kind", "scrap") == "life_orb":
				collect_life_orb(int(drops[i]["orb_index"]))
			elif drops[i].get("kind", "scrap") == "white_orb":
				white_orb_collected = true
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
	# Shop only after each group of five missions, never after ordinary stages.
	if level % 5 == 0:
		state = "shop"
	elif level >= MAX_LEVEL:
		finish_run(true)
	else:
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
	state = "victory" if won else "gameover"
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
	queue_redraw()

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
	else:
		text_at("Your score: %d" % score, 254, 738, 22, Color(1.0, 0.87, 0.60))
		text_at("ENTER - New game", 257, 781, 21, Color(0.55, 0.89, 1.0))

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

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	# F2 is accessible from gameplay, shop, victory, and test intermissions.
	if event.keycode == KEY_F2:
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
	if state == "city_select":
		match event.keycode:
			KEY_LEFT, KEY_UP:
				cycle_city(-1)
			KEY_RIGHT, KEY_DOWN:
				cycle_city(1)
			KEY_ENTER, KEY_KP_ENTER:
				start_city_flight(selected_city)
		queue_redraw()
		return
	# Test-only invulnerability hotkey: available in any game state.
	if event.keycode == KEY_O:
		god_mode = not god_mode
		queue_redraw()
		return
	if state == "shop":
		match event.keycode:
			KEY_1: buy_upgrade(1)
			KEY_2: buy_upgrade(2)
			KEY_3: buy_upgrade(3)
			KEY_4: buy_upgrade(4)
			KEY_5: buy_upgrade(5)

			KEY_ENTER, KEY_KP_ENTER:
				if level >= MAX_LEVEL:
					finish_run(true)
				else:
					# Each city ends in its own shop; then return to the map.
					show_city_map()
	elif state == "playing" or state == "intermission" or state == "boss_intro" or state == "boss_rewards":
		if event.keycode == KEY_P:
			game_paused = not game_paused
			if game_paused:
				show_stats_modal = false
		elif game_paused:
			return
		elif event.keycode == KEY_TAB:
			show_stats_modal = not show_stats_modal
		elif show_stats_modal:
			return
		elif event.keycode == KEY_R and ability_time <= 0.0 and ability_cooldown <= 0.0:
			ability_time = float(ability_level * 2)
			ability_cooldown = 0.0
	elif state == "gameover" or state == "victory":
		if awaiting_score_name:
			return
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
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
			white_orb_collected = false
			drops.clear() # A new run must not inherit old rewards.
			level = 1
			damage_level = 0
			rate_level = 0
			speed_level = 0
			ability_level = 1
			show_city_map()
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
	text_at("TAB - CLOSE / RESUME", 230, 652, 19, Color(0.80, 0.91, 1.0))

func _draw() -> void:
	
	if city_name() == "ZADAR" and state in [
		"playing",
		"intermission",
		"boss_intro",
		"boss_rewards"
	]:
		draw_zadar_background()


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
	text_at("TAB - SHIP STATUS", 27, 183, 14, Color(0.7, 0.85, 0.98))
	if not active_multipliers.is_empty():
		draw_rect(Rect2(385, 168, 316, 65), Color(0.17, 0.10, 0.26, 0.90))
		text_at("SCORE x%d" % score_multiplier(), 399, 195, 24, Color(1.0, 0.85, 0.35))
		text_at("%.1fs remaining" % multiplier_time_left(), 400, 220, 17, Color(0.95, 0.85, 1.0))
	if state == "playing" or state == "intermission" or state == "boss_intro" or state == "boss_rewards":
		if invulnerable <= 0.0 or int(Time.get_ticks_msec() / 100) % 2 == 0:
			var ship := PackedVector2Array([Vector2(player_x, PLAYER_Y - 36), Vector2(player_x - 27, PLAYER_Y + 23), Vector2(player_x, PLAYER_Y + 12), Vector2(player_x + 27, PLAYER_Y + 23)])
			draw_colored_polygon(ship, Color(0.2, 0.8, 1.0))
			draw_circle(Vector2(player_x, PLAYER_Y + 3), 7.0, Color(1.0, 0.9, 0.3))
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
		draw_circle(bullet["pos"], 9.0, bullet.get("color", Color(1.0, 0.35, 0.65)))
		draw_circle(bullet["pos"], 4.0, Color(1.0, 0.88, 0.7))
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
		match int(enemy["kind"]):
			0: # Jellyfish: glowing bell and trailing tentacles
				draw_circle(pos + Vector2(0, -5), 23.0, Color(0.45, 0.75, 1.0))
				draw_arc(pos + Vector2(0, -5), 22.0, PI, TAU, 20, Color(0.75, 0.95, 1.0), 4.0)
				for t in range(-2, 3):
					draw_line(pos + Vector2(t * 8.0, 8), pos + Vector2(t * 8.0 + sin(level_time * 4.0 + t) * 6.0, 31), Color(0.5, 0.9, 1.0), 3.0)
			1: # Armored crab: broad shell and pincers
				draw_circle(pos, 22.0, Color(0.95, 0.35, 0.22))
				draw_rect(Rect2(pos.x - 20, pos.y - 7, 40, 16), Color(0.55, 0.16, 0.16))
				draw_circle(pos + Vector2(-27, 7), 11.0, Color(1.0, 0.48, 0.3))
				draw_circle(pos + Vector2(27, 7), 11.0, Color(1.0, 0.48, 0.3))
			2: # Electric eel: thick connected body instead of a self-intersecting polygon.
				var wiggle := sin(level_time * 8.0 + pos.x * 0.015) * 7.0
				var tail := pos + Vector2(-22, 17 + wiggle)
				var mid := pos + Vector2(5, 5 - wiggle)
				var head := pos + Vector2(13, -16)
				draw_line(tail, mid, Color(0.16, 0.36, 0.1), 20.0, true)
				draw_line(mid, head, Color(0.16, 0.36, 0.1), 21.0, true)
				draw_line(tail, mid, Color(0.65, 1.0, 0.22), 14.0, true)
				draw_line(mid, head, Color(0.65, 1.0, 0.22), 15.0, true)
				draw_circle(head, 11.0, Color(0.65, 1.0, 0.22))
				draw_circle(head + Vector2(-3, -3), 3.0, Color.WHITE)
				draw_circle(head + Vector2(-3, -3), 1.2, Color(0.09, 0.16, 0.06))
	if boss_active and not boss.is_empty():
		var pos: Vector2 = boss["pos"]
		if level == MAX_LEVEL:
			# Massive central body and orbiting armored plates for Zagreb's guardian.
			draw_circle(pos, 112.0, Color(0.12, 0.25, 0.36))
			draw_arc(pos, 116.0, 0.0, TAU, 64, Color(0.35, 0.9, 1.0), 7.0)
		draw_circle(pos, 68.0, Color(0.24, 0.62, 0.48))
		for i in range(6):
			var angle := i * TAU / 6.0 + spin_rotation
			var p := pos + Vector2(cos(angle), sin(angle)) * 88.0
			draw_line(pos, p, Color(0.6, 0.9, 0.65), 13.0)
		draw_circle(pos, 25.0, Color(0.9, 0.2, 0.2) if boss_shields == 0 else Color(0.2, 0.65, 1.0))
		if spin_countdown > 0.0:
			draw_arc(pos, 106.0, 0.0, TAU, 64, Color(1.0, 0.25, 0.65, 0.9), 5.0)
			text_at("360 ATTACK!  R SHIELD!", 201, 230, 25, Color(1.0, 0.5, 0.65))
		if boss_warning_time > 0.0:
			draw_rect(Rect2(boss_warning_x - 25.0, 215.0, 50.0, H - 295.0), Color(1.0, 0.16, 0.1, 0.16))
			draw_line(Vector2(boss_warning_x, 215.0), Vector2(boss_warning_x, H - 80.0), Color(1.0, 0.35, 0.25, 0.7), 2.0)
		draw_rect(Rect2(150, 85, 420, 12), Color(0.25, 0.25, 0.35))
		draw_rect(Rect2(150, 85, 420 * float(boss["hp"]) / float(boss["max_hp"]), 12), Color(0.9, 0.25, 0.3))
		var boss_status := "ZONE GUARDIAN | SHIELD ROUND %d/2: %d" % [boss_shield_round, boss_shields] if level == MAX_LEVEL else "CITY GUARDIAN | SHIELD %d" % boss_shields
		text_at(boss_status, 155, 118, 18)
		if level == MAX_LEVEL and storm_warning_time > 0.0:
			for lane in range(9):
				if lane == storm_safe_lane:
					continue
				var x := 40.0 + float(lane) * 80.0
				draw_rect(Rect2(x - 22.0, 180.0, 44.0, H - 250.0), Color(1.0, 0.3, 0.22, 0.20))
			text_at("ADRIATIC STORM! FIND THE OPEN LANE", 85, 264, 22, Color(1.0, 0.75, 0.33))
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
			draw_circle(pos, 22.0, Color(0.08, 0.27, 0.52))
			draw_arc(pos, 21.0, 0.0, TAU, 32, Color(0.35, 0.78, 1.0), 4.0)
			text_at("D", pos.x - 9.0, pos.y + 9.0, 28, Color(0.65, 0.94, 1.0))
		else:
			draw_circle(pos, 9.0, Color(0.95, 0.82, 0.25))
			draw_circle(pos, 4.0, Color(0.45, 0.3, 0.08))
	for effect in explosions:
		var pos: Vector2 = effect["pos"]
		draw_arc(pos, 30.0 * float(effect["time"]) / 0.3 + 8.0, 0, TAU, 20, Color(1.0, 0.68, 0.2), 4.0)
	if state == "boss_rewards":
		draw_rect(Rect2(75.0, 209.0, 570.0, 92.0), Color(0.05, 0.1, 0.22, 0.89))
		if level == MAX_LEVEL:
			text_at("ZONE GUARDIAN DEFEATED!", 118, 244, 27, Color(0.9, 0.98, 1.0))
			text_at("COLLECT THE WHITE ORB - %d s" % int(ceil(boss_reward_time)), 153, 283, 21, Color(1.0, 1.0, 1.0))
		else:
			text_at("LIEUTENANT DEFEATED!", 156, 244, 27, Color(0.68, 1.0, 0.72))
			text_at("COLLECT THE ORB - %d s" % int(ceil(boss_reward_time)), 198, 283, 22, Color(1.0, 0.89, 0.46))
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
	if state == "shop":
		draw_rect(Rect2(52, 190, 616, 555), Color(0.07, 0.12, 0.23, 0.96))
		text_at("%s LIBERATED!" % city_name(), 185, 250, 30)
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
		text_at("ENTER - View results" if level >= MAX_LEVEL else "ENTER - Next mission", 160, 707, 26, Color(0.4, 0.9, 1.0))
	elif state == "gameover" or state == "victory":
		draw_leaderboard()
		if state == "victory":
			text_at("CROATIA LIBERATED!", 186, 174, 29, Color(0.45, 1.0, 0.7))
		else:
			text_at("GAME OVER", 258, 174, 29, Color(1.0, 0.35, 0.4))
	if show_stats_modal and (state == "playing" or state == "intermission" or state == "boss_intro" or state == "boss_rewards"):
		draw_ship_status_modal()
	if game_paused and (state == "playing" or state == "intermission" or state == "boss_intro" or state == "boss_rewards"):
		draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.02, 0.06, 0.65))
		draw_rect(Rect2(124, 362, 472, 212), Color(0.06, 0.12, 0.23, 0.98))
		text_at("GAME PAUSED", 226, 449, 34, Color(0.9, 0.96, 1.0))
		text_at("Press P to resume", 228, 508, 23, Color(0.45, 0.9, 1.0))
	text_at("A/D: move  B/SPACE: fire  R: shield  P: pause  F2: levels", 14, H - 22, 16, Color(0.65, 0.8, 0.95))
	if state == "city_select":
		draw_city_map()
	elif state == "city_flight":
		draw_city_flight()
	if debug_level_menu:
		draw_debug_level_menu()
