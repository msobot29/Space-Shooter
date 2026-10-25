extends Node2D
## Adriatic Uprising - playable Croatia chapter prototype (levels 1-5).
## All sprites are procedural. Godot 4.x / GDScript 2.0.

const W := 720.0
const H := 960.0
const PLAYER_Y := 840.0
const BASE_SPEED := 295.0
const SPEED_STEP := 48.0
const SPIN_WARNING := 1.5
const SPIN_PROJECTILES := 48
const BULLET_SPEED := 820.0
const MAX_LEVEL := 5
const ABILITY_COOLDOWN := 10.0 # Starts after the shield expires
const WAVE_DELAY := 5.0
const ENEMIES_PER_WAVE := 10
const WAVES_PER_LEVEL := 2

var font: Font
var stars: Array[Vector2] = []
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
var state := "playing" # playing, shop, gameover, victory
var show_stats_modal := false
var game_paused := false
var enemies: Array[Dictionary] = []
var player_bullets: Array[Dictionary] = [] # Each shot stores pos and velocity
var enemy_bullets: Array[Vector2] = []
var radial_bullets: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var explosions: Array[Dictionary] = []
var fire_clock := 0.0
var enemy_fire_clock := 1.0
var spawn_clock := 0.0
var invulnerable := 0.0
var drift := 1.0
var boss: Dictionary = {}
var boss_active := false
var boss_fire_clock := 0.0
var boss_phase := 1
var boss_shields := 2
var boss_attack_index := 0
var boss_warning_time := 0.0
var boss_warning_x := 360.0
var spin_countdown := 0.0
var spin_rotation := 0.0
var level_time := 0.0
var kills := 0
var target_kills := 0
var waves_spawned := 0
var wave_path_ids: Array[int] = []
var boss_pending := false

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	for i in range(110):
		stars.append(Vector2(randf_range(0.0, W), randf_range(0.0, H)))
	start_level()

func start_level() -> void:
	state = "playing"
	show_stats_modal = false
	game_paused = false
	enemies.clear()
	player_bullets.clear()
	enemy_bullets.clear()
	radial_bullets.clear()
	drops.clear()
	explosions.clear()
	boss.clear()
	boss_active = false
	boss_pending = level == 4
	waves_spawned = 0
	wave_path_ids.clear()
	boss_phase = 1
	boss_shields = 2
	boss_attack_index = 0
	boss_warning_time = 0.0
	boss_warning_x = W / 2.0
	spin_countdown = 0.0
	spin_rotation = 0.0
	drift = 1.0
	fire_clock = 0.0
	enemy_fire_clock = 1.1
	boss_fire_clock = 1.0
	spawn_clock = 0.0
	invulnerable = 1.0
	ability_time = 0.0
	ability_cooldown = 0.0 # Ready again at the beginning of a mission.
	level_time = 0.0
	kills = 0
	target_kills = WAVES_PER_LEVEL * ENEMIES_PER_WAVE
	spawn_wave()
	queue_redraw()

func spawn_wave() -> void:
	# Two mirrored groups of five, with red crabs always guarding the front line.
	waves_spawned += 1
	var path_id := randi_range(0, 3)
	wave_path_ids.append(path_id)
	for side in range(2):
		for index in range(5):
			var left := side == 0
			var is_guard := index < 2
			var kind := 1 if is_guard else (0 if index == 2 or index == 4 else 2)
			var lane := index if is_guard else (index - 2) % 2
			var formation_x := (155.0 + float(lane) * 120.0) if left else (565.0 - float(lane) * 120.0)
			var row_y := (505.0 + float(index) * 45.0) if is_guard else (250.0 + float(index - 2) * 67.0)
			var target_pos := Vector2(formation_x, row_y + float(waves_spawned - 1) * 25.0)
			var start_pos := Vector2(-85.0 - float(index) * 35.0 if left else W + 85.0 + float(index) * 35.0, 110.0 + float(index) * 38.0)
			enemies.append({
				"pos": start_pos,
				"start": start_pos,
				"target": target_pos,
				"age": 0.0,
				"delay": float(index) * 0.19 + float(side) * 0.07,
				"path": path_id,
				"side": -1.0 if left else 1.0,
				"offset": float(index) * 0.26,
				"hp": 5 + int(level / 3) if is_guard else 2 + int(level / 3),
				"kind": kind
			})

func move_enemy(enemy: Dictionary, delta: float) -> void:
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

