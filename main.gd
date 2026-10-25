extends Node2D
## A playable Godot 4 vertical arcade shooter. No external assets required.

const W := 720.0
const H := 960.0
const PLAYER_SPEED := 470.0
const SHOT_SPEED := 780.0
const ENEMY_SPEED := 90.0
const PLAYER_Y := 850.0

var player_x := W / 2.0
var shots: Array[Vector2] = []
var enemies: Array[Vector2] = []
var stars: Array[Vector2] = []
var score := 0
var lives := 3
var wave := 0
var fire_timer := 0.0
var enemy_direction := 1.0
var game_over := false
var font: Font

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	for i in range(75):
		stars.append(Vector2(randf_range(0.0, W), randf_range(0.0, H)))
	start_wave()

func start_wave() -> void:
	wave += 1
	enemies.clear()
	enemy_direction = 1.0
	for row in range(3):
		for column in range(7):
			enemies.append(Vector2(100.0 + column * 86.0, 115.0 + row * 75.0))

func _process(delta: float) -> void:
	if game_over:
		if Input.is_key_pressed(KEY_ENTER):
			score = 0
			lives = 3
			wave = 0
			shots.clear()
			game_over = false
			start_wave()
		queue_redraw()
		return

	var movement := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A):
		movement -= 1.0
	if Input.is_key_pressed(KEY_D):
		movement += 1.0
	player_x = clampf(player_x + clampf(movement, -1.0, 1.0) * PLAYER_SPEED * delta, 30.0, W - 30.0)

	fire_timer -= delta
	if (Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_timer <= 0.0:
		shots.append(Vector2(player_x, PLAYER_Y - 32.0))
		fire_timer = 0.18

	for i in range(shots.size() - 1, -1, -1):
		shots[i].y -= SHOT_SPEED * delta
		if shots[i].y < -20.0:
			shots.remove_at(i)

	var hit_edge := false
	for enemy in enemies:
		if enemy.x + enemy_direction * ENEMY_SPEED * delta > W - 32.0 or enemy.x + enemy_direction * ENEMY_SPEED * delta < 32.0:
			hit_edge = true
			break
	if hit_edge:
		enemy_direction *= -1.0
		for i in range(enemies.size()):
			enemies[i].y += 22.0
	for i in range(enemies.size()):
		enemies[i].x += enemy_direction * (ENEMY_SPEED + wave * 8.0) * delta

	for s in range(shots.size() - 1, -1, -1):
		var hit := false
		for e in range(enemies.size() - 1, -1, -1):
			if shots[s].distance_to(enemies[e]) < 31.0:
				enemies.remove_at(e)
				score += 100
				hit = true
				break
		if hit:
			shots.remove_at(s)

	for e in range(enemies.size() - 1, -1, -1):
		if enemies[e].y >= PLAYER_Y - 22.0:
			enemies.remove_at(e)
			lives -= 1
			if lives <= 0:
				game_over = true
				break

	if enemies.is_empty() and not game_over:
		start_wave()
	queue_redraw()

func _draw() -> void:
	for star in stars:
		draw_circle(star, 1.6, Color(0.45, 0.56, 0.8, 0.65))
	draw_string(font, Vector2(20, 36), "SCORE: %d     LIVES: %d     WAVE: %d" % [score, lives, wave], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
	draw_string(font, Vector2(20, H - 18), "MOVE: A/D or arrows    FIRE: SPACE or mouse", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.65, 0.75, 0.95))
	if not game_over:
		var ship := PackedVector2Array([
			Vector2(player_x, PLAYER_Y - 35),
			Vector2(player_x - 26, PLAYER_Y + 24),
			Vector2(player_x, PLAYER_Y + 12),
			Vector2(player_x + 26, PLAYER_Y + 24)
		])
		draw_colored_polygon(ship, Color(0.2, 0.8, 1.0))
		draw_circle(Vector2(player_x, PLAYER_Y + 3), 7.0, Color(1.0, 0.95, 0.35))
	for shot in shots:
		draw_rect(Rect2(shot.x - 3.0, shot.y - 13.0, 6.0, 22.0), Color(1.0, 0.9, 0.2))
	for enemy in enemies:
		draw_circle(enemy, 23.0, Color(0.95, 0.25, 0.48))
		draw_rect(Rect2(enemy.x - 13.0, enemy.y - 6.0, 26.0, 12.0), Color(0.35, 0.1, 0.5))
		draw_circle(enemy + Vector2(-8, -5), 3.0, Color.WHITE)
		draw_circle(enemy + Vector2(8, -5), 3.0, Color.WHITE)
	if game_over:
		draw_string(font, Vector2(220, 440), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color(1.0, 0.3, 0.4))
		draw_string(font, Vector2(205, 490), "Press ENTER to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
