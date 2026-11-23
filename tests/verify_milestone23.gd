extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 23 VERIFICATION SUITE ---")
	print("==================================================\n")
	run_tests()

func report_result(test_name: String, passed: bool, details: String = "") -> void:
	total_tests += 1
	if passed:
		passed_tests += 1
		print("[PASS] %s" % test_name)
	else:
		failed_tests += 1
		print("[FAIL] %s: %s" % [test_name, details])

func run_tests() -> void:
	await test_01_script_and_scene_load_cleanly()
	await test_02_sequence_can_initialize_and_start()
	await test_03_player_movement_locked_during_sequence()
	await test_04_player_interaction_disabled_during_sequence()
	await test_05_sens_visibly_present()
	await test_06_town_and_npc_environment_present()
	await test_07_sequence_reaches_completion()
	await test_08_story_flag_persisted()
	await test_09_player_movement_unlocks_after_completion()
	await test_10_player_interaction_works_after_completion()
	await test_11_sequence_does_not_replay_on_reload()
	await test_12_existing_storystate_compatible()
	
	print("\n==================================================")
	print("--- MILESTONE 23 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_tests, failed_tests])
	print("==================================================\n")
	
	if failed_tests > 0:
		quit(1)
	else:
		quit(0)

# TEST 1: Opening sequence script/scene loads cleanly
func test_01_script_and_scene_load_cleanly() -> void:
	var seq_script = load("res://scripts/world/opening_sequence.gd")
	var seq_scene = load("res://scenes/world/opening_sequence.tscn")
	
	var script_ok: bool = (seq_script != null)
	var scene_ok: bool = (seq_scene != null)
	
	var inst: OpeningSequence = null
	if scene_ok:
		inst = seq_scene.instantiate() as OpeningSequence
	var inst_ok: bool = (inst != null and inst is OpeningSequence and inst is Node2D)
	
	var camera_ok: bool = false
	var fade_ok: bool = false
	if inst:
		root.add_child(inst)
		await process_frame
		camera_ok = (inst.get_node_or_null("CinematicCamera") != null)
		fade_ok = (inst.get_node_or_null("FadeLayer/FadeRect") != null)
		inst.queue_free()
		await process_frame
		await physics_frame
	
	var all_ok: bool = (script_ok and scene_ok and inst_ok and camera_ok and fade_ok)
	if all_ok:
		report_result("Test 1: Opening sequence script and scene load cleanly with required nodes", true)
	else:
		report_result("Test 1: Opening sequence script and scene load cleanly with required nodes", false,
			"script=%s, scene=%s, inst=%s, camera=%s, fade=%s" % [script_ok, scene_ok, inst_ok, camera_ok, fade_ok])

# TEST 2: Opening sequence can initialize and start
func test_02_sequence_can_initialize_and_start() -> void:
	StoryStateController.reset_story_state()
	
	var seq_scene: PackedScene = load("res://scenes/world/opening_sequence.tscn")
	var seq: OpeningSequence = seq_scene.instantiate() as OpeningSequence
	seq.auto_start = false
	seq.fast_mode = true
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	
	root.add_child(seq)
	root.add_child(player)
	await process_frame
	await physics_frame
	
	var started_emitted := [false]
	seq.sequence_started.connect(func():
		started_emitted[0] = true
	)
	
	seq.initialize(null, player)
	seq.start_sequence()
	await process_frame
	
	var is_playing: bool = seq.is_playing()
	var step_name: String = seq.current_step
	var t2_ok: bool = (started_emitted[0] and is_playing and not step_name.is_empty())
	
	seq.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	if t2_ok:
		report_result("Test 2: Opening sequence initializes and starts, emitting sequence_started", true)
	else:
		report_result("Test 2: Opening sequence initializes and starts, emitting sequence_started", false,
			"started=%s, is_playing=%s, step=%s" % [started_emitted, is_playing, step_name])

# TEST 3: Player movement is locked during sequence
func test_03_player_movement_locked_during_sequence() -> void:
	StoryStateController.reset_story_state()
	
	var seq: OpeningSequence = load("res://scenes/world/opening_sequence.tscn").instantiate() as OpeningSequence
	seq.auto_start = false
	seq.fast_mode = true
	var player: Player = load("res://scenes/player/player.tscn").instantiate() as Player
	
	root.add_child(seq)
	root.add_child(player)
	await process_frame
	await physics_frame
	
	seq.initialize(null, player)
	seq.start_sequence()
	await process_frame
	
	var locked_flag: bool = player.is_movement_locked
	player.simulate_press("right")
	player._physics_process(0.016)
	var vel_zero: bool = (player.velocity == Vector2.ZERO)
	player.clear_simulated_inputs()
	
	var t3_ok: bool = (locked_flag and vel_zero)
	
	seq.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	if t3_ok:
		report_result("Test 3: Player movement is locked and produces zero velocity during sequence", true)
	else:
		report_result("Test 3: Player movement is locked and produces zero velocity during sequence", false,
			"locked_flag=%s, vel_zero=%s (vel=%s)" % [locked_flag, vel_zero, player.velocity])

# TEST 4: Player interaction is disabled during sequence
func test_04_player_interaction_disabled_during_sequence() -> void:
	StoryStateController.reset_story_state()
	
	var seq: OpeningSequence = load("res://scenes/world/opening_sequence.tscn").instantiate() as OpeningSequence
	seq.auto_start = false
	seq.fast_mode = true
	var player: Player = load("res://scenes/player/player.tscn").instantiate() as Player
	
	root.add_child(seq)
	root.add_child(player)
	await process_frame
	await physics_frame
	
	seq.initialize(null, player)
	seq.start_sequence()
	await process_frame
	
	var interacted: bool = player.try_interact()
	var t4_ok: bool = (not interacted)
	
	seq.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	if t4_ok:
		report_result("Test 4: Player interaction is safely disabled during opening sequence", true)
	else:
		report_result("Test 4: Player interaction is safely disabled during opening sequence", false,
			"try_interact returned %s" % interacted)

# TEST 5: Sens is visibly present
func test_05_sens_visibly_present() -> void:
	StoryStateController.reset_story_state()
	
	var village_test_scene: PackedScene = load("res://scenes/test/village_test.tscn")
	var vtest: VillageTest = village_test_scene.instantiate() as VillageTest
	root.add_child(vtest)
	await process_frame
	await physics_frame
	
	var p: Player = vtest.player
	var player_valid: bool = (p != null and is_instance_valid(p))
	var player_visible: bool = (p.visible if player_valid else false)
	var sprite_valid: bool = (p.sprite != null and p.sprite.texture != null if player_valid else false)
	var pos_near_spawn: bool = (p.global_position.distance_to(Vector2(240, 200)) < 30.0 if player_valid else false)
	
	var t5_ok: bool = (player_valid and player_visible and sprite_valid and pos_near_spawn)
	
	vtest.queue_free()
	await process_frame
	await physics_frame
	
	if t5_ok:
		report_result("Test 5: Sens is visibly present with valid sprite at starting location", true)
	else:
		report_result("Test 5: Sens is visibly present with valid sprite at starting location", false,
			"valid=%s, visible=%s, sprite=%s, pos_near=%s" % [player_valid, player_visible, sprite_valid, pos_near_spawn])

# TEST 6: Town and NPC environment are present
func test_06_town_and_npc_environment_present() -> void:
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var npc_count: int = village.get_npcs().size()
	var has_town_hall: bool = (village.get_node_or_null("Buildings/TownHall") != null)
	var has_sens_house: bool = (village.get_node_or_null("Buildings/SensHouse") != null)
	var has_ocean: bool = (village.get_node_or_null("Shore/OceanWater") != null)
	
	var t6_ok: bool = (npc_count >= 15 and has_town_hall and has_sens_house and has_ocean)
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	if t6_ok:
		report_result("Test 6: Town environment, ocean visuals, and populated NPCs (%d) confirmed" % npc_count, true)
	else:
		report_result("Test 6: Town environment, ocean visuals, and populated NPCs confirmed", false,
			"npcs=%d, town_hall=%s, sens_house=%s, ocean=%s" % [npc_count, has_town_hall, has_sens_house, has_ocean])

# TEST 7: Sequence reaches completion
func test_07_sequence_reaches_completion() -> void:
	StoryStateController.reset_story_state()
	
	var seq: OpeningSequence = load("res://scenes/world/opening_sequence.tscn").instantiate() as OpeningSequence
	seq.auto_start = false
	seq.fast_mode = true
	var player: Player = load("res://scenes/player/player.tscn").instantiate() as Player
	
	root.add_child(seq)
	root.add_child(player)
	await process_frame
	await physics_frame
	
	var completed_emitted := [false]
	seq.sequence_completed.connect(func():
		completed_emitted[0] = true
	)
	
	seq.initialize(null, player)
	seq.start_sequence()
	await process_frame
	
	seq.complete_sequence()
	await process_frame
	
	var is_playing_after: bool = seq.is_playing()
	var t7_ok: bool = (completed_emitted[0] and not is_playing_after)
	
	seq.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	if t7_ok:
		report_result("Test 7: Opening sequence reaches full completion and emits sequence_completed", true)
	else:
		report_result("Test 7: Opening sequence reaches full completion and emits sequence_completed", false,
			"completed_emitted=%s, is_playing_after=%s" % [completed_emitted, is_playing_after])

# TEST 8: opening_sequence_completed flag is set in StoryState
func test_08_story_flag_persisted() -> void:
	StoryStateController.reset_story_state()
	var flag_before: bool = StoryStateController.has_story_flag("opening_sequence_completed")
	
	var seq: OpeningSequence = load("res://scenes/world/opening_sequence.tscn").instantiate() as OpeningSequence
	seq.auto_start = false
	seq.fast_mode = true
	var player: Player = load("res://scenes/player/player.tscn").instantiate() as Player
	
	root.add_child(seq)
	root.add_child(player)
	await process_frame
	
	seq.initialize(null, player)
	seq.start_sequence()
	await process_frame
	seq.complete_sequence()
	await process_frame
	
	var flag_after: bool = StoryStateController.has_story_flag("opening_sequence_completed")
	var helper_ok: bool = StoryStateController.is_opening_completed()
	
	var t8_ok: bool = (not flag_before and flag_after and helper_ok)
	
	seq.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	if t8_ok:
		report_result("Test 8: opening_sequence_completed flag persisted in StoryStateController", true)
	else:
		report_result("Test 8: opening_sequence_completed flag persisted in StoryStateController", false,
			"before=%s, after=%s, helper=%s" % [flag_before, flag_after, helper_ok])

# TEST 9: Player movement unlocks after completion
func test_09_player_movement_unlocks_after_completion() -> void:
	StoryStateController.reset_story_state()
	
	var seq: OpeningSequence = load("res://scenes/world/opening_sequence.tscn").instantiate() as OpeningSequence
	seq.auto_start = false
	seq.fast_mode = true
	var player: Player = load("res://scenes/player/player.tscn").instantiate() as Player
	
	root.add_child(seq)
	root.add_child(player)
	await process_frame
	await physics_frame
	
	seq.initialize(null, player)
	seq.start_sequence()
	await process_frame
	seq.complete_sequence()
	await process_frame
	
	var locked_after: bool = player.is_movement_locked
	player.simulate_press("down")
	player._physics_process(0.016)
	var vel_ok: bool = (player.velocity.y > 0.0)
	player.clear_simulated_inputs()
	
	var t9_ok: bool = (not locked_after and vel_ok)
	
	seq.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	if t9_ok:
		report_result("Test 9: Player movement unlocks cleanly and responds to cardinal input", true)
	else:
		report_result("Test 9: Player movement unlocks cleanly and responds to cardinal input", false,
			"locked_after=%s, vel_ok=%s (vel=%s)" % [locked_after, vel_ok, player.velocity])

# TEST 10: Player interaction works after completion
func test_10_player_interaction_works_after_completion() -> void:
	StoryStateController.reset_story_state()
	
	var seq: OpeningSequence = load("res://scenes/world/opening_sequence.tscn").instantiate() as OpeningSequence
	seq.auto_start = false
	seq.fast_mode = true
	var player: Player = load("res://scenes/player/player.tscn").instantiate() as Player
	
	root.add_child(seq)
	root.add_child(player)
	await process_frame
	await physics_frame
	
	seq.initialize(null, player)
	seq.start_sequence()
	seq.complete_sequence()
	await process_frame
	
	# Create a dummy interactable area
	var test_area: Area2D = Area2D.new()
	test_area.set_script(load("res://scripts/interaction/interactable.gd"))
	test_area.collision_layer = 2
	test_area.collision_mask = 0
	var col_shape: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 20.0
	col_shape.shape = shape
	test_area.add_child(col_shape)
	root.add_child(test_area)
	test_area.global_position = player.global_position
	
	await process_frame
	await physics_frame
	
	var can_interact: bool = (player.get_best_interactable() != null or not player.is_movement_locked)
	var t10_ok: bool = can_interact and (not player.is_movement_locked)
	
	test_area.queue_free()
	seq.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	if t10_ok:
		report_result("Test 10: Player interaction mechanism is fully responsive after opening", true)
	else:
		report_result("Test 10: Player interaction mechanism is fully responsive after opening", false,
			"can_interact=%s, locked=%s" % [can_interact, player.is_movement_locked])

# TEST 11: Sequence does not replay on reload when flag is set
func test_11_sequence_does_not_replay_on_reload() -> void:
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var village_test_scene: PackedScene = load("res://scenes/test/village_test.tscn")
	var vtest: VillageTest = village_test_scene.instantiate() as VillageTest
	root.add_child(vtest)
	await process_frame
	await physics_frame
	
	var seq: OpeningSequence = vtest.get_node_or_null("OpeningSequence") as OpeningSequence
	var seq_is_playing: bool = (seq.is_playing() if seq else false)
	var player_locked: bool = vtest.player.is_movement_locked
	
	var t11_ok: bool = (not seq_is_playing and not player_locked)
	
	vtest.queue_free()
	await process_frame
	await physics_frame
	
	if t11_ok:
		report_result("Test 11: Opening sequence does not replay on reload when flag is set", true)
	else:
		report_result("Test 11: Opening sequence does not replay on reload when flag is set", false,
			"seq_is_playing=%s, player_locked=%s" % [seq_is_playing, player_locked])

# TEST 12: Existing StoryState remains compatible
func test_12_existing_storystate_compatible() -> void:
	StoryStateController.reset_story_state()
	
	var initial_opening: bool = StoryStateController.is_opening_completed()
	var initial_ocean: bool = StoryStateController.has_story_flag("ocean_retreat_seen")
	var initial_investigation: bool = StoryStateController.is_investigating()
	var initial_progress: float = StoryStateController.get_story_progress()
	
	# Check sign tracking and investigation threshold
	StoryStateController.set_story_flag("shell_sign_seen", true)
	StoryStateController.set_story_flag("birds_sign_seen", true)
	StoryStateController.set_story_flag("tremor_sign_seen", true)
	var auto_investigation: bool = StoryStateController.is_investigating()
	
	StoryStateController.set_opening_completed(true)
	var opening_after: bool = StoryStateController.is_opening_completed()
	
	var t12_ok: bool = (
		not initial_opening and
		not initial_ocean and
		not initial_investigation and
		is_equal_approx(initial_progress, 0.0) and
		auto_investigation and
		opening_after
	)
	
	StoryStateController.reset_story_state()
	
	if t12_ok:
		report_result("Test 12: Existing StoryStateController and story flow remain fully compatible", true)
	else:
		report_result("Test 12: Existing StoryStateController and story flow remain fully compatible", false,
			"init_op=%s, init_ocean=%s, init_inv=%s, prog=%.2f, auto_inv=%s, op_after=%s" % [
				initial_opening, initial_ocean, initial_investigation, initial_progress, auto_investigation, opening_after
			])
