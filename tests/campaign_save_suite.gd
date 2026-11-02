extends Node
## Real disk I/O is confined to a dedicated test directory, never user:// saves.

class Fixture:
	extends "res://main.gd"
	var test_directory := ""
	func _ready() -> void:
		pass
	func campaign_save_path() -> String:
		assert(not test_directory.is_empty())
		return test_directory.path_join("campaign_save.cfg")
	func controls_save_path() -> String:
		assert(not test_directory.is_empty())
		return test_directory.path_join("controls.cfg")

var checks := 0
var failures := 0
var directory := ""
var phase := "all"

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func game():
	var instance := Fixture.new()
	instance.test_directory = directory
	instance.reset_bindings()
	instance.score_name_field = LineEdit.new()
	get_tree().root.add_child(instance.score_name_field)
	instance.score_name_field.hide()
	return instance

func key(instance, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	instance._unhandled_key_input(event)

func bytes(instance) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(instance.campaign_save_path())

func saved_campaign(instance) -> void:
	instance.level = 26
	instance.city_route.assign([0,3,1,2,4,5])
	instance.lives = 2
	instance.score = 275300
	instance.scrap = 9825
	instance.speed_level = 3
	instance.rate_level = 2
	instance.extra_bullet_level = 8
	instance.damage_level = 6
	instance.ability_level = 3
	instance.arc_lightning_owned = true
	instance.campaign_orbs_found_mask = 15
	instance.collected_orb_mask = 3
	instance.white_orb_collected = true
	instance.total_kills = 640
	instance.save_campaign_checkpoint("playing")
	expect(instance.save_available, "Written checkpoint is valid")

func fresh(instance) -> void:
	expect(instance.level == 1 and instance.state == "city_select", "New Game opens Croatia level 1 map")
	expect(instance.city_route.is_empty() and instance.selected_city == 0, "No liberated cities or route")
	for city in range(10):
		expect(instance.city_selectable(city) == (city < 4), "Only ordinary Croatia cities selectable")
	expect(instance.score == 0 and instance.scrap == 0 and instance.total_kills == 0, "Campaign rewards reset")
	expect(instance.lives == 3, "Three initial lives")
	expect([instance.speed_level, instance.rate_level, instance.extra_bullet_level, instance.damage_level] == [0,0,0,0], "Ship upgrades reset")
	expect(instance.ability_level == 1 and not instance.arc_lightning_owned and not instance.plasma_cannon_active, "Default weapon and shield")
	expect(instance.campaign_orbs_found_mask == 0 and instance.collected_orb_mask == 0 and not instance.white_orb_collected and not instance.bosnia_white_orb_secured, "All story and life orbs reset")
	expect(not instance.ship_status_open and not instance.god_mode and not instance.debug_run, "Fresh gameplay flags")
	expect(instance.armor_fragments.is_empty() and instance.destruction_effects.is_empty(), "No previous combat effects")
	expect(instance.invulnerable == 0.0 and not instance.fire_held and instance.plasma_shot_sequence == 0, "Combat transient state reset")
	expect(instance.pre_boss_shop == false and instance.hq_dialogue_index == 0 and instance.storm_pulses_remaining == 0, "No previous boss/HQ state")
	expect(instance.pending_campaign_save.get("level") == 1, "New checkpoint replaces prior campaign")

func test_all() -> void:
	var instance = game()
	expect(not FileAccess.file_exists(instance.campaign_save_path()), "Fresh test profile has no save")
	instance.read_campaign_save()
	expect(not instance.save_available, "Continue disabled with no save")
	instance.main_menu_selection = 0
	key(instance, KEY_ENTER)
	expect(instance.state == "main_menu" and not FileAccess.file_exists(instance.campaign_save_path()), "Unavailable Continue does not start or save")
	instance.main_menu_selection = 1
	key(instance, KEY_ENTER)
	fresh(instance)
	saved_campaign(instance)
	var saved := bytes(instance)
	instance.state = "main_menu"
	instance.main_menu_selection = 1
	instance.save_available = false # Simulate a save appearing after the menu was drawn.
	key(instance, KEY_ENTER)
	expect(instance.state == "menu_confirm_new", "New Game rechecks existing save")
	expect(bytes(instance) == saved, "Opening confirmation does not write progress")
	key(instance, KEY_ESCAPE)
	expect(instance.state == "main_menu" and bytes(instance) == saved, "Cancel preserves exact save bytes")
	instance.main_menu_selection = 0
	key(instance, KEY_ENTER)
	expect(instance.state == "playing" and instance.level == 26, "Continue loads saved Bosnia mission")
	expect(instance.city_route == [0,3,1,2,4,5] and instance.score == 275300 and instance.scrap == 9825, "Continue restores route and rewards")
	expect(instance.extra_bullet_level == 8 and instance.arc_lightning_owned and instance.campaign_orbs_found_mask == 15, "Continue restores upgrades, advanced weapon and orbs")
	expect(bytes(instance) == saved, "Continue does not rewrite saved data")
	instance.bindings.assign([KEY_J, KEY_L, KEY_K, KEY_U, KEY_I, KEY_TAB])
	expect(instance.save_bindings(), "Custom test bindings saved")
	var controls := FileAccess.get_file_as_bytes(instance.controls_save_path())
	instance.music_enabled = false
	instance.music_volume = 0.2
	instance.sfx_volume = 0.4
	instance.show_performance_stats = true
	instance.armor_fragments.append({"test": true})
	instance.invulnerable = 8.0
	instance.fire_held = true
	instance.plasma_shot_sequence = 15
	instance.pre_boss_shop = true
	instance.hq_dialogue_index = 3
	instance.storm_pulses_remaining = 3
	instance.state = "main_menu"
	instance.main_menu_selection = 1
	key(instance, KEY_ENTER)
	key(instance, KEY_ENTER)
	fresh(instance)
	expect(instance.bindings == [KEY_J,KEY_L,KEY_K,KEY_U,KEY_I,KEY_TAB], "New Game preserves custom bindings in memory")
	expect(FileAccess.get_file_as_bytes(instance.controls_save_path()) == controls, "New Game preserves bindings file bytes")
	expect(not instance.music_enabled and instance.music_volume == 0.2 and instance.sfx_volume == 0.4 and instance.show_performance_stats, "New Game preserves user preferences")
	var restarted = game()
	restarted.continue_campaign()
	expect(restarted.level == 1 and restarted.state == "city_select" and restarted.city_route.is_empty(), "New instance resumes fresh checkpoint")
	expect(restarted.load_bindings_from_path(restarted.controls_save_path()) and restarted.bindings == instance.bindings, "Bindings survive restart")
	restarted.free()
	# Version-1 compatibility: optional fields absent; legacy capital route retained.
	var legacy := ConfigFile.new()
	legacy.set_value("campaign", "version", 1)
	legacy.set_value("campaign", "checkpoint", "playing")
	legacy.set_value("campaign", "level", 46)
	legacy.set_value("campaign", "lives", 2)
	legacy.set_value("campaign", "city_route", [0,1,2,3,4,5,6,7,8,9])
	expect(legacy.save(instance.campaign_save_path()) == OK, "Legacy fixture written")
	var legacy_bytes := bytes(instance)
	instance.continue_campaign()
	expect(instance.level == 46 and instance.city_route[9] == 9 and instance.extra_bullet_level == 0, "Older save and legacy Bosnia route load")
	expect(bytes(instance) == legacy_bytes, "Legacy load does not rewrite file")
	var invalid := FileAccess.open(instance.campaign_save_path(), FileAccess.WRITE)
	invalid.store_string("[campaign]\nversion=999\n")
	invalid.close()
	var invalid_bytes := bytes(instance)
	instance.state = "main_menu"
	instance.continue_campaign()
	expect(not instance.save_available and instance.state == "main_menu", "Invalid save cannot Continue")
	instance.main_menu_selection = 1
	key(instance, KEY_ENTER)
	expect(instance.state == "menu_confirm_new", "Invalid existing save also requires replacement confirmation")
	key(instance, KEY_ESCAPE)
	expect(bytes(instance) == invalid_bytes, "Cancel preserves invalid file for recovery")
	instance.free()

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-test-dir="):
			directory = argument.trim_prefix("--save-test-dir=")
		if argument.begins_with("--phase="):
			phase = argument.trim_prefix("--phase=")
	if directory.is_empty():
		if not OS.has_feature("editor"):
			push_error("Exported QA requires an explicit --save-test-dir")
			get_tree().quit(1)
			return
		directory = ProjectSettings.globalize_path("res://build/campaign-save-test-%d" % Time.get_ticks_usec())
	if not directory.is_absolute_path() or phase not in ["all", "write", "read"]:
		push_error("Invalid QA directory or phase")
		get_tree().quit(1)
		return
	if phase != "read" and FileAccess.file_exists(directory.path_join("campaign_save.cfg")):
		push_error("Refusing to replace a pre-existing test save; choose a fresh QA directory")
		get_tree().quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("Cannot create QA profile")
		get_tree().quit(1)
		return
	print("CAMPAIGN SAVE QA BEGIN: phase=", phase)
	get_tree().create_timer(30.0).timeout.connect(func():
		push_error("Campaign save QA watchdog expired")
		get_tree().quit(1))
	call_deferred("run_tests")

func run_tests() -> void:
	if phase == "write":
		var instance = game()
		saved_campaign(instance)
		instance.free()
	elif phase == "read":
		var instance = game()
		var before := bytes(instance)
		instance.continue_campaign()
		expect(instance.level == 26 and instance.score == 275300 and instance.arc_lightning_owned, "New OS process continues saved campaign")
		expect(bytes(instance) == before, "Process restart preserves checkpoint bytes")
		instance.free()
	elif phase == "all":
		test_all()
	else:
		expect(false, "Unknown test phase")
	print("CAMPAIGN SAVE QA: ", checks, " checks, ", failures, " failures")
	print("CAMPAIGN SAVE QA COMPLETE: phase=%s checks=%d failures=%d" % [phase, checks, failures])
	get_tree().quit(1 if failures else 0)
