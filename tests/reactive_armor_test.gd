extends SceneTree
## godot --headless --path . --script res://tests/reactive_armor_test.gd
## Optional before/after comparison: -- --baseline=res://path/to/main-before.txt
## All instances bypass normal startup and player save I/O.

const GAME = preload("res://main.gd")
var checks := 0
var failures := 0
var baseline: GDScript

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func tank(hp: float, kind: int = 1) -> Dictionary:
	return {"pos": Vector2(320, 340), "prev_pos": Vector2(320, 340), "kind": kind,
		"hp": hp, "armor_left": 3 if kind == 4 else 0, "visual_armor_max_hp": hp,
		"start": Vector2(-85, 110), "target": Vector2(320, 340), "age": 4.0,
		"delay": 0.0, "path": 0, "side": 1.0, "offset": 0.0}

func combat_state(game) -> Dictionary:
	var enemies: Array = game.enemies.duplicate(true)
	for enemy in enemies:
		enemy.erase("visual_armor_max_hp")
		enemy.erase("armor_shock")
	return {"enemies": enemies, "kills": game.kills, "total_kills": game.total_kills,
		"scrap": game.scrap, "score": game.score, "drops": game.drops.duplicate(true),
		"bullets": game.player_bullets.duplicate(true), "enemy_bullets": game.enemy_bullets.duplicate(true),
		"radial": game.radial_bullets.duplicate(true), "enemy_fire_clock": game.enemy_fire_clock}

func run_combat(script: GDScript, level: int, hp: int, choice: int, seed_value: int, god: bool = false) -> Dictionary:
	var game = script.new()
	game.level = level
	game.god_mode = god
	game.damage_level = [0, 3, 6, 0, 0][choice]
	game.arc_lightning_owned = choice == 3
	game.plasma_cannon_active = choice == 4
	game.enemies.append(tank(hp, 4 if level >= 26 else 1))
	seed(seed_value)
	var stages: Array = []
	for hit in range(12):
		if game.enemies.is_empty():
			break
		game.arc_lightning_cooldown = 0.0
		game.fire_weapon()
		for bullet in game.player_bullets:
			bullet["pos"] = Vector2(320, 440)
			bullet["velocity"] = Vector2(0, -1000)
		game.update_bullets(0.15)
		stages.append(combat_state(game))
	game.update_enemies(0.05)
	var result := {"stages": stages, "final": combat_state(game), "rng": randf()}
	if level >= 26:
		# Bosnia's original effect dictionaries must stay exactly the same as well.
		result["effects"] = [game.armor_fragments.duplicate(true), game.coral_armor_sparks.duplicate(true), game.coral_energy_flashes.duplicate(true)]
	game.free()
	return result

func test_all_stages() -> void:
	for hp in [3, 6, 7, 8, 9]:
		var game = GAME.new()
		game.level = 1
		game.enemies.append(tank(hp))
		for stage in range(hp - 1, -1, -1):
			var before: int = game.armor_fragments.size()
			game.apply_enemy_weapon_damage(0, 1.0, 3)
			expect(game.armor_fragments.size() - before == (7 if stage == 0 else 1), "Exactly one shell fragment per HP plus six final shards: %d / %d" % [hp, stage])
			if stage > 0:
				expect(game.enemies[0]["hp"] == stage and game.enemies[0]["armor_left"] == 0, "HP-only durability preserved")
				expect(is_equal_approx(game.enemies[0]["armor_shock"], 0.15), "Shock begins at 0.15s")
				var pos: Vector2 = game.enemies[0]["pos"]
				expect(game.coral_colossus_draw_position(game.enemies[0]) != pos, "Visual shock moves drawing")
				game.update_coral_armor_feedback(0.075)
				expect(game.enemies[0]["pos"] == pos, "Shock never changes physics")
				game.update_coral_armor_feedback(0.076)
				expect(game.coral_colossus_draw_position(game.enemies[0]) == pos, "Shock expires")
			expect(game.coral_energy_flashes.size() == (1 if stage == 0 else 0), "One final burst only")
			var fragment: Dictionary = game.armor_fragments.back().duplicate(true)
			game.update_armor_fragments(0.03)
			expect(game.armor_fragments.back()["rotation"] != fragment["rotation"] and game.armor_fragments.back()["velocity"].y > fragment["velocity"].y and game.armor_fragments.back()["pos"] != fragment["pos"], "Fragments rotate, move and fall")
			expect(game.armor_fragments.size() <= 72 and game.coral_armor_sparks.size() <= 144 and game.coral_energy_flashes.size() <= 16, "Bounded effects")
		expect(game.kills == 1 and game.enemies.is_empty(), "Exactly one kill")
		game.update_armor_fragments(1.0)
		game.update_coral_armor_feedback(1.0)
		expect(game.armor_fragments.is_empty() and game.coral_armor_sparks.is_empty() and game.coral_energy_flashes.is_empty(), "All effects expire")
		game.free()
	var game = GAME.new()
	game.enemies.append(tank(9))
	game.apply_enemy_weapon_damage(0, 0.0, 3)
	expect(game.armor_fragments.is_empty() and game.coral_armor_sparks.is_empty(), "No feedback for zero damage")
	game.free()

