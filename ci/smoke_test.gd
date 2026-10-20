extends SceneTree

# Automated gameplay smoke test, run with --headless --script ci/smoke_test.gd.
# Tests real engine scene loading and gameplay startup, not device installation.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	if packed == null:
		_fail("Could not load main game scene")
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	if game.state != "menu":
		_fail("Game did not enter main menu")
		return
	game.new_game()
	await process_frame
	if game.state != "playing" or game.enemies.is_empty():
		_fail("No enemies spawned on new game")
		return
	game.fire_weapon()
	if game.bullets.is_empty():
		_fail("Weapon did not fire")
		return
	game.finish_stage()
	if game.state != "upgrade" or game.choice_ids.size() != 3:
		_fail("Upgrade stage was not reached")
		return
	game.apply_upgrade(0)
	if game.stage != 2 or game.state != "playing":
		_fail("Stage transition did not work")
		return
	print("SMOKE_TEST_OK: menu, combat, weapons, upgrades and stage transitions")
	quit(0)

func _fail(message: String) -> void:
	printerr("SMOKE_TEST_FAILED: " + message)
	quit(1)
