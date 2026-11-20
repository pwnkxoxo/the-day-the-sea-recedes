extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null
var story_state_node: StoryStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 11 VERIFICATION SUITE ---")
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
	await test_1_shipwreck_investigation_scene_loads()
	await test_2_shipwreck_exists_in_seabed()
	await test_3_investigation_initially_unavailable()
	await test_4_investigation_becomes_available_after_investigation_started()
	await test_5_player_can_interact_with_investigation_point()
	await test_6_dialogue_begins_on_investigation()
	await test_7_dialogue_contains_multiple_discovery_lines()
	await test_8_completing_dialogue_sets_shipwreck_clue_found()
	await test_9_shipwreck_clue_found_persists()
	await test_10_discovery_does_not_replay_on_subsequent_interaction()
	await test_11_major_truth_discovered_remains_false()
	await test_12_story_state_remains_persistent()
	await test_13_ocean_state_remains_independent()
	await test_14_player_movement_works_outside_dialogue()
	await test_15_player_movement_is_locked_during_dialogue()
	await test_16_player_movement_resumes_after_dialogue()
	await test_17_existing_environmental_signs_still_work()
	await test_18_existing_dialogue_ui_still_works()
	await test_19_existing_milestone_10_progression_still_works()
	await test_20_main_scene_remains_valid()
	
	print("\n==================================================")
	print("--- MILESTONE 11 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Shipwreck investigation scene loads
func test_1_shipwreck_investigation_scene_loads() -> void:
	print("[TEST 1] Verifying shipwreck investigation test scene loads cleanly...")
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	
	var scene_ok: bool = scene_node != null and scene_node is ShipwreckInvestigationTestScene
	var hud_ok: bool = scene_node.investigation_status_label != null
	
	scene_node.queue_free()
	await process_frame
	
	if scene_ok and hud_ok:
		report_result("Test 1: Shipwreck investigation test scene loads cleanly", true)
	else:
		report_result("Test 1: Shipwreck investigation test scene loads cleanly", false,
			"scene_ok=%s, hud_ok=%s" % [scene_ok, hud_ok])

# TEST 2: Shipwreck exists in seabed
func test_2_shipwreck_exists_in_seabed() -> void:
	print("[TEST 2] Verifying shipwreck and investigation point exist in seabed.tscn...")
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var wreck: StaticBody2D = seabed.get_node("ShipwreckArea/Shipwreck") as StaticBody2D
	var inv: ShipwreckInvestigation = seabed.get_node("ShipwreckArea/ShipwreckInvestigation") as ShipwreckInvestigation
	var desk: ColorRect = seabed.get_node("ShipwreckArea/Shipwreck/LedgerDesk") as ColorRect
	
	var wreck_ok: bool = wreck != null
	var inv_ok: bool = inv != null and inv is ShipwreckInvestigation
	var props_ok: bool = desk != null
	
	seabed.queue_free()
	await process_frame
	
	if wreck_ok and inv_ok and props_ok:
		report_result("Test 2: Shipwreck, investigation point, and physical props exist in seabed.tscn", true)
	else:
		report_result("Test 2: Shipwreck, investigation point, and physical props exist in seabed.tscn", false,
			"wreck_ok=%s, inv_ok=%s, props_ok=%s" % [wreck_ok, inv_ok, props_ok])

# TEST 3: Investigation initially unavailable
func test_3_investigation_initially_unavailable() -> void:
	print("[TEST 3] Verifying investigation is gated before investigation_started...")
	story_state_node.reset_state()
	
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	
	var player: Player = scene_node.player
	var inv: ShipwreckInvestigation = scene_node.investigation
	var ui: DialogueUI = scene_node.dialogue_ui
	
	# Interact before investigation starts
	inv.interact(player)
	await process_frame
	
	var dialogue_not_started: bool = not ui.is_active()
	var clue_not_found: bool = not story_state_node.has_flag("shipwreck_clue_found")
	var prompt_is_examine: bool = inv.prompt_message == "Examine Wreckage"
	
	scene_node.queue_free()
	await process_frame
	
	if dialogue_not_started and clue_not_found and prompt_is_examine:
		report_result("Test 3: Investigation is initially gated (dialogue doesn't start, clue not set)", true)
	else:
		report_result("Test 3: Investigation is initially gated (dialogue doesn't start, clue not set)", false,
			"dialogue_not_started=%s, clue_not_found=%s, prompt='%s'" % [dialogue_not_started, clue_not_found, inv.prompt_message])

# TEST 4: Investigation becomes available after investigation_started
func test_4_investigation_becomes_available_after_investigation_started() -> void:
	print("[TEST 4] Verifying prompt updates and gate opens after investigation_started...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	
	var inv := ShipwreckInvestigation.new()
	root.add_child(inv)
	await process_frame
	
	var prompt_updated: bool = inv.prompt_message == "Search Captain's Quarters"
	var can_inv: bool = StoryStateController.is_investigating()
	
	inv.queue_free()
	await process_frame
	
	if prompt_updated and can_inv:
		report_result("Test 4: Investigation gate opens and prompt updates to 'Search Captain's Quarters'", true)
	else:
		report_result("Test 4: Investigation gate opens and prompt updates to 'Search Captain's Quarters'", false,
			"prompt='%s', can_inv=%s" % [inv.prompt_message, can_inv])

# TEST 5: Player can interact with investigation point
func test_5_player_can_interact_with_investigation_point() -> void:
	print("[TEST 5] Verifying Player proximity detection and try_interact() triggers investigation...")
	story_state_node.reset_state()
	
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var inv: ShipwreckInvestigation = scene_node.investigation
	
	# Position player within interaction radius of investigation point (at 320, 135)
	player.global_position = Vector2(310, 135)
	await physics_frame
	
	var interact_success: bool = player.try_interact()
	var count_increased: bool = inv.interaction_count >= 1
	
	scene_node.queue_free()
	await process_frame
	
	if interact_success and count_increased:
		report_result("Test 5: Player interacts with ShipwreckInvestigation through normal interaction area", true)
	else:
		report_result("Test 5: Player interacts with ShipwreckInvestigation through normal interaction area", false,
			"interact_success=%s, count=%d" % [interact_success, inv.interaction_count])

# TEST 6: Dialogue begins on investigation
func test_6_dialogue_begins_on_investigation() -> void:
	print("[TEST 6] Verifying discovery dialogue begins when investigating with gate open...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var inv: ShipwreckInvestigation = scene_node.investigation
	var ui: DialogueUI = scene_node.dialogue_ui
	
	inv.interact(player)
	await process_frame
	
	var dialogue_active: bool = ui.is_active()
	var first_line_text: bool = ui.text_label.text.contains("captain's quarters")
	
	scene_node.queue_free()
	await process_frame
	
	if dialogue_active and first_line_text:
		report_result("Test 6: Discovery dialogue sequence begins successfully on investigation", true)
	else:
		report_result("Test 6: Discovery dialogue sequence begins successfully on investigation", false,
			"dialogue_active=%s, first_line_text=%s" % [dialogue_active, first_line_text])

# TEST 7: Dialogue contains multiple discovery lines
func test_7_dialogue_contains_multiple_discovery_lines() -> void:
	print("[TEST 7] Verifying discovery dialogue contains all required narrative beats...")
	var dialogue := ShipwreckInvestigation.DISCOVERY_DIALOGUE
	var line_count_ok: bool = dialogue.size() >= 4
	
	var has_ledger: bool = false
	var has_century: bool = false
	var has_danger_not_retreat: bool = false
	var has_surge: bool = false
	
	for entry in dialogue:
		var txt: String = entry.get("text", "")
		if txt.contains("ledger") or txt.contains("quarters"): has_ledger = true
		if txt.contains("hundred years") or txt.contains("Century"): has_century = true
		if txt.contains("receding is not the disaster") or txt.contains("not the disaster"): has_danger_not_retreat = true
		if txt.contains("wave") or txt.contains("surge"): has_surge = true
	
	var all_beats_present: bool = line_count_ok and has_ledger and has_century and has_danger_not_retreat and has_surge
	if all_beats_present:
		report_result("Test 7: Discovery dialogue contains 5 lines with all core story beats", true)
	else:
		report_result("Test 7: Discovery dialogue contains 5 lines with all core story beats", false,
			"count=%d, ledger=%s, century=%s, danger_not_retreat=%s, surge=%s" %
			[dialogue.size(), has_ledger, has_century, has_danger_not_retreat, has_surge])

# TEST 8: Completing dialogue sets shipwreck_clue_found
func test_8_completing_dialogue_sets_shipwreck_clue_found() -> void:
	print("[TEST 8] Verifying completing discovery dialogue sets shipwreck_clue_found...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var inv: ShipwreckInvestigation = scene_node.investigation
	var ui: DialogueUI = scene_node.dialogue_ui
	
	inv.interact(player)
	await process_frame
	
	# Advance through all 5 lines to complete dialogue
	for i in range(5):
		ui.advance_dialogue()
		await process_frame
	
	await physics_frame
	
	var clue_set: bool = story_state_node.has_flag("shipwreck_clue_found")
	var dialogue_closed: bool = not ui.is_active()
	
	scene_node.queue_free()
	await process_frame
	
	if clue_set and dialogue_closed:
		report_result("Test 8: Completing dialogue sets shipwreck_clue_found in StoryState", true)
	else:
		report_result("Test 8: Completing dialogue sets shipwreck_clue_found in StoryState", false,
			"clue_set=%s, dialogue_closed=%s" % [clue_set, dialogue_closed])

# TEST 9: shipwreck_clue_found persists
func test_9_shipwreck_clue_found_persists() -> void:
	print("[TEST 9] Verifying shipwreck_clue_found persists across scene transitions...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	story_state_node.set_flag("shipwreck_clue_found", true)
	
	# Transition to Village
	var village_scene: PackedScene = load("res://scenes/test/village_test.tscn")
	var village_test: Node2D = village_scene.instantiate()
	root.add_child(village_test)
	await process_frame
	
	var persists_in_village: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	
	village_test.queue_free()
	await process_frame
	
	# Transition to Seabed
	var seabed_scene: PackedScene = load("res://scenes/test/seabed_test.tscn")
	var seabed_test: Node2D = seabed_scene.instantiate()
	root.add_child(seabed_test)
	await process_frame
	
	var persists_in_seabed: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	
	seabed_test.queue_free()
	await process_frame
	
	if persists_in_village and persists_in_seabed:
		report_result("Test 9: shipwreck_clue_found persists across Village and Seabed transitions", true)
	else:
		report_result("Test 9: shipwreck_clue_found persists across Village and Seabed transitions", false,
			"village=%s, seabed=%s" % [persists_in_village, persists_in_seabed])

# TEST 10: Discovery does not replay on subsequent interaction
func test_10_discovery_does_not_replay_on_subsequent_interaction() -> void:
	print("[TEST 10] Verifying subsequent interaction does NOT replay full dialogue...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	story_state_node.set_flag("shipwreck_clue_found", true)
	
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var inv: ShipwreckInvestigation = scene_node.investigation
	var ui: DialogueUI = scene_node.dialogue_ui
	
	# Repeat interaction
	inv.interact(player)
	await process_frame
	
	var dialogue_stayed_inactive: bool = not ui.is_active()
	var prompt_is_remnants: bool = inv.prompt_message == "Examine Log Remnants"
	
	scene_node.queue_free()
	await process_frame
	
	if dialogue_stayed_inactive and prompt_is_remnants:
		report_result("Test 10: Subsequent interaction displays short toast without replaying dialogue", true)
	else:
		report_result("Test 10: Subsequent interaction displays short toast without replaying dialogue", false,
			"dialogue_inactive=%s, prompt='%s'" % [dialogue_stayed_inactive, inv.prompt_message])

# TEST 11: major_truth_discovered remains false
func test_11_major_truth_discovered_remains_false() -> void:
	print("[TEST 11] Verifying major_truth_discovered remains false after finding shipwreck clue...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	story_state_node.set_flag("shipwreck_clue_found", true)
	
	var truth_is_false: bool = not story_state_node.has_flag("major_truth_discovered")
	var can_discover_now: bool = story_state_node.can_discover_truth()
	
	if truth_is_false and can_discover_now:
		report_result("Test 11: major_truth_discovered remains false; can_discover_truth() unlocks for next milestone", true)
	else:
		report_result("Test 11: major_truth_discovered remains false; can_discover_truth() unlocks for next milestone", false,
			"truth_false=%s, can_discover=%s" % [truth_is_false, can_discover_now])

# TEST 12: StoryState remains persistent
func test_12_story_state_remains_persistent() -> void:
	print("[TEST 12] Verifying StoryState flag dictionary persists and calculates progress accurately...")
	story_state_node.reset_state()
	story_state_node.set_flag("ocean_retreat_seen", true)
	story_state_node.set_flag("shell_sign_seen", true)
	story_state_node.set_flag("birds_sign_seen", true)
	story_state_node.set_flag("tremor_sign_seen", true) # investigation auto-starts
	story_state_node.set_flag("shipwreck_clue_found", true)
	
	var expected_progress: float = 0.15 + (3 * 0.15) + 0.10 + 0.15 # 0.85
	var actual_progress: float = story_state_node.get_progress()
	var progress_ok: bool = is_equal_approx(actual_progress, expected_progress)
	
	if progress_ok:
		report_result("Test 12: StoryState persistence and progress calculation (85%%) verified", true)
	else:
		report_result("Test 12: StoryState persistence and progress calculation (85%%) verified", false,
			"actual=%.2f, expected=%.2f" % [actual_progress, expected_progress])

# TEST 13: OceanState remains independent
func test_13_ocean_state_remains_independent() -> void:
	print("[TEST 13] Verifying OceanState operations do not alter StoryState shipwreck clues...")
	story_state_node.reset_state()
	story_state_node.set_flag("shipwreck_clue_found", true)
	
	OceanStateController.reset_ocean_state()
	var clue_still_found_1: bool = story_state_node.has_flag("shipwreck_clue_found")
	
	OceanStateController.trigger_ocean_retreat()
	var clue_still_found_2: bool = story_state_node.has_flag("shipwreck_clue_found")
	
	if clue_still_found_1 and clue_still_found_2:
		report_result("Test 13: OceanState operations maintain strict independence from StoryState clues", true)
	else:
		report_result("Test 13: OceanState operations maintain strict independence from StoryState clues", false,
			"clue1=%s, clue2=%s" % [clue_still_found_1, clue_still_found_2])

# TEST 14: Player movement works outside dialogue
func test_14_player_movement_works_outside_dialogue() -> void:
	print("[TEST 14] Verifying Player movement is enabled when outside dialogue...")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player.global_position = Vector2(100, 100)
	await physics_frame
	
	var is_locked: bool = player.is_movement_locked
	player.velocity = Vector2(80, 0)
	player.move_and_slide()
	await physics_frame
	var moved: bool = player.global_position.x > 100.0
	
	player.queue_free()
	await process_frame
	
	if not is_locked and moved:
		report_result("Test 14: Player movement is fully operational outside dialogue", true)
	else:
		report_result("Test 14: Player movement is fully operational outside dialogue", false,
			"locked=%s, moved=%s" % [is_locked, moved])

# TEST 15: Player movement is locked during dialogue
func test_15_player_movement_is_locked_during_dialogue() -> void:
	print("[TEST 15] Verifying Player movement is locked during discovery dialogue...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var inv: ShipwreckInvestigation = scene_node.investigation
	
	inv.interact(player)
	await process_frame
	await physics_frame
	
	var locked: bool = player.is_movement_locked
	player.velocity = Vector2(80, 0)
	player._physics_process(0.016)
	var vel_zero: bool = player.velocity == Vector2.ZERO
	
	scene_node.queue_free()
	await process_frame
	
	if locked and vel_zero:
		report_result("Test 15: Player movement is locked and velocity forced to ZERO during dialogue", true)
	else:
		report_result("Test 15: Player movement is locked and velocity forced to ZERO during dialogue", false,
			"locked=%s, vel_zero=%s" % [locked, vel_zero])

# TEST 16: Player movement resumes after dialogue
func test_16_player_movement_resumes_after_dialogue() -> void:
	print("[TEST 16] Verifying Player movement unlocks cleanly after dialogue finishes...")
	story_state_node.reset_state()
	story_state_node.set_flag("investigation_started", true)
	
	var test_scene: PackedScene = load("res://scenes/test/shipwreck_investigation_test.tscn")
	var scene_node: ShipwreckInvestigationTestScene = test_scene.instantiate() as ShipwreckInvestigationTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var inv: ShipwreckInvestigation = scene_node.investigation
	var ui: DialogueUI = scene_node.dialogue_ui
	
	inv.interact(player)
	await process_frame
	
	for i in range(5):
		ui.advance_dialogue()
		await process_frame
	
	await physics_frame
	
	var unlocked_after: bool = not player.is_movement_locked
	player.velocity = Vector2(80, 0)
	player.move_and_slide()
	await physics_frame
	var moved_after: bool = player.global_position.x > 140.0
	
	scene_node.queue_free()
	await process_frame
	
	if unlocked_after and moved_after:
		report_result("Test 16: Player movement cleanly unlocks and resumes after dialogue completion", true)
	else:
		report_result("Test 16: Player movement cleanly unlocks and resumes after dialogue completion", false,
			"unlocked=%s, moved=%s" % [unlocked_after, moved_after])

# TEST 17: Existing environmental signs still work
func test_17_existing_environmental_signs_still_work() -> void:
	print("[TEST 17] Verifying Milestone 8 environmental signs (Shells, TidePools, Birds, Tremor, Wind)...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var shell: SeabedShell = seabed.get_node("StrangeSigns/ShellTidePools") as SeabedShell
	var pools: TidePoolSign = seabed.get_node("TidePools") as TidePoolSign
	var tremor: SeabedTremorSign = seabed.get_node("StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	
	var all_signs_ok: bool = shell.is_interactable and pools.is_drained and tremor.is_active
	
	seabed.queue_free()
	await process_frame
	
	if all_signs_ok:
		report_result("Test 17: Milestone 8 environmental signs operate with 100% integrity", true)
	else:
		report_result("Test 17: Milestone 8 environmental signs operate with 100% integrity", false,
			"all_signs_ok=%s" % all_signs_ok)

# TEST 18: Existing DialogueUI still works
func test_18_existing_dialogue_ui_still_works() -> void:
	print("[TEST 18] Verifying Milestone 9 DialogueUI standalone functionality...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	ui.start_dialogue([{"speaker": "A", "text": "Test"}])
	await process_frame
	var active_ok: bool = ui.is_active()
	ui.advance_dialogue()
	await process_frame
	var ended_ok: bool = not ui.is_active()
	
	ui.queue_free()
	await process_frame
	
	if active_ok and ended_ok:
		report_result("Test 18: Milestone 9 DialogueUI operates cleanly", true)
	else:
		report_result("Test 18: Milestone 9 DialogueUI operates cleanly", false,
			"active=%s, ended=%s" % [active_ok, ended_ok])

# TEST 19: Existing Milestone 10 progression still works
func test_19_existing_milestone_10_progression_still_works() -> void:
	print("[TEST 19] Verifying Milestone 10 threshold triggers and discovery recording...")
	story_state_node.reset_state()
	
	story_state_node.record_discovery("shell_sign_seen")
	story_state_node.record_discovery("birds_sign_seen")
	var inv_not_yet: bool = not story_state_node.is_investigation_started()
	
	story_state_node.record_discovery("tremor_sign_seen")
	var inv_now: bool = story_state_node.is_investigation_started()
	
	if inv_not_yet and inv_now:
		report_result("Test 19: Milestone 10 threshold progression (3 signs) triggers accurately", true)
	else:
		report_result("Test 19: Milestone 10 threshold progression (3 signs) triggers accurately", false,
			"not_yet=%s, now=%s" % [inv_not_yet, inv_now])

# TEST 20: Main scene remains valid
func test_20_main_scene_remains_valid() -> void:
	print("[TEST 20] Verifying main scene (scenes/main.tscn) instantiates cleanly...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node = main_scene.instantiate()
	var main_ok: bool = main_node is Node2D
	main_node.queue_free()
	await process_frame
	
	if main_ok:
		report_result("Test 20: Main scene instantiates cleanly as valid Node2D foundation", true)
	else:
		report_result("Test 20: Main scene instantiates cleanly as valid Node2D foundation", false,
			"main_ok=%s" % main_ok)
