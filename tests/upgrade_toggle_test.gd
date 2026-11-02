extends SceneTree
## godot --headless --path . --script res://tests/upgrade_toggle_test.gd
## No startup, campaign save or control-file writes.

const GAME = preload("res://main.gd")
var checks := 0
var failures := 0

class LiveFixture:
	extends "res://main.gd"
	func _ready() -> void:
		pass

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func make_game():
	var game = GAME.new()
	game.reset_bindings()
	game.debug_run = true
	game.state = "playing"
	game.level = 26
	return game

func key(code: int, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event

func pickup(game, kind: String) -> void:
	game.drops.append({"pos": Vector2(game.player_x, game.PLAYER_Y), "kind": kind})
	game.update_pickups(0.0)

func test_bonus() -> void:
	for starting_level in range(4):
		var game = make_game()
		game.speed_level = starting_level
		pickup(game, "extra_speed")
		expect(game.speed_level == starting_level + 1 and game.score == 0, "Normal Speed pickup upgrades without score")
		game.free()
	var game = make_game()
	game.speed_level = 4
	game.extra_bullet_level = 8
	game.active_multipliers.append({"factor": 8, "time": 20.0})
	pickup(game, "extra_bullet")
	var bullet_bonus: int = game.score
	var popup: Dictionary = game.bonus_popups.back().duplicate(true)
	expect(bullet_bonus == 10000, "Existing Extra Bullet bonus is exactly 10000, without multiplier")
	for i in range(20):
		var previous_score: int = game.score
		pickup(game, "extra_speed")
		expect(game.speed_level == 4 and game.score == previous_score + bullet_bonus, "Each capped Speed pickup awards exactly the same bonus")
		expect(game.bonus_popups.back() == popup, "Speed reuses exact existing score popup near ship")
		game.update_pickups(0.0)
		expect(game.score == previous_score + bullet_bonus and game.drops.is_empty(), "Consumed pickup cannot reward twice")
	expect(game.bonus_popups.size() == 8, "Repeated bonus popups remain bounded")
	game.speed_level = 3
	var previous_score: int = game.score
	for i in range(3):
		game.drops.append({"pos": Vector2(game.player_x, game.PLAYER_Y), "kind": "extra_speed"})
	game.update_pickups(0.0)
	expect(game.speed_level == 4 and game.score == previous_score + 20000, "Mixed upgrade plus two capped pickups award twice")
	game.free()

func test_death_matrix() -> void:
	for speed in range(5):
		for rate in range(5):
			for extra in range(9):
				var game = make_game()
				game.speed_level = speed
				game.rate_level = rate
				game.extra_bullet_level = extra
				game.take_damage()
				expect([game.speed_level,game.rate_level,game.extra_bullet_level] == [maxi(0,speed-1),maxi(0,rate-1),maxi(0,extra-1)] and game.lives == 2, "All upgrade penalties apply once and clamp at zero")
				game.take_damage()
				expect(game.lives == 2 and game.extra_bullet_level == maxi(0,extra-1), "Invulnerability prevents second penalty")
				game.free()
	for protection in ["god_mode", "ability_time", "invulnerable"]:
		var game = make_game()
		game.speed_level = 4
		game.rate_level = 4
		game.extra_bullet_level = 8
		game.set(protection, true if protection == "god_mode" else 2.0)
		game.take_damage()
		expect([game.speed_level,game.rate_level,game.extra_bullet_level,game.lives] == [4,4,8,3], "Protection blocks every penalty: " + protection)
		game.free()
	var game = make_game()
	game.speed_level = 2
	game.rate_level = 1
	game.extra_bullet_level = 1
	for hit in range(3):
		game.invulnerable = 0.0
		game.take_damage()
	expect([game.speed_level,game.rate_level,game.extra_bullet_level,game.lives] == [0,0,0,0], "Repeated actual deaths stop all levels at zero")
	game.free()

func test_capacity_and_controls() -> void:
	for weapon in range(5):
		var game = make_game()
		game.apply_debug_weapon(weapon)
		game.speed_level = 4
		game.rate_level = 4
		game.extra_bullet_level = 1
		for i in range(6):
			game.player_bullets.append({"pos": Vector2(200,400), "velocity": Vector2(0,-100)})
		game.take_damage()
		expect(game.extra_bullet_level == 0 and game.player_bullets.size() == 6 and not game.fire_weapon(), "Reduced capacity blocks new fire without deleting flying shots")
		game.player_bullets.clear()
		var volley_size: int = [1,1,2,1,1][weapon]
		for i in range(5 - volley_size):
			game.player_bullets.append({"pos": Vector2(200,400), "velocity": Vector2(0,-100)})
		expect(game.fire_weapon() and game.player_bullets.size() == 5, "Whole volley uses updated capacity after existing weapon downgrade")
		game.player_bullets.clear()
		game.arc_lightning_cooldown = 0.0
		game.fire_clock = 0.0
		game.player_x = 100.0
		Input.parse_input_event(key(KEY_D))
		Input.flush_buffered_events()
		game.update_player(1.0)
		expect(is_equal_approx(game.player_x, 539.0), "Movement immediately uses Speed 3 (439 px/s)")
		Input.parse_input_event(key(KEY_D, false))
		Input.flush_buffered_events()
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		Input.parse_input_event(click)
		Input.flush_buffered_events()
		game.update_player(0.0)
		expect(is_equal_approx(game.fire_clock, 0.19 / (0.6 if weapon == 4 else 1.0)), "Next shot uses ROF 3 and original Plasma factor")
		var release := click.duplicate()
		release.pressed = false
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		game.free()

func test_toggle() -> void:
	var game = make_game()
	expect(not game.ship_status_hud_visible() and not game.ship_status_open, "Gameplay starts closed")
	game.waves_spawned = game.waves_for_level()
	var target := {"pos": Vector2(300,300), "prev_pos": Vector2(300,300), "kind": 3, "hp": 8.0,
		"start": Vector2(-80,110), "target": Vector2(300,300), "age": 3.0, "delay": 0.0, "path": 0, "side": 1.0, "offset": 0.0}
	game.enemies.append(target)
	game.player_bullets.append({"pos": Vector2(600,600), "velocity": Vector2(0,-100)})
	game._unhandled_key_input(key(KEY_TAB))
	expect(game.ship_status_hud_visible() and not game.game_paused, "TAB opens without pause")
	var previous_pos: Vector2 = game.enemies[0]["pos"]
	game._process(0.1)
	expect(game.level_time > 0.0 and game.enemies[0]["pos"] != previous_pos and game.player_bullets[0]["pos"].y < 600, "Simulation, enemies and bullets advance while panel is open")
	game._unhandled_key_input(key(KEY_R))
	expect(game.ability_time > 0.0, "Shield remains usable while status is open")
	var echo := key(KEY_TAB)
	echo.echo = true
	game._unhandled_key_input(echo)
	expect(game.ship_status_open, "Key repeat does not toggle repeatedly")
	game._unhandled_key_input(key(KEY_TAB, false))
	expect(game.ship_status_open, "Key release does not toggle")
	game._unhandled_key_input(key(KEY_TAB))
	expect(not game.ship_status_hud_visible(), "Second TAB closes")
	var modified := key(KEY_TAB)
	modified.ctrl_pressed = true
	game._unhandled_key_input(modified)
	expect(not game.ship_status_open, "Ctrl+TAB does not toggle the panel")
	game.bindings[5] = KEY_Q
	game._unhandled_key_input(key(KEY_Q))
	expect(game.ship_status_open, "Custom status binding retained")
	game._unhandled_key_input(key(KEY_TAB))
	expect(not game.ship_status_open, "TAB remains available after status remap")
	game.bindings[5] = KEY_TAB
	for action in range(5):
		game.reset_bindings()
		game.bindings[action] = KEY_TAB
		game.ship_status_open = false
		game.game_paused = false
		game.ability_time = 0.0
		game._unhandled_key_input(key(KEY_TAB))
		Input.parse_input_event(key(KEY_TAB))
		Input.flush_buffered_events()
		expect(game.ship_status_open and not game.game_paused and game.ability_time == 0.0 and not game.key_down(action), "Legacy TAB binding cannot trigger another gameplay action")
		Input.parse_input_event(key(KEY_TAB, false))
		Input.flush_buffered_events()
	game.reset_bindings()
	for debug_key in [KEY_F2, KEY_F4]:
		game.ship_status_open = true
		game._unhandled_key_input(key(debug_key))
		expect(not game.ship_status_open, "Opening a debug menu closes the panel")
		game._unhandled_key_input(key(debug_key))
	for state in ["main_menu", "menu_options", "shop", "city_select", "gameover", "victory", "shop_arrival"]:
		game.state = state
		game.ship_status_open = true
		game._process(0.0)
		expect(not game.ship_status_open, "Leaving gameplay closes status in " + state)
	game.state = "playing"
	for block in ["game_paused", "debug_level_menu", "debug_weapon_menu"]:
		game.set(block, true)
		game._unhandled_key_input(key(KEY_TAB))
		expect(not game.ship_status_open, "Pause/debug controls block status toggle")
		game.set(block, false)
	game.state = "menu_bindings"
	game.binding_capture = true
	game.binding_selection = 0
	game._unhandled_key_input(key(KEY_TAB))
	expect(game.binding_notice == "KEY RESERVED" and game.bindings[0] == KEY_A, "Binding capture reserves TAB without writing controls")
	game.free()
	var live := LiveFixture.new()
	live.reset_bindings()
	live.state = "playing"
	live.hide()
	live.set_process(false)
	live.set_process_unhandled_key_input(false)
	root.add_child(live)
	var input := LineEdit.new()
	root.add_child(input)
	input.grab_focus()
	live._unhandled_key_input(key(KEY_TAB))
	expect(not live.ship_status_open and input.has_focus(), "Focused text entry does not toggle gameplay status")
	input.free()
	live.set_process_unhandled_key_input(true)
	Input.parse_input_event(key(KEY_TAB))
	Input.flush_buffered_events()
	expect(live.ship_status_open, "Real viewport input dispatch opens status on TAB")
	Input.parse_input_event(key(KEY_TAB, false))
	Input.flush_buffered_events()
	Input.parse_input_event(key(KEY_TAB))
	Input.flush_buffered_events()
	expect(not live.ship_status_open, "Real viewport input dispatch closes status on the next press")
	Input.parse_input_event(key(KEY_TAB, false))
	Input.flush_buffered_events()
	live.free()

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	test_bonus()
	test_death_matrix()
	test_capacity_and_controls()
	test_toggle()
	print("UPGRADE TOGGLE QA: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
