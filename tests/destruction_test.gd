extends SceneTree
## godot --headless --path . --script res://tests/destruction_test.gd
## Optional: -- --baseline=res://path/to/main-before.txt
## Instances bypass startup; debug_run prevents campaign and leaderboard writes.

const GAME = preload("res://main.gd")
var checks := 0
var failures := 0
var baseline: GDScript

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func make_game(script: GDScript, level: int, choice: int):
	var game = script.new()
	game.reset_bindings()
	game.debug_run = true
	game.state = "playing"
	game.level = level
	game.damage_level = [0, 3, 6, 0, 0][choice]
	game.arc_lightning_owned = choice == 3
	game.plasma_cannon_active = choice == 4
	return game

func enemy(kind: int) -> Dictionary:
	return {"pos": Vector2(320, 340), "prev_pos": Vector2(320, 340), "kind": kind,
		"hp": [2.0, 9.0, 6.0, 8.0, 24.0, 12.0][kind], "armor_left": 3 if kind == 4 else 0,
		"visual_armor_max_hp": 9.0}

func snapshot(game) -> Array:
	return [game.enemies.duplicate(true), game.boss.duplicate(true), game.kills, game.total_kills,
		game.score, game.scrap, game.drops.duplicate(true), game.boss_active,
		game.boss_shields, game.boss_shield_hp, game.boss_shield_round, game.state,
		game.player_bullets.duplicate(true), game.lives, game.speed_level, game.rate_level, game.extra_bullet_level]

func effect_count(game) -> int:
	return game.destruction_effects.size() + game.coral_energy_flashes.size()

func run_combat(script: GDScript, level: int, kind: int, choice: int, god: bool, seed_value: int, boss_enemy: bool = false) -> Dictionary:
	var game = make_game(script, level, choice)
	game.god_mode = god
	if boss_enemy:
		game.launch_boss()
		game.boss["pos"] = Vector2(320, 340)
		game.boss["prev_pos"] = Vector2(320, 340)
		# Exercise shield interception and lethal hits while keeping the matrix fast.
		game.boss["hp"] = 14.0
		game.boss_shield_hp = 5.0
	else:
		game.enemies.append(enemy(kind))
	seed(seed_value)
	var stages: Array = []
	for volley in range(32):
		if (boss_enemy and game.boss.is_empty()) or (not boss_enemy and game.enemies.is_empty()):
			break
		game.player_bullets.clear()
		game.arc_lightning_cooldown = 0.0
		game.fire_weapon()
		for bullet in game.player_bullets:
			bullet["pos"] = Vector2(320, 440)
			bullet["velocity"] = Vector2(0, -1000)
		game.update_bullets(0.2)
		stages.append(snapshot(game))
	var result := {"stages": stages, "rng": randf()}
	if script == GAME:
		expect(effect_count(game) == 1, "Exactly one destruction: level %d kind %d weapon %d god %s" % [level, kind, choice, god])
		if boss_enemy:
			expect(game.boss.is_empty() and game.score == 2500, "Boss removed and rewarded immediately")
		else:
			expect(game.enemies.is_empty() and game.kills == 1, "Enemy removed and rewarded immediately")
		var before := snapshot(game)
		game.player_bullets.clear()
		game.update_bullets(0.0)
		game.award_enemy_kill(-1)
		game.award_enemy_kill(0)
		expect(effect_count(game) == 1 and game.kills <= 1 and game.score == before[4] and game.scrap == before[5] and game.drops == before[6], "No duplicate effect/reward from stale hits")
		if boss_enemy:
			game.waves_spawned = game.waves_for_level()
			game._process(0.0)
			expect(game.state == "boss_rewards" and is_equal_approx(game.boss_reward_time, game.BOSS_REWARD_SECONDS) and effect_count(game) == 1, "Reward window begins with animation still active")
		game.update_effects(2.0)
		expect(effect_count(game) == 0 and game.armor_fragments.is_empty(), "Destruction expires")
	game.free()
	return result

func test_matrix() -> void:
	for kind in range(6):
		for choice in range(5):
			for god in [false, true]:
				for seed_value in range(8):
					var level := 21 if kind < 3 else 26
					var result := run_combat(GAME, level, kind, choice, god, seed_value)
					if baseline != null:
						expect(result == run_combat(baseline, level, kind, choice, god, seed_value), "Regular combat, drops and RNG match baseline")
	for level in [5,10,15,20,25,30,35,40,45,50]:
		for choice in range(5):
			for god in [false, true]:
				for seed_value in range(8):
					var result := run_combat(GAME, level, 0, choice, god, seed_value, true)
					if baseline != null:
						expect(result == run_combat(baseline, level, 0, choice, god, seed_value, true), "Boss combat, orbs, rewards and RNG match baseline")

func test_chain_and_limits() -> void:
	var states: Array = []
	var scripts: Array = [GAME] if baseline == null else [baseline, GAME]
	for script in scripts:
		var game = make_game(script, 26, 3)
		for i in range(3):
			var target := enemy(3)
			target["pos"] += Vector2(i * 60, 0)
			target["hp"] = 1.0
			game.enemies.append(target)
		seed(456)
		game.arc_chain_impact(0)
		states.append([snapshot(game), randf()])
		if script == GAME:
			expect(game.kills == 3 and effect_count(game) == 3, "Arc chain creates one effect per death")
		game.free()
	if baseline != null:
		expect(states[0] == states[1], "Arc multi-kill gameplay and RNG unchanged")
	var game = make_game(GAME, 1, 0)
	for i in range(100):
		game.enemies.append(enemy(0))
	for i in range(99, -1, -1):
		game.apply_enemy_weapon_damage(i, 12.0, 3)
	expect(game.kills == 100 and game.destruction_effects.size() == game.MAX_DESTRUCTION_EFFECTS, "100 deaths stay inside the visual pool limit")
	game.update_effects(2.0)
	expect(game.destruction_effects.is_empty(), "Stress effects disappear")
	game.free()

func test_transitions() -> void:
	var game = make_game(GAME, 1, 0)
	game.enemies.append(enemy(0))
	game.apply_enemy_weapon_damage(0, 12.0, 3)
	game.waves_spawned = game.waves_for_level()
	game._process(0.0)
	expect(game.state == "intermission" and game.level == 2 and effect_count(game) == 1, "Last enemy death does not delay stage completion or erase the effect")
	game._process(0.2)
	expect(effect_count(game) == 1 and game.destruction_effects[0]["time"] < 0.65, "Animation advances during intermission")
	game.game_paused = true
	var before: float = game.destruction_effects[0]["time"]
	game._process(0.2)
	expect(game.destruction_effects[0]["time"] == before, "Pause freezes visuals")
	game.game_paused = false
	game.state = "gameover"
	game._process(2.0)
	expect(effect_count(game) == 0, "Visuals do not freeze forever after game over")
	game.free()
	# Reactive tank finish also survives the immediate stage transition.
	game = make_game(GAME, 21, 0)
	game.enemies.append(enemy(1))
	game.apply_enemy_weapon_damage(0, 12.0, 3)
	game.begin_level_transition()
	expect(game.coral_energy_flashes.size() == 1 and game.armor_fragments.size() == 15, "Reactive finish survives transition without duplicate shards")
	game.free()

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--baseline="):
			baseline = GDScript.new()
			baseline.source_code = FileAccess.get_file_as_string(argument.trim_prefix("--baseline="))
			if baseline.reload() != OK:
				quit(2)
				return
	test_matrix()
	test_chain_and_limits()
	test_transitions()
	print("DESTRUCTION QA: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
