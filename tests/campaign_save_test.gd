extends SceneTree
## Editor CLI entry point. The exported QA build uses the same suite as its main scene.

const SUITE = preload("res://tests/campaign_save_suite.gd")

func _initialize() -> void:
	call_deferred("start_suite")

func start_suite() -> void:
	root.add_child(SUITE.new())
