extends SceneTree
## godot --headless --path . --script res://tests/ship_status_test.gd
## Exercises real upgrades, damage and save decoding without player file I/O.

const GAME = preload("res://main.gd")
var checks := 0
var failures := 0

class ReloadFixture:
	extends "res://main.gd"
	var test_save := ConfigFile.new()
	func read_campaign_save() -> void:
		pending_campaign_save = decode_campaign_save(test_save)
		save_available = not pending_campaign_save.is_empty()
	func save_campaign_checkpoint(_checkpoint_state: String) -> void:
		pass

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func expect_levels(game, levels: Array, label: String) -> void:
	var rows: Array = game.ship_status_rows()
	expect([rows[0]["level"], rows[1]["level"], rows[2]["level"]] == levels, label)
	expect([rows[0]["max"], rows[1]["max"], rows[2]["max"]] == [4, 4, 8], "Actual upgrade limits")

func make_game():
	var game = GAME.new()
	game.reset_bindings()
	game.debug_run = true
	game.level = 26
	game.state = "playing"
	game.score_name_field = LineEdit.new()
	root.add_child(game.score_name_field)
	game.score_name_field.hide()
	return game

func dispose(game) -> void:
	game.score_name_field.free()
	game.free()

func pickup(game, kind: String) -> void:
	game.drops.append({"pos": Vector2(game.player_x, game.PLAYER_Y), "kind": kind})
	game.update_pickups(0.0)

func test_upgrade_flows() -> void:
	var game = make_game()
	expect_levels(game, [0,0,0], "New ship shows upgrade zero, not capacity five")
	game.state = "shop"
	game.scrap = 100000
	game.buy_upgrade(1)
	game.buy_upgrade(2)
	expect_levels(game, [1,1,0], "Shop purchases update live rows")
	pickup(game, "extra_speed")
	pickup(game, "extra_bullet")
	expect_levels(game, [2,1,1], "Independent Speed and Extra Bullet pickups")
	game.damage_level = 3
	pickup(game, "double_shot")
	expect_levels(game, [2,2,1], "Repeated Double pickup increases only existing ROF level")
	game.damage_level = 6
	pickup(game, "triple_shot")
	expect_levels(game, [2,3,1], "Repeated Triple pickup reports existing ROF upgrade")
	for i in range(12):
		game.buy_upgrade(1)
		game.buy_upgrade(2)
		pickup(game, "extra_bullet")
	expect_levels(game, [4,4,8], "Maximum levels stay capped")
	game.state = "playing"
	for weapon in range(5):
		game.apply_debug_weapon(weapon)
		expect_levels(game, [4,4,8], "Switching weapon preserves separate upgrade levels")
	game.take_damage()
	expect_levels(game, [3,3,7], "Life loss immediately reflects all three upgrade penalties")
	game.take_damage()
	expect_levels(game, [3,3,7], "Post-hit invulnerability adds no penalty")
	game.start_level()
	expect_levels(game, [3,3,7], "Restarting mission preserves current upgrades")
	game.speed_level = 0
	game.rate_level = 0
	game.invulnerable = 0.0
	game.take_damage()
	expect_levels(game, [0,0,6], "All penalties clamp at zero and Extra Bullet loses one more level")
	dispose(game)

func test_reload() -> void:
	for values in [[0,0,0], [1,3,5], [4,4,8]]:
		var game := ReloadFixture.new()
		game.reset_bindings()
		game.score_name_field = LineEdit.new()
		root.add_child(game.score_name_field)
		game.score_name_field.hide()
		var fields := {"version": game.CAMPAIGN_SAVE_VERSION, "checkpoint": "playing", "level": 26,
			"lives": 3, "speed_level": values[0], "rate_level": values[1], "extra_bullet_level": values[2],
			"city_route": [0,1,2,3,4,5]}
		for key in fields:
			game.test_save.set_value("campaign", key, fields[key])
		game.continue_campaign()
		expect(game.save_available and game.state == "playing", "Real save decode and continue flow succeeds")
		expect(not game.ship_status_open, "Loaded gameplay starts with status closed")
		expect_levels(game, values, "Reloaded HUD matches persisted upgrades")
		dispose(game)

func test_values_and_layout() -> void:
	var game = make_game()
	for speed in range(5):
		for rate in range(5):
			for extra in range(9):
				game.speed_level = speed
				game.rate_level = rate
				game.extra_bullet_level = extra
				expect_levels(game, [speed,rate,extra], "Live rows read independent state at every valid level")
	for state in ["playing", "intermission", "boss_intro", "boss_rewards", "pre_boss_shop_wait"]:
		game.state = state
		game.ship_status_open = false
		expect(not game.ship_status_hud_visible(), "Gameplay HUD closed by default in " + state)
		game.ship_status_open = true
		expect(game.ship_status_hud_visible(), "Opened gameplay HUD visible in " + state)
	for state in ["main_menu", "menu_options", "city_select", "shop", "gameover", "victory", "shop_arrival"]:
		game.state = state
		expect(not game.ship_status_hud_visible(), "Gameplay panel hidden in " + state)
	var panel: Rect2 = game.SHIP_STATUS_HUD_RECT
	for obstacle in [Rect2(0,0,720,72), Rect2(0,73,320,31), Rect2(150,85,420,57), Rect2(385,168,316,65), Rect2(0,925,720,35)]:
		expect(not panel.intersects(obstacle), "Panel clears existing HUD zone")
	var font := ThemeDB.fallback_font
	for row in game.ship_status_rows():
		expect(26 + font.get_string_size(row["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x < 176, "Labels clear level column")
	for label in ["R ACTIVE 6.0s", "R CD 10.0s", "R READY Lv.3"]:
		expect(20 + font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x < 150, "Compact shield readout clears boss bars")
	for window in [Vector2(540,720), Vector2(720,960), Vector2(1080,1440)]:
		var factor: float = window.x / 720.0
		expect(Rect2(Vector2.ZERO, window).encloses(Rect2(panel.position * factor, panel.size * factor)), "Panel fits proportional window")
	dispose(game)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	test_upgrade_flows()
	test_reload()
	test_values_and_layout()
	print("SHIP STATUS QA: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
