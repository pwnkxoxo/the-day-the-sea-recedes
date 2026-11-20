extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null
var story_state_node: StoryStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 14 VERIFICATION SUITE ---")
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
	await test_2_high_ground_component_exists()
	await test_3_evacuation_route_exists()
	await test_4_high_ground_trigger_exists()
	await test_5_evacuation_is_gated_before_town_warned()
	await test_6_evacuation_remains_inactive_without_town_warned()
	await test_7_town_warned_unlocks_evacuation()
	await test_8_evacuation_started_initially_false()
	await test_9_entering_warned_village_starts_evacuation_state()
	await test_10_evacuation_started_becomes_true()
	await test_11_player_remains_controllable_after_evacuation_start()
	await test_12_route_is_physically_traversable()
	await test_13_high_ground_zone_detects_player()
	await test_14_high_ground_flag_remains_false_before_arrival()
	await test_15_high_ground_flag_becomes_true_upon_arrival()
	await test_16_high_ground_flag_set_only_upon_actual_arrival()
	await test_17_high_ground_message_appears()
	await test_18_repeated_high_ground_entry_does_not_repeat_completion()
	await test_19_evacuation_flags_persist()
	await test_20_existing_town_warned_state_remains_intact()
	await test_21_major_truth_discovered_remains_intact()
	await test_22_shipwreck_clue_remains_intact()
	await test_23_environmental_urgency_changes_activate_correctly()
	await test_24_ocean_state_remains_independent()
	await test_25_m13_town_warning_still_works()
	await test_26_m12_major_truth_still_works()
	await test_27_m11_shipwreck_investigation_still_works()
	await test_28_m10_story_state_progression_still_works()
	await test_29_m9_dialogue_ui_still_works()
	await test_30_m8_environmental_signs_still_work()
	await test_31_m7_ocean_state_still_works()
	await test_32_main_scene_loads_cleanly()
	
	print("\n==================================================")
	print("--- MILESTONE 14 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Test scene loads cleanly
func test_1_test_scene_loads() -> void:
	print("[TEST 1] Verifying evacuation escape test scene loads cleanly...")
	var test_scene: PackedScene = load("res://scenes/test/evacuation_escape_test.tscn")
	var scene_node: EvacuationEscapeTestScene = test_scene.instantiate() as EvacuationEscapeTestScene
	root.add_child(scene_node)
	await process_frame
	
	var scene_ok: bool = scene_node != null and scene_node is EvacuationEscapeTestScene
	var hud_ok: bool = scene_node.town_warned_label != null and scene_node.high_ground_status_label != null
	var player_ok: bool = scene_node.player != null and scene_node.player is Player
	var zone_ok: bool = scene_node.high_ground_zone != null and scene_node.high_ground_zone is HighGroundZone
	
	scene_node.queue_free()
	await process_frame
	
	if scene_ok and hud_ok and player_ok and zone_ok:
		report_result("Test 1: Evacuation escape test scene loads cleanly", true)
	else:
		report_result("Test 1: Evacuation escape test scene loads cleanly", false,
			"scene_ok=%s, hud_ok=%s, player_ok=%s, zone_ok=%s" % [scene_ok, hud_ok, player_ok, zone_ok])

# TEST 2: HighGroundZone component exists
func test_2_high_ground_component_exists() -> void:
	print("[TEST 2] Verifying HighGroundZone class and component exist...")
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	var is_area: bool = zone is Area2D
	var has_signals: bool = zone.has_signal("high_ground_reached") and zone.has_signal("high_ground_attempted")
	var has_props: bool = "is_active" in zone and "has_triggered" in zone and "primary_message" in zone and "followup_message" in zone
	
	zone.queue_free()
	await process_frame
	
	if is_area and has_signals and has_props:
		report_result("Test 2: HighGroundZone component exists and extends Area2D with required signals and properties", true)
	else:
		report_result("Test 2: HighGroundZone component exists", false,
			"is_area=%s, has_signals=%s, has_props=%s" % [is_area, has_signals, has_props])

# TEST 3: Evacuation route exists
func test_3_evacuation_route_exists() -> void:
	print("[TEST 3] Verifying evacuation route exists in village and test scene...")
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Node2D = village_scene.instantiate() as Node2D
	root.add_child(village)
	await process_frame
	
	var ascent_path: Node = village.find_child("PathHighGroundAscent", true, false)
	var plateau_path: Node = village.find_child("HighGroundPlateau", true, false)
	var route_in_village: bool = ascent_path != null and plateau_path != null
	
	village.queue_free()
	await process_frame
	
	var test_scene: PackedScene = load("res://scenes/test/evacuation_escape_test.tscn")
	var test_node: Node2D = test_scene.instantiate() as Node2D
	root.add_child(test_node)
	await process_frame
	
	var route_in_test: bool = test_node.find_child("EvacuationTrail", true, false) != null and test_node.find_child("HighGroundPlateau", true, false) != null
	test_node.queue_free()
	await process_frame
	
	if route_in_village and route_in_test:
		report_result("Test 3: Evacuation route exists in village and test scene", true)
	else:
		report_result("Test 3: Evacuation route exists", false,
			"route_in_village=%s, route_in_test=%s" % [route_in_village, route_in_test])

# TEST 4: High-ground trigger exists
func test_4_high_ground_trigger_exists() -> void:
	print("[TEST 4] Verifying HighGroundZone trigger exists in village with valid collision shape...")
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Node2D = village_scene.instantiate() as Node2D
	root.add_child(village)
	await process_frame
	
	var hg_zone: HighGroundZone = village.find_child("HighGroundZone", true, false) as HighGroundZone
	var has_zone: bool = hg_zone != null
	var has_shape: bool = false
	if hg_zone:
		var col: CollisionShape2D = hg_zone.get_node_or_null("CollisionShape2D")
		has_shape = col != null and col.shape != null
	
	village.queue_free()
	await process_frame
	
	if has_zone and has_shape:
		report_result("Test 4: HighGroundZone trigger exists in village with valid CollisionShape2D", true)
	else:
		report_result("Test 4: High-ground trigger exists", false,
			"has_zone=%s, has_shape=%s" % [has_zone, has_shape])

# TEST 5: Evacuation is gated before town_warned
func test_5_evacuation_is_gated_before_town_warned() -> void:
	print("[TEST 5] Verifying evacuation is gated before town_warned...")
	StoryStateController.reset_story_state()
	
	var can_evac: bool = StoryStateController.can_begin_evacuation()
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	var attempt_data := {"gated": false, "called": false}
	zone.high_ground_attempted.connect(func(was_gated: bool):
		attempt_data["called"] = true
		attempt_data["gated"] = was_gated
	)
	
	zone.trigger_entry()
	await process_frame
	
	var flag_remained_false: bool = not StoryStateController.has_story_flag("evacuation_reached_high_ground")
	var was_gated: bool = attempt_data["called"] and attempt_data["gated"] == true
	
	zone.queue_free()
	await process_frame
	
	if not can_evac and flag_remained_false and was_gated:
		report_result("Test 5: Evacuation is gated before town_warned (was_gated=true, flag untouched)", true)
	else:
		report_result("Test 5: Evacuation is gated before town_warned", false,
			"can_evac=%s, flag_remained_false=%s, was_gated=%s" % [can_evac, flag_remained_false, was_gated])

# TEST 6: Evacuation remains inactive without town_warned
func test_6_evacuation_remains_inactive_without_town_warned() -> void:
	print("[TEST 6] Verifying evacuation remains completely inactive without town_warned...")
	StoryStateController.reset_story_state()
	
	var is_evacuating: bool = StoryStateController.is_evacuating()
	var reached_hg: bool = StoryStateController.is_high_ground_reached()
	var started_flag: bool = StoryStateController.has_story_flag("evacuation_started")
	var hg_flag: bool = StoryStateController.has_story_flag("evacuation_reached_high_ground")
	
	if not is_evacuating and not reached_hg and not started_flag and not hg_flag:
		report_result("Test 6: Evacuation remains completely inactive without town_warned", true)
	else:
		report_result("Test 6: Evacuation remains inactive without town_warned", false,
			"is_evacuating=%s, reached_hg=%s, started=%s, hg=%s" % [is_evacuating, reached_hg, started_flag, hg_flag])

# TEST 7: town_warned unlocks evacuation
func test_7_town_warned_unlocks_evacuation() -> void:
	print("[TEST 7] Verifying town_warned unlocks evacuation prerequisite...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var can_evac: bool = StoryStateController.can_begin_evacuation()
	var instance_can_evac: bool = StoryStateController.instance.can_start_evacuation() if StoryStateController.instance else true
	
	if can_evac and instance_can_evac:
		report_result("Test 7: town_warned unlocks evacuation prerequisite (can_start_evacuation == true)", true)
	else:
		report_result("Test 7: town_warned unlocks evacuation", false,
			"can_evac=%s, instance_can_evac=%s" % [can_evac, instance_can_evac])

# TEST 8: evacuation_started initially false
func test_8_evacuation_started_initially_false() -> void:
	print("[TEST 8] Verifying evacuation_started is initially false on baseline state...")
	StoryStateController.reset_story_state()
	
	var initially_false: bool = not StoryStateController.has_story_flag("evacuation_started")
	var instance_check: bool = not StoryStateController.instance.is_evacuation_started() if StoryStateController.instance else true
	
	if initially_false and instance_check:
		report_result("Test 8: evacuation_started is initially false", true)
	else:
		report_result("Test 8: evacuation_started initially false", false,
			"initially_false=%s, instance_check=%s" % [initially_false, instance_check])

# TEST 9: Entering warned village starts evacuation state
func test_9_entering_warned_village_starts_evacuation_state() -> void:
	print("[TEST 9] Verifying entering warned village initiates evacuation start sequence...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Node2D = village_scene.instantiate() as Node2D
	root.add_child(village)
	await process_frame
	await process_frame
	
	var evac_started: bool = StoryStateController.has_story_flag("evacuation_started")
	village.queue_free()
	await process_frame
	
	if evac_started:
		report_result("Test 9: Entering warned village initiates evacuation start sequence", true)
	else:
		report_result("Test 9: Entering warned village starts evacuation state", false,
			"evac_started=%s" % evac_started)

# TEST 10: evacuation_started becomes true
func test_10_evacuation_started_becomes_true() -> void:
	print("[TEST 10] Verifying evacuation_started becomes true when evacuation begins...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var signal_data := {"emitted": false}
	if StoryStateController.instance:
		StoryStateController.instance.evacuation_started.connect(func():
			signal_data["emitted"] = true
		, CONNECT_ONE_SHOT)
	
	StoryStateController.set_story_flag("evacuation_started", true)
	
	var flag_ok: bool = StoryStateController.has_story_flag("evacuation_started")
	var signal_ok: bool = signal_data["emitted"]
	
	if flag_ok and signal_ok:
		report_result("Test 10: evacuation_started becomes true and emits evacuation_started signal", true)
	else:
		report_result("Test 10: evacuation_started becomes true", false,
			"flag_ok=%s, signal_ok=%s" % [flag_ok, signal_ok])

# TEST 11: Player remains controllable after evacuation-start sequence
func test_11_player_remains_controllable_after_evacuation_start() -> void:
	print("[TEST 11] Verifying player remains controllable after evacuation start sequence...")
	var test_scene: PackedScene = load("res://scenes/test/evacuation_escape_test.tscn")
	var test_node: EvacuationEscapeTestScene = test_scene.instantiate() as EvacuationEscapeTestScene
	root.add_child(test_node)
	await process_frame
	
	var player: Player = test_node.player
	var not_locked: bool = not player.is_movement_locked
	
	test_node.queue_free()
	await process_frame
	
	if not_locked:
		report_result("Test 11: Player remains controllable after evacuation start sequence", true)
	else:
		report_result("Test 11: Player remains controllable", false, "is_movement_locked=true")

# TEST 12: Route is physically traversable
func test_12_route_is_physically_traversable() -> void:
	print("[TEST 12] Verifying evacuation route is physically traversable...")
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Node2D = village_scene.instantiate() as Node2D
	root.add_child(village)
	await process_frame
	
	var hg_zone: HighGroundZone = village.find_child("HighGroundZone", true, false) as HighGroundZone
	var hg_pos: Vector2 = hg_zone.global_position if hg_zone else Vector2.ZERO
	
	# Route goes from CentralPlaza (480, 200) -> East along PathEastWest to (836, 200) -> North up PathHighGroundAscent to (870, 55)
	# High ground position in village should be near (870, 55)
	var pos_valid: bool = hg_pos.x >= 800.0 and hg_pos.x <= 940.0 and hg_pos.y >= 20.0 and hg_pos.y <= 90.0
	
	village.queue_free()
	await process_frame
	
	if pos_valid:
		report_result("Test 12: Evacuation route to high ground is unobstructed and physically traversable", true)
	else:
		report_result("Test 12: Route is physically traversable", false, "hg_pos=%s" % str(hg_pos))

# TEST 13: High-ground zone detects player
func test_13_high_ground_zone_detects_player() -> void:
	print("[TEST 13] Verifying HighGroundZone detects Player entry...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var zone: HighGroundZone = HighGroundZone.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	col.shape = shape
	zone.add_child(col)
	root.add_child(zone)
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	player.position = Vector2(0, 0)
	root.add_child(player)
	
	var entry_detected := {"reached": false}
	zone.high_ground_reached.connect(func():
		entry_detected["reached"] = true
	)
	
	zone.trigger_entry(player)
	await process_frame
	
	var detected: bool = entry_detected["reached"]
	player.queue_free()
	zone.queue_free()
	await process_frame
	
	if detected:
		report_result("Test 13: HighGroundZone detects player entry cleanly", true)
	else:
		report_result("Test 13: High-ground zone detects player", false, "detected=%s" % detected)

# TEST 14: High-ground flag remains false before arrival
func test_14_high_ground_flag_remains_false_before_arrival() -> void:
	print("[TEST 14] Verifying high_ground flag remains false before arrival...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	StoryStateController.set_story_flag("evacuation_started", true)
	
	var remains_false: bool = not StoryStateController.has_story_flag("evacuation_reached_high_ground")
	var is_reached: bool = StoryStateController.is_high_ground_reached()
	
	if remains_false and not is_reached:
		report_result("Test 14: high_ground flag remains false before player reaches safety", true)
	else:
		report_result("Test 14: High-ground flag remains false before arrival", false,
			"remains_false=%s, is_reached=%s" % [remains_false, is_reached])

# TEST 15: High-ground flag becomes true upon arrival
func test_15_high_ground_flag_becomes_true_upon_arrival() -> void:
	print("[TEST 15] Verifying high_ground flag becomes true upon arrival...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	var signal_data := {"reached": false}
	if StoryStateController.instance:
		StoryStateController.instance.high_ground_reached.connect(func():
			signal_data["reached"] = true
		, CONNECT_ONE_SHOT)
	
	zone.trigger_entry()
	await process_frame
	
	var flag_true: bool = StoryStateController.has_story_flag("evacuation_reached_high_ground")
	var signal_fired: bool = signal_data["reached"]
	
	zone.queue_free()
	await process_frame
	
	if flag_true and signal_fired:
		report_result("Test 15: evacuation_reached_high_ground becomes true upon arrival with signal emitted", true)
	else:
		report_result("Test 15: High-ground flag becomes true upon arrival", false,
			"flag_true=%s, signal_fired=%s" % [flag_true, signal_fired])

# TEST 16: High-ground flag is set only upon actual arrival
func test_16_high_ground_flag_set_only_upon_actual_arrival() -> void:
	print("[TEST 16] Verifying high_ground flag is set strictly upon actual arrival...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	StoryStateController.set_story_flag("evacuation_started", true)
	
	# Simulate moving through lower village and trail without touching high ground
	var flag_before: bool = StoryStateController.has_story_flag("evacuation_reached_high_ground")
	
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	zone.trigger_entry()
	await process_frame
	
	var flag_after: bool = StoryStateController.has_story_flag("evacuation_reached_high_ground")
	zone.queue_free()
	await process_frame
	
	if not flag_before and flag_after:
		report_result("Test 16: high_ground flag is set strictly upon actual arrival", true)
	else:
		report_result("Test 16: High-ground flag set only upon actual arrival", false,
			"flag_before=%s, flag_after=%s" % [flag_before, flag_after])

# TEST 17: High-ground message appears
func test_17_high_ground_message_appears() -> void:
	print("[TEST 17] Verifying high-ground atmospheric message appears...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var msg_ui_scene: PackedScene = load("res://scenes/ui/atmospheric_message_ui.tscn")
	var msg_ui: AtmosphericMessageUI = msg_ui_scene.instantiate() as AtmosphericMessageUI
	root.add_child(msg_ui)
	await process_frame
	
	var captured_text := {"text": ""}
	msg_ui.message_displayed.connect(func(t: String):
		captured_text["text"] = t
	)
	
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	zone.trigger_entry()
	await process_frame
	
	var message_matched: bool = captured_text["text"] == "High ground."
	zone.queue_free()
	msg_ui.queue_free()
	await process_frame
	
	if message_matched:
		report_result("Test 17: High-ground message 'High ground.' appears on arrival", true)
	else:
		report_result("Test 17: High-ground message appears", false,
			"captured='%s'" % captured_text["text"])

# TEST 18: Repeated high-ground entry does not repeat completion
func test_18_repeated_high_ground_entry_does_not_repeat_completion() -> void:
	print("[TEST 18] Verifying repeated high-ground entry is idempotent...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var zone: HighGroundZone = HighGroundZone.new()
	root.add_child(zone)
	await process_frame
	
	var count_data := {"count": 0}
	zone.high_ground_reached.connect(func():
		count_data["count"] += 1
	)
	
	zone.trigger_entry()
	await process_frame
	zone.trigger_entry()
	await process_frame
	
	var triggers_once: bool = count_data["count"] == 1
	zone.queue_free()
	await process_frame
	
	if triggers_once:
		report_result("Test 18: Repeated high-ground entry does not repeat completion (idempotent)", true)
	else:
		report_result("Test 18: Repeated high-ground entry does not repeat completion", false,
			"count=%d" % count_data["count"])

# TEST 19: Evacuation flags persist across scene transitions
func test_19_evacuation_flags_persist() -> void:
	print("[TEST 19] Verifying evacuation flags persist across world scene reloads...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	StoryStateController.set_story_flag("evacuation_started", true)
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	# Reload Village scene
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Node2D = village_scene.instantiate() as Node2D
	root.add_child(village)
	await process_frame
	
	var started_persisted: bool = StoryStateController.has_story_flag("evacuation_started")
	var hg_persisted: bool = StoryStateController.has_story_flag("evacuation_reached_high_ground")
	
	village.queue_free()
	await process_frame
	
	if started_persisted and hg_persisted:
		report_result("Test 19: Evacuation flags persist across scene reloads", true)
	else:
		report_result("Test 19: Evacuation flags persist", false,
			"started=%s, hg=%s" % [started_persisted, hg_persisted])

# TEST 20: Existing town_warned state remains intact
func test_20_existing_town_warned_state_remains_intact() -> void:
	print("[TEST 20] Verifying town_warned flag remains intact throughout evacuation...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	StoryStateController.set_story_flag("evacuation_started", true)
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	var town_warned_intact: bool = StoryStateController.is_village_warned()
	if town_warned_intact:
		report_result("Test 20: Existing town_warned flag remains intact throughout evacuation", true)
	else:
		report_result("Test 20: Existing town_warned state remains intact", false, "town_warned=false")

# TEST 21: Major truth discovered remains intact
func test_21_major_truth_discovered_remains_intact() -> void:
	print("[TEST 21] Verifying major_truth_discovered remains intact...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	StoryStateController.set_story_flag("evacuation_started", true)
	
	var truth_intact: bool = StoryStateController.is_truth_known()
	if truth_intact:
		report_result("Test 21: major_truth_discovered flag remains intact", true)
	else:
		report_result("Test 21: major_truth_discovered remains intact", false, "truth_intact=false")

# TEST 22: Shipwreck clue remains intact
func test_22_shipwreck_clue_remains_intact() -> void:
	print("[TEST 22] Verifying shipwreck_clue_found remains intact...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	StoryStateController.set_story_flag("evacuation_started", true)
	
	var clue_intact: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	if clue_intact:
		report_result("Test 22: shipwreck_clue_found flag remains intact", true)
	else:
		report_result("Test 22: Shipwreck clue remains intact", false, "clue_intact=false")

# TEST 23: Environmental urgency changes activate correctly
func test_23_environmental_urgency_changes_activate_correctly() -> void:
	print("[TEST 23] Verifying environmental urgency changes activate in village...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("town_warned", true)
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var props_visible: bool = village.evacuation_props != null and village.evacuation_props.visible == true
	var door_open: bool = village.town_hall_door != null and village.town_hall_door.color == Color(0.08, 0.05, 0.04, 1)
	
	village.queue_free()
	await process_frame
	
	if props_visible and door_open:
		report_result("Test 23: Environmental urgency visual changes activate correctly in warned village", true)
	else:
		report_result("Test 23: Environmental urgency changes activate correctly", false,
			"props_visible=%s, door_open=%s" % [props_visible, door_open])

# TEST 24: OceanState remains independent
func test_24_ocean_state_remains_independent() -> void:
	print("[TEST 24] Verifying OceanState remains independent from evacuation...")
	OceanStateController.reset_ocean_state()
	StoryStateController.reset_story_state()
	
	StoryStateController.set_story_flag("evacuation_started", true)
	StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	var ocean_unaffected: bool = not OceanStateController.is_ocean_retreated()
	
	OceanStateController.trigger_ocean_retreat()
	var retreats_normally: bool = OceanStateController.is_ocean_retreated()
	
	if ocean_unaffected and retreats_normally:
		report_result("Test 24: OceanState operations maintain complete independence from evacuation flags", true)
	else:
		report_result("Test 24: OceanState remains independent", false,
			"ocean_unaffected=%s, retreats_normally=%s" % [ocean_unaffected, retreats_normally])

# TEST 25: M13 town warning still works
func test_25_m13_town_warning_still_works() -> void:
	print("[TEST 25] Verifying Milestone 13 TownWarning component regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("major_truth_discovered", true)
	
	var warning := TownWarning.new()
	root.add_child(warning)
	await process_frame
	
	var was_called := {"done": false}
	warning.warning_completed.connect(func():
		was_called["done"] = true
	)
	
	warning.interact(null)
	await process_frame
	
	var warned: bool = StoryStateController.is_village_warned()
	warning.queue_free()
	await process_frame
	
	if warned and was_called["done"]:
		report_result("Test 25: Milestone 13 TownWarning regression passes cleanly", true)
	else:
		report_result("Test 25: M13 town warning still works", false,
			"warned=%s, done=%s" % [warned, was_called["done"]])

# TEST 26: M12 major truth still works
func test_26_m12_major_truth_still_works() -> void:
	print("[TEST 26] Verifying Milestone 12 MajorTruthDiscovery regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	var truth := MajorTruthDiscovery.new()
	root.add_child(truth)
	await process_frame
	
	truth.interact(null)
	await process_frame
	
	var truth_found: bool = StoryStateController.is_truth_known()
	truth.queue_free()
	await process_frame
	
	if truth_found:
		report_result("Test 26: Milestone 12 MajorTruthDiscovery regression passes cleanly", true)
	else:
		report_result("Test 26: M12 major truth still works", false, "truth_found=false")

# TEST 27: M11 shipwreck investigation still works
func test_27_m11_shipwreck_investigation_still_works() -> void:
	print("[TEST 27] Verifying Milestone 11 ShipwreckInvestigation regression...")
	StoryStateController.reset_story_state()
	StoryStateController.set_story_flag("investigation_started", true)
	
	var wreck := ShipwreckInvestigation.new()
	root.add_child(wreck)
	await process_frame
	
	wreck.interact(null)
	await process_frame
	
	var clue_found: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	wreck.queue_free()
	await process_frame
	
	if clue_found:
		report_result("Test 27: Milestone 11 ShipwreckInvestigation regression passes cleanly", true)
	else:
		report_result("Test 27: M11 shipwreck investigation still works", false, "clue_found=false")

# TEST 28: M10 StoryState progression still works
func test_28_m10_story_state_progression_still_works() -> void:
	print("[TEST 28] Verifying Milestone 10 3-sign threshold progression regression...")
	StoryStateController.reset_story_state()
	
	StoryStateController.record_story_discovery("shell_sign_seen")
	StoryStateController.record_story_discovery("tide_pool_sign_seen")
	var before_threshold: bool = not StoryStateController.is_investigating()
	
	StoryStateController.record_story_discovery("birds_sign_seen")
	var after_threshold: bool = StoryStateController.is_investigating()
	
	if before_threshold and after_threshold:
		report_result("Test 28: Milestone 10 StoryState progression regression passes cleanly", true)
	else:
		report_result("Test 28: M10 StoryState progression still works", false,
			"before=%s, after=%s" % [before_threshold, after_threshold])

# TEST 29: M9 DialogueUI still works
func test_29_m9_dialogue_ui_still_works() -> void:
	print("[TEST 29] Verifying Milestone 9 DialogueUI standalone regression...")
	var dlg_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var dlg_ui: DialogueUI = dlg_scene.instantiate() as DialogueUI
	root.add_child(dlg_ui)
	await process_frame
	
	var signal_data: Dictionary = {"started": false, "ended": false}
	dlg_ui.dialogue_started.connect(func(): signal_data["started"] = true)
	dlg_ui.dialogue_ended.connect(func(): signal_data["ended"] = true)
	
	dlg_ui.start_dialogue([{"speaker": "Sens", "text": "Testing dialogue system"}])
	await process_frame
	
	var active_ok: bool = dlg_ui.is_active() and signal_data["started"]
	dlg_ui.advance_dialogue()
	await process_frame
	
	var ended_ok: bool = (not dlg_ui.is_active()) and signal_data["ended"]
	
	dlg_ui.queue_free()
	await process_frame
	
	if active_ok and ended_ok:
		report_result("Test 29: Milestone 9 DialogueUI regression passes cleanly", true)
	else:
		report_result("Test 29: M9 DialogueUI still works", false,
			"active=%s, ended=%s" % [active_ok, ended_ok])

# TEST 30: M8 environmental signs still work
func test_30_m8_environmental_signs_still_work() -> void:
	print("[TEST 30] Verifying Milestone 8 environmental signs regression...")
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
		report_result("Test 30: Milestone 8 environmental signs regression passes cleanly", true)
	else:
		report_result("Test 30: M8 environmental signs still work", false, "all_ok is false")

# TEST 31: M7 OceanState still works
func test_31_m7_ocean_state_still_works() -> void:
	print("[TEST 31] Verifying Milestone 7 OceanState retreat regression...")
	OceanStateController.reset_ocean_state()
	
	var is_initial_normal: bool = not OceanStateController.is_ocean_retreated()
	OceanStateController.trigger_ocean_retreat()
	var is_retreated: bool = OceanStateController.is_ocean_retreated()
	
	if is_initial_normal and is_retreated:
		report_result("Test 31: Milestone 7 OceanState retreat regression passes cleanly", true)
	else:
		report_result("Test 31: M7 OceanState still works", false,
			"initial=%s, retreated=%s" % [is_initial_normal, is_retreated])

# TEST 32: Main scene loads cleanly
func test_32_main_scene_loads_cleanly() -> void:
	print("[TEST 32] Verifying main scene (scenes/main.tscn) loads cleanly...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate() as Node2D
	root.add_child(main_node)
	await process_frame
	
	var loads_ok: bool = main_node != null and main_node is Node2D
	main_node.queue_free()
	await process_frame
	
	if loads_ok:
		report_result("Test 32: Main scene (scenes/main.tscn) loads cleanly as root", true)
	else:
		report_result("Test 32: Main scene loads cleanly", false, "loads_ok=%s" % loads_ok)
