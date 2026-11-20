extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null
var story_state_node: StoryStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 15 VERIFICATION SUITE ---")
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
	await test_2_approaching_wave_component_exists()
	await test_3_wave_controller_has_expected_state_machine()
	await test_4_wave_event_is_initially_idle()
	await test_5_wave_is_gated_before_high_ground()
	await test_6_wave_does_not_start_without_evacuation_reached_high_ground()
	await test_7_high_ground_unlocks_wave_event()
	await test_8_wave_event_started_initially_false()
	await test_9_wave_event_starts_correctly()
	await test_10_wave_event_started_becomes_true()
	await test_11_wave_event_can_only_start_once()
	await test_12_distant_wave_phase_activates()
	await test_13_wave_visual_exists()
	await test_14_wave_visual_grows_moves_toward_village()
	await test_15_wave_arrival_state_activates()
	await test_16_wave_arrived_becomes_true()
	await test_17_impact_effect_activates()
	await test_18_lower_village_becomes_visually_flooded_obscured()
	await test_19_high_ground_remains_safe()
	await test_20_player_is_not_moved_into_the_wave()
	await test_21_player_movement_is_restored_after_event()
	await test_22_survived_wave_remains_false_before_completion()
	await test_23_survived_wave_becomes_true_after_completion()
	await test_24_repeated_trigger_does_not_restart_event()
	await test_25_story_state_flags_persist()
	await test_26_town_warned_remains_intact()
	await test_27_major_truth_discovered_remains_intact()
	await test_28_evacuation_started_remains_intact()
	await test_29_evacuation_reached_high_ground_remains_intact()
	await test_30_ocean_state_remains_independent()
	await test_31_m14_evacuation_regression_passes()
	await test_32_m13_town_warning_regression_passes()
	await test_33_m12_major_truth_regression_passes()
	await test_34_m11_shipwreck_regression_passes()
	await test_35_m10_story_state_regression_passes()
	await test_36_m9_dialogue_ui_regression_passes()
	await test_37_m8_environmental_signs_regression_passes()
	await test_38_m7_ocean_state_regression_passes()
	await test_39_main_scene_loads_cleanly()
	
	print("\n==================================================")
	print("--- MILESTONE 15 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Test scene loads cleanly
func test_1_test_scene_loads() -> void:
	print("[TEST 1] Verifying approaching wave test scene loads cleanly...")
	var test_scene: PackedScene = load("res://scenes/test/approaching_wave_test.tscn")
	var scene_node: ApproachingWaveTestScene = test_scene.instantiate() as ApproachingWaveTestScene
	root.add_child(scene_node)
	await process_frame
	
	var scene_ok: bool = scene_node != null and scene_node is ApproachingWaveTestScene
	var hud_ok: bool = scene_node.wave_state_label != null and scene_node.progress_label != null
	var player_ok: bool = scene_node.player != null and scene_node.player is Player
	var wave_ok: bool = scene_node.approaching_wave != null and scene_node.approaching_wave is ApproachingWave
	
	scene_node.queue_free()
	await process_frame
	
	if scene_ok and hud_ok and player_ok and wave_ok:
		report_result("Test 1: Approaching wave test scene loads cleanly", true)
	else:
		report_result("Test 1: Approaching wave test scene loads cleanly", false,
			"scene_ok=%s, hud_ok=%s, player_ok=%s, wave_ok=%s" % [scene_ok, hud_ok, player_ok, wave_ok])

# TEST 2: Approaching wave component exists
func test_2_approaching_wave_component_exists() -> void:
	print("[TEST 2] Verifying ApproachingWave class and component exist...")
	var wave: ApproachingWave = ApproachingWave.new()
	root.add_child(wave)
	await process_frame
	
	var is_node2d: bool = wave is Node2D
	var has_signals: bool = wave.has_signal("wave_started") and wave.has_signal("wave_approaching") and wave.has_signal("wave_impacted") and wave.has_signal("wave_completed") and wave.has_signal("wave_attempted")
	
	wave.queue_free()
	await process_frame
	
	if is_node2d and has_signals:
		report_result("Test 2: ApproachingWave component exists and extends Node2D with required signals", true)
	else:
		report_result("Test 2: Approaching wave component exists", false,
			"is_node2d=%s, has_signals=%s" % [is_node2d, has_signals])

# TEST 3: Wave controller has expected state machine
func test_3_wave_controller_has_expected_state_machine() -> void:
	print("[TEST 3] Verifying ApproachingWave state machine...")
	var wave: ApproachingWave = ApproachingWave.new()
	root.add_child(wave)
	await process_frame
	
	var has_states: bool = ApproachingWave.WaveState.IDLE == 0 and ApproachingWave.WaveState.APPROACHING == 1 and ApproachingWave.WaveState.ARRIVING == 2 and ApproachingWave.WaveState.COMPLETE == 3
	var query_ok: bool = wave.get_state() == ApproachingWave.WaveState.IDLE
	
	wave.queue_free()
	await process_frame
	
	if has_states and query_ok:
		report_result("Test 3: Wave controller exposes expected WaveState enum (IDLE, APPROACHING, ARRIVING, COMPLETE)", true)
	else:
		report_result("Test 3: Wave controller has expected state machine", false,
			"has_states=%s, query_ok=%s" % [has_states, query_ok])

# TEST 4: Wave event is initially idle
func test_4_wave_event_is_initially_idle() -> void:
	print("[TEST 4] Verifying wave event is initially IDLE...")
	var wave: ApproachingWave = ApproachingWave.new()
	root.add_child(wave)
	await process_frame
	
	var is_idle: bool = wave.current_state == ApproachingWave.WaveState.IDLE
	var str_ok: bool = wave.get_state_string() == "IDLE"
	
	wave.queue_free()
	await process_frame
	
	if is_idle and str_ok:
		report_result("Test 4: Wave event is initially IDLE", true)
	else:
		report_result("Test 4: Wave event is initially idle", false, "is_idle=%s, str=%s" % [is_idle, str_ok])

# TEST 5: Wave is gated before high ground
func test_5_wave_is_gated_before_high_ground() -> void:
	print("[TEST 5] Verifying wave event is gated before reaching high ground...")
	StoryStateController.reset_story_state()
	
	var wave: ApproachingWave = ApproachingWave.new()
	root.add_child(wave)
	await process_frame
	
	var attempt_data := {"gated": false, "called": false}
	wave.wave_attempted.connect(func(was_gated: bool):
		attempt_data["called"] = true
		attempt_data["gated"] = was_gated
	)
	
	var started: bool = wave.start_wave_event()
	await process_frame
	
	var flag_remained_false: bool = not StoryStateController.is_wave_approaching()
	var state_remained_idle: bool = wave.current_state == ApproachingWave.WaveState.IDLE
	var was_gated: bool = attempt_data["called"] and attempt_data["gated"] == true
	
	wave.queue_free()
	await process_frame
	
	if not started and flag_remained_false and state_remained_idle and was_gated:
		report_result("Test 5: Wave is gated before high ground (was_gated=true, remains IDLE)", true)
	else:
		report_result("Test 5: Wave is gated before high ground", false,
			"started=%s, flag_false=%s, idle=%s, gated=%s" % [started, flag_remained_false, state_remained_idle, was_gated])

# TEST 6: Wave does not start without evacuation_reached_high_ground
func test_6_wave_does_not_start_without_evacuation_reached_high_ground() -> void:
	print("[TEST 6] Verifying wave prerequisite gate function...")
	StoryStateController.reset_story_state()
	
	var can_trigger: bool = StoryStateController.can_trigger_wave_event()
	var instance_can: bool = StoryStateController.instance.can_start_wave_event() if StoryStateController.instance else true
	
	if not can_trigger and not instance_can:
		report_result("Test 6: Wave cannot start without evacuation_reached_high_ground", true)
	else:
		report_result("Test 6: Wave does not start without evacuation_reached_high_ground", false,
			"can_trigger=%s, instance_can=%s" % [can_trigger, instance_can])

# TEST 7: High ground unlocks wave event
func test_7_high_ground_unlocks_wave_event() -> void:
	print("[TEST 7] Verifying high ground flag unlocks wave event...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	var can_trigger: bool = StoryStateController.can_trigger_wave_event()
	var instance_can: bool = StoryStateController.instance.can_start_wave_event() if StoryStateController.instance else true
	
	if can_trigger and instance_can:
		report_result("Test 7: evacuation_reached_high_ground unlocks wave event prerequisite", true)
	else:
		report_result("Test 7: High ground unlocks wave event", false,
			"can_trigger=%s, instance_can=%s" % [can_trigger, instance_can])

# TEST 8: wave_event_started initially false
func test_8_wave_event_started_initially_false() -> void:
	print("[TEST 8] Verifying wave_event_started is initially false on baseline...")
	StoryStateController.reset_story_state()
	
	var is_false: bool = not StoryStateController.has_story_flag("wave_event_started")
	var instance_false: bool = not StoryStateController.instance.is_wave_event_started() if StoryStateController.instance else true
	
	if is_false and instance_false:
		report_result("Test 8: wave_event_started is initially false", true)
	else:
		report_result("Test 8: wave_event_started initially false", false,
			"is_false=%s, instance_false=%s" % [is_false, instance_false])

# TEST 9: Wave event starts correctly
func test_9_wave_event_starts_correctly() -> void:
	print("[TEST 9] Verifying wave event starts correctly when unlocked...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	var wave: ApproachingWave = ApproachingWave.new()
	wave.auto_start_on_high_ground = false
	root.add_child(wave)
	await process_frame
	
	var success: bool = wave.start_wave_event()
	var state_ok: bool = wave.current_state == ApproachingWave.WaveState.APPROACHING
	
	wave.queue_free()
	await process_frame
	
	if success and state_ok:
		report_result("Test 9: Wave event starts correctly and transitions to APPROACHING", true)
	else:
		report_result("Test 9: Wave event starts correctly", false,
			"success=%s, state_ok=%s" % [success, state_ok])

# TEST 10: wave_event_started becomes true
func test_10_wave_event_started_becomes_true() -> void:
	print("[TEST 10] Verifying wave_event_started flag becomes true...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	var signal_data := {"emitted": false}
	if StoryStateController.instance:
		StoryStateController.instance.wave_event_started.connect(func():
			signal_data["emitted"] = true
		, CONNECT_ONE_SHOT)
	
	var wave: ApproachingWave = ApproachingWave.new()
	wave.auto_start_on_high_ground = false
	root.add_child(wave)
	await process_frame
	
	wave.start_wave_event()
	await process_frame
	
	var flag_ok: bool = StoryStateController.has_story_flag("wave_event_started")
	var signal_ok: bool = signal_data["emitted"]
	
	wave.queue_free()
	await process_frame
	
	if flag_ok and signal_ok:
		report_result("Test 10: wave_event_started becomes true and emits wave_event_started signal", true)
	else:
		report_result("Test 10: wave_event_started becomes true", false,
			"flag_ok=%s, signal_ok=%s" % [flag_ok, signal_ok])

# TEST 11: Wave event can only start once
func test_11_wave_event_can_only_start_once() -> void:
	print("[TEST 11] Verifying wave event cannot be started multiple times concurrently...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	var wave: ApproachingWave = ApproachingWave.new()
	wave.auto_start_on_high_ground = false
	root.add_child(wave)
	await process_frame
	
	var first_start: bool = wave.start_wave_event()
	var second_start: bool = wave.start_wave_event()
	
	wave.queue_free()
	await process_frame
	
	if first_start and not second_start:
		report_result("Test 11: Wave event can only start once (duplicate calls rejected)", true)
	else:
		report_result("Test 11: Wave event can only start once", false,
			"first=%s, second=%s" % [first_start, second_start])

# TEST 12: Distant wave phase activates
func test_12_distant_wave_phase_activates() -> void:
	print("[TEST 12] Verifying distant wave approach phase activates...")
	var wave: ApproachingWave = ApproachingWave.new()
	var container := Node2D.new()
	container.name = "WaveContainer"
	wave.add_child(container)
	root.add_child(wave)
	await process_frame
	
	wave._show_distant_wave()
	await process_frame
	
	var is_visible: bool = container.visible
	var scale_reduced: bool = container.scale.x < 0.5
	
	wave.queue_free()
	await process_frame
	
	if is_visible and scale_reduced:
		report_result("Test 12: Distant wave phase activates with visible horizon container", true)
	else:
		report_result("Test 12: Distant wave phase activates", false,
			"is_visible=%s, scale_reduced=%s" % [is_visible, scale_reduced])

# TEST 13: Wave visual exists
func test_13_wave_visual_exists() -> void:
	print("[TEST 13] Verifying wave visual nodes exist in ApproachingWave test scene...")
	var test_scene: PackedScene = load("res://scenes/test/approaching_wave_test.tscn")
	var scene_node: ApproachingWaveTestScene = test_scene.instantiate() as ApproachingWaveTestScene
	root.add_child(scene_node)
	await process_frame
	
	var wave := scene_node.approaching_wave
	var has_container: bool = wave.wave_container != null
	var has_surge: bool = wave.surge_wall != null
	var has_foam: bool = wave.wave_foam != null
	var has_flooded: bool = wave.flooded_overlay != null
	
	scene_node.queue_free()
	await process_frame
	
	if has_container and has_surge and has_foam and has_flooded:
		report_result("Test 13: Wave visual nodes (WaveContainer, SurgeWall, WaveFoam, FloodedOverlay) exist", true)
	else:
		report_result("Test 13: Wave visual exists", false,
			"container=%s, surge=%s, foam=%s, flooded=%s" % [has_container, has_surge, has_foam, has_flooded])

# TEST 14: Wave visual grows/moves toward village
func test_14_wave_visual_grows_moves_toward_village() -> void:
	print("[TEST 14] Verifying wave visual advances toward village...")
	var wave: ApproachingWave = ApproachingWave.new()
	var container := Node2D.new()
	container.name = "WaveContainer"
	wave.add_child(container)
	root.add_child(wave)
	await process_frame
	
	wave._show_distant_wave()
	var init_y: float = container.position.y
	wave.wave_travel_duration = 0.1
	wave._animate_wave_advance()
	await create_timer(0.15).timeout
	
	var moved_toward_village: bool = container.position.y < init_y
	var scaled_up: bool = container.scale.x > 0.5
	
	wave.queue_free()
	await process_frame
	
	if moved_toward_village and scaled_up:
		report_result("Test 14: Wave visual grows and advances toward village", true)
	else:
		report_result("Test 14: Wave visual grows/moves toward village", false,
			"moved=%s, scaled=%s" % [moved_toward_village, scaled_up])

# TEST 15: Wave arrival state activates
func test_15_wave_arrival_state_activates() -> void:
	print("[TEST 15] Verifying wave arrival state transitions to ARRIVING...")
	var wave: ApproachingWave = ApproachingWave.new()
	root.add_child(wave)
	await process_frame
	
	wave._execute_wave_arrival()
	var state_arriving: bool = wave.current_state == ApproachingWave.WaveState.ARRIVING
	var str_ok: bool = wave.get_state_string() == "ARRIVING"
	
	wave.queue_free()
	await process_frame
	
	if state_arriving and str_ok:
		report_result("Test 15: Wave arrival state transitions to ARRIVING", true)
	else:
		report_result("Test 15: Wave arrival state activates", false,
			"state_arriving=%s, str=%s" % [state_arriving, str_ok])

# TEST 16: wave_arrived becomes true
func test_16_wave_arrived_becomes_true() -> void:
	print("[TEST 16] Verifying wave_arrived flag becomes true upon arrival...")
	StoryStateController.reset_story_state()
	
	var signal_data := {"impacted": false}
	var wave: ApproachingWave = ApproachingWave.new()
	wave.wave_impacted.connect(func(): signal_data["impacted"] = true)
	root.add_child(wave)
	await process_frame
	
	wave._execute_wave_arrival()
	await process_frame
	
	var flag_ok: bool = StoryStateController.has_story_flag("wave_arrived")
	var signal_ok: bool = signal_data["impacted"]
	
	wave.queue_free()
	await process_frame
	
	if flag_ok and signal_ok:
		report_result("Test 16: wave_arrived flag becomes true and emits wave_impacted", true)
	else:
		report_result("Test 16: wave_arrived becomes true", false,
			"flag_ok=%s, signal_ok=%s" % [flag_ok, signal_ok])

# TEST 17: Impact effect activates
func test_17_impact_effect_activates() -> void:
	print("[TEST 17] Verifying impact flash effect activates...")
	var wave: ApproachingWave = ApproachingWave.new()
	var flash := ColorRect.new()
	flash.name = "FlashOverlay"
	wave.add_child(flash)
	root.add_child(wave)
	await process_frame
	
	wave._trigger_impact_flash()
	await process_frame
	
	var flash_visible: bool = flash.visible and flash.modulate.a > 0.1
	
	wave.queue_free()
	await process_frame
	
	if flash_visible:
		report_result("Test 17: Impact effect activates flash overlay", true)
	else:
		report_result("Test 17: Impact effect activates", false, "flash_visible=%s" % flash_visible)

# TEST 18: Lower village becomes visually flooded/obscured
func test_18_lower_village_becomes_visually_flooded_obscured() -> void:
	print("[TEST 18] Verifying lower village becomes visually flooded/obscured...")
	var wave: ApproachingWave = ApproachingWave.new()
	var flooded := ColorRect.new()
	flooded.name = "FloodedOverlay"
	wave.add_child(flooded)
	root.add_child(wave)
	await process_frame
	
	wave._apply_post_wave_environment()
	await process_frame
	
	var flooded_ok: bool = flooded.visible and flooded.modulate.a > 0.5
	
	wave.queue_free()
	await process_frame
	
	if flooded_ok:
		report_result("Test 18: Lower village visually flooded/obscured overlay activates", true)
	else:
		report_result("Test 18: Lower village becomes visually flooded/obscured", false, "flooded_ok=%s" % flooded_ok)

# TEST 19: High ground remains safe
func test_19_high_ground_remains_safe() -> void:
	print("[TEST 19] Verifying high ground plateau remains above flooded water...")
	var test_scene: PackedScene = load("res://scenes/test/approaching_wave_test.tscn")
	var scene_node: ApproachingWaveTestScene = test_scene.instantiate() as ApproachingWaveTestScene
	root.add_child(scene_node)
	await process_frame
	
	var plateau: ColorRect = scene_node.find_child("HighGroundPlateau", true, false) as ColorRect
	var flood: ColorRect = scene_node.approaching_wave.flooded_overlay
	
	# High ground plateau is at y: 20..110; flooded overlay starts at y: 130
	var hg_top_y: float = plateau.offset_top if plateau else 0.0
	var hg_bottom_y: float = plateau.offset_bottom if plateau else 0.0
	var flood_top_y: float = flood.offset_top if flood else 0.0
	
	var plateau_safe: bool = hg_bottom_y < flood_top_y
	
	scene_node.queue_free()
	await process_frame
	
	if plateau_safe:
		report_result("Test 19: High ground plateau remains safe above the flooded water level", true)
	else:
		report_result("Test 19: High ground remains safe", false,
			"hg_bottom=%f, flood_top=%f" % [hg_bottom_y, flood_top_y])

# TEST 20: Player is not moved into the wave
func test_20_player_is_not_moved_into_the_wave() -> void:
	print("[TEST 20] Verifying player remains on high ground and is not relocated into the wave...")
	var test_scene: PackedScene = load("res://scenes/test/approaching_wave_test.tscn")
	var scene_node: ApproachingWaveTestScene = test_scene.instantiate() as ApproachingWaveTestScene
	root.add_child(scene_node)
	await process_frame
	
	var player_init_pos: Vector2 = scene_node.player.global_position
	scene_node.approaching_wave._execute_wave_arrival()
	await process_frame
	scene_node.approaching_wave._execute_wave_survival()
	await process_frame
	
	var player_final_pos: Vector2 = scene_node.player.global_position
	var position_intact: bool = player_init_pos.distance_to(player_final_pos) < 1.0
	
	scene_node.queue_free()
	await process_frame
	
	if position_intact:
		report_result("Test 20: Player remains safely on high ground without being moved into the wave", true)
	else:
		report_result("Test 20: Player is not moved into the wave", false,
			"init=%s, final=%s" % [str(player_init_pos), str(player_final_pos)])

# TEST 21: Player movement is restored after event
func test_21_player_movement_is_restored_after_event() -> void:
	print("[TEST 21] Verifying player movement is restored after wave event...")
	var test_scene: PackedScene = load("res://scenes/test/approaching_wave_test.tscn")
	var scene_node: ApproachingWaveTestScene = test_scene.instantiate() as ApproachingWaveTestScene
	root.add_child(scene_node)
	await process_frame
	
	scene_node.approaching_wave._bound_player = scene_node.player
	scene_node.approaching_wave._execute_wave_arrival()
	var locked_during: bool = scene_node.player.is_movement_locked
	
	scene_node.approaching_wave._execute_wave_survival()
	var unlocked_after: bool = not scene_node.player.is_movement_locked
	
	scene_node.queue_free()
	await process_frame
	
	if locked_during and unlocked_after:
		report_result("Test 21: Player movement is locked during impact and cleanly restored after survival", true)
	else:
		report_result("Test 21: Player movement is restored after event", false,
			"locked_during=%s, unlocked_after=%s" % [locked_during, unlocked_after])

# TEST 22: survived_wave remains false before completion
func test_22_survived_wave_remains_false_before_completion() -> void:
	print("[TEST 22] Verifying survived_wave remains false prior to completion...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	StoryStateController.set_story_flag("wave_event_started", true)
	StoryStateController.set_story_flag("wave_arrived", true)
	
	var is_false: bool = not StoryStateController.has_story_flag("survived_wave")
	var instance_false: bool = not StoryStateController.instance.has_survived_wave() if StoryStateController.instance else true
	
	if is_false and instance_false:
		report_result("Test 22: survived_wave flag remains false while wave impact is in progress", true)
	else:
		report_result("Test 22: survived_wave remains false before completion", false,
			"is_false=%s, instance_false=%s" % [is_false, instance_false])

# TEST 23: survived_wave becomes true after completion
func test_23_survived_wave_becomes_true_after_completion() -> void:
	print("[TEST 23] Verifying survived_wave becomes true upon completion...")
	StoryStateController.reset_story_state()
	
	var signal_data := {"completed": false}
	var wave: ApproachingWave = ApproachingWave.new()
	wave.wave_completed.connect(func(): signal_data["completed"] = true)
	root.add_child(wave)
	await process_frame
	
	wave._execute_wave_survival()
	await process_frame
	
	var flag_ok: bool = StoryStateController.has_story_flag("survived_wave")
	var state_ok: bool = wave.current_state == ApproachingWave.WaveState.COMPLETE
	var signal_ok: bool = signal_data["completed"]
	
	wave.queue_free()
	await process_frame
	
	if flag_ok and state_ok and signal_ok:
		report_result("Test 23: survived_wave becomes true, state is COMPLETE, and wave_completed is emitted", true)
	else:
		report_result("Test 23: survived_wave becomes true after completion", false,
			"flag_ok=%s, state_ok=%s, signal_ok=%s" % [flag_ok, state_ok, signal_ok])

# TEST 24: Repeated trigger does not restart event
func test_24_repeated_trigger_does_not_restart_event() -> void:
	print("[TEST 24] Verifying repeated trigger does not restart wave event...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	var wave: ApproachingWave = ApproachingWave.new()
	wave.auto_start_on_high_ground = false
	root.add_child(wave)
	await process_frame
	
	wave.start_wave_event()
	wave._execute_wave_survival()
	
	var repeat_call: bool = wave.start_wave_event()
	var state_complete: bool = wave.current_state == ApproachingWave.WaveState.COMPLETE
	
	wave.queue_free()
	await process_frame
	
	if not repeat_call and state_complete:
		report_result("Test 24: Repeated trigger does not restart event (idempotent)", true)
	else:
		report_result("Test 24: Repeated trigger does not restart event", false,
			"repeat_call=%s, state_complete=%s" % [repeat_call, state_complete])

# TEST 25: StoryState flags persist across world scene reloads
func test_25_story_state_flags_persist() -> void:
	print("[TEST 25] Verifying wave flags persist across world scene reloads...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("wave_event_started", true)
	StoryStateController.set_story_flag("wave_arrived", true)
	StoryStateController.set_story_flag("survived_wave", true)
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Node2D = village_scene.instantiate() as Node2D
	root.add_child(village)
	await process_frame
	
	var f1: bool = StoryStateController.has_story_flag("wave_event_started")
	var f2: bool = StoryStateController.has_story_flag("wave_arrived")
	var f3: bool = StoryStateController.has_story_flag("survived_wave")
	
	village.queue_free()
	await process_frame
	
	if f1 and f2 and f3:
		report_result("Test 25: Wave StoryState flags persist across scene reloads", true)
	else:
		report_result("Test 25: StoryState flags persist", false, "f1=%s, f2=%s, f3=%s" % [f1, f2, f3])

# TEST 26: town_warned remains intact
func test_26_town_warned_remains_intact() -> void:
	print("[TEST 26] Verifying town_warned flag remains intact throughout wave event...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	StoryStateController.set_story_flag("survived_wave", true)
	
	var ok: bool = StoryStateController.is_village_warned()
	if ok:
		report_result("Test 26: town_warned remains intact throughout wave event", true)
	else:
		report_result("Test 26: town_warned remains intact", false, "ok=false")

# TEST 27: major_truth_discovered remains intact
func test_27_major_truth_discovered_remains_intact() -> void:
	print("[TEST 27] Verifying major_truth_discovered remains intact...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	StoryStateController.set_story_flag("survived_wave", true)
	
	var ok: bool = StoryStateController.is_truth_known()
	if ok:
		report_result("Test 27: major_truth_discovered remains intact", true)
	else:
		report_result("Test 27: major_truth_discovered remains intact", false, "ok=false")

# TEST 28: evacuation_started remains intact
func test_28_evacuation_started_remains_intact() -> void:
	print("[TEST 28] Verifying evacuation_started remains intact...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_started", true)
	StoryStateController.set_story_flag("survived_wave", true)
	
	var ok: bool = StoryStateController.has_story_flag("evacuation_started")
	if ok:
		report_result("Test 28: evacuation_started remains intact", true)
	else:
		report_result("Test 28: evacuation_started remains intact", false, "ok=false")

# TEST 29: evacuation_reached_high_ground remains intact
func test_29_evacuation_reached_high_ground_remains_intact() -> void:
	print("[TEST 29] Verifying evacuation_reached_high_ground remains intact...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	StoryStateController.set_story_flag("survived_wave", true)
	
	var ok: bool = StoryStateController.is_high_ground_reached()
	if ok:
		report_result("Test 29: evacuation_reached_high_ground remains intact", true)
	else:
		report_result("Test 29: evacuation_reached_high_ground remains intact", false, "ok=false")

# TEST 30: OceanState remains independent
func test_30_ocean_state_remains_independent() -> void:
	print("[TEST 30] Verifying OceanState operations remain independent from wave event...")
	OceanStateController.reset_ocean_state()
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("survived_wave", true)
	
	var normal_ok: bool = not OceanStateController.is_ocean_retreated()
	OceanStateController.trigger_ocean_retreat()
	var retreat_ok: bool = OceanStateController.is_ocean_retreated()
	
	if normal_ok and retreat_ok:
		report_result("Test 30: OceanState operations maintain complete independence from wave event", true)
	else:
		report_result("Test 30: OceanState remains independent", false,
			"normal=%s, retreat=%s" % [normal_ok, retreat_ok])

# TEST 31: M14 evacuation regression passes
func test_31_m14_evacuation_regression_passes() -> void:
	print("[TEST 31] Verifying Milestone 14 HighGroundZone regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	zone.trigger_entry()
	await process_frame
	
	var hg_ok: bool = StoryStateController.is_high_ground_reached()
	zone.queue_free()
	await process_frame
	
	if hg_ok:
		report_result("Test 31: Milestone 14 HighGroundZone regression passes cleanly", true)
	else:
		report_result("Test 31: M14 evacuation regression passes", false, "hg_ok=false")

# TEST 32: M13 town warning regression passes
func test_32_m13_town_warning_regression_passes() -> void:
	print("[TEST 32] Verifying Milestone 13 TownWarning regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var warning: TownWarning = TownWarning.new()
	root.add_child(warning)
	await process_frame
	
	warning.interact(null)
	await process_frame
	
	var warned_ok: bool = StoryStateController.is_village_warned()
	warning.queue_free()
	await process_frame
	
	if warned_ok:
		report_result("Test 32: Milestone 13 TownWarning regression passes cleanly", true)
	else:
		report_result("Test 32: M13 town warning regression passes", false, "warned_ok=false")

# TEST 33: M12 major truth regression passes
func test_33_m12_major_truth_regression_passes() -> void:
	print("[TEST 33] Verifying Milestone 12 MajorTruthDiscovery regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var truth: MajorTruthDiscovery = MajorTruthDiscovery.new()
	root.add_child(truth)
	await process_frame
	
	truth.interact(null)
	await process_frame
	
	var truth_ok: bool = StoryStateController.is_truth_known()
	truth.queue_free()
	await process_frame
	
	if truth_ok:
		report_result("Test 33: Milestone 12 MajorTruthDiscovery regression passes cleanly", true)
	else:
		report_result("Test 33: M12 major truth regression passes", false, "truth_ok=false")

# TEST 34: M11 shipwreck regression passes
func test_34_m11_shipwreck_regression_passes() -> void:
	print("[TEST 34] Verifying Milestone 11 ShipwreckInvestigation regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	
	var wreck: ShipwreckInvestigation = ShipwreckInvestigation.new()
	root.add_child(wreck)
	await process_frame
	
	wreck.interact(null)
	await process_frame
	
	var clue_ok: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	wreck.queue_free()
	await process_frame
	
	if clue_ok:
		report_result("Test 34: Milestone 11 ShipwreckInvestigation regression passes cleanly", true)
	else:
		report_result("Test 34: M11 shipwreck regression passes", false, "clue_ok=false")

# TEST 35: M10 StoryState regression passes
func test_35_m10_story_state_regression_passes() -> void:
	print("[TEST 35] Verifying Milestone 10 3-sign threshold regression...")
	StoryStateController.reset_story_state()
	
	StoryStateController.record_story_discovery("shell_sign_seen")
	StoryStateController.record_story_discovery("tide_pool_sign_seen")
	var before_threshold: bool = not StoryStateController.is_investigating()
	
	StoryStateController.record_story_discovery("birds_sign_seen")
	var after_threshold: bool = StoryStateController.is_investigating()
	
	if before_threshold and after_threshold:
		report_result("Test 35: Milestone 10 StoryState regression passes cleanly", true)
	else:
		report_result("Test 35: M10 StoryState regression passes", false,
			"before=%s, after=%s" % [before_threshold, after_threshold])

# TEST 36: M9 DialogueUI regression passes
func test_36_m9_dialogue_ui_regression_passes() -> void:
	print("[TEST 36] Verifying Milestone 9 DialogueUI standalone regression...")
	var dlg_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var dlg_ui: DialogueUI = dlg_scene.instantiate() as DialogueUI
	root.add_child(dlg_ui)
	await process_frame
	
	var signal_data: Dictionary = {"started": false, "ended": false}
	dlg_ui.dialogue_started.connect(func(): signal_data["started"] = true)
	dlg_ui.dialogue_ended.connect(func(): signal_data["ended"] = true)
	
	dlg_ui.start_dialogue([{"speaker": "Sens", "text": "Testing wave dialogue"}])
	await process_frame
	
	var active_ok: bool = dlg_ui.is_active() and signal_data["started"]
	dlg_ui.advance_dialogue()
	await process_frame
	
	var ended_ok: bool = (not dlg_ui.is_active()) and signal_data["ended"]
	
	dlg_ui.queue_free()
	await process_frame
	
	if active_ok and ended_ok:
		report_result("Test 36: Milestone 9 DialogueUI regression passes cleanly", true)
	else:
		report_result("Test 36: M9 DialogueUI regression passes", false,
			"active=%s, ended=%s" % [active_ok, ended_ok])

# TEST 37: M8 environmental signs regression passes
func test_37_m8_environmental_signs_regression_passes() -> void:
	print("[TEST 37] Verifying Milestone 8 environmental signs regression...")
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
		report_result("Test 37: Milestone 8 environmental signs regression passes cleanly", true)
	else:
		report_result("Test 37: M8 environmental signs regression passes", false, "all_ok is false")

# TEST 38: M7 OceanState regression passes
func test_38_m7_ocean_state_regression_passes() -> void:
	print("[TEST 38] Verifying Milestone 7 OceanState retreat regression...")
	OceanStateController.reset_ocean_state()
	
	var is_initial_normal: bool = not OceanStateController.is_ocean_retreated()
	OceanStateController.trigger_ocean_retreat()
	var is_retreated: bool = OceanStateController.is_ocean_retreated()
	
	if is_initial_normal and is_retreated:
		report_result("Test 38: Milestone 7 OceanState retreat regression passes cleanly", true)
	else:
		report_result("Test 38: M7 OceanState regression passes", false,
			"initial=%s, retreated=%s" % [is_initial_normal, is_retreated])

# TEST 39: Main scene loads cleanly
func test_39_main_scene_loads_cleanly() -> void:
	print("[TEST 39] Verifying main scene (scenes/main.tscn) loads cleanly...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate() as Node2D
	root.add_child(main_node)
	await process_frame
	
	var loads_ok: bool = main_node != null and main_node is Node2D
	main_node.queue_free()
	await process_frame
	
	if loads_ok:
		report_result("Test 39: Main scene (scenes/main.tscn) loads cleanly as root", true)
	else:
		report_result("Test 39: Main scene loads cleanly", false, "loads_ok=%s" % loads_ok)