func test_baseline() -> void:
	if baseline == null:
		print("No baseline supplied; before/after comparisons skipped")
		return
	for region in [[1,3], [6,6], [11,7], [16,8], [21,9], [26,24]]:
		for choice in range(5):
			for seed_value in range(20):
				expect(run_combat(GAME, region[0], region[1], choice, seed_value) == run_combat(baseline, region[0], region[1], choice, seed_value), "Combat, rewards, RNG and Bosnia effects unchanged: level %d weapon %d seed %d" % [region[0], choice, seed_value])
			expect(run_combat(GAME, region[0], region[1], choice, 42, true) == run_combat(baseline, region[0], region[1], choice, 42, true), "God Mode unchanged")
	# Real formations preserve HP, routes, attacks and RNG during visual shock.
	for level in range(1, 51):
		var games := [baseline.new(), GAME.new()]
		var states: Array = []
		for game in games:
			game.level = level
			seed(1234)
			game.spawn_wave()
			game.apply_enemy_weapon_damage(0, 1.0, 1)
			game.update_enemies(0.05)
			states.append([combat_state(game), randf()])
			game.free()
		expect(states[0] == states[1], "Formation HP, path, attacks and RNG unchanged at level %d" % level)
	# Arc secondary jumps may hit several tanks in one event.
	var states: Array = []
	for script in [baseline, GAME]:
		var game = script.new()
		game.level = 21
		for i in range(3):
			var enemy := tank(9)
			enemy["pos"] += Vector2(i * 60, 0)
			game.enemies.append(enemy)
		seed(456)
		game.arc_chain_impact(0)
		states.append([combat_state(game), randf()])
		game.free()
	expect(states[0] == states[1], "Arc jumps preserve gameplay and RNG")

func test_weapons_and_limits() -> void:
	for hp in [3, 6, 7, 8, 9]:
		for choice in range(5):
			var result := run_combat(GAME, 21, hp, choice, 123)
			var expected_volleys := ceili(float(hp) / [1.0, 8.0, 21.0, 8.0, 12.0][choice])
			expect(result["stages"].size() == expected_volleys and result["final"]["kills"] == 1, "Existing HP damage/volley count: HP %d weapon %d" % [hp, choice])
			expect(result["final"]["score"] == 100 and result["final"]["scrap"] == 12, "Croatia tank rewards unchanged")
	var game = GAME.new()
	for i in range(50):
		game.enemies.append(tank(9))
	for i in range(49, -1, -1):
		game.apply_enemy_weapon_damage(i, 12.0, 3, "plasma")
	expect(game.kills == 50 and game.armor_fragments.size() == 72 and game.coral_armor_sparks.size() == 144 and game.coral_energy_flashes.size() == 16, "Large simultaneous destruction keeps fixed effect limits")
	game.update_effects(1.0)
	expect(game.armor_fragments.is_empty() and game.coral_armor_sparks.is_empty() and game.coral_energy_flashes.is_empty(), "Stress effects expire")
	game.free()

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--baseline="):
			baseline = GDScript.new()
			baseline.source_code = FileAccess.get_file_as_string(argument.trim_prefix("--baseline="))
			if baseline.reload() != OK:
				quit(2)
				return
	test_all_stages()
	test_weapons_and_limits()
	test_baseline()
	print("REACTIVE ARMOR QA: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