func launch_boss() -> void:
	boss_pending = false
	boss_active = true
	enemy_bullets.clear()
	boss = {"pos": Vector2(W / 2.0, 155.0), "hp": 200.0, "max_hp": 200.0, "direction": 1.0}
	boss_fire_clock = 1.4
	spin_countdown = 0.0
	spin_rotation = 0.0


func _process(delta: float) -> void:
	if game_paused or show_stats_modal:
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
	if waves_spawned == 1 and level_time >= WAVE_DELAY:
		spawn_wave()
	update_player(delta)
	update_enemies(delta)
	update_boss(delta)
	update_bullets(delta)
	update_pickups(delta)
	update_effects(delta)
	if lives <= 0:
		state = "gameover"
	elif waves_spawned == WAVES_PER_LEVEL and enemies.is_empty():
		if boss_active:
			if boss.is_empty():
				complete_level()
		elif boss_pending:
			launch_boss()
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
	fire_clock -= delta
	if (Input.is_key_pressed(KEY_B) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_clock <= 0.0:
		fire_weapon()
		fire_clock = maxf(0.12, 0.34 - rate_level * 0.05)

func add_player_bullet(offset_x: float, angle_degrees: float) -> void:
	# Negative angle goes left; positive angle goes right, with up as the forward axis.
	var radians := deg_to_rad(angle_degrees)
	var velocity := Vector2(sin(radians), -cos(radians)) * BULLET_SPEED
	player_bullets.append({"pos": Vector2(player_x + offset_x, PLAYER_Y - 34.0), "velocity": velocity})

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
		var attacker: Dictionary = enemies[randi_range(0, enemies.size() - 1)]
		var source: Vector2 = attacker["pos"]
		if source.x > 15.0 and source.x < W - 15.0:
			enemy_bullets.append(source + Vector2(0, 18))
			# Jellyfish fire an additional offset projectile.
			if int(attacker["kind"]) == 0:
				enemy_bullets.append(source + Vector2(22, 18))
		enemy_fire_clock = maxf(0.45, 1.4 - level * 0.12)

func update_boss(delta: float) -> void:
	if not boss_active or boss.is_empty():
		return
	var pos: Vector2 = boss["pos"]
	var direction: float = boss["direction"]
	pos.x += direction * (100.0 if boss_phase == 1 else 165.0) * delta
	if pos.x >= W - 110.0 or pos.x <= 110.0:
		direction *= -1.0
	pos.x = clampf(pos.x, 110.0, W - 110.0)
	# Boss dives toward the player while winding up the radial attack.
	pos.y = move_toward(pos.y, 395.0 if spin_countdown > 0.0 else 155.0, 230.0 * delta)
	boss["pos"] = pos
	boss["direction"] = direction
	boss_fire_clock -= delta
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
		if boss_attack_index % 3 == 0:
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
		boss_fire_clock = 1.5 if boss_phase == 1 else 1.2
	if boss_phase == 1 and float(boss["hp"]) <= 95.0:
		boss_phase = 2

func fire_radial_barrage(origin: Vector2) -> void:
	# 360-degree ring with two deliberate, wider dodge corridors.
	# Aim one corridor near the player and offset another to provide a choice.
	var aimed_angle := (Vector2(player_x, PLAYER_Y) - origin).angle()
	var second_gap := aimed_angle + 0.62
	for i in range(SPIN_PROJECTILES):
		var angle := TAU * float(i) / float(SPIN_PROJECTILES)
		var near_player_gap := absf(wrapf(angle - aimed_angle, -PI, PI)) < 0.22
		var secondary_gap := absf(wrapf(angle - second_gap, -PI, PI)) < 0.19
		if near_player_gap or secondary_gap:
			continue
		var velocity := Vector2(cos(angle), sin(angle)) * (350.0 if boss_phase == 1 else 410.0)
		radial_bullets.append({"pos": origin, "velocity": velocity})

func update_bullets(delta: float) -> void:
	for i in range(player_bullets.size() - 1, -1, -1):
		var bullet: Dictionary = player_bullets[i]
		var shot: Vector2 = bullet["pos"] + Vector2(bullet["velocity"]) * delta
		bullet["pos"] = shot
		var hit := false
		if boss_active and not boss.is_empty():
			var boss_pos: Vector2 = boss["pos"]
			if shot.distance_to(boss_pos) < 66.0:
				hit = true
				if boss_shields > 0:
					boss_shields -= 1
				else:
					boss["hp"] = maxf(0.0, float(boss["hp"]) - (2.0 + damage_level))
				explosions.append({"pos": shot, "time": 0.25})
				if boss_shields == 0 and float(boss["hp"]) <= 0.0:
					score += 2500
					scrap += 300 # Award immediately because the stage ends on victory.
					boss.clear()
		elif not boss_active:
			for j in range(enemies.size() - 1, -1, -1):
				var pos: Vector2 = enemies[j]["pos"]
				if shot.distance_to(pos) < 26.0:
					hit = true
					enemies[j]["hp"] = int(enemies[j]["hp"]) - (1 + damage_level)
					if int(enemies[j]["hp"]) <= 0:
						enemies.remove_at(j)
						kills += 1
						score += 100
						scrap += 25 # Guaranteed mission income; drops are bonus Scrap.
						explosions.append({"pos": pos, "time": 0.3})
						if randf() < 0.85:
							drop_scrap(pos, 1)
					break
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
	if invulnerable > 0.0 or ability_time > 0.0:
		return
	lives -= 1
	invulnerable = 1.7
	explosions.append({"pos": Vector2(player_x, PLAYER_Y), "time": 0.45})

func drop_scrap(pos: Vector2, amount: int) -> void:
	for i in range(amount):
		drops.append({"pos": pos + Vector2(randf_range(-25.0, 25.0), randf_range(-20.0, 20.0)), "value": 10 if amount == 1 else 20})

func update_pickups(delta: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		var pos: Vector2 = drops[i]["pos"]
		pos.y += 115.0 * delta
		drops[i]["pos"] = pos
		if pos.distance_to(Vector2(player_x, PLAYER_Y)) < 34.0:
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
	if level == MAX_LEVEL:
		state = "victory"
	else:
		state = "shop"

const DOUBLE_SHOT_PRICE := 540
const TRIPLE_SHOT_PRICE := 1580

func upgrade_cost(kind: int) -> int:
	match kind:
		1: return 50
		2: return 75
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
	if state == "shop":
		match event.keycode:
			KEY_1: buy_upgrade(1)
			KEY_2: buy_upgrade(2)
			KEY_3: buy_upgrade(3)
			KEY_4: buy_upgrade(4)
			KEY_5: buy_upgrade(5)

			KEY_ENTER, KEY_KP_ENTER:
				level += 1
				start_level()
	elif state == "playing":
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
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			lives = 3
			score = 0
			scrap = 0
			level = 1
			damage_level = 0
			rate_level = 0
			speed_level = 0
			ability_level = 1
			start_level()
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
	for star in stars:
		draw_circle(star, 1.5, Color(0.45, 0.65, 0.9, 0.55))
	text_at("CROATIA %d/5  WAVE %d/2  SCORE %d" % [level, waves_spawned, score], 20, 35)
	text_at("LIVES %d       SCRAP %d" % [lives, scrap], 20, 66, 21, Color(0.8, 0.95, 0.7))
	if ability_time > 0.0:
		text_at("X SHIELD: %.1fs" % ability_time, 20, 96, 19, Color(0.3, 1.0, 1.0))
	elif ability_cooldown > 0.0:
		text_at("X RECHARGE: %.1fs" % ability_cooldown, 20, 96, 19, Color(0.9, 0.75, 0.5))
	else:
		text_at("X SHIELD READY (Lv.%d)" % ability_level, 20, 96, 19, Color(0.4, 1.0, 0.7))
	# Compact Warblade-inspired S/F status indicators; no large box obscuring enemies.
	draw_rect(Rect2(14, 111, 291, 82), Color(0.05, 0.11, 0.2, 0.80))
	draw_stat_meter("SPEED", speed_level, 4, 25, 135, Color(0.24, 0.7, 1.0))
	draw_stat_meter("FIRE", rate_level, 4, 25, 162, Color(1.0, 0.38, 0.3))
	text_at("TAB - SHIP STATUS", 27, 183, 14, Color(0.7, 0.85, 0.98))
	if state == "playing":
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
		draw_line(shot_pos - direction * 11.0, shot_pos + direction * 11.0, Color(1.0, 0.92, 0.25), 6.0, true)
	for shot in enemy_bullets:
		draw_circle(shot, 7.0, Color(1.0, 0.3, 0.18))
	for bullet in radial_bullets:
		draw_circle(bullet["pos"], 9.0, Color(1.0, 0.35, 0.65))
		draw_circle(bullet["pos"], 4.0, Color(1.0, 0.85, 0.45))
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
		draw_circle(pos, 68.0, Color(0.24, 0.62, 0.48))
		for i in range(6):
			var angle := i * TAU / 6.0 + spin_rotation
			var p := pos + Vector2(cos(angle), sin(angle)) * 88.0
			draw_line(pos, p, Color(0.6, 0.9, 0.65), 13.0)
		draw_circle(pos, 25.0, Color(0.9, 0.2, 0.2) if boss_shields == 0 else Color(0.2, 0.65, 1.0))
		if spin_countdown > 0.0:
			draw_arc(pos, 106.0, 0.0, TAU, 64, Color(1.0, 0.25, 0.65, 0.9), 5.0)
			text_at("360 ATTACK!  X SHIELD!", 201, 230, 25, Color(1.0, 0.5, 0.65))
		if boss_warning_time > 0.0:
			draw_rect(Rect2(boss_warning_x - 25.0, 215.0, 50.0, H - 295.0), Color(1.0, 0.16, 0.1, 0.16))
			draw_line(Vector2(boss_warning_x, 215.0), Vector2(boss_warning_x, H - 80.0), Color(1.0, 0.35, 0.25, 0.7), 2.0)
		draw_rect(Rect2(150, 85, 420, 12), Color(0.25, 0.25, 0.35))
		draw_rect(Rect2(150, 85, 420 * float(boss["hp"]) / float(boss["max_hp"]), 12), Color(0.9, 0.25, 0.3))
		text_at("MINI BOSS  |  SHIELD %d" % boss_shields, 226, 118, 18)
	for drop in drops:
		var pos: Vector2 = drop["pos"]
		draw_circle(pos, 9.0, Color(0.95, 0.82, 0.25))
		draw_circle(pos, 4.0, Color(0.45, 0.3, 0.08))
	for effect in explosions:
		var pos: Vector2 = effect["pos"]
		draw_arc(pos, 30.0 * float(effect["time"]) / 0.3 + 8.0, 0, TAU, 20, Color(1.0, 0.68, 0.2), 4.0)
	if state == "shop":
		draw_rect(Rect2(52, 190, 616, 555), Color(0.07, 0.12, 0.23, 0.96))
		text_at("MISSION COMPLETE!", 198, 250, 32)
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
			text_at("3 - Double Shot: OWNED", 105, 461, 22, Color(0.5, 1.0, 0.7))
		else:
			text_at("3 - Double Shot (%d Scrap)" % upgrade_cost(3), 105, 461, 22)
		if damage_level >= 6:
			text_at("4 - Triple Shot: OWNED", 105, 515, 22, Color(0.5, 1.0, 0.7))
		else:
			text_at("4 - Triple Shot (%d Scrap)" % upgrade_cost(4), 105, 515, 22)
		if ability_level >= 3:
			text_at("5 - Shield Upgrade: MAX", 105, 569, 22)
		else:
			text_at("5 - Shield Upgrade Lv.%d/3 (%d)" % [ability_level, upgrade_cost(5)], 105, 569, 22)
		# In-shop ship stats are live and update immediately after a purchase.
		text_at("SHIP SPEED  %d px/s  Lv.%d/4" % [int(BASE_SPEED + speed_level * SPEED_STEP), speed_level], 105, 616, 17, Color(0.55, 0.83, 1.0))
		text_at("FIRE RATE  %.2f shots/s  Lv.%d/4" % [shots_per_second(), rate_level], 105, 640, 17, Color(1.0, 0.65, 0.5))
		text_at("%s SHOT  |  SHIELD Lv.%d/3" % [equipped_weapon_name(), ability_level], 105, 664, 17, Color(0.6, 0.96, 0.76))
		text_at("ENTER - Next mission", 185, 707, 26, Color(0.4, 0.9, 1.0))
	elif state == "gameover":
		text_at("GAME OVER", 195, 440, 52, Color(1.0, 0.35, 0.4))
		text_at("Press ENTER to restart", 205, 500, 24)
	elif state == "victory":
		text_at("CROATIA PROTOTYPE CLEARED!", 85, 435, 31, Color(0.45, 1.0, 0.7))
		text_at("Press ENTER to play again", 193, 490, 24)
	if show_stats_modal and state == "playing":
		draw_ship_status_modal()
	if game_paused and state == "playing":
		draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.02, 0.06, 0.65))
		draw_rect(Rect2(124, 362, 472, 212), Color(0.06, 0.12, 0.23, 0.98))
		text_at("GAME PAUSED", 226, 449, 34, Color(0.9, 0.96, 1.0))
		text_at("Press P to resume", 228, 508, 23, Color(0.45, 0.9, 1.0))
	text_at("A/D: move  B/SPACE: fire  R: shield  P: pause", 14, H - 22, 17, Color(0.65, 0.8, 0.95))
