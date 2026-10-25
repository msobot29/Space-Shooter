extends Node2D
## Adriatic Uprising - playable Croatia chapter prototype (levels 1-5).
## All sprites are procedural. Godot 4.x / GDScript 2.0.

const W := 720.0
const H := 960.0
const PLAYER_Y := 840.0
const SPEED := 470.0
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
var damage_level := 0 # 0-2 single, 3-5 double, 6 triple
var rate_level := 0
var ability_level := 1 # 1/2/3 = 2/4/6 seconds
var ability_time := 0.0
var ability_cooldown := 0.0
var state := "playing" # playing, shop, gameover, victory
var enemies: Array[Dictionary] = []
var player_bullets: Array[Dictionary] = [] # Each shot stores pos and velocity
var enemy_bullets: Array[Vector2] = []
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
	enemies.clear()
	player_bullets.clear()
	enemy_bullets.clear()
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
	# Exactly five attackers enter from each side; each wave has an independent route.
	waves_spawned += 1
	var path_id := randi_range(0, 3)
	wave_path_ids.append(path_id)
	for side in range(2):
		for index in range(5):
			var left := side == 0
			var row_y := 170.0 + float(index) * 70.0
			var formation_x := (128.0 + float(index) * 46.0) if left else (592.0 - float(index) * 46.0)
			var from_x := (-65.0 - float(index) * 52.0) if left else (W + 65.0 + float(index) * 52.0)
			var start_pos := Vector2(from_x, row_y - 105.0)
			var target_pos := Vector2(formation_x, row_y + (waves_spawned - 1) * 27.0)
			enemies.append({
				"pos": start_pos,
				"start": start_pos,
				"target": target_pos,
				"age": 0.0,
				"path": path_id,
				"side": -1.0 if left else 1.0,
				"offset": float(index) * 0.26,
				"hp": (2 + int(level / 3)) + (1 if (side + index + waves_spawned) % 3 == 1 else 0),
				"kind": (side + index + waves_spawned) % 3
			})

func move_enemy(enemy: Dictionary, delta: float) -> void:
	var age: float = float(enemy["age"]) + delta
	enemy["age"] = age
	var entrance_time := 1.55 + float(enemy["offset"])
	var fraction := clampf(age / entrance_time, 0.0, 1.0)
	var eased := fraction * fraction * (3.0 - 2.0 * fraction)
	var source: Vector2 = enemy["start"]
	var target: Vector2 = enemy["target"]
	var side: float = enemy["side"]
	var offset: float = enemy["offset"]
	var route: int = enemy["path"]
	var position := source.lerp(target, eased)
	if fraction < 1.0:
		# Different arcs and swerves while entering from opposite screen edges.
		match route:
			0:
				position.y -= sin(PI * fraction) * 100.0
			1:
				position.y += sin(PI * fraction) * 115.0
			2:
				position.x += side * sin(TAU * fraction) * 92.0
			3:
				position.x -= side * sin(PI * fraction) * 110.0
	else:
		# Enemies keep flying in curved paths instead of staying static.
		var t := age - entrance_time
		match route:
			0:
				position.x += sin(t * 1.2 + offset * 3.0) * 70.0
				position.y += sin(t * 1.7 + offset) * 35.0
			1:
				position.x += cos(t * 1.7 + offset * 2.0) * 85.0
				position.y += sin(t * 1.1 + offset) * 54.0
			2:
				position.x += sin(t * 2.0 + offset) * 96.0
				position.y += sin(t * 1.0 + offset * 2.0) * 50.0
			3:
				position.x += side * sin(t * 1.3 + offset * 2.0) * 110.0
				position.y += cos(t * 1.6 + offset) * 36.0
	# Eels are fast evasive attackers; crabs are tougher and move more steadily.
	var kind: int = int(enemy["kind"])
	if kind == 2 and fraction >= 1.0:
		position.x += sin(age * 4.2 + offset * 5.0) * 36.0
	elif kind == 1 and fraction >= 1.0:
		position.y += sin(age * 0.9 + offset) * 18.0
	position.x = clampf(position.x, -360.0, W + 360.0)
	position.y = clampf(position.y, 55.0, 650.0)
	enemy["pos"] = position

func launch_boss() -> void:
	boss_pending = false
	boss_active = true
	enemy_bullets.clear()
	boss = {"pos": Vector2(W / 2.0, 155.0), "hp": 90.0, "max_hp": 90.0, "direction": 1.0}
	boss_fire_clock = 1.4


