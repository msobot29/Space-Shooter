extends SceneTree
## Run: godot --headless --path . --script res://tests/weapon_system_test.gd
## Instances stay outside the tree, so player saves and normal startup are untouched.

const GAME = preload("res://main.gd")
const VOLLEYS := [1, 2, 3, 1, 1]
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func make_game(choice: int):
	var game = GAME.new()
	game.reset_bindings()
	game.level = 26
	game.state = "playing"
	game.damage_level = [0, 3, 6, 0, 0][choice]
	game.arc_lightning_owned = choice == 3
	game.plasma_cannon_active = choice == 4
	return game

func occupy(game, count: int) -> void:
	for i in range(count):
		game.player_bullets.append({"pos": Vector2(100, -19), "velocity": Vector2(0, -100)})

func test_capacity() -> void:
	for choice in range(5):
		for extra in range(9):
			var game = make_game(choice)
			game.extra_bullet_level = extra
			var capacity: int = 5 + extra
			occupy(game, capacity - VOLLEYS[choice] + 1)
			var before: Array = game.player_bullets.duplicate(true)
			expect(not game.fire_weapon(), "Reject incomplete volley %d / extra %d" % [choice, extra])
			expect(game.player_bullets == before, "No partial shots %d / extra %d" % [choice, extra])
			expect(game.arc_lightning_cooldown == 0.0 and game.plasma_shot_sequence == 0, "Rejected shot has no side effects")
			game.player_bullets.pop_back()
			expect(game.fire_weapon() and game.player_bullets.size() == capacity, "Whole volley fits exactly %d / extra %d" % [choice, extra])
			game.arc_lightning_cooldown = 0.0
			expect(not game.fire_weapon() and game.player_bullets.size() == capacity, "Full screen cannot overflow")
			game.free()
	for choice in range(5):
		var game = make_game(choice)
		occupy(game, 5)
		game.update_bullets(0.02)
		expect(game.player_bullets.is_empty() and game.fire_weapon(), "Offscreen shots release slots %d" % choice)
		# A successful impact also releases all projectile slots, including Arc/Plasma.
		for bullet in game.player_bullets:
			bullet["pos"] = Vector2(320, 400)
			bullet["velocity"] = Vector2(0, -1000)
		game.enemies.append({"pos": Vector2(320, 320), "prev_pos": Vector2(320, 320), "kind": 3, "hp": 100.0})
		game.update_bullets(0.1)
		expect(game.player_bullets.is_empty(), "Impacts release slots %d" % choice)
		game.free()

func test_life_loss() -> void:
	for choice in range(5):
		for speed in range(5):
			for rate in range(5):
				var game = make_game(choice)
				game.speed_level = speed
				game.rate_level = rate
				game.extra_bullet_level = 8
				game.scrap = 1234
				game.score = 5678
				game.ability_level = 3
				game.take_damage()
				expect(game.lives == 2 and game.speed_level == maxi(0, speed - 1) and game.rate_level == maxi(0, rate - 1), "One life and one Speed/ROF level lost %d / %d / %d" % [choice, speed, rate])
				expect(game.damage_level == [0, 0, 3, 0, 0][choice] and game.arc_lightning_owned == (choice == 3) and game.plasma_cannon_active == (choice == 4), "Existing weapon penalty preserved")
				expect(game.extra_bullet_level == 7 and game.scrap == 1234 and game.score == 5678 and game.ability_level == 3, "Extra Bullet loses one level; rewards and shield upgrade preserved")
				game.take_damage()
				expect(game.lives == 2 and game.speed_level == maxi(0, speed - 1) and game.rate_level == maxi(0, rate - 1) and game.extra_bullet_level == 7, "Post-hit invulnerability prevents repeat penalties")
				game.free()
	for protection in ["god_mode", "invulnerable", "ability_time"]:
		var game = make_game(2)
		game.speed_level = 4
		game.rate_level = 4
		game.set(protection, true if protection == "god_mode" else 2.0)
		game.take_damage()
		expect(game.lives == 3 and game.speed_level == 4 and game.rate_level == 4 and game.damage_level == 6, "Protection blocks penalties: " + protection)
		game.free()
	var game = make_game(2)
	game.speed_level = 2
	game.rate_level = 1
	for hit in range(3):
		game.invulnerable = 0.0
		game.take_damage()
	expect(game.lives == 0 and game.speed_level == 0 and game.rate_level == 0 and game.damage_level == 0, "Repeated life losses clamp at zero")
	game.free()
	# Several projectiles in one frame still cost only one life and one level.
	game = make_game(2)
	game.speed_level = 4
	game.rate_level = 4
	game.extra_bullet_level = 3
	game.enemy_bullets.append(Vector2(game.player_x, game.PLAYER_Y))
	game.enemy_bullets.append(Vector2(game.player_x, game.PLAYER_Y))
	game.radial_bullets.append({"pos": Vector2(game.player_x, game.PLAYER_Y), "velocity": Vector2.ZERO})
	game.update_bullets(0.0)
	expect(game.lives == 2 and game.speed_level == 3 and game.rate_level == 3 and game.extra_bullet_level == 2, "Incoming bullet collisions apply exactly one penalty per life")
	game.free()

func mouse_button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_input_and_timing() -> void:
	for choice in range(5):
		for rate in range(5):
			var game = make_game(choice)
			game.rate_level = rate
			occupy(game, 5)
			mouse_button(true)
			game.update_player(0.0)
			expect(game.player_bullets.size() == 5 and game.fire_clock == 0.0, "Full capacity click consumes no fire timer")
			game.player_bullets.clear()
			mouse_button(false)
			game.update_player(0.0)
			mouse_button(true)
			game.update_player(0.0)
			var interval: float = maxf(0.12, 0.34 - rate * 0.05) / (0.6 if choice == 4 else 1.0)
			expect(game.player_bullets.size() == VOLLEYS[choice] and is_equal_approx(game.fire_clock, interval), "Fresh press and original firing interval %d / %d" % [choice, rate])
			game.update_player(1.0)
			expect(game.player_bullets.size() == VOLLEYS[choice], "Holding does not autofire")
			mouse_button(false)
			game.free()
	var arc = make_game(3)
	arc.fire_weapon()
	arc.fire_clock = 0.0
	mouse_button(true)
	arc.update_player(0.0)
	expect(arc.player_bullets.size() == 1 and arc.fire_clock == 0.0, "Arc cooldown rejection does not consume fire timer")
	mouse_button(false)
	arc.free()

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	test_capacity()
	test_life_loss()
	test_input_and_timing()
	print("WEAPON SYSTEM QA: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
