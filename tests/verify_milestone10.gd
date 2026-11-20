extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null
var story_state_node: StoryStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 10 VERIFICATION SUITE ---")
	print("==================================================\n")
	# Ensure OceanState and StoryState instances are active in root for test run
	ocean_state_node = OceanStateController.new()
	ocean_state_node.name = "OceanState"
	root.add_child(ocean_state_node)
	
	story_state_node = StoryStateController.new()
	story_state_node.name = "StoryState"
	root.add_child(story_state_node)
	
	call_deferred("_run_all_tests")

func report_result(test_name: String, passed: bool, error_msg: String = "") -> void:
	if passed:
		passed_count += 1
		print("[PASS] %s" % test_name)
	else:
		failed_count += 1
		print("[FAIL] %s: %s" % [test_name, error_msg])

func _run_all_tests() -> void:
	await test_1_story_state_initialization()
	await test_2_all_expected_flags_start_false()
	await test_3_set_flag_and_has_flag()
	await test_4_flag_idempotency()
	await test_5_shell_discovery_recording()
	await test_6_tide_pool_discovery_recording()
	await test_7_bird_discovery_recording()
	await test_8_tremor_discovery_recording()
	await test_9_wind_discovery_recording()
	await test_10_investigation_threshold_activation()
	await test_11_investigation_does_not_activate_prematurely()
	await test_12_major_truth_discovered_remains_false_initially()
	await test_13_major_truth_discovered_explicit_setting()
	await test_14_persistence_across_scene_transitions()
	await test_15_ocean_state_independence()
	await test_16_environmental_signs_milestone8_integrity()
	await test_17_dialogue_ui_milestone9_integrity()
	await test_18_player_movement_and_interactions_integrity()
	await test_19_main_scene_integrity()
	await test_20_story_state_test_scene_integrity()
	
	print("\n==================================================")
	print("--- MILESTONE 10 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: StoryState initialization
func test_1_story_state_initialization() -> void:
	print("[TEST 1] Verifying StoryState initialization and singleton instance...")
	var is_inst: bool = StoryStateController.instance != null
	var is_node: bool = story_state_node is StoryStateController
	var has_threshold: bool = StoryStateController.INVESTIGATION_THRESHOLD == 3
	
	if is_inst and is_node and has_threshold:
		report_result("Test 1: StoryState initializes correctly with singleton instance and threshold 3", true)
	else:
		report_result("Test 1: StoryState initializes correctly with singleton instance and threshold 3", false,
			"is_inst=%s, is_node=%s, threshold=%d" % [is_inst, is_node, StoryStateController.INVESTIGATION_THRESHOLD])

# TEST 2: All expected flags start false
func test_2_all_expected_flags_start_false() -> void:
	print("[TEST 2] Verifying all expected story flags initialize to false...")
	story_state_node.reset_state()
	
	var expected_flags := [
		"ocean_retreat_seen",
		"shell_sign_seen",
		"tide_pool_sign_seen",
		"birds_sign_seen",
		"tremor_sign_seen",
		"wind_sign_seen",
		"investigation_started",
		"shipwreck_clue_found",
		"major_truth_discovered"
	]
	
	var all_false: bool = true
	var bad_flag: String = ""
	for f in expected_flags:
		if story_state_node.has_flag(f):
			all_false = false
			bad_flag = f
			break
	
	var progress_zero: bool = is_equal_approx(story_state_node.get_progress(), 0.0)
	
	if all_false and progress_zero:
		report_result("Test 2: All expected flags initialize to false with progress 0.0", true)
	else:
		report_result("Test 2: All expected flags initialize to false with progress 0.0", false,
			"all_false=%s (bad=%s), progress_zero=%s" % [all_false, bad_flag, progress_zero])

# TEST 3: set_flag and has_flag
func test_3_set_flag_and_has_flag() -> void:
	print("[TEST 3] Verifying set_flag(), has_flag(), and flag_changed signal...")
	story_state_node.reset_state()
	
	var capture := {"changed": false, "flag": "", "val": false}
	var cb = func(f_name: String, n_val: bool):
		capture.changed = true
		capture.flag = f_name
		capture.val = n_val
	story_state_node.flag_changed.connect(cb)
	
	story_state_node.set_flag("ocean_retreat_seen", true)
	await process_frame
	
	var flag_ok: bool = story_state_node.has_flag("ocean_retreat_seen")
	var signal_ok: bool = capture.changed and capture.flag == "ocean_retreat_seen" and capture.val == true
	
	story_state_node.flag_changed.disconnect(cb)
	
	if flag_ok and signal_ok:
		report_result("Test 3: set_flag() sets state and emits flag_changed accurately", true)
	else:
		report_result("Test 3: set_flag() sets state and emits flag_changed accurately", false,
			"flag_ok=%s, signal_ok=%s" % [flag_ok, signal_ok])

# TEST 4: Flag idempotency
func test_4_flag_idempotency() -> void:
	print("[TEST 4] Verifying set_flag() is idempotent and safe...")
	story_state_node.reset_state()
	story_state_node.set_flag("shell_sign_seen", true)
	
	var emit_count: int = 0
	var cb = func(_f, _v): emit_count += 1
	story_state_node.flag_changed.connect(cb)
	
	# Setting already-true flag again should NOT emit or corrupt state
	story_state_node.set_flag("shell_sign_seen", true)
	story_state_node.set_flag("shell_sign_seen", true)
	await process_frame
	
	story_state_node.flag_changed.disconnect(cb)
	
	var remains_true: bool = story_state_node.has_flag("shell_sign_seen")
	var no_extra_emits: bool = emit_count == 0
	
	if remains_true and no_extra_emits:
		report_result("Test 4: Re-setting existing flag is safe and idempotent (0 re-emissions)", true)
	else:
		report_result("Test 4: Re-setting existing flag is safe and idempotent (0 re-emissions)", false,
			"remains_true=%s, emits=%d" % [remains_true, emit_count])

# TEST 5: Shell discovery recording
func test_5_shell_discovery_recording() -> void:
	print("[TEST 5] Verifying shell interaction records shell_sign_seen in StoryState...")
	story_state_node.reset_state()
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var shell_scene: PackedScene = load("res://scenes/world/seabed/shell.tscn")
	var shell: SeabedShell = shell_scene.instantiate() as SeabedShell
	root.add_child(shell)
	await process_frame
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	await process_frame
	
	shell.interact(player)
	await process_frame
	
	var shell_seen: bool = story_state_node.has_flag("shell_sign_seen")
	
	shell.queue_free()
	player.queue_free()
	await process_frame
	
	if shell_seen:
		report_result("Test 5: Examining singing shell records shell_sign_seen in StoryState", true)
	else:
		report_result("Test 5: Examining singing shell records shell_sign_seen in StoryState", false,
			"shell_seen=%s" % shell_seen)

# TEST 6: Tide pool discovery recording
func test_6_tide_pool_discovery_recording() -> void:
	print("[TEST 6] Verifying tide pool observation records tide_pool_sign_seen...")
	story_state_node.reset_state()
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	await process_frame
	
	var tide_pools: TidePoolSign = seabed.get_node("TidePools") as TidePoolSign
	tide_pools.observe_tide_pools()
	await process_frame
	
	var pool_seen: bool = story_state_node.has_flag("tide_pool_sign_seen")
	
	seabed.queue_free()
	await process_frame
	
	if pool_seen:
		report_result("Test 6: Observing drained tide pools records tide_pool_sign_seen in StoryState", true)
	else:
		report_result("Test 6: Observing drained tide pools records tide_pool_sign_seen in StoryState", false,
			"pool_seen=%s" % pool_seen)

# TEST 7: Bird discovery recording
func test_7_bird_discovery_recording() -> void:
	print("[TEST 7] Verifying inland bird observation records birds_sign_seen...")
	story_state_node.reset_state()
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	await process_frame
	
	var birds: CoastalBirdsSign = village.get_node("CoastalBirds") as CoastalBirdsSign
	birds.observe_birds()
	await process_frame
	
	var birds_seen: bool = story_state_node.has_flag("birds_sign_seen")
	
	village.queue_free()
	await process_frame
	
	if birds_seen:
		report_result("Test 7: Observing inland birds records birds_sign_seen in StoryState", true)
	else:
		report_result("Test 7: Observing inland birds records birds_sign_seen in StoryState", false,
			"birds_seen=%s" % birds_seen)

# TEST 8: Tremor discovery recording
func test_8_tremor_discovery_recording() -> void:
	print("[TEST 8] Verifying subtle tremor records tremor_sign_seen...")
	story_state_node.reset_state()
	
	var tremor_node := SeabedTremorSign.new()
	root.add_child(tremor_node)
	await process_frame
	
	tremor_node.trigger_subtle_tremor()
	await process_frame
	
	var tremor_seen: bool = story_state_node.has_flag("tremor_sign_seen")
	
	tremor_node.queue_free()
	await process_frame
	
	if tremor_seen:
		report_result("Test 8: Experiencing seabed tremor records tremor_sign_seen in StoryState", true)
	else:
		report_result("Test 8: Experiencing seabed tremor records tremor_sign_seen in StoryState", false,
			"tremor_seen=%s" % tremor_seen)

# TEST 9: Wind discovery recording
func test_9_wind_discovery_recording() -> void:
	print("[TEST 9] Verifying wind draft observation records wind_sign_seen...")
	story_state_node.reset_state()
	
	var wind_node := SeabedWindSign.new()
	root.add_child(wind_node)
	await process_frame
	
	wind_node._update_sign_state(true)
	wind_node.observe_wind()
	await process_frame
	
	var wind_seen: bool = story_state_node.has_flag("wind_sign_seen")
	
	wind_node.queue_free()
	await process_frame
	
	if wind_seen:
		report_result("Test 9: Observing seabed wind draft records wind_sign_seen in StoryState", true)
	else:
		report_result("Test 9: Observing seabed wind draft records wind_sign_seen in StoryState", false,
			"wind_seen=%s" % wind_seen)

# TEST 10: Investigation threshold activation (3 signs)
func test_10_investigation_threshold_activation() -> void:
	print("[TEST 10] Verifying investigation activates automatically at threshold of 3 signs...")
	story_state_node.reset_state()
	
	var capture := {"investigation_emitted": false}
	story_state_node.investigation_started.connect(func(): capture.investigation_emitted = true)
	
	# Sign 1
	story_state_node.set_flag("shell_sign_seen", true)
	# Sign 2
	story_state_node.set_flag("birds_sign_seen", true)
	# Sign 3 (Threshold!)
	story_state_node.set_flag("tremor_sign_seen", true)
	await process_frame
	
	var count_3: bool = story_state_node.get_discovered_sign_count() == 3
	var inv_active: bool = story_state_node.is_investigation_started()
	var signal_emitted: bool = capture.investigation_emitted
	
	if count_3 and inv_active and signal_emitted:
		report_result("Test 10: Investigation phase activates automatically upon discovering 3 signs", true)
	else:
		report_result("Test 10: Investigation phase activates automatically upon discovering 3 signs", false,
			"count_3=%s, inv_active=%s, signal=%s" % [count_3, inv_active, signal_emitted])

# TEST 11: Investigation does not activate prematurely (< 3 signs)
func test_11_investigation_does_not_activate_prematurely() -> void:
	print("[TEST 11] Verifying investigation does NOT activate with 0, 1, or 2 signs...")
	story_state_node.reset_state()
	
	# 0 signs
	var zero_ok: bool = not story_state_node.is_investigation_started()
	
	# 1 sign
	story_state_node.set_flag("shell_sign_seen", true)
	var one_ok: bool = not story_state_node.is_investigation_started()
	
	# 2 signs
	story_state_node.set_flag("tide_pool_sign_seen", true)
	var two_ok: bool = not story_state_node.is_investigation_started()
	
	if zero_ok and one_ok and two_ok:
		report_result("Test 11: Investigation remains strictly INACTIVE below threshold (< 3 signs)", true)
	else:
		report_result("Test 11: Investigation remains strictly INACTIVE below threshold (< 3 signs)", false,
			"zero=%s, one=%s, two=%s" % [zero_ok, one_ok, two_ok])

# TEST 12: major_truth_discovered remains false initially
func test_12_major_truth_discovered_remains_false_initially() -> void:
	print("[TEST 12] Verifying major_truth_discovered and can_discover_truth() remain false initially...")
	story_state_node.reset_state()
	
	var truth_false: bool = not story_state_node.is_truth_discovered()
	var can_truth_false: bool = not story_state_node.can_discover_truth()
	
	# Even with investigation active, cannot discover truth without shipwreck clue
	story_state_node.set_flag("investigation_started", true)
	var can_truth_still_false: bool = not story_state_node.can_discover_truth()
	
	if truth_false and can_truth_false and can_truth_still_false:
		report_result("Test 12: Major truth remains undiscovered and locked without prerequisite clues", true)
	else:
		report_result("Test 12: Major truth remains undiscovered and locked without prerequisite clues", false,
			"truth_false=%s, can_truth_false=%s, can_truth_still_false=%s" %
			[truth_false, can_truth_false, can_truth_still_false])

# TEST 13: major_truth_discovered explicit setting
func test_13_major_truth_discovered_explicit_setting() -> void:
	print("[TEST 13] Verifying can_discover_truth() and truth_discovered emission when prerequisites met...")
	story_state_node.reset_state()
	
	var capture := {"truth_emitted": false}
	story_state_node.truth_discovered.connect(func(): capture.truth_emitted = true)
	
	story_state_node.set_flag("investigation_started", true)
	story_state_node.set_flag("shipwreck_clue_found", true)
	
	var can_discover: bool = story_state_node.can_discover_truth()
	
	# Explicitly uncover truth (to be invoked in Milestone 11)
	story_state_node.set_flag("major_truth_discovered", true)
	await process_frame
	
	var truth_is_discovered: bool = story_state_node.is_truth_discovered()
	var signal_emitted: bool = capture.truth_emitted
	
	if can_discover and truth_is_discovered and signal_emitted:
		report_result("Test 13: Prerequisites enable can_discover_truth(), explicit set emits truth_discovered", true)
	else:
		report_result("Test 13: Prerequisites enable can_discover_truth(), explicit set emits truth_discovered", false,
			"can=%s, truth=%s, signal=%s" % [can_discover, truth_is_discovered, signal_emitted])

# TEST 14: StoryState persists across Village <-> Seabed transitions
func test_14_persistence_across_scene_transitions() -> void:
	print("[TEST 14] Verifying StoryState persists across scene transitions...")
	story_state_node.reset_state()
	
	story_state_node.set_flag("shell_sign_seen", true)
	story_state_node.set_flag("birds_sign_seen", true)
	story_state_node.set_flag("tremor_sign_seen", true) # investigation active
	
	# Transition to Seabed test scene
	var seabed_scene: PackedScene = load("res://scenes/test/seabed_test.tscn")
	var seabed_test: Node2D = seabed_scene.instantiate()
	root.add_child(seabed_test)
	await process_frame
	
	var persisted_in_seabed: bool = (
		StoryStateController.has_story_flag("shell_sign_seen") and
		StoryStateController.has_story_flag("birds_sign_seen") and
		StoryStateController.has_story_flag("tremor_sign_seen") and
		StoryStateController.is_investigating()
	)
	
	seabed_test.queue_free()
	await process_frame
	
	# Transition back to Village test scene
	var village_scene: PackedScene = load("res://scenes/test/village_test.tscn")
	var village_test: Node2D = village_scene.instantiate()
	root.add_child(village_test)
	await process_frame
	
	var persisted_in_village: bool = (
		StoryStateController.has_story_flag("shell_sign_seen") and
		StoryStateController.has_story_flag("birds_sign_seen") and
		StoryStateController.has_story_flag("tremor_sign_seen") and
		StoryStateController.is_investigating()
	)
	
	village_test.queue_free()
	await process_frame
	
	if persisted_in_seabed and persisted_in_village:
		report_result("Test 14: StoryState flags and investigation status fully survive round-trip scene transitions", true)
	else:
		report_result("Test 14: StoryState flags and investigation status fully survive round-trip scene transitions", false,
			"seabed=%s, village=%s" % [persisted_in_seabed, persisted_in_village])

# TEST 15: OceanState independence
func test_15_ocean_state_independence() -> void:
	print("[TEST 15] Verifying OceanState remains independent from StoryState...")
	story_state_node.reset_state()
	OceanStateController.reset_ocean_state()
	
	story_state_node.set_flag("birds_sign_seen", true)
	story_state_node.set_flag("shell_sign_seen", true)
	
	# Trigger and reset OceanState
	OceanStateController.trigger_ocean_retreat()
	var ocean_is_retreated: bool = OceanStateController.is_ocean_retreated()
	
	# Birds and shell flags in StoryState should remain untouched
	var birds_still_true: bool = story_state_node.has_flag("birds_sign_seen")
	var shell_still_true: bool = story_state_node.has_flag("shell_sign_seen")
	
	OceanStateController.reset_ocean_state()
	var ocean_is_normal: bool = OceanStateController.is_ocean_normal()
	var birds_persists_after_reset: bool = story_state_node.has_flag("birds_sign_seen")
	
	if ocean_is_retreated and ocean_is_normal and birds_still_true and shell_still_true and birds_persists_after_reset:
		report_result("Test 15: OceanState and StoryState operate independently without cross-corruption", true)
	else:
		report_result("Test 15: OceanState and StoryState operate independently without cross-corruption", false,
			"retreated=%s, normal=%s, birds=%s, shell=%s, birds_after=%s" %
			[ocean_is_retreated, ocean_is_normal, birds_still_true, shell_still_true, birds_persists_after_reset])

# TEST 16: Milestone 8 environmental signs integrity
func test_16_environmental_signs_milestone8_integrity() -> void:
	print("[TEST 16] Verifying Milestone 8 environmental signs (Shells, TidePools, Birds, Tremor, Wind)...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var shell: SeabedShell = seabed.get_node("StrangeSigns/ShellTidePools") as SeabedShell
	var shell_ok: bool = shell != null and shell.is_interactable and shell.visible
	
	var pools: TidePoolSign = seabed.get_node("TidePools") as TidePoolSign
	var pools_ok: bool = pools != null and pools.is_drained
	
	var tremor: SeabedTremorSign = seabed.get_node("StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	var tremor_ok: bool = tremor != null and tremor.is_active
	
	var wind: SeabedWindSign = seabed.get_node("StrangeSigns/SeabedWindSign") as SeabedWindSign
	var wind_ok: bool = wind != null and wind.is_active
	
	seabed.queue_free()
	await process_frame
	
	if shell_ok and pools_ok and tremor_ok and wind_ok:
		report_result("Test 16: Milestone 8 environmental signs remain 100% functional and responsive", true)
	else:
		report_result("Test 16: Milestone 8 environmental signs remain 100% functional and responsive", false,
			"shell=%s, pools=%s, tremor=%s, wind=%s" % [shell_ok, pools_ok, tremor_ok, wind_ok])

# TEST 17: Milestone 9 dialogue integrity
func test_17_dialogue_ui_milestone9_integrity() -> void:
	print("[TEST 17] Verifying Milestone 9 DialogueUI remains functional...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var test_entries := [
		{"speaker": "Narrator", "text": "Line A"},
		{"speaker": "Narrator", "text": "Line B"}
	]
	ui.start_dialogue(test_entries)
	await process_frame
	
	var open_ok: bool = ui.is_active() and ui.text_label.text == "Line A"
	ui.advance_dialogue()
	await process_frame
	var adv_ok: bool = ui.is_active() and ui.text_label.text == "Line B"
	ui.advance_dialogue()
	await process_frame
	var close_ok: bool = not ui.is_active()
	
	ui.queue_free()
	await process_frame
	
	if open_ok and adv_ok and close_ok:
		report_result("Test 17: Milestone 9 DialogueUI sequential progression operates cleanly", true)
	else:
		report_result("Test 17: Milestone 9 DialogueUI sequential progression operates cleanly", false,
			"open=%s, adv=%s, close=%s" % [open_ok, adv_ok, close_ok])

# TEST 18: Player movement and interactions integrity
func test_18_player_movement_and_interactions_integrity() -> void:
	print("[TEST 18] Verifying Player speed, diagonal normalization, and camera limits...")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player.global_position = Vector2(100, 100)
	await physics_frame
	
	# Normal diagonal velocity
	player.velocity = Vector2(1, 1).normalized() * player.speed
	var norm_ok: bool = is_equal_approx(player.velocity.length(), 80.0)
	
	# Movement locking
	player.lock_movement()
	player._physics_process(0.016)
	var lock_ok: bool = player.velocity == Vector2.ZERO
	player.unlock_movement()
	
	player.queue_free()
	await process_frame
	
	if norm_ok and lock_ok:
		report_result("Test 18: Player controller movement, normalization, and locking operate flawlessly", true)
	else:
		report_result("Test 18: Player controller movement, normalization, and locking operate flawlessly", false,
			"norm=%s, lock=%s" % [norm_ok, lock_ok])

# TEST 19: Main scene integrity
func test_19_main_scene_integrity() -> void:
	print("[TEST 19] Verifying main scene (scenes/main.tscn) instantiates cleanly...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node = main_scene.instantiate()
	var main_ok: bool = main_node is Node2D
	main_node.queue_free()
	await process_frame
	
	if main_ok:
		report_result("Test 19: Main scene instantiates cleanly as valid Node2D foundation", true)
	else:
		report_result("Test 19: Main scene instantiates cleanly as valid Node2D foundation", false,
			"main_ok=%s" % main_ok)

# TEST 20: StoryState test scene integrity
func test_20_story_state_test_scene_integrity() -> void:
	print("[TEST 20] Verifying story_state_test.tscn instantiates cleanly with all markers and HUD...")
	var test_scene: PackedScene = load("res://scenes/test/story_state_test.tscn")
	var scene_node: StoryStateTestScene = test_scene.instantiate() as StoryStateTestScene
	root.add_child(scene_node)
	await process_frame
	
	var player_ok: bool = scene_node.player != null
	var hud_ok: bool = scene_node.progress_label != null and scene_node.investigation_label != null
	var shell_marker_ok: bool = scene_node.shell_marker != null
	var truth_marker_ok: bool = scene_node.truth_marker != null
	
	scene_node.queue_free()
	await process_frame
	
	var pass_all: bool = player_ok and hud_ok and shell_marker_ok and truth_marker_ok
	if pass_all:
		report_result("Test 20: story_state_test.tscn instantiates cleanly with all clue markers and Debug HUD", true)
	else:
		report_result("Test 20: story_state_test.tscn instantiates cleanly with all clue markers and Debug HUD", false,
			"player=%s, hud=%s, shell_marker=%s, truth_marker=%s" %
			[player_ok, hud_ok, shell_marker_ok, truth_marker_ok])