func _process(delta: float) -> void:
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
	player_x = clampf(player_x + clampf(move, -1.0, 1.0) * SPEED * delta, 28.0, W - 28.0)
	fire_clock -= delta
	if (Input.is_key_pressed(KEY_B) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_clock <= 0.0:
		fire_weapon()
		fire_clock = maxf(0.085, 0.22 - rate_level * 0.035)

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
	boss["pos"] = pos
	boss["direction"] = direction
	boss_fire_clock -= delta
	# Alternating attack patterns: fan volley, then a telegraphed aimed column.
	var previous_warning := boss_warning_time
	boss_warning_time = maxf(0.0, boss_warning_time - delta)
	if previous_warning > 0.0 and boss_warning_time <= 0.0:
		for lane in range(-1, 2):
			enemy_bullets.append(Vector2(boss_warning_x + lane * 22.0, pos.y + 38.0))
	if boss_fire_clock <= 0.0:
		if boss_attack_index % 2 == 0:
			for lane in range(-2, 3):
				enemy_bullets.append(pos + Vector2(lane * 42.0, 38.0))
		else:
			boss_warning_x = player_x
			boss_warning_time = 0.7
			# The danger column fires after the marker has been visible.
		boss_attack_index += 1
		boss_fire_clock = 1.4 if boss_phase == 1 else 1.0
	if boss_phase == 1 and float(boss["hp"]) <= 40.0:
		boss_phase = 2

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

func upgrade_cost(kind: int) -> int:
	match kind:
		1: return 80 + damage_level * 100
		2: return 80 + rate_level * 100
		3:
			return 900 if ability_level == 1 else 1800
	return 99999

func buy_upgrade(kind: int) -> void:
	var capped := (kind == 1 and damage_level >= 6) or (kind == 2 and rate_level >= 4) or (kind == 3 and ability_level >= 3)
	if capped or scrap < upgrade_cost(kind):
		return
	scrap -= upgrade_cost(kind)
	match kind:
		1: damage_level += 1
		2: rate_level += 1
		3: ability_level += 1
		   
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if state == "shop":
		match event.keycode:
			KEY_1: buy_upgrade(1)
			KEY_2: buy_upgrade(2)
			KEY_3: buy_upgrade(3)

			KEY_ENTER, KEY_KP_ENTER:
				level += 1
				start_level()
	elif state == "playing":
		if event.keycode == KEY_X and ability_time <= 0.0 and ability_cooldown <= 0.0:
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
			ability_level = 1
			start_level()
	queue_redraw()

func text_at(value: String, x: float, y: float, size: int = 22, color: Color = Color.WHITE) -> void:
	draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

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
			var p := pos + Vector2(cos(i * TAU / 6.0), sin(i * TAU / 6.0)) * 88.0
			draw_line(pos, p, Color(0.6, 0.9, 0.65), 13.0)
		draw_circle(pos, 25.0, Color(0.9, 0.2, 0.2) if boss_shields == 0 else Color(0.2, 0.65, 1.0))
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
		draw_rect(Rect2(70, 218, 580, 495), Color(0.07, 0.12, 0.23, 0.96))
		text_at("MISSION COMPLETE!", 198, 310, 32)
		text_at("SCRAP: %d" % scrap, 265, 360, 26, Color(0.95, 0.85, 0.3))
		if damage_level >= 6:
			text_at("1 - TRIPLE SHOT MAX", 120, 430, 23)
		else:
			text_at("1 - %s  (%d)" % [weapon_label(), upgrade_cost(1)], 120, 430, 23)
		text_at("Next: %s" % next_weapon_label(), 120, 457, 17, Color(0.6, 0.85, 0.98))
		text_at("2 - Fire rate Lv.%d       (%d)" % [rate_level, upgrade_cost(2)], 120, 490, 23)
		text_at("3 - X shield Lv.%d / 3   (%d)" % [ability_level, upgrade_cost(3)], 120, 555, 23)
		text_at("ENTER - Next mission", 185, 660, 26, Color(0.4, 0.9, 1.0))
	elif state == "gameover":
		text_at("GAME OVER", 195, 440, 52, Color(1.0, 0.35, 0.4))
		text_at("Press ENTER to restart", 205, 500, 24)
	elif state == "victory":
		text_at("CROATIA PROTOTYPE CLEARED!", 85, 435, 31, Color(0.45, 1.0, 0.7))
		text_at("Press ENTER to play again", 193, 490, 24)
	text_at("A/D: move    B/SPACE: fire    X: shield", 22, H - 22, 19, Color(0.65, 0.8, 0.95))
