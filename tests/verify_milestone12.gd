extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null
var story_state_node: StoryStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 12 VERIFICATION SUITE ---")
	print("==================================================\n")
	# Ensure singletons are active in root for test run
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
	await test_1_major_truth_discovery_test_scene_loads()
	await test_2_major_truth_discovery_exists_in_village()
	await test_3_truth_discovery_initially_gated()
	await test_4_gated_interaction_shows_pre_toast_and_emits_gated_signal()
	await test_5_gated_prompt_is_look_out_at_bay()
	await test_6_partial_prerequisite_investigation_only_remains_gated()
	await test_7_partial_prerequisite_clue_only_remains_gated()
	await test_8_both_prerequisites_unlock_can_discover_truth()
	await test_9_unlocked_prompt_updates_to_survey_receded_ocean()
	await test_10_player_proximity_and_interact_triggers_overlook()
	await test_11_interaction_triggers_intro_toast_and_dialogue()
	await test_12_dialogue_contains_all_six_narrative_lines()
	await test_13_completing_dialogue_sets_major_truth_discovered()
	await test_14_signals_truth_revealed_and_truth_discovered_fired()
	await test_15_prompt_updates_to_observe_horizon_after_discovery()
	await test_16_subsequent_interaction_does_not_replay_dialogue()
	await test_17_major_truth_discovered_persists_across_scene_reloads()
	await test_18_story_progress_calculation_with_major_truth()
	await test_19_player_movement_locked_during_dialogue()
	await test_20_player_movement_unlocked_after_dialogue()
	await test_21_ocean_state_remains_independent()
	await test_22_milestone_8_environmental_signs_regression()
	await test_23_milestone_11_shipwreck_investigation_regression()
	await test_24_milestone_9_dialogue_ui_regression()
	await test_25_main_scene_instantiates_cleanly()
	
	print("\n==================================================")
	print("--- MILESTONE 12 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Major truth discovery test scene loads
func test_1_major_truth_discovery_test_scene_loads() -> void:
	print("[TEST 1] Verifying major truth discovery test scene loads cleanly...")
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	var scene_ok: bool = scene_node != null and scene_node is MajorTruthDiscoveryTestScene
	var hud_ok: bool = scene_node.investigation_status_label != null and scene_node.truth_status_label != null
	var overlook_ok: bool = scene_node.overlook != null and scene_node.overlook is MajorTruthDiscovery
	
	scene_node.queue_free()
	await process_frame
	
	if scene_ok and hud_ok and overlook_ok:
		report_result("Test 1: Major truth discovery test scene loads cleanly", true)
	else:
		report_result("Test 1: Major truth discovery test scene loads cleanly", false,
			"scene_ok=%s, hud_ok=%s, overlook_ok=%s" % [scene_ok, hud_ok, overlook_ok])

# TEST 2: MajorTruthDiscovery exists in village
func test_2_major_truth_discovery_exists_in_village() -> void:
	print("[TEST 2] Verifying CliffOverlook with MajorTruthDiscovery exists in village.tscn...")
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var overlook: MajorTruthDiscovery = village.get_node_or_null("Interactables/CliffOverlook") as MajorTruthDiscovery
	var shape: CollisionShape2D = village.get_node_or_null("Interactables/CliffOverlook/CollisionShape2D") as CollisionShape2D
	
	var overlook_ok: bool = overlook != null and overlook is MajorTruthDiscovery
	var pos_ok: bool = overlook != null and overlook.position == Vector2(480, 360)
	var shape_ok: bool = shape != null and shape.shape is CircleShape2D
	
	village.queue_free()
	await process_frame
	
	if overlook_ok and pos_ok and shape_ok:
		report_result("Test 2: CliffOverlook MajorTruthDiscovery exists in village.tscn at (480, 360)", true)
	else:
		report_result("Test 2: CliffOverlook MajorTruthDiscovery exists in village.tscn", false,
			"overlook_ok=%s, pos_ok=%s, shape_ok=%s" % [overlook_ok, pos_ok, shape_ok])

# TEST 3: Gated initially
func test_3_truth_discovery_initially_gated() -> void:
	print("[TEST 3] Verifying truth discovery is initially gated before prerequisites...")
	StoryStateController.reset_story_state()
	
	var can_discover: bool = StoryStateController.instance.can_discover_truth()
	var is_truth: bool = StoryStateController.instance.is_truth_discovered()
	
	if not can_discover and not is_truth:
		report_result("Test 3: Truth discovery is initially gated (can_discover_truth() == false)", true)
	else:
		report_result("Test 3: Truth discovery is initially gated", false,
			"can_discover=%s, is_truth=%s" % [can_discover, is_truth])

# TEST 4: Gated interaction shows pre-text toast and emits truth_attempted(true)
func test_4_gated_interaction_shows_pre_toast_and_emits_gated_signal() -> void:
	print("[TEST 4] Verifying gated interaction emits truth_attempted(true) and doesn't launch dialogue...")
	StoryStateController.reset_story_state()
	
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	var signal_data: Dictionary = {"attempted": false, "was_gated": false, "started": false}
	scene_node.overlook.truth_attempted.connect(func(was_gated: bool):
		signal_data["attempted"] = true
		signal_data["was_gated"] = was_gated
	)
	scene_node.overlook.truth_sequence_started.connect(func():
		signal_data["started"] = true
	)
	
	scene_node.overlook.interact(scene_node.player)
	await process_frame
	
	var attempted_ok: bool = signal_data["attempted"] and signal_data["was_gated"] == true
	var dialogue_not_started: bool = not signal_data["started"] and not scene_node.dialogue_ui.is_dialogue_active
	var truth_remains_false: bool = not StoryStateController.is_truth_known()
	
	scene_node.queue_free()
	await process_frame
	
	if attempted_ok and dialogue_not_started and truth_remains_false:
		report_result("Test 4: Gated interaction emits truth_attempted(true), no dialogue", true)
	else:
		report_result("Test 4: Gated interaction emits truth_attempted(true)", false,
			"attempted_ok=%s, dialogue_not_started=%s, truth_remains_false=%s" % [attempted_ok, dialogue_not_started, truth_remains_false])

# TEST 5: Gated prompt is "Look Out at Bay"
func test_5_gated_prompt_is_look_out_at_bay() -> void:
	print("[TEST 5] Verifying gated prompt is 'Look Out at Bay'...")
	StoryStateController.reset_story_state()
	var overlook := MajorTruthDiscovery.new()
	root.add_child(overlook)
	await process_frame
	
	var prompt_ok: bool = overlook.prompt_message == "Look Out at Bay"
	overlook.queue_free()
	await process_frame
	
	if prompt_ok:
		report_result("Test 5: Gated prompt message is 'Look Out at Bay'", true)
	else:
		report_result("Test 5: Gated prompt message is 'Look Out at Bay'", false,
			"prompt=%s" % overlook.prompt_message)

# TEST 6: Investigation started only remains gated
func test_6_partial_prerequisite_investigation_only_remains_gated() -> void:
	print("[TEST 6] Verifying investigation_started only leaves can_discover_truth() false...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	
	var can_discover: bool = StoryStateController.instance.can_discover_truth()
	var can_static: bool = StoryStateController.can_reveal_truth()
	
	if not can_discover and not can_static:
		report_result("Test 6: investigation_started only leaves truth discovery gated", true)
	else:
		report_result("Test 6: investigation_started only leaves truth discovery gated", false,
			"can_discover=%s, can_static=%s" % [can_discover, can_static])

# TEST 7: Clue found only remains gated
func test_7_partial_prerequisite_clue_only_remains_gated() -> void:
	print("[TEST 7] Verifying shipwreck_clue_found only leaves can_discover_truth() false...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var can_discover: bool = StoryStateController.instance.can_discover_truth()
	var can_static: bool = StoryStateController.can_reveal_truth()
	
	if not can_discover and not can_static:
		report_result("Test 7: shipwreck_clue_found only leaves truth discovery gated", true)
	else:
		report_result("Test 7: shipwreck_clue_found only leaves truth discovery gated", false,
			"can_discover=%s, can_static=%s" % [can_discover, can_static])

# TEST 8: Both prerequisites unlock can_discover_truth()
func test_8_both_prerequisites_unlock_can_discover_truth() -> void:
	print("[TEST 8] Verifying both prerequisites unlock can_discover_truth()...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var can_discover: bool = StoryStateController.instance.can_discover_truth()
	var can_static: bool = StoryStateController.can_reveal_truth()
	
	if can_discover and can_static:
		report_result("Test 8: Both prerequisites successfully unlock can_discover_truth()", true)
	else:
		report_result("Test 8: Both prerequisites unlock can_discover_truth()", false,
			"can_discover=%s, can_static=%s" % [can_discover, can_static])

# TEST 9: Unlocked prompt updates to "Survey the Receded Ocean"
func test_9_unlocked_prompt_updates_to_survey_receded_ocean() -> void:
	print("[TEST 9] Verifying prompt updates to 'Survey the Receded Ocean' when unlocked...")
	StoryStateController.reset_story_state()
	var overlook := MajorTruthDiscovery.new()
	root.add_child(overlook)
	await process_frame
	
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	overlook._update_prompt()
	
	var prompt_ok: bool = overlook.prompt_message == "Survey the Receded Ocean"
	overlook.queue_free()
	await process_frame
	
	if prompt_ok:
		report_result("Test 9: Prompt updates to 'Survey the Receded Ocean' when unlocked", true)
	else:
		report_result("Test 9: Prompt updates to 'Survey the Receded Ocean' when unlocked", false,
			"prompt=%s" % overlook.prompt_message)

# TEST 10: Player proximity and interact
func test_10_player_proximity_and_interact_triggers_overlook() -> void:
	print("[TEST 10] Verifying Player proximity and try_interact() triggers MajorTruthDiscovery...")
	StoryStateController.reset_story_state()
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var overlook: MajorTruthDiscovery = scene_node.overlook
	
	# Position player within interaction radius of overlook point (at 240, 160)
	player.global_position = Vector2(240, 160)
	await physics_frame
	await physics_frame
	
	var target: Interactable = player.get_best_interactable()
	var target_ok: bool = target == overlook
	
	var interacted: bool = player.try_interact()
	var count_ok: bool = overlook.interaction_count >= 1
	
	scene_node.queue_free()
	await process_frame
	
	if target_ok and interacted and count_ok:
		report_result("Test 10: Player proximity detection and try_interact() triggers MajorTruthDiscovery", true)
	else:
		report_result("Test 10: Player proximity detection and try_interact()", false,
			"target_ok=%s, interacted=%s, count_ok=%s" % [target_ok, interacted, count_ok])

# TEST 11: Interaction triggers intro toast and dialogue
func test_11_interaction_triggers_intro_toast_and_dialogue() -> void:
	print("[TEST 11] Verifying interaction when unlocked starts intro toast and dialogue...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	var signal_data: Dictionary = {"attempted": false, "was_gated": true, "started": false}
	scene_node.overlook.truth_attempted.connect(func(was_gated: bool):
		signal_data["attempted"] = true
		signal_data["was_gated"] = was_gated
	)
	scene_node.overlook.truth_sequence_started.connect(func():
		signal_data["started"] = true
	)
	
	scene_node.overlook.interact(scene_node.player)
	await process_frame
	
	var attempted_ok: bool = signal_data["attempted"] and signal_data["was_gated"] == false
	var started_ok: bool = signal_data["started"]
	var dialogue_active: bool = scene_node.dialogue_ui.is_dialogue_active
	
	scene_node.queue_free()
	await process_frame
	
	if attempted_ok and started_ok and dialogue_active:
		report_result("Test 11: Unlocked overlook interaction begins sequence and displays DialogueUI", true)
	else:
		report_result("Test 11: Unlocked overlook interaction begins sequence", false,
			"attempted_ok=%s, started_ok=%s, dialogue_active=%s" % [attempted_ok, started_ok, dialogue_active])

# TEST 12: Dialogue contains 6 lines
func test_12_dialogue_contains_all_six_narrative_lines() -> void:
	print("[TEST 12] Verifying dialogue sequence contains 6 narrative lines synthesizing clues...")
	var dialogue: Array[Dictionary] = MajorTruthDiscovery.TRUTH_DIALOGUE
	
	var size_ok: bool = dialogue.size() == 6
	var line1_has_stretches: bool = dialogue[0].get("text", "").contains("stretches farther")
	var line2_has_signs: bool = dialogue[1].get("text", "").contains("singing shells") and dialogue[1].get("text", "").contains("drained tide pools")
	var line3_has_log: bool = dialogue[2].get("text", "").contains("century turn")
	var line4_has_quote: bool = dialogue[3].get("text", "").contains("water drawing breath")
	var line5_has_room: bool = dialogue[4].get("text", "").contains("making room")
	var line6_has_tide: bool = dialogue[5].get("text", "").contains("won't be a tide")
	
	var all_ok: bool = size_ok and line1_has_stretches and line2_has_signs and line3_has_log and line4_has_quote and line5_has_room and line6_has_tide
	
	if all_ok:
		report_result("Test 12: Dialogue contains all 6 lines with correct narrative beats", true)
	else:
		report_result("Test 12: Dialogue contains all 6 lines", false,
			"size_ok=%s, 1=%s, 2=%s, 3=%s, 4=%s, 5=%s, 6=%s" % [
				size_ok, line1_has_stretches, line2_has_signs, line3_has_log, line4_has_quote, line5_has_room, line6_has_tide
			])

# TEST 13: Completing dialogue sets major_truth_discovered
func test_13_completing_dialogue_sets_major_truth_discovered() -> void:
	print("[TEST 13] Verifying completing dialogue sequence sets major_truth_discovered...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node.overlook.interact(scene_node.player)
	await process_frame
	
	# Advance through all lines of dialogue
	while scene_node.dialogue_ui.is_dialogue_active:
		scene_node.dialogue_ui.advance_dialogue()
		await process_frame
	
	var truth_set: bool = StoryStateController.is_truth_known()
	var instance_truth: bool = StoryStateController.instance.is_truth_discovered()
	
	scene_node.queue_free()
	await process_frame
	
	if truth_set and instance_truth:
		report_result("Test 13: Completing dialogue sequence sets major_truth_discovered in StoryState", true)
	else:
		report_result("Test 13: Completing dialogue sequence sets major_truth_discovered", false,
			"truth_set=%s, instance_truth=%s" % [truth_set, instance_truth])

# TEST 14: Signals truth_revealed and truth_discovered fired
func test_14_signals_truth_revealed_and_truth_discovered_fired() -> void:
	print("[TEST 14] Verifying truth_revealed on component and truth_discovered on StoryState are fired...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	var signal_data: Dictionary = {"component_revealed": false, "controller_discovered": false}
	scene_node.overlook.truth_revealed.connect(func():
		signal_data["component_revealed"] = true
	)
	StoryStateController.instance.truth_discovered.connect(func():
		signal_data["controller_discovered"] = true
	)
	
	scene_node.overlook.interact(scene_node.player)
	await process_frame
	
	while scene_node.dialogue_ui.is_dialogue_active:
		scene_node.dialogue_ui.advance_dialogue()
		await process_frame
	
	var comp_ok: bool = signal_data["component_revealed"]
	var ctrl_ok: bool = signal_data["controller_discovered"]
	
	scene_node.queue_free()
	await process_frame
	
	if comp_ok and ctrl_ok:
		report_result("Test 14: Both truth_revealed and truth_discovered signals fire on discovery", true)
	else:
		report_result("Test 14: Both truth_revealed and truth_discovered signals fire", false,
			"comp_ok=%s, ctrl_ok=%s" % [comp_ok, ctrl_ok])

# TEST 15: Prompt updates to "Observe the Horizon" after discovery
func test_15_prompt_updates_to_observe_horizon_after_discovery() -> void:
	print("[TEST 15] Verifying prompt updates to 'Observe the Horizon' after discovery...")
	StoryStateController.reset_story_state()
	var overlook := MajorTruthDiscovery.new()
	root.add_child(overlook)
	await process_frame
	
	StoryStateController.set_story_flag("major_truth_discovered", true)
	overlook._update_prompt()
	
	var prompt_ok: bool = overlook.prompt_message == "Observe the Horizon"
	overlook.queue_free()
	await process_frame
	
	if prompt_ok:
		report_result("Test 15: Prompt updates to 'Observe the Horizon' when truth is known", true)
	else:
		report_result("Test 15: Prompt updates to 'Observe the Horizon'", false,
			"prompt=%s" % overlook.prompt_message)

# TEST 16: Subsequent interaction does NOT replay dialogue
func test_16_subsequent_interaction_does_not_replay_dialogue() -> void:
	print("[TEST 16] Verifying subsequent interaction does NOT replay full dialogue...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	var sequence_started: bool = false
	scene_node.overlook.truth_sequence_started.connect(func():
		sequence_started = true
	)
	
	scene_node.overlook.interact(scene_node.player)
	await process_frame
	
	var dialogue_not_opened: bool = not scene_node.dialogue_ui.is_dialogue_active
	var sequence_not_fired: bool = not sequence_started
	
	scene_node.queue_free()
	await process_frame
	
	if dialogue_not_opened and sequence_not_fired:
		report_result("Test 16: Subsequent interaction shows repeat toast without replaying dialogue", true)
	else:
		report_result("Test 16: Subsequent interaction does not replay dialogue", false,
			"dialogue_not_opened=%s, sequence_not_fired=%s" % [dialogue_not_opened, sequence_not_fired])

# TEST 17: major_truth_discovered persists across scene reloads
func test_17_major_truth_discovered_persists_across_scene_reloads() -> void:
	print("[TEST 17] Verifying major_truth_discovered persists across Village and Seabed scene loads...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var in_village_truth: bool = StoryStateController.is_truth_known()
	village.queue_free()
	await process_frame
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var in_seabed_truth: bool = StoryStateController.is_truth_known()
	seabed.queue_free()
	await process_frame
	
	if in_village_truth and in_seabed_truth:
		report_result("Test 17: major_truth_discovered flag persists across world scene reloads", true)
	else:
		report_result("Test 17: major_truth_discovered flag persists across scene reloads", false,
			"in_village=%s, in_seabed=%s" % [in_village_truth, in_seabed_truth])

# TEST 18: Story progress calculation with major_truth_discovered
func test_18_story_progress_calculation_with_major_truth() -> void:
	print("[TEST 18] Verifying progress calculation reaches 100% (1.0) with major truth discovered...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("ocean_retreat_seen", true)
	StoryStateController.set_story_flag("shell_sign_seen", true)
	StoryStateController.set_story_flag("tide_pool_sign_seen", true)
	StoryStateController.set_story_flag("birds_sign_seen", true)
	# investigation_started auto-set by 3 signs
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var progress: float = StoryStateController.get_story_progress()
	var progress_100: bool = is_equal_approx(progress, 1.0)
	
	if progress_100:
		report_result("Test 18: Story progress calculates to 100% (1.0) with all major flags", true)
	else:
		report_result("Test 18: Story progress calculates to 100%", false,
			"progress=%f" % progress)

# TEST 19: Player movement locked during dialogue
func test_19_player_movement_locked_during_dialogue() -> void:
	print("[TEST 19] Verifying player movement is locked and velocity forced to zero during dialogue...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node.player.velocity = Vector2(80, 0)
	scene_node.overlook.interact(scene_node.player)
	await process_frame
	
	var locked_ok: bool = scene_node.player.is_movement_locked == true
	var vel_ok: bool = scene_node.player.velocity == Vector2.ZERO
	
	scene_node.queue_free()
	await process_frame
	
	if locked_ok and vel_ok:
		report_result("Test 19: Player movement is locked and velocity forced to zero during dialogue", true)
	else:
		report_result("Test 19: Player movement locked during dialogue", false,
			"locked_ok=%s, vel_ok=%s" % [locked_ok, vel_ok])

# TEST 20: Player movement unlocked after dialogue
func test_20_player_movement_unlocked_after_dialogue() -> void:
	print("[TEST 20] Verifying player movement is cleanly unlocked after dialogue finishes...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var test_scene: PackedScene = load("res://scenes/test/major_truth_discovery_test.tscn")
	var scene_node: MajorTruthDiscoveryTestScene = test_scene.instantiate() as MajorTruthDiscoveryTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node.overlook.interact(scene_node.player)
	await process_frame
	
	while scene_node.dialogue_ui.is_dialogue_active:
		scene_node.dialogue_ui.advance_dialogue()
		await process_frame
	
	# Wait one frame for deferred player unlock
	await process_frame
	
	var unlocked_ok: bool = scene_node.player.is_movement_locked == false
	
	scene_node.queue_free()
	await process_frame
	
	if unlocked_ok:
		report_result("Test 20: Player movement cleanly unlocks after dialogue sequence finishes", true)
	else:
		report_result("Test 20: Player movement unlocked after dialogue", false,
			"unlocked_ok=%s" % unlocked_ok)

# TEST 21: OceanState remains independent
func test_21_ocean_state_remains_independent() -> void:
	print("[TEST 21] Verifying OceanState operations maintain strict independence from StoryState...")
	OceanStateController.reset_ocean_state()
	StoryStateController.reset_story_state()
	
	var ocean_retreated_init: bool = OceanStateController.is_ocean_retreated()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	var ocean_retreated_after_truth: bool = OceanStateController.is_ocean_retreated()
	
	OceanStateController.trigger_ocean_retreat()
	var truth_after_retreat: bool = StoryStateController.is_truth_known()
	
	var ok: bool = (not ocean_retreated_init) and (not ocean_retreated_after_truth) and truth_after_retreat
	
	if ok:
		report_result("Test 21: OceanState and StoryState remain decoupled and independent", true)
	else:
		report_result("Test 21: OceanState remains independent", false,
			"init=%s, after_truth=%s, truth_after_retreat=%s" % [ocean_retreated_init, ocean_retreated_after_truth, truth_after_retreat])

# TEST 22: Milestone 8 environmental signs regression
func test_22_milestone_8_environmental_signs_regression() -> void:
	print("[TEST 22] Verifying Milestone 8 environmental signs (Shells, TidePools, Birds, Tremor, Wind)...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var shell: SeabedShell = seabed.get_node_or_null("StrangeSigns/ShellTidePools") as SeabedShell
	var pools: TidePoolSign = seabed.get_node_or_null("TidePools") as TidePoolSign
	var tremor: SeabedTremorSign = seabed.get_node_or_null("StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	
	var all_signs_ok: bool = shell != null and shell.is_interactable and pools != null and pools.is_drained and tremor != null and tremor.is_active
	
	seabed.queue_free()
	await process_frame
	
	if all_signs_ok:
		report_result("Test 22: Milestone 8 environmental signs operate without regression", true)
	else:
		report_result("Test 22: Milestone 8 environmental signs regression", false,
			"all_signs_ok=%s" % all_signs_ok)

# TEST 23: Milestone 11 ShipwreckInvestigation regression
func test_23_milestone_11_shipwreck_investigation_regression() -> void:
	print("[TEST 23] Verifying Milestone 11 ShipwreckInvestigation still functions...")
	StoryStateController.reset_story_state()
	var wreck_inv := ShipwreckInvestigation.new()
	root.add_child(wreck_inv)
	await process_frame
	
	var initial_prompt_ok: bool = wreck_inv.prompt_message == "Examine Wreckage"
	StoryStateController.set_story_flag("investigation_started", true)
	wreck_inv._update_prompt()
	var inv_prompt_ok: bool = wreck_inv.prompt_message == "Search Captain's Quarters"
	
	wreck_inv.queue_free()
	await process_frame
	
	if initial_prompt_ok and inv_prompt_ok:
		report_result("Test 23: Milestone 11 ShipwreckInvestigation operates without regression", true)
	else:
		report_result("Test 23: Milestone 11 ShipwreckInvestigation regression", false,
			"init=%s, inv=%s" % [initial_prompt_ok, inv_prompt_ok])

# TEST 24: Milestone 9 DialogueUI standalone functionality
func test_24_milestone_9_dialogue_ui_regression() -> void:
	print("[TEST 24] Verifying Milestone 9 DialogueUI operates cleanly...")
	var dialogue_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = dialogue_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var signal_data: Dictionary = {"started": false, "ended": false}
	ui.dialogue_started.connect(func(): signal_data["started"] = true)
	ui.dialogue_ended.connect(func(): signal_data["ended"] = true)
	
	ui.start_dialogue([{"speaker": "Narrator", "text": "Testing dialogue regression"}])
	await process_frame
	
	var active_ok: bool = ui.is_active() and signal_data["started"]
	ui.advance_dialogue()
	await process_frame
	
	var ended_ok: bool = (not ui.is_active()) and signal_data["ended"]
	
	ui.queue_free()
	await process_frame
	
	if active_ok and ended_ok:
		report_result("Test 24: Milestone 9 DialogueUI standalone regression passes", true)
	else:
		report_result("Test 24: Milestone 9 DialogueUI regression", false,
			"active_ok=%s, ended_ok=%s" % [active_ok, ended_ok])

# TEST 25: Main scene instantiates cleanly
func test_25_main_scene_instantiates_cleanly() -> void:
	print("[TEST 25] Verifying main scene (scenes/main.tscn) instantiates cleanly...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate() as Node2D
	root.add_child(main_node)
	await process_frame
	
	var main_ok: bool = main_node != null and main_node is Node2D
	
	main_node.queue_free()
	await process_frame
	
	if main_ok:
		report_result("Test 25: Main scene (scenes/main.tscn) instantiates cleanly as valid Node2D", true)
	else:
		report_result("Test 25: Main scene instantiation", false, "main_node is null")
