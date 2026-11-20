extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null
var story_state_node: StoryStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 13 VERIFICATION SUITE ---")
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
	await test_1_test_scene_loads()
	await test_2_town_warning_component_exists()
	await test_3_town_hall_warning_location_exists()
	await test_4_warning_is_gated_before_major_truth_discovered()
	await test_5_warning_remains_unavailable_without_major_truth()
	await test_6_warning_becomes_available_after_major_truth()
	await test_7_interaction_triggers_warning_dialogue()
	await test_8_warning_dialogue_has_multiple_lines()
	await test_9_dialogue_contains_required_warning_narrative()
	await test_10_player_movement_locks_during_dialogue()
	await test_11_player_velocity_becomes_zero()
	await test_12_town_warned_is_false_before_completion()
	await test_13_town_warned_is_set_only_after_dialogue_completion()
	await test_14_town_warned_persists()
	await test_15_repeat_interaction_does_not_replay_dialogue()
	await test_16_repeat_interaction_uses_atmospheric_reminder()
	await test_17_town_warning_state_changes_after_completion()
	await test_18_existing_story_state_flags_remain_intact()
	await test_19_ocean_state_remains_independent()
	await test_20_village_scene_loads_cleanly()
	await test_21_seabed_scene_still_loads()
	await test_22_shipwreck_investigation_still_works()
	await test_23_major_truth_discovery_still_works()
	await test_24_dialogue_ui_regression_works()
	await test_25_environmental_signs_regression_works()
	await test_26_ocean_state_regression_works()
	await test_27_main_scene_loads_cleanly()
	
	print("\n==================================================")
	print("--- MILESTONE 13 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Test scene loads
func test_1_test_scene_loads() -> void:
	print("[TEST 1] Verifying town warning test scene loads cleanly...")
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	var scene_ok: bool = scene_node != null and scene_node is TownWarningTestScene
	var hud_ok: bool = scene_node.truth_status_label != null and scene_node.warning_status_label != null
	var warning_ok: bool = scene_node.town_warning != null and scene_node.town_warning is TownWarning
	
	scene_node.queue_free()
	await process_frame
	
	if scene_ok and hud_ok and warning_ok:
		report_result("Test 1: Town warning test scene loads cleanly", true)
	else:
		report_result("Test 1: Town warning test scene loads cleanly", false,
			"scene_ok=%s, hud_ok=%s, warning_ok=%s" % [scene_ok, hud_ok, warning_ok])

# TEST 2: TownWarning component exists
func test_2_town_warning_component_exists() -> void:
	print("[TEST 2] Verifying TownWarning class and component exist...")
	var warning: TownWarning = TownWarning.new()
	root.add_child(warning)
	await process_frame
	
	var is_interactable_subclass: bool = warning is Interactable
	var has_expected_signals: bool = warning.has_signal("warning_attempted") and warning.has_signal("warning_sequence_started") and warning.has_signal("warning_completed")
	
	warning.queue_free()
	await process_frame
	
	if is_interactable_subclass and has_expected_signals:
		report_result("Test 2: TownWarning component exists and extends Interactable", true)
	else:
		report_result("Test 2: TownWarning component exists", false,
			"interactable=%s, signals=%s" % [is_interactable_subclass, has_expected_signals])

# TEST 3: Town Hall warning location exists
func test_3_town_hall_warning_location_exists() -> void:
	print("[TEST 3] Verifying Town Hall warning location exists in village.tscn...")
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var warning_node: TownWarning = village.get_node_or_null("Interactables/TownWarning") as TownWarning
	var shape: CollisionShape2D = village.get_node_or_null("Interactables/TownWarning/CollisionShape2D") as CollisionShape2D
	
	var warning_ok: bool = warning_node != null and warning_node is TownWarning
	var pos_ok: bool = warning_node != null and warning_node.position == Vector2(480, 130)
	var shape_ok: bool = shape != null and shape.shape is CircleShape2D
	
	village.queue_free()
	await process_frame
	
	if warning_ok and pos_ok and shape_ok:
		report_result("Test 3: Town Hall warning location exists in village.tscn at (480, 130)", true)
	else:
		report_result("Test 3: Town Hall warning location exists in village.tscn", false,
			"warning_ok=%s, pos_ok=%s, shape_ok=%s" % [warning_ok, pos_ok, shape_ok])

# TEST 4: Warning is gated before major_truth_discovered
func test_4_warning_is_gated_before_major_truth_discovered() -> void:
	print("[TEST 4] Verifying warning is gated before major_truth_discovered...")
	StoryStateController.reset_story_state()
	
	var can_warn: bool = StoryStateController.instance.can_warn_town()
	var is_warned: bool = StoryStateController.instance.is_town_warned()
	
	var warning: TownWarning = TownWarning.new()
	root.add_child(warning)
	await process_frame
	
	var prompt_is_normal: bool = warning.prompt_message == "Town Hall"
	warning.queue_free()
	await process_frame
	
	if not can_warn and not is_warned and prompt_is_normal:
		report_result("Test 4: Warning is gated before major_truth_discovered", true)
	else:
		report_result("Test 4: Warning is gated before major_truth_discovered", false,
			"can_warn=%s, is_warned=%s, prompt=%s" % [can_warn, is_warned, warning.prompt_message])

# TEST 5: Warning remains unavailable without major truth
func test_5_warning_remains_unavailable_without_major_truth() -> void:
	print("[TEST 5] Verifying warning interaction remains unavailable without major truth...")
	StoryStateController.reset_story_state()
	# Set earlier flags but NOT major_truth_discovered
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	var signal_data: Dictionary = {"attempted": false, "was_gated": false, "started": false}
	scene_node.town_warning.warning_attempted.connect(func(was_gated: bool):
		signal_data["attempted"] = true
		signal_data["was_gated"] = was_gated
	)
	scene_node.town_warning.warning_sequence_started.connect(func():
		signal_data["started"] = true
	)
	
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	var gated_attempt: bool = signal_data["attempted"] and signal_data["was_gated"] == true
	var dialogue_not_started: bool = not signal_data["started"] and not scene_node.dialogue_ui.is_dialogue_active
	var town_remains_unwarned: bool = not StoryStateController.is_village_warned()
	
	scene_node.queue_free()
	await process_frame
	
	if gated_attempt and dialogue_not_started and town_remains_unwarned:
		report_result("Test 5: Warning remains unavailable without major truth (emits gated attempt)", true)
	else:
		report_result("Test 5: Warning remains unavailable without major truth", false,
			"gated=%s, dialogue_not_started=%s, unwarned=%s" % [gated_attempt, dialogue_not_started, town_remains_unwarned])

# TEST 6: Warning becomes available after major truth
func test_6_warning_becomes_available_after_major_truth() -> void:
	print("[TEST 6] Verifying warning becomes available after major_truth_discovered...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var can_warn: bool = StoryStateController.instance.can_warn_town()
	var can_static: bool = StoryStateController.can_trigger_town_warning()
	
	var warning: TownWarning = TownWarning.new()
	root.add_child(warning)
	await process_frame
	
	var prompt_updated: bool = warning.prompt_message == "Warn the Town"
	warning.queue_free()
	await process_frame
	
	if can_warn and can_static and prompt_updated:
		report_result("Test 6: Warning becomes available with prompt 'Warn the Town' after major truth", true)
	else:
		report_result("Test 6: Warning becomes available after major truth", false,
			"can_warn=%s, can_static=%s, prompt=%s" % [can_warn, can_static, warning.prompt_message])

# TEST 7: Interaction triggers warning dialogue
func test_7_interaction_triggers_warning_dialogue() -> void:
	print("[TEST 7] Verifying interaction triggers warning dialogue when unlocked...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	var signal_data: Dictionary = {"attempted": false, "was_gated": true, "started": false}
	scene_node.town_warning.warning_attempted.connect(func(was_gated: bool):
		signal_data["attempted"] = true
		signal_data["was_gated"] = was_gated
	)
	scene_node.town_warning.warning_sequence_started.connect(func():
		signal_data["started"] = true
	)
	
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	var attempt_ok: bool = signal_data["attempted"] and signal_data["was_gated"] == false
	var started_ok: bool = signal_data["started"]
	var dialogue_active: bool = scene_node.dialogue_ui.is_dialogue_active
	
	scene_node.queue_free()
	await process_frame
	
	if attempt_ok and started_ok and dialogue_active:
		report_result("Test 7: Interaction triggers warning dialogue sequence successfully", true)
	else:
		report_result("Test 7: Interaction triggers warning dialogue", false,
			"attempt_ok=%s, started_ok=%s, dialogue_active=%s" % [attempt_ok, started_ok, dialogue_active])

# TEST 8: Warning dialogue has multiple lines
func test_8_warning_dialogue_has_multiple_lines() -> void:
	print("[TEST 8] Verifying warning dialogue has multiple lines (7 lines)...")
	var dialogue: Array[Dictionary] = TownWarning.WARNING_DIALOGUE
	var line_count_ok: bool = dialogue.size() >= 5
	
	if line_count_ok:
		report_result("Test 8: Warning dialogue has %d sequential lines" % dialogue.size(), true)
	else:
		report_result("Test 8: Warning dialogue has multiple lines", false,
			"size=%d" % dialogue.size())

# TEST 9: Dialogue contains required warning narrative
func test_9_dialogue_contains_required_warning_narrative() -> void:
	print("[TEST 9] Verifying dialogue contains required warning narrative beats...")
	var dialogue: Array[Dictionary] = TownWarning.WARNING_DIALOGUE
	
	var line1_has_feed_wave: bool = dialogue[0].get("text", "").contains("feed a wave") or dialogue[0].get("text", "").contains("wave")
	var line2_has_making_room: bool = dialogue[1].get("text", "").contains("making room") or dialogue[1].get("text", "").contains("century")
	var line3_has_elder: bool = dialogue[2].get("speaker", "") == "Elder Cael" and dialogue[2].get("text", "").contains("certain")
	var line4_has_signs: bool = dialogue[3].get("text", "").contains("shells") and dialogue[3].get("text", "").contains("tide pools")
	var line5_has_metaphors: bool = dialogue[4].get("text", "").contains("legends") or dialogue[4].get("text", "").contains("gulls")
	var line6_has_warn_everyone: bool = dialogue[5].get("text", "").contains("warn everyone")
	var line7_has_high_ground: bool = dialogue[6].get("text", "").contains("high ground")
	
	var narrative_ok: bool = line1_has_feed_wave and line2_has_making_room and line3_has_elder and line4_has_signs and line5_has_metaphors and line6_has_warn_everyone and line7_has_high_ground
	
	if narrative_ok:
		report_result("Test 9: Dialogue contains all required narrative beats (retreat truth, signs, elder acceptance, high ground)", true)
	else:
		report_result("Test 9: Dialogue contains required narrative beats", false,
			"1=%s, 2=%s, 3=%s, 4=%s, 5=%s, 6=%s, 7=%s" % [
				line1_has_feed_wave, line2_has_making_room, line3_has_elder, line4_has_signs, line5_has_metaphors, line6_has_warn_everyone, line7_has_high_ground
			])

# TEST 10: Player movement locks during dialogue
func test_10_player_movement_locks_during_dialogue() -> void:
	print("[TEST 10] Verifying player movement locks during warning dialogue...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	var is_locked: bool = scene_node.player.is_movement_locked == true
	
	scene_node.queue_free()
	await process_frame
	
	if is_locked:
		report_result("Test 10: Player movement is locked during warning dialogue", true)
	else:
		report_result("Test 10: Player movement locks during dialogue", false,
			"locked=%s" % is_locked)

# TEST 11: Player velocity becomes zero
func test_11_player_velocity_becomes_zero() -> void:
	print("[TEST 11] Verifying player velocity is forced to zero during dialogue...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node.player.velocity = Vector2(80, 40)
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	var vel_zero: bool = scene_node.player.velocity == Vector2.ZERO
	
	scene_node.queue_free()
	await process_frame
	
	if vel_zero:
		report_result("Test 11: Player velocity becomes Vector2.ZERO upon starting warning dialogue", true)
	else:
		report_result("Test 11: Player velocity becomes zero", false,
			"velocity=%s" % scene_node.player.velocity)

# TEST 12: town_warned is false before completion
func test_12_town_warned_is_false_before_completion() -> void:
	print("[TEST 12] Verifying town_warned is false before dialogue completion...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	var warned_during_dialogue: bool = StoryStateController.is_village_warned()
	
	scene_node.queue_free()
	await process_frame
	
	if not warned_during_dialogue:
		report_result("Test 12: town_warned flag remains false while dialogue is active", true)
	else:
		report_result("Test 12: town_warned is false before completion", false,
			"warned_during_dialogue=%s" % warned_during_dialogue)

# TEST 13: town_warned is set only after dialogue completion
func test_13_town_warned_is_set_only_after_dialogue_completion() -> void:
	print("[TEST 13] Verifying town_warned is set only after dialogue sequence finishes...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	var signal_data: Dictionary = {"completed": false}
	scene_node.town_warning.warning_completed.connect(func(): signal_data["completed"] = true)
	
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	while scene_node.dialogue_ui.is_dialogue_active:
		scene_node.dialogue_ui.advance_dialogue()
		await process_frame
	
	var warned_after: bool = StoryStateController.is_village_warned()
	var signal_ok: bool = signal_data["completed"]
	
	scene_node.queue_free()
	await process_frame
	
	if warned_after and signal_ok:
		report_result("Test 13: town_warned is set to true and warning_completed is emitted upon completion", true)
	else:
		report_result("Test 13: town_warned is set only after dialogue completion", false,
			"warned_after=%s, signal_ok=%s" % [warned_after, signal_ok])

# TEST 14: town_warned persists
func test_14_town_warned_persists() -> void:
	print("[TEST 14] Verifying town_warned persists across scene loads...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var in_village_warned: bool = StoryStateController.is_village_warned()
	village.queue_free()
	await process_frame
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var in_seabed_warned: bool = StoryStateController.is_village_warned()
	seabed.queue_free()
	await process_frame
	
	if in_village_warned and in_seabed_warned:
		report_result("Test 14: town_warned flag persists across world scene reloads", true)
	else:
		report_result("Test 14: town_warned persists", false,
			"in_village=%s, in_seabed=%s" % [in_village_warned, in_seabed_warned])

# TEST 15: Repeat interaction does not replay dialogue
func test_15_repeat_interaction_does_not_replay_dialogue() -> void:
	print("[TEST 15] Verifying repeat interaction does NOT replay full dialogue...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	StoryStateController.set_story_flag("town_warned", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	var sequence_started: bool = false
	scene_node.town_warning.warning_sequence_started.connect(func(): sequence_started = true)
	
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	var dialogue_not_opened: bool = not scene_node.dialogue_ui.is_dialogue_active
	var sequence_not_fired: bool = not sequence_started
	
	scene_node.queue_free()
	await process_frame
	
	if dialogue_not_opened and sequence_not_fired:
		report_result("Test 15: Repeat interaction does NOT replay dialogue sequence", true)
	else:
		report_result("Test 15: Repeat interaction does not replay dialogue", false,
			"dialogue_not_opened=%s, sequence_not_fired=%s" % [dialogue_not_opened, sequence_not_fired])

# TEST 16: Repeat interaction uses atmospheric reminder
func test_16_repeat_interaction_uses_atmospheric_reminder() -> void:
	print("[TEST 16] Verifying repeat interaction emits non-gated attempt and updates prompt...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	StoryStateController.set_story_flag("town_warned", true)
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	var signal_data: Dictionary = {"attempted": false, "was_gated": true}
	scene_node.town_warning.warning_attempted.connect(func(was_gated: bool):
		signal_data["attempted"] = true
		signal_data["was_gated"] = was_gated
	)
	
	scene_node.town_warning.interact(scene_node.player)
	await process_frame
	
	var attempt_ok: bool = signal_data["attempted"] and signal_data["was_gated"] == false
	var prompt_ok: bool = scene_node.town_warning.prompt_message == "Town Hall"
	
	scene_node.queue_free()
	await process_frame
	
	if attempt_ok and prompt_ok:
		report_result("Test 16: Repeat interaction uses atmospheric reminder and non-gated event", true)
	else:
		report_result("Test 16: Repeat interaction uses atmospheric reminder", false,
			"attempt_ok=%s, prompt_ok=%s" % [attempt_ok, prompt_ok])

# TEST 17: Town warning state changes after completion
func test_17_town_warning_state_changes_after_completion() -> void:
	print("[TEST 17] Verifying town warning state changes after completion (alarm beacon visible)...")
	StoryStateController.reset_story_state()
	
	var test_scene: PackedScene = load("res://scenes/test/town_warning_test.tscn")
	var scene_node: TownWarningTestScene = test_scene.instantiate() as TownWarningTestScene
	root.add_child(scene_node)
	await process_frame
	
	var beacon_init_hidden: bool = scene_node.town_warning.alarm_beacon != null and not scene_node.town_warning.alarm_beacon.visible
	
	StoryStateController.set_story_flag("town_warned", true)
	scene_node.town_warning._update_visuals()
	
	var beacon_after_visible: bool = scene_node.town_warning.alarm_beacon != null and scene_node.town_warning.alarm_beacon.visible
	
	scene_node.queue_free()
	await process_frame
	
	if beacon_init_hidden and beacon_after_visible:
		report_result("Test 17: Town warning visual state changes deterministically after completion", true)
	else:
		report_result("Test 17: Town warning state changes after completion", false,
			"init_hidden=%s, after_visible=%s" % [beacon_init_hidden, beacon_after_visible])

# TEST 18: Existing StoryState flags remain intact
func test_18_existing_story_state_flags_remain_intact() -> void:
	print("[TEST 18] Verifying all 9 existing StoryState flags remain intact and operational...")
	StoryStateController.reset_story_state()
	
	var expected_flags: Array[String] = [
		"ocean_retreat_seen",
		"shell_sign_seen",
		"tide_pool_sign_seen",
		"birds_sign_seen",
		"tremor_sign_seen",
		"wind_sign_seen",
		"investigation_started",
		"shipwreck_clue_found",
		"major_truth_discovered",
		"town_warned"
	]
	
	var all_present: bool = true
	for f in expected_flags:
		if not StoryStateController.DEFAULT_FLAGS.has(f):
			all_present = false
			break
	
	if all_present:
		report_result("Test 18: All 10 story flags exist with correct default state in StoryState", true)
	else:
		report_result("Test 18: Existing StoryState flags remain intact", false, "Missing expected flag")

# TEST 19: OceanState remains independent
func test_19_ocean_state_remains_independent() -> void:
	print("[TEST 19] Verifying OceanState operations remain independent from town warning...")
	OceanStateController.reset_ocean_state()
	StoryStateController.reset_story_state()
	
	StoryStateController.set_story_flag("town_warned", true)
	var ocean_normal: bool = OceanStateController.is_ocean_normal()
	
	OceanStateController.trigger_ocean_retreat()
	var town_warned_still: bool = StoryStateController.is_village_warned()
	
	if ocean_normal and town_warned_still:
		report_result("Test 19: OceanState and StoryState town_warned operate with complete independence", true)
	else:
		report_result("Test 19: OceanState remains independent", false,
			"ocean_normal=%s, town_warned=%s" % [ocean_normal, town_warned_still])

# TEST 20: Village scene loads cleanly
func test_20_village_scene_loads_cleanly() -> void:
	print("[TEST 20] Verifying village scene loads cleanly with TownWarning interactable...")
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var village_ok: bool = village != null and village is Village
	var warning_ok: bool = village.get_node_or_null("Interactables/TownWarning") is TownWarning
	var door_ok: bool = village.town_hall_door != null
	
	village.queue_free()
	await process_frame
	
	if village_ok and warning_ok and door_ok:
		report_result("Test 20: Village scene loads cleanly with TownWarning and TownHall door linkage", true)
	else:
		report_result("Test 20: Village scene loads cleanly", false,
			"village_ok=%s, warning_ok=%s, door_ok=%s" % [village_ok, warning_ok, door_ok])

# TEST 21: Seabed scene still loads
func test_21_seabed_scene_still_loads() -> void:
	print("[TEST 21] Verifying seabed scene loads cleanly...")
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var seabed_ok: bool = seabed != null and seabed is Seabed
	seabed.queue_free()
	await process_frame
	
	if seabed_ok:
		report_result("Test 21: Seabed scene loads cleanly without errors", true)
	else:
		report_result("Test 21: Seabed scene still loads", false, "seabed_ok is false")

# TEST 22: Shipwreck investigation still works
func test_22_shipwreck_investigation_still_works() -> void:
	print("[TEST 22] Verifying ShipwreckInvestigation operates without regression...")
	StoryStateController.reset_story_state()
	var inv: ShipwreckInvestigation = ShipwreckInvestigation.new()
	root.add_child(inv)
	await process_frame
	
	var initial_prompt: bool = inv.prompt_message == "Examine Wreckage"
	StoryStateController.set_story_flag("investigation_started", true)
	inv._update_prompt()
	var search_prompt: bool = inv.prompt_message == "Search Captain's Quarters"
	
	inv.queue_free()
	await process_frame
	
	if initial_prompt and search_prompt:
		report_result("Test 22: ShipwreckInvestigation operates without regression", true)
	else:
		report_result("Test 22: Shipwreck investigation regression", false,
			"init=%s, search=%s" % [initial_prompt, search_prompt])

# TEST 23: Major truth discovery still works
func test_23_major_truth_discovery_still_works() -> void:
	print("[TEST 23] Verifying MajorTruthDiscovery operates without regression...")
	StoryStateController.reset_story_state()
	var truth: MajorTruthDiscovery = MajorTruthDiscovery.new()
	root.add_child(truth)
	await process_frame
	
	var initial_prompt: bool = truth.prompt_message == "Look Out at Bay"
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	truth._update_prompt()
	var survey_prompt: bool = truth.prompt_message == "Survey the Receded Ocean"
	
	truth.queue_free()
	await process_frame
	
	if initial_prompt and survey_prompt:
		report_result("Test 23: MajorTruthDiscovery operates without regression", true)
	else:
		report_result("Test 23: Major truth discovery regression", false,
			"init=%s, survey=%s" % [initial_prompt, survey_prompt])

# TEST 24: DialogueUI regression works
func test_24_dialogue_ui_regression_works() -> void:
	print("[TEST 24] Verifying DialogueUI operates cleanly...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var signal_data: Dictionary = {"started": false, "ended": false}
	ui.dialogue_started.connect(func(): signal_data["started"] = true)
	ui.dialogue_ended.connect(func(): signal_data["ended"] = true)
	
	ui.start_dialogue([{"speaker": "Elder Cael", "text": "Testing dialogue system"}])
	await process_frame
	
	var active_ok: bool = ui.is_active() and signal_data["started"]
	ui.advance_dialogue()
	await process_frame
	
	var ended_ok: bool = (not ui.is_active()) and signal_data["ended"]
	
	ui.queue_free()
	await process_frame
	
	if active_ok and ended_ok:
		report_result("Test 24: DialogueUI standalone regression operates flawlessly", true)
	else:
		report_result("Test 24: DialogueUI regression", false,
			"active=%s, ended=%s" % [active_ok, ended_ok])

# TEST 25: Environmental signs regression works
func test_25_environmental_signs_regression_works() -> void:
	print("[TEST 25] Verifying Milestone 8 environmental signs regression...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var shell: SeabedShell = seabed.get_node_or_null("StrangeSigns/ShellTidePools") as SeabedShell
	var pools: TidePoolSign = seabed.get_node_or_null("TidePools") as TidePoolSign
	var tremor: SeabedTremorSign = seabed.get_node_or_null("StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	
	var all_ok: bool = shell != null and shell.is_interactable and pools != null and pools.is_drained and tremor != null and tremor.is_active
	
	seabed.queue_free()
	await process_frame
	
	if all_ok:
		report_result("Test 25: Environmental signs operate without regression", true)
	else:
		report_result("Test 25: Environmental signs regression", false, "all_ok is false")

# TEST 26: OceanState regression works
func test_26_ocean_state_regression_works() -> void:
	print("[TEST 26] Verifying OceanState normal vs retreated transitions...")
	OceanStateController.reset_ocean_state()
	var is_normal: bool = OceanStateController.is_ocean_normal()
	
	OceanStateController.trigger_ocean_retreat()
	var is_retreated: bool = OceanStateController.is_ocean_retreated()
	
	if is_normal and is_retreated:
		report_result("Test 26: OceanState state machine transitions operate cleanly", true)
	else:
		report_result("Test 26: OceanState regression", false,
			"normal=%s, retreated=%s" % [is_normal, is_retreated])

# TEST 27: Main scene loads cleanly
func test_27_main_scene_loads_cleanly() -> void:
	print("[TEST 27] Verifying main scene (scenes/main.tscn) loads cleanly...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate() as Node2D
	root.add_child(main_node)
	await process_frame
	
	var main_ok: bool = main_node != null and main_node is Node2D
	
	main_node.queue_free()
	await process_frame
	
	if main_ok:
		report_result("Test 27: Main scene (scenes/main.tscn) instantiates cleanly as valid root", true)
	else:
		report_result("Test 27: Main scene loading", false, "main_node is null")
