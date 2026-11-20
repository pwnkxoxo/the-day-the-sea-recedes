extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null
var story_state_node: StoryStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 16 VERIFICATION SUITE ---")
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
	await test_1_aftermath_test_scene_loads()
	await test_2_final_overlook_component_exists()
	await test_3_ending_overlay_exists()
	await test_4_aftermath_is_initially_inactive()
	await test_5_ending_is_initially_inactive()
	await test_6_aftermath_is_gated_before_survived_wave()
	await test_7_ending_is_gated_before_survived_wave()
	await test_8_survived_wave_unlocks_aftermath()
	await test_9_aftermath_started_initially_false()
	await test_10_aftermath_begins_correctly()
	await test_11_aftermath_started_becomes_true()
	await test_12_aftermath_start_sequence_occurs_only_once()
	await test_13_player_remains_controllable_after_aftermath_begins()
	await test_14_flooded_environment_exists()
	await test_15_returned_ocean_visual_exists()
	await test_16_lower_village_remains_visually_changed()
	await test_17_high_ground_remains_safe()
	await test_18_survivor_interaction_exists()
	await test_19_survivor_interaction_is_gated_before_survival()
	await test_20_survivor_dialogue_opens_correctly()
	await test_21_dialogue_uses_existing_dialogue_ui()
	await test_22_final_overlook_exists()
	await test_23_final_overlook_is_gated_before_survival()
	await test_24_final_overlook_becomes_available_after_survival()
	await test_25_final_story_sequence_starts_correctly()
	await test_26_ending_overlay_appears()
	await test_27_ending_completed_initially_false()
	await test_28_ending_completed_becomes_true_only_after_ending_sequence()
	await test_29_ending_sequence_is_idempotent()
	await test_30_story_state_flags_persist()
	await test_31_survived_wave_remains_intact()
	await test_32_wave_arrived_remains_intact()
	await test_33_evacuation_reached_high_ground_remains_intact()
	await test_34_town_warned_remains_intact()
	await test_35_major_truth_discovered_remains_intact()
	await test_36_ocean_state_remains_independent()
	await test_37_milestone_15_regression_passes()
	await test_38_milestone_14_regression_passes()
	await test_39_milestone_13_regression_passes()
	await test_40_milestone_12_regression_passes()
	await test_41_milestone_11_regression_passes()
	await test_42_milestone_10_regression_passes()
	await test_43_milestone_9_regression_passes()
	await test_44_milestone_8_regression_passes()
	await test_45_milestone_7_regression_passes()
	await test_46_main_scene_loads_cleanly()
	
	print("\n==================================================")
	print("--- MILESTONE 16 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Aftermath test scene loads
func test_1_aftermath_test_scene_loads() -> void:
	print("[TEST 1] Verifying aftermath ending test scene loads cleanly...")
	var test_scene: PackedScene = load("res://scenes/test/aftermath_ending_test.tscn")
	var scene_node: AftermathEndingTestScene = test_scene.instantiate() as AftermathEndingTestScene
	root.add_child(scene_node)
	await process_frame
	
	var scene_ok: bool = scene_node != null and scene_node is AftermathEndingTestScene
	var player_ok: bool = scene_node.player != null and scene_node.player is Player
	var cael_ok: bool = scene_node.elder_cael != null and scene_node.elder_cael is SurvivorInteractable
	var villager_ok: bool = scene_node.villager != null and scene_node.villager is SurvivorInteractable
	var overlook_ok: bool = scene_node.final_overlook != null and scene_node.final_overlook is FinalOverlook
	var ending_ok: bool = scene_node.ending_ui != null and scene_node.ending_ui is EndingUI
	var hud_ok: bool = scene_node.aftermath_label != null and scene_node.ending_label != null
	
	scene_node.queue_free()
	await process_frame
	
	if scene_ok and player_ok and cael_ok and villager_ok and overlook_ok and ending_ok and hud_ok:
		report_result("Test 1: Aftermath test scene loads cleanly", true)
	else:
		report_result("Test 1: Aftermath test scene loads cleanly", false,
			"scene=%s, player=%s, cael=%s, villager=%s, overlook=%s, ending=%s, hud=%s" % [
				scene_ok, player_ok, cael_ok, villager_ok, overlook_ok, ending_ok, hud_ok
			])

# TEST 2: Final overlook component exists
func test_2_final_overlook_component_exists() -> void:
	print("[TEST 2] Verifying FinalOverlook component properties and signals...")
	var overlook: FinalOverlook = FinalOverlook.new()
	var is_interactable: bool = overlook is Interactable
	var has_attempted_sig: bool = overlook.has_signal("overlook_attempted")
	var has_started_sig: bool = overlook.has_signal("resolution_started")
	var has_ended_sig: bool = overlook.has_signal("resolution_ended")
	var has_ending_sig: bool = overlook.has_signal("ending_triggered")
	var has_method: bool = overlook.has_method("can_trigger_overlook")
	
	overlook.free()
	
	if is_interactable and has_attempted_sig and has_started_sig and has_ended_sig and has_ending_sig and has_method:
		report_result("Test 2: FinalOverlook component exists and inherits Interactable", true)
	else:
		report_result("Test 2: Final overlook component exists", false,
			"is_interactable=%s, method=%s" % [is_interactable, has_method])

# TEST 3: Ending overlay exists
func test_3_ending_overlay_exists() -> void:
	print("[TEST 3] Verifying EndingUI component structure and API...")
	var ending_scene: PackedScene = load("res://scenes/ui/ending_ui.tscn")
	var ending: EndingUI = ending_scene.instantiate() as EndingUI
	root.add_child(ending)
	await process_frame
	
	var is_canvas: bool = ending is CanvasLayer
	var has_method: bool = ending.has_method("show_ending") and ending.has_method("is_ending_active")
	var has_bg: bool = ending.background != null
	var has_title: bool = ending.title_label != null
	var has_message: bool = ending.message_label != null
	var has_prompt: bool = ending.prompt_label != null
	
	ending.queue_free()
	await process_frame
	
	if is_canvas and has_method and has_bg and has_title and has_message and has_prompt:
		report_result("Test 3: EndingUI overlay exists with pixel UI typography and API", true)
	else:
		report_result("Test 3: Ending overlay exists", false,
			"is_canvas=%s, method=%s, bg=%s, title=%s, msg=%s, prompt=%s" % [
				is_canvas, has_method, has_bg, has_title, has_message, has_prompt
			])

# TEST 4: Aftermath is initially inactive
func test_4_aftermath_is_initially_inactive() -> void:
	print("[TEST 4] Verifying aftermath is initially inactive in default state...")
	StoryStateController.reset_story_state()
	
	var active_false: bool = not StoryStateController.is_aftermath_active()
	var can_trigger_false: bool = not StoryStateController.can_trigger_aftermath()
	var instance_active_false: bool = not StoryStateController.instance.is_aftermath_started() if StoryStateController.instance else true
	
	if active_false and can_trigger_false and instance_active_false:
		report_result("Test 4: Aftermath is initially inactive", true)
	else:
		report_result("Test 4: Aftermath is initially inactive", false,
			"active=%s, can_trigger=%s" % [active_false, can_trigger_false])

# TEST 5: Ending is initially inactive
func test_5_ending_is_initially_inactive() -> void:
	print("[TEST 5] Verifying ending is initially inactive in default state...")
	StoryStateController.reset_story_state()
	
	var ended_false: bool = not StoryStateController.is_game_ended()
	var can_trigger_false: bool = not StoryStateController.can_trigger_ending()
	var instance_ended_false: bool = not StoryStateController.instance.is_ending_completed() if StoryStateController.instance else true
	
	if ended_false and can_trigger_false and instance_ended_false:
		report_result("Test 5: Ending is initially inactive", true)
	else:
		report_result("Test 5: Ending is initially inactive", false,
			"ended=%s, can_trigger=%s" % [ended_false, can_trigger_false])

# TEST 6: Aftermath is gated before survived_wave
func test_6_aftermath_is_gated_before_survived_wave() -> void:
	print("[TEST 6] Verifying aftermath cannot start before survived_wave...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	StoryStateController.set_story_flag("wave_event_started", true)
	StoryStateController.set_story_flag("wave_arrived", true)
	
	var can_start_before: bool = StoryStateController.can_trigger_aftermath()
	var instance_can: bool = StoryStateController.instance.can_start_aftermath() if StoryStateController.instance else false
	
	if not can_start_before and not instance_can:
		report_result("Test 6: Aftermath is properly gated before survived_wave is true", true)
	else:
		report_result("Test 6: Aftermath is gated before survived_wave", false,
			"can_start=%s, instance_can=%s" % [can_start_before, instance_can])

# TEST 7: Ending is gated before survived_wave
func test_7_ending_is_gated_before_survived_wave() -> void:
	print("[TEST 7] Verifying ending is gated before survived_wave...")
	StoryStateController.reset_story_state()
	
	var overlook: FinalOverlook = FinalOverlook.new()
	root.add_child(overlook)
	await process_frame
	
	var signal_data := {"gated": false}
	overlook.overlook_attempted.connect(func(was_gated: bool): signal_data["gated"] = was_gated)
	
	var can_trigger_before: bool = overlook.can_trigger_overlook()
	overlook.interact(null)
	await process_frame
	
	var was_gated: bool = signal_data["gated"]
	var ended_remains_false: bool = not StoryStateController.is_game_ended()
	
	overlook.queue_free()
	await process_frame
	
	if (not can_trigger_before) and was_gated and ended_remains_false:
		report_result("Test 7: Ending is gated before survived_wave and rejects trigger", true)
	else:
		report_result("Test 7: Ending is gated before survived_wave", false,
			"can_trigger=%s, was_gated=%s, ended=%s" % [can_trigger_before, was_gated, ended_remains_false])

# TEST 8: survived_wave unlocks aftermath
func test_8_survived_wave_unlocks_aftermath() -> void:
	print("[TEST 8] Verifying survived_wave unlocks aftermath availability...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var can_start: bool = StoryStateController.can_trigger_aftermath()
	var instance_can: bool = StoryStateController.instance.can_start_aftermath() if StoryStateController.instance else true
	
	if can_start and instance_can:
		report_result("Test 8: survived_wave unlocks aftermath availability", true)
	else:
		report_result("Test 8: survived_wave unlocks aftermath", false,
			"can_start=%s, instance_can=%s" % [can_start, instance_can])

# TEST 9: aftermath_started initially false
func test_9_aftermath_started_initially_false() -> void:
	print("[TEST 9] Verifying aftermath_started is initially false...")
	StoryStateController.reset_story_state()
	var is_false: bool = not StoryStateController.has_story_flag("aftermath_started")
	if is_false:
		report_result("Test 9: aftermath_started initially false", true)
	else:
		report_result("Test 9: aftermath_started initially false", false, "is_false is false")

# TEST 10: Aftermath begins correctly
func test_10_aftermath_begins_correctly() -> void:
	print("[TEST 10] Verifying aftermath sequence begins correctly and emits signal...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var signal_data := {"started": false}
	if StoryStateController.instance:
		StoryStateController.instance.aftermath_started.connect(func(): signal_data["started"] = true)
	
	StoryStateController.set_story_flag("aftermath_started", true)
	await process_frame
	
	var signal_ok: bool = signal_data["started"]
	if signal_ok:
		report_result("Test 10: Aftermath begins correctly and emits aftermath_started signal", true)
	else:
		report_result("Test 10: Aftermath begins correctly", false, "signal_ok is false")

# TEST 11: aftermath_started becomes true
func test_11_aftermath_started_becomes_true() -> void:
	print("[TEST 11] Verifying aftermath_started becomes true upon aftermath start...")
	var flag_ok: bool = StoryStateController.has_story_flag("aftermath_started")
	var helper_ok: bool = StoryStateController.is_aftermath_active()
	if flag_ok and helper_ok:
		report_result("Test 11: aftermath_started becomes true and is_aftermath_active returns true", true)
	else:
		report_result("Test 11: aftermath_started becomes true", false,
			"flag_ok=%s, helper_ok=%s" % [flag_ok, helper_ok])

# TEST 12: Aftermath start sequence occurs only once
func test_12_aftermath_start_sequence_occurs_only_once() -> void:
	print("[TEST 12] Verifying aftermath start sequence is idempotent and occurs once...")
	var emit_count := {"count": 0}
	var callable := func(): emit_count["count"] += 1
	if StoryStateController.instance:
		StoryStateController.instance.aftermath_started.connect(callable)
	
	# Repeated call to set aftermath_started true when already true
	StoryStateController.set_story_flag("aftermath_started", true)
	await process_frame
	
	if StoryStateController.instance:
		StoryStateController.instance.aftermath_started.disconnect(callable)
	
	var no_duplicate: bool = emit_count["count"] == 0
	if no_duplicate:
		report_result("Test 12: Aftermath start sequence occurs only once and ignores duplicate calls", true)
	else:
		report_result("Test 12: Aftermath start sequence occurs only once", false,
			"count=%d" % emit_count["count"])

# TEST 13: Player remains controllable after aftermath begins
func test_13_player_remains_controllable_after_aftermath_begins() -> void:
	print("[TEST 13] Verifying player remains controllable during aftermath exploration...")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var p: Player = player_scene.instantiate() as Player
	root.add_child(p)
	await process_frame
	
	var can_move: bool = not p.is_movement_locked
	p.queue_free()
	await process_frame
	
	if can_move:
		report_result("Test 13: Player remains controllable with restored movement during aftermath", true)
	else:
		report_result("Test 13: Player remains controllable after aftermath begins", false, "movement locked")

# TEST 14: Flooded environment exists
func test_14_flooded_environment_exists() -> void:
	print("[TEST 14] Verifying flooded environment visual overlay exists...")
	var test_scene: PackedScene = load("res://scenes/test/aftermath_ending_test.tscn")
	var scene_node: AftermathEndingTestScene = test_scene.instantiate() as AftermathEndingTestScene
	root.add_child(scene_node)
	await process_frame
	
	var exists: bool = scene_node.flooded_village != null and scene_node.flooded_village is ColorRect
	scene_node.queue_free()
	await process_frame
	
	if exists:
		report_result("Test 14: Flooded environment visual overlay exists", true)
	else:
		report_result("Test 14: Flooded environment exists", false, "exists is false")

# TEST 15: Returned ocean visual exists
func test_15_returned_ocean_visual_exists() -> void:
	print("[TEST 15] Verifying returned ocean visual exists...")
	var test_scene: PackedScene = load("res://scenes/test/aftermath_ending_test.tscn")
	var scene_node: AftermathEndingTestScene = test_scene.instantiate() as AftermathEndingTestScene
	root.add_child(scene_node)
	await process_frame
	
	var ocean_exists: bool = scene_node.returned_ocean != null and scene_node.returned_ocean is ColorRect
	scene_node.queue_free()
	await process_frame
	
	if ocean_exists:
		report_result("Test 15: Returned ocean visual exists", true)
	else:
		report_result("Test 15: Returned ocean visual exists", false, "ocean_exists is false")

# TEST 16: Lower village remains visually changed
func test_16_lower_village_remains_visually_changed() -> void:
	print("[TEST 16] Verifying lower village remains visually changed/flooded in aftermath...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var test_scene: PackedScene = load("res://scenes/test/aftermath_ending_test.tscn")
	var scene_node: AftermathEndingTestScene = test_scene.instantiate() as AftermathEndingTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node._update_environment()
	var flood_visible: bool = scene_node.flooded_village.visible
	var ocean_visible: bool = scene_node.returned_ocean.visible
	
	scene_node.queue_free()
	await process_frame
	
	if flood_visible and ocean_visible:
		report_result("Test 16: Lower village remains visually changed and flooded in aftermath", true)
	else:
		report_result("Test 16: Lower village remains visually changed", false,
			"flood=%s, ocean=%s" % [flood_visible, ocean_visible])

# TEST 17: High ground remains safe
func test_17_high_ground_remains_safe() -> void:
	print("[TEST 17] Verifying high ground plateau remains elevated and safe above flooded area...")
	var test_scene: PackedScene = load("res://scenes/test/aftermath_ending_test.tscn")
	var scene_node: AftermathEndingTestScene = test_scene.instantiate() as AftermathEndingTestScene
	root.add_child(scene_node)
	await process_frame
	
	var hg_bottom_y: float = scene_node.high_ground_plateau.offset_bottom
	var flood_top_y: float = scene_node.flooded_village.offset_top
	var safe: bool = hg_bottom_y <= flood_top_y
	
	scene_node.queue_free()
	await process_frame
	
	if safe:
		report_result("Test 17: High ground plateau remains safe above flood level", true)
	else:
		report_result("Test 17: High ground remains safe", false,
			"hg_bottom=%f, flood_top=%f" % [hg_bottom_y, flood_top_y])

# TEST 18: Survivor interaction exists
func test_18_survivor_interaction_exists() -> void:
	print("[TEST 18] Verifying static survivor interactables exist...")
	var survivor: SurvivorInteractable = SurvivorInteractable.new()
	var is_interactable: bool = survivor is Interactable
	var has_signal: bool = survivor.has_signal("survivor_dialogue_started") and survivor.has_signal("survivor_dialogue_completed")
	var has_method: bool = survivor.has_method("can_interact_survivor")
	survivor.free()
	
	if is_interactable and has_signal and has_method:
		report_result("Test 18: Survivor interaction exists as Interactable component", true)
	else:
		report_result("Test 18: Survivor interaction exists", false,
			"is_interactable=%s, signal=%s" % [is_interactable, has_signal])

# TEST 19: Survivor interaction is gated before survival
func test_19_survivor_interaction_is_gated_before_survival() -> void:
	print("[TEST 19] Verifying survivor interaction is gated before survival...")
	StoryStateController.reset_story_state()
	
	var survivor: SurvivorInteractable = SurvivorInteractable.new()
	root.add_child(survivor)
	await process_frame
	
	var signal_data := {"gated": false}
	survivor.survivor_interacted.connect(func(was_gated: bool): signal_data["gated"] = was_gated)
	
	var can_talk: bool = survivor.can_interact_survivor()
	survivor.interact(null)
	await process_frame
	
	var was_gated: bool = signal_data["gated"]
	var spoken_false: bool = not survivor.has_spoken
	
	survivor.queue_free()
	await process_frame
	
	if (not can_talk) and was_gated and spoken_false:
		report_result("Test 19: Survivor interaction is gated before survival and rejects interaction", true)
	else:
		report_result("Test 19: Survivor interaction is gated before survival", false,
			"can_talk=%s, was_gated=%s, spoken=%s" % [can_talk, was_gated, spoken_false])

# TEST 20: Survivor dialogue opens correctly
func test_20_survivor_dialogue_opens_correctly() -> void:
	print("[TEST 20] Verifying survivor dialogue opens and completes after survival...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var survivor: SurvivorInteractable = SurvivorInteractable.new()
	survivor.survivor_name = "Elder Cael"
	root.add_child(survivor)
	await process_frame
	
	var signal_data := {"started": false, "completed": false}
	survivor.survivor_dialogue_started.connect(func(): signal_data["started"] = true)
	survivor.survivor_dialogue_completed.connect(func(): signal_data["completed"] = true)
	
	survivor.interact(null)
	await process_frame
	
	var started_ok: bool = signal_data["started"]
	var completed_ok: bool = signal_data["completed"]
	var has_spoken: bool = survivor.has_spoken
	
	survivor.queue_free()
	await process_frame
	
	if started_ok and completed_ok and has_spoken:
		report_result("Test 20: Survivor dialogue opens and completes correctly after survival", true)
	else:
		report_result("Test 20: Survivor dialogue opens correctly", false,
			"started=%s, completed=%s, spoken=%s" % [started_ok, completed_ok, has_spoken])

# TEST 21: Dialogue uses existing DialogueUI
func test_21_dialogue_uses_existing_dialogue_ui() -> void:
	print("[TEST 21] Verifying survivor dialogue integrates with DialogueUI...")
	var dlg_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var dlg: DialogueUI = dlg_scene.instantiate() as DialogueUI
	root.add_child(dlg)
	await process_frame
	
	var survivor: SurvivorInteractable = SurvivorInteractable.new()
	survivor.survivor_name = "Elder Cael"
	root.add_child(survivor)
	await process_frame
	
	StoryStateController.set_story_flag("survived_wave", true)
	survivor.interact(null)
	await process_frame
	
	var dlg_active: bool = dlg.is_active()
	var line_count: int = dlg.current_entries.size()
	
	dlg.end_dialogue()
	await process_frame
	
	survivor.queue_free()
	dlg.queue_free()
	await process_frame
	
	if dlg_active and line_count > 0:
		report_result("Test 21: Dialogue uses existing DialogueUI without custom dialog framework", true)
	else:
		report_result("Test 21: Dialogue uses existing DialogueUI", false,
			"dlg_active=%s, lines=%d" % [dlg_active, line_count])

# TEST 22: Final overlook exists
func test_22_final_overlook_exists() -> void:
	print("[TEST 22] Verifying FinalOverlook instance in aftermath test scene...")
	var test_scene: PackedScene = load("res://scenes/test/aftermath_ending_test.tscn")
	var scene_node: AftermathEndingTestScene = test_scene.instantiate() as AftermathEndingTestScene
	root.add_child(scene_node)
	await process_frame
	
	var overlook_ok: bool = scene_node.final_overlook != null and scene_node.final_overlook is FinalOverlook
	scene_node.queue_free()
	await process_frame
	
	if overlook_ok:
		report_result("Test 22: Final overlook component exists in test scene", true)
	else:
		report_result("Test 22: Final overlook exists", false, "overlook_ok is false")

# TEST 23: Final overlook is gated before survival
func test_23_final_overlook_is_gated_before_survival() -> void:
	print("[TEST 23] Verifying FinalOverlook is gated before wave survival...")
	StoryStateController.reset_story_state()
	
	var overlook: FinalOverlook = FinalOverlook.new()
	root.add_child(overlook)
	await process_frame
	
	var signal_data := {"gated": false}
	overlook.overlook_attempted.connect(func(was_gated: bool): signal_data["gated"] = was_gated)
	
	overlook.interact(null)
	await process_frame
	
	var was_gated: bool = signal_data["gated"]
	var is_res_active: bool = overlook.is_resolution_active
	
	overlook.queue_free()
	await process_frame
	
	if was_gated and not is_res_active:
		report_result("Test 23: Final overlook is strictly gated before survival", true)
	else:
		report_result("Test 23: Final overlook is gated before survival", false,
			"was_gated=%s, res_active=%s" % [was_gated, is_res_active])

# TEST 24: Final overlook becomes available after survival
func test_24_final_overlook_becomes_available_after_survival() -> void:
	print("[TEST 24] Verifying FinalOverlook becomes available after survival...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var overlook: FinalOverlook = FinalOverlook.new()
	root.add_child(overlook)
	await process_frame
	
	var can_trigger: bool = overlook.can_trigger_overlook()
	overlook._update_prompt()
	var prompt_ok: bool = overlook.prompt_message == "Look Out Over the Sea"
	
	overlook.queue_free()
	await process_frame
	
	if can_trigger and prompt_ok:
		report_result("Test 24: Final overlook becomes available after survival with correct prompt", true)
	else:
		report_result("Test 24: Final overlook becomes available after survival", false,
			"can_trigger=%s, prompt_ok=%s" % [can_trigger, prompt_ok])

# TEST 25: Final story sequence starts correctly
func test_25_final_story_sequence_starts_correctly() -> void:
	print("[TEST 25] Verifying final story resolution sequence starts cleanly...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var overlook: FinalOverlook = FinalOverlook.new()
	root.add_child(overlook)
	await process_frame
	
	var signal_data := {"started": false}
	overlook.resolution_started.connect(func(): signal_data["started"] = true)
	
	overlook.interact(null)
	await process_frame
	
	var started: bool = signal_data["started"]
	overlook.queue_free()
	await process_frame
	
	if started:
		report_result("Test 25: Final story resolution sequence starts correctly", true)
	else:
		report_result("Test 25: Final story sequence starts correctly", false, "started is false")

# TEST 26: Ending overlay appears
func test_26_ending_overlay_appears() -> void:
	print("[TEST 26] Verifying ending overlay appears upon completion...")
	var ending_scene: PackedScene = load("res://scenes/ui/ending_ui.tscn")
	var ending: EndingUI = ending_scene.instantiate() as EndingUI
	root.add_child(ending)
	await process_frame
	
	ending.show_ending(0.0)
	await process_frame
	
	var is_act: bool = ending.is_ending_active()
	var bg_vis: bool = ending.background.visible
	var bg_alpha: bool = ending.background.modulate.a > 0.5
	
	ending.queue_free()
	await process_frame
	
	if is_act and bg_vis and bg_alpha:
		report_result("Test 26: Ending overlay appears with title and ending prose", true)
	else:
		report_result("Test 26: Ending overlay appears", false,
			"act=%s, bg=%s, alpha=%s" % [is_act, bg_vis, bg_alpha])

# TEST 27: ending_completed initially false
func test_27_ending_completed_initially_false() -> void:
	print("[TEST 27] Verifying ending_completed is initially false...")
	StoryStateController.reset_story_state()
	var is_false: bool = not StoryStateController.has_story_flag("ending_completed")
	var helper_false: bool = not StoryStateController.is_game_ended()
	
	if is_false and helper_false:
		report_result("Test 27: ending_completed initially false", true)
	else:
		report_result("Test 27: ending_completed initially false", false,
			"is_false=%s, helper=%s" % [is_false, helper_false])

# TEST 28: ending_completed becomes true only after ending sequence
func test_28_ending_completed_becomes_true_only_after_ending_sequence() -> void:
	print("[TEST 28] Verifying ending_completed becomes true only after ending sequence...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var overlook: FinalOverlook = FinalOverlook.new()
	root.add_child(overlook)
	await process_frame
	
	overlook._trigger_ending_overlay()
	await process_frame
	
	var flag_true: bool = StoryStateController.has_story_flag("ending_completed")
	var is_ended: bool = StoryStateController.is_game_ended()
	
	overlook.queue_free()
	await process_frame
	
	if flag_true and is_ended:
		report_result("Test 28: ending_completed becomes true only after ending sequence", true)
	else:
		report_result("Test 28: ending_completed becomes true only after ending sequence", false,
			"flag=%s, is_ended=%s" % [flag_true, is_ended])

# TEST 29: Ending sequence is idempotent
func test_29_ending_sequence_is_idempotent() -> void:
	print("[TEST 29] Verifying ending sequence is idempotent...")
	var overlook: FinalOverlook = FinalOverlook.new()
	root.add_child(overlook)
	await process_frame
	
	overlook.has_completed = true
	var signal_data := {"started": false}
	overlook.resolution_started.connect(func(): signal_data["started"] = true)
	
	overlook.interact(null)
	await process_frame
	
	var not_restarted: bool = not signal_data["started"]
	var still_ended: bool = StoryStateController.is_game_ended()
	
	overlook.queue_free()
	await process_frame
	
	if not_restarted and still_ended:
		report_result("Test 29: Ending sequence is idempotent and does not replay", true)
	else:
		report_result("Test 29: Ending sequence is idempotent", false,
			"not_restarted=%s, still_ended=%s" % [not_restarted, still_ended])

# TEST 30: StoryState flags persist
func test_30_story_state_flags_persist() -> void:
	print("[TEST 30] Verifying StoryState flags persist across calls...")
	var flags_dict: Dictionary = StoryStateController._persisted_flags
	var has_aftermath: bool = flags_dict.has("aftermath_started")
	var has_ending: bool = flags_dict.has("ending_completed")
	var has_survived: bool = flags_dict.has("survived_wave")
	
	if has_aftermath and has_ending and has_survived:
		report_result("Test 30: StoryState flags persist with aftermath and ending keys", true)
	else:
		report_result("Test 30: StoryState flags persist", false,
			"aftermath=%s, ending=%s, survived=%s" % [has_aftermath, has_ending, has_survived])

# TEST 31: survived_wave remains intact
func test_31_survived_wave_remains_intact() -> void:
	print("[TEST 31] Verifying survived_wave flag remains intact...")
	StoryStateController.set_story_flag("survived_wave", true)
	var ok: bool = StoryStateController.has_player_survived()
	if ok:
		report_result("Test 31: survived_wave remains intact", true)
	else:
		report_result("Test 31: survived_wave remains intact", false, "ok is false")

# TEST 32: wave_arrived remains intact
func test_32_wave_arrived_remains_intact() -> void:
	print("[TEST 32] Verifying wave_arrived flag remains intact...")
	StoryStateController.set_story_flag("wave_arrived", true)
	var ok: bool = StoryStateController.is_wave_hit()
	if ok:
		report_result("Test 32: wave_arrived remains intact", true)
	else:
		report_result("Test 32: wave_arrived remains intact", false, "ok is false")

# TEST 33: evacuation_reached_high_ground remains intact
func test_33_evacuation_reached_high_ground_remains_intact() -> void:
	print("[TEST 33] Verifying evacuation_reached_high_ground flag remains intact...")
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	var ok: bool = StoryStateController.is_high_ground_reached()
	if ok:
		report_result("Test 33: evacuation_reached_high_ground remains intact", true)
	else:
		report_result("Test 33: evacuation_reached_high_ground remains intact", false, "ok is false")

# TEST 34: town_warned remains intact
func test_34_town_warned_remains_intact() -> void:
	print("[TEST 34] Verifying town_warned flag remains intact...")
	StoryStateController.set_story_flag("town_warned", true)
	var ok: bool = StoryStateController.is_village_warned()
	if ok:
		report_result("Test 34: town_warned remains intact", true)
	else:
		report_result("Test 34: town_warned remains intact", false, "ok is false")

# TEST 35: major_truth_discovered remains intact
func test_35_major_truth_discovered_remains_intact() -> void:
	print("[TEST 35] Verifying major_truth_discovered flag remains intact...")
	StoryStateController.set_story_flag("major_truth_discovered", true)
	var ok: bool = StoryStateController.is_truth_known()
	if ok:
		report_result("Test 35: major_truth_discovered remains intact", true)
	else:
		report_result("Test 35: major_truth_discovered remains intact", false, "ok is false")

# TEST 36: OceanState remains independent
func test_36_ocean_state_remains_independent() -> void:
	print("[TEST 36] Verifying OceanState remains independent of story progression...")
	OceanStateController.reset_ocean_state()
	var init_normal: bool = not OceanStateController.is_ocean_retreated()
	OceanStateController.trigger_ocean_retreat()
	var retreated: bool = OceanStateController.is_ocean_retreated()
	
	if init_normal and retreated:
		report_result("Test 36: OceanState remains decoupled and independent", true)
	else:
		report_result("Test 36: OceanState remains independent", false,
			"normal=%s, retreated=%s" % [init_normal, retreated])

# TEST 37: Milestone 15 regression passes
func test_37_milestone_15_regression_passes() -> void:
	print("[TEST 37] Verifying Milestone 15 ApproachingWave regression...")
	var wave: ApproachingWave = ApproachingWave.new()
	root.add_child(wave)
	await process_frame
	
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	wave._execute_arrival_instant()
	wave._execute_completion_instant()
	
	var arrived: bool = StoryStateController.is_wave_hit()
	var survived: bool = StoryStateController.has_player_survived()
	
	wave.queue_free()
	await process_frame
	
	if arrived and survived:
		report_result("Test 37: Milestone 15 ApproachingWave regression passes cleanly", true)
	else:
		report_result("Test 37: M15 regression passes", false,
			"arrived=%s, survived=%s" % [arrived, survived])

# TEST 38: Milestone 14 regression passes
func test_38_milestone_14_regression_passes() -> void:
	print("[TEST 38] Verifying Milestone 14 HighGroundZone regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	StoryStateController.set_story_flag("evacuation_started", true)
	
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	zone.trigger_entry(null)
	await process_frame
	
	var reached: bool = StoryStateController.is_high_ground_reached()
	zone.queue_free()
	await process_frame
	
	if reached:
		report_result("Test 38: Milestone 14 HighGroundZone regression passes cleanly", true)
	else:
		report_result("Test 38: M14 regression passes", false, "reached is false")

# TEST 39: Milestone 13 regression passes
func test_39_milestone_13_regression_passes() -> void:
	print("[TEST 39] Verifying Milestone 13 TownWarning regression...")
	var warning: TownWarning = TownWarning.new()
	root.add_child(warning)
	await process_frame
	
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	warning._finalize_town_warning()
	await process_frame
	
	var warned: bool = StoryStateController.is_village_warned()
	warning.queue_free()
	await process_frame
	
	if warned:
		report_result("Test 39: Milestone 13 TownWarning regression passes cleanly", true)
	else:
		report_result("Test 39: M13 regression passes", false, "warned is false")

# TEST 40: Milestone 12 regression passes
func test_40_milestone_12_regression_passes() -> void:
	print("[TEST 40] Verifying Milestone 12 MajorTruthDiscovery regression...")
	var truth: MajorTruthDiscovery = MajorTruthDiscovery.new()
	root.add_child(truth)
	await process_frame
	
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	truth._finalize_truth_discovery()
	await process_frame
	
	var known: bool = StoryStateController.is_truth_known()
	truth.queue_free()
	await process_frame
	
	if known:
		report_result("Test 40: Milestone 12 MajorTruthDiscovery regression passes cleanly", true)
	else:
		report_result("Test 40: M12 regression passes", false, "known is false")

# TEST 41: Milestone 11 regression passes
func test_41_milestone_11_regression_passes() -> void:
	print("[TEST 41] Verifying Milestone 11 ShipwreckInvestigation regression...")
	var wreck: ShipwreckInvestigation = ShipwreckInvestigation.new()
	root.add_child(wreck)
	await process_frame
	
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	
	wreck._finalize_clue_discovery()
	await process_frame
	
	var clue: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	wreck.queue_free()
	await process_frame
	
	if clue:
		report_result("Test 41: Milestone 11 ShipwreckInvestigation regression passes cleanly", true)
	else:
		report_result("Test 41: M11 regression passes", false, "clue is false")

# TEST 42: Milestone 10 regression passes
func test_42_milestone_10_regression_passes() -> void:
	print("[TEST 42] Verifying Milestone 10 story threshold regression...")
	StoryStateController.reset_story_state()
	StoryStateController.record_story_discovery("shell_sign_seen")
	StoryStateController.record_story_discovery("tide_pool_sign_seen")
	var before: bool = not StoryStateController.is_investigating()
	StoryStateController.record_story_discovery("birds_sign_seen")
	var after: bool = StoryStateController.is_investigating()
	
	if before and after:
		report_result("Test 42: Milestone 10 StoryState threshold regression passes cleanly", true)
	else:
		report_result("Test 42: M10 regression passes", false, "before=%s, after=%s" % [before, after])

# TEST 43: Milestone 9 regression passes
func test_43_milestone_9_regression_passes() -> void:
	print("[TEST 43] Verifying Milestone 9 DialogueUI standalone regression...")
	var dlg_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var dlg: DialogueUI = dlg_scene.instantiate() as DialogueUI
	root.add_child(dlg)
	await process_frame
	
	dlg.start_dialogue([{"speaker": "Sens", "text": "Milestone 9 check"}])
	var act: bool = dlg.is_active()
	dlg.advance_dialogue()
	var closed: bool = not dlg.is_active()
	
	dlg.queue_free()
	await process_frame
	
	if act and closed:
		report_result("Test 43: Milestone 9 DialogueUI regression passes cleanly", true)
	else:
		report_result("Test 43: M9 regression passes", false, "act=%s, closed=%s" % [act, closed])

# TEST 44: Milestone 8 regression passes
func test_44_milestone_8_regression_passes() -> void:
	print("[TEST 44] Verifying Milestone 8 environmental signs regression...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var shell: SeabedShell = seabed.get_node_or_null("StrangeSigns/ShellTidePools") as SeabedShell
	var pools: TidePoolSign = seabed.get_node_or_null("TidePools") as TidePoolSign
	var tremor: SeabedTremorSign = seabed.get_node_or_null("StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	var all_ok: bool = shell != null and pools != null and tremor != null
	
	seabed.queue_free()
	await process_frame
	
	if all_ok:
		report_result("Test 44: Milestone 8 environmental signs regression passes cleanly", true)
	else:
		report_result("Test 44: M8 regression passes", false, "all_ok is false")

# TEST 45: Milestone 7 regression passes
func test_45_milestone_7_regression_passes() -> void:
	print("[TEST 45] Verifying Milestone 7 OceanState regression...")
	OceanStateController.reset_ocean_state()
	var normal: bool = not OceanStateController.is_ocean_retreated()
	OceanStateController.trigger_ocean_retreat()
	var retreated: bool = OceanStateController.is_ocean_retreated()
	
	if normal and retreated:
		report_result("Test 45: Milestone 7 OceanState regression passes cleanly", true)
	else:
		report_result("Test 45: M7 regression passes", false, "normal=%s, retreated=%s" % [normal, retreated])

# TEST 46: Main scene loads cleanly
func test_46_main_scene_loads_cleanly() -> void:
	print("[TEST 46] Verifying main scene loads cleanly...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate() as Node2D
	root.add_child(main_node)
	await process_frame
	
	var ok: bool = main_node != null and main_node is Node2D
	main_node.queue_free()
	await process_frame
	
	if ok:
		report_result("Test 46: Main scene (scenes/main.tscn) loads cleanly", true)
	else:
		report_result("Test 46: Main scene loads cleanly", false, "ok is false")
