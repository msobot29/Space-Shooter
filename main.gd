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

var font: Font
var stars: Array[Vector2] = []
var player_x := 360.0
var lives := 3
var score := 0
var scrap := 0
var level := 1
var damage_level := 0
var rate_level := 0
var armor_level := 0
var ability_level := 1 # 1/2/3 = 2/4/6 seconds
var ability_time := 0.0
var ability_cooldown := 0.0
var state := "playing" # playing, shop, gameover, victory
var enemies: Array[Dictionary] = []
var player_bullets: Array[Vector2] = []
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
var level_time := 0.0
var kills := 0
var target_kills := 0

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
	boss_active = level == 4
	boss_phase = 1
	boss_shields = 2
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
	target_kills = 8 + level * 4
	if boss_active:
		boss = {"pos": Vector2(W / 2.0, 155.0), "hp": 90.0, "max_hp": 90.0, "direction": 1.0}
	else:
		spawn_formation()
	queue_redraw()

func spawn_formation() -> void:
	for row in range(2):
		for col in range(5):
			enemies.append({"pos": Vector2(120.0 + col * 118.0, 118.0 + row * 76.0), "hp": 2 + int(level / 3), "kind": (row + col) % 2})

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
	update_player(delta)
	update_enemies(delta)
	update_boss(delta)
	update_bullets(delta)
	update_pickups(delta)
	update_effects(delta)
	if lives <= 0:
		state = "gameover"
	elif boss_active:
		if boss.is_empty():
			complete_level()
	elif kills >= target_kills and enemies.is_empty():
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
		player_bullets.append(Vector2(player_x, PLAYER_Y - 34.0))
		fire_clock = maxf(0.085, 0.22 - rate_level * 0.035)

func update_enemies(delta: float) -> void:
	if boss_active:
		return
	var edge := false
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
		if pos.x + drift * (95.0 + level * 12.0) * delta > W - 32.0 or pos.x + drift * (95.0 + level * 12.0) * delta < 32.0:
			edge = true
			break
	if edge:
		drift *= -1.0
	for i in range(enemies.size()):
		var pos: Vector2 = enemies[i]["pos"]
		pos.x += drift * (95.0 + level * 12.0) * delta
		if edge:
			pos.y += 20.0
		enemies[i]["pos"] = pos
	for i in range(enemies.size() - 1, -1, -1):
		var pos: Vector2 = enemies[i]["pos"]
		if pos.y >= PLAYER_Y - 25.0:
			enemies.remove_at(i)
			take_damage()
	enemy_fire_clock -= delta
	if enemy_fire_clock <= 0.0 and not enemies.is_empty():
		var source: Vector2 = enemies[randi_range(0, enemies.size() - 1)]["pos"]
		enemy_bullets.append(source + Vector2(0, 18))
		enemy_fire_clock = maxf(0.45, 1.4 - level * 0.12)
	if enemies.is_empty() and kills < target_kills:
		spawn_clock += delta
		if spawn_clock >= 0.5:
			spawn_clock = 0.0
			spawn_formation()

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
	if boss_fire_clock <= 0.0:
		for lane in range(-2, 3):
			enemy_bullets.append(pos + Vector2(lane * 42.0, 38.0))
		boss_fire_clock = 0.95 if boss_phase == 1 else 0.48
	if float(boss["hp"]) <= 40.0:
		boss_phase = 2

func update_bullets(delta: float) -> void:
	for i in range(player_bullets.size() - 1, -1, -1):
		var shot := player_bullets[i] + Vector2(0, -BULLET_SPEED * delta)
		player_bullets[i] = shot
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
						explosions.append({"pos": pos, "time": 0.3})
						if randf() < 0.65:
							drop_scrap(pos, 1)
					break
		if hit or shot.y < -20.0:
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
	invulnerable = 1.7 + armor_level * 0.4
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
		3: return 100 + armor_level * 130
		4: return 160 + (ability_level - 1) * 240
	return 99999

func buy_upgrade(kind: int) -> void:
	var capped := (kind == 1 and damage_level >= 4) or (kind == 2 and rate_level >= 4) or (kind == 3 and armor_level >= 3) or (kind == 4 and ability_level >= 3)
	if capped or scrap < upgrade_cost(kind):
		return
	scrap -= upgrade_cost(kind)
	match kind:
		1: damage_level += 1
		2: rate_level += 1
		3: armor_level += 1
		4: ability_level += 1
		   
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if state == "shop":
		match event.keycode:
			KEY_1: buy_upgrade(1)
			KEY_2: buy_upgrade(2)
			KEY_3: buy_upgrade(3)
			KEY_4: buy_upgrade(4)
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
			armor_level = 0
			ability_level = 1
			start_level()
	queue_redraw()

func text_at(value: String, x: float, y: float, size: int = 22, color: Color = Color.WHITE) -> void:
	draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	for star in stars:
		draw_circle(star, 1.5, Color(0.45, 0.65, 0.9, 0.55))
	text_at("CROATIA  %d/5       SCORE %d" % [level, score], 20, 35)
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
	for shot in player_bullets:
		draw_rect(Rect2(shot.x - 3.0, shot.y - 13.0, 6.0, 22.0), Color(1.0, 0.92, 0.25))
	for shot in enemy_bullets:
		draw_circle(shot, 7.0, Color(1.0, 0.3, 0.18))
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
		draw_circle(pos, 23.0, Color(0.95, 0.25, 0.48) if int(enemy["kind"]) == 0 else Color(0.6, 0.35, 0.95))
		draw_rect(Rect2(pos.x - 14, pos.y - 6, 28, 12), Color(0.15, 0.08, 0.35))
		draw_circle(pos + Vector2(-8, -5), 3.5, Color.WHITE)
		draw_circle(pos + Vector2(8, -5), 3.5, Color.WHITE)
	if boss_active and not boss.is_empty():
		var pos: Vector2 = boss["pos"]
		draw_circle(pos, 68.0, Color(0.24, 0.62, 0.48))
		for i in range(6):
			var p := pos + Vector2(cos(i * TAU / 6.0), sin(i * TAU / 6.0)) * 88.0
			draw_line(pos, p, Color(0.6, 0.9, 0.65), 13.0)
		draw_circle(pos, 25.0, Color(0.9, 0.2, 0.2) if boss_shields == 0 else Color(0.2, 0.65, 1.0))
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
		text_at("1 - Weapon damage Lv.%d   (%d)" % [damage_level, upgrade_cost(1)], 120, 430, 23)
		text_at("2 - Fire rate Lv.%d       (%d)" % [rate_level, upgrade_cost(2)], 120, 490, 23)
		text_at("3 - Armor Lv.%d           (%d)" % [armor_level, upgrade_cost(3)], 120, 540, 23)
		text_at("4 - X shield Lv.%d / 3   (%d)" % [ability_level, upgrade_cost(4)], 120, 590, 23)
		text_at("ENTER - Next mission", 185, 660, 26, Color(0.4, 0.9, 1.0))
	elif state == "gameover":
		text_at("GAME OVER", 195, 440, 52, Color(1.0, 0.35, 0.4))
		text_at("Press ENTER to restart", 205, 500, 24)
	elif state == "victory":
		text_at("CROATIA PROTOTYPE CLEARED!", 85, 435, 31, Color(0.45, 1.0, 0.7))
		text_at("Press ENTER to play again", 193, 490, 24)
	text_at("A/D: move    B/SPACE: fire    X: shield", 22, H - 22, 19, Color(0.65, 0.8, 0.95))
