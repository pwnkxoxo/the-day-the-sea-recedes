extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 9 VERIFICATION SUITE ---")
	print("==================================================\n")
	# Register OceanState instance for regression checks
	ocean_state_node = OceanStateController.new()
	ocean_state_node.name = "OceanState"
	root.add_child(ocean_state_node)
	call_deferred("_run_all_tests")

func report_result(test_name: String, passed: bool, error_msg: String = "") -> void:
	if passed:
		passed_count += 1
		print("[PASS] %s" % test_name)
	else:
		failed_count += 1
		print("[FAIL] %s: %s" % [test_name, error_msg])

func _run_all_tests() -> void:
	await test_1_dialogue_ui_initialization_and_visibility()
	await test_2_dialogue_start_first_entry_and_signal()
	await test_3_advance_dialogue_line_by_line()
	await test_4_input_advance_with_interact_action()
	await test_5_dialogue_completion_and_closing()
	await test_6_player_movement_locking_and_unlocking()
	await test_7_no_double_trigger_on_dialogue_close()
	await test_8_retrigger_dialogue_cleanly()
	await test_9_static_api_helper()
	await test_10_decoupled_architecture_arbitrary_data()
	await test_11_milestones_7_and_8_regression()
	
	print("\n==================================================")
	print("--- MILESTONE 9 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: DialogueUI initialization and hidden state
func test_1_dialogue_ui_initialization_and_visibility() -> void:
	print("[TEST 1] Verifying DialogueUI initialization and initial hidden state...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var not_active: bool = not ui.is_active()
	var panel_hidden: bool = ui.panel != null and not ui.panel.visible
	var index_zero: bool = ui.get_current_index() == 0
	var instance_set: bool = DialogueUI.instance == ui
	
	ui.queue_free()
	await process_frame
	
	if not_active and panel_hidden and index_zero and instance_set:
		report_result("Test 1: DialogueUI initializes hidden with instance registered and index 0", true)
	else:
		report_result("Test 1: DialogueUI initializes hidden with instance registered and index 0", false,
			"not_active=%s, panel_hidden=%s, index_zero=%s, instance_set=%s" % [not_active, panel_hidden, index_zero, instance_set])

# TEST 2: Dialogue start, first line display, and dialogue_started signal
func test_2_dialogue_start_first_entry_and_signal() -> void:
	print("[TEST 2] Verifying dialogue_started signal and first line population...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var capture := {"started": false}
	ui.dialogue_started.connect(func(): capture.started = true)
	
	var test_entries := [
		{"speaker": "Elder", "text": "The ocean has receded."},
		{"speaker": "Elder", "text": "Do not linger on the sand."}
	]
	
	ui.start_dialogue(test_entries)
	await process_frame
	
	var is_active: bool = ui.is_active()
	var panel_visible: bool = ui.panel.visible
	var speaker_ok: bool = ui.speaker_label.text == "Elder" and ui.speaker_label.visible
	var text_ok: bool = ui.text_label.text == "The ocean has receded."
	var signal_ok: bool = capture.started
	
	ui.queue_free()
	await process_frame
	
	if is_active and panel_visible and speaker_ok and text_ok and signal_ok:
		report_result("Test 2: start_dialogue displays first entry and emits dialogue_started", true)
	else:
		report_result("Test 2: start_dialogue displays first entry and emits dialogue_started", false,
			"active=%s, visible=%s, speaker_ok=%s, text_ok=%s, signal_ok=%s" % [is_active, panel_visible, speaker_ok, text_ok, signal_ok])

# TEST 3: Sequential advance line-by-line and line_advanced signal
func test_3_advance_dialogue_line_by_line() -> void:
	print("[TEST 3] Verifying sequential line advance and line_advanced signal...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var advanced_indices: Array[int] = []
	ui.line_advanced.connect(func(idx: int): advanced_indices.append(idx))
	
	var test_entries := [
		{"speaker": "Test Character", "text": "This is the first dialogue line."},
		{"speaker": "Test Character", "text": "This is the second dialogue line."},
		{"speaker": "Test Character", "text": "Dialogue system working."}
	]
	
	ui.start_dialogue(test_entries)
	await process_frame
	
	# Advance to Line 2 (index 1)
	ui.advance_dialogue()
	await process_frame
	var line2_ok: bool = ui.get_current_index() == 1 and ui.text_label.text == "This is the second dialogue line."
	
	# Advance to Line 3 (index 2)
	ui.advance_dialogue()
	await process_frame
	var line3_ok: bool = ui.get_current_index() == 2 and ui.text_label.text == "Dialogue system working."
	
	var signals_ok: bool = advanced_indices == [1, 2]
	
	ui.queue_free()
	await process_frame
	
	if line2_ok and line3_ok and signals_ok:
		report_result("Test 3: Sequential advance updates content and emits line_advanced accurately", true)
	else:
		report_result("Test 3: Sequential advance updates content and emits line_advanced accurately", false,
			"line2_ok=%s, line3_ok=%s, signals_ok=%s (indices=%s)" % [line2_ok, line3_ok, signals_ok, advanced_indices])

# TEST 4: Input event advance via 'interact' action with echo rejection
func test_4_input_advance_with_interact_action() -> void:
	print("[TEST 4] Verifying interact input action advances single line without echo skipping...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var test_entries := [
		{"speaker": "Sign", "text": "Line 1"},
		{"speaker": "Sign", "text": "Line 2"},
		{"speaker": "Sign", "text": "Line 3"}
	]
	
	ui.start_dialogue(test_entries)
	# Advance a frame so _started_on_frame guard does not suppress input
	await process_frame
	
	# Create simulated 'interact' press event (E key)
	var ev_press := InputEventKey.new()
	ev_press.physical_keycode = KEY_E
	ev_press.keycode = KEY_E
	ev_press.pressed = true
	ev_press.echo = false
	
	# Send press event
	ui._unhandled_input(ev_press)
	await process_frame
	var advanced_to_1: bool = ui.get_current_index() == 1
	
	# Create simulated echo event (holding key down)
	var ev_echo := InputEventKey.new()
	ev_echo.physical_keycode = KEY_E
	ev_echo.keycode = KEY_E
	ev_echo.pressed = true
	ev_echo.echo = true
	
	# Send echo event - should be ignored!
	ui._unhandled_input(ev_echo)
	await process_frame
	var stayed_at_1: bool = ui.get_current_index() == 1
	
	# Send release event
	var ev_release := InputEventKey.new()
	ev_release.physical_keycode = KEY_E
	ev_release.keycode = KEY_E
	ev_release.pressed = false
	ev_release.echo = false
	ui._unhandled_input(ev_release)
	await process_frame
	var still_at_1: bool = ui.get_current_index() == 1
	
	# Send Space press event to advance to Line 3 (index 2)
	var ev_space := InputEventKey.new()
	ev_space.physical_keycode = KEY_SPACE
	ev_space.keycode = KEY_SPACE
	ev_space.pressed = true
	ev_space.echo = false
	ui._unhandled_input(ev_space)
	await process_frame
	var advanced_to_2: bool = ui.get_current_index() == 2
	
	ui.queue_free()
	await process_frame
	
	if advanced_to_1 and stayed_at_1 and still_at_1 and advanced_to_2:
		report_result("Test 4: Input event advances exactly one line per press; echo hold rejected", true)
	else:
		report_result("Test 4: Input event advances exactly one line per press; echo hold rejected", false,
			"adv1=%s, stayed1=%s, still1=%s, adv2=%s" % [advanced_to_1, stayed_at_1, still_at_1, advanced_to_2])

# TEST 5: Dialogue completion and closing
func test_5_dialogue_completion_and_closing() -> void:
	print("[TEST 5] Verifying dialogue completion closes UI and emits dialogue_ended...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var capture := {"ended": false}
	ui.dialogue_ended.connect(func(): capture.ended = true)
	
	var test_entries := [
		{"speaker": "A", "text": "Single line dialogue."}
	]
	
	ui.start_dialogue(test_entries)
	await process_frame
	
	# Advancing past single line triggers end
	ui.advance_dialogue()
	await process_frame
	
	var not_active: bool = not ui.is_active()
	var panel_hidden: bool = not ui.panel.visible
	var ended_emitted: bool = capture.ended
	var index_reset: bool = ui.get_current_index() == 0
	
	ui.queue_free()
	await process_frame
	
	if not_active and panel_hidden and ended_emitted and index_reset:
		report_result("Test 5: Advancing past final line closes UI and emits dialogue_ended", true)
	else:
		report_result("Test 5: Advancing past final line closes UI and emits dialogue_ended", false,
			"not_active=%s, panel_hidden=%s, ended=%s, index_reset=%s" % [not_active, panel_hidden, ended_emitted, index_reset])

# TEST 6: Player movement locking during dialogue and unlocking on close
func test_6_player_movement_locking_and_unlocking() -> void:
	print("[TEST 6] Verifying player movement is locked during dialogue and restored after...")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player.global_position = Vector2(100, 100)
	await physics_frame
	
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	# Start dialogue with player
	ui.start_dialogue([{"speaker": "NPC", "text": "Halt!"}], player)
	await process_frame
	await physics_frame
	
	var locked_initially: bool = player.is_movement_locked
	
	# Simulate physics tick while locked: player velocity should be forced to ZERO
	player.velocity = Vector2(80, 0)
	player._physics_process(0.016)
	var velocity_zero_while_locked: bool = player.velocity == Vector2.ZERO
	var pos_unchanged: bool = player.global_position.is_equal_approx(Vector2(100, 100))
	
	# Advance and finish dialogue
	ui.advance_dialogue()
	await process_frame
	await physics_frame # Allow deferred unlock to execute
	
	var unlocked_after: bool = not player.is_movement_locked
	
	# Test normal movement when unlocked
	player.velocity = Vector2(80, 0)
	player.move_and_slide()
	await physics_frame
	var player_moved: bool = player.global_position.x > 100.0
	
	player.queue_free()
	ui.queue_free()
	await process_frame
	
	if locked_initially and velocity_zero_while_locked and pos_unchanged and unlocked_after and player_moved:
		report_result("Test 6: Player movement cleanly locked during dialogue and restored on completion", true)
	else:
		report_result("Test 6: Player movement cleanly locked during dialogue and restored on completion", false,
			"locked=%s, vel_zero=%s, pos_same=%s, unlocked=%s, moved=%s" %
			[locked_initially, velocity_zero_while_locked, pos_unchanged, unlocked_after, player_moved])

# TEST 7: No double-trigger on dialogue close in DialogueTestScene
func test_7_no_double_trigger_on_dialogue_close() -> void:
	print("[TEST 7] Verifying interact key on final line does not re-trigger world interaction...")
	var test_scene: PackedScene = load("res://scenes/test/dialogue_test.tscn")
	var scene_node: DialogueTestScene = test_scene.instantiate() as DialogueTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var npc: Interactable = scene_node.test_npc
	var ui: DialogueUI = scene_node.dialogue_ui
	
	# Move player next to NPC (NPC is at 240, 135)
	player.global_position = Vector2(225, 135)
	await physics_frame
	
	# Trigger interaction (simulates pressing E near NPC)
	var interact_success: bool = player.try_interact()
	await process_frame
	await physics_frame
	
	var count_after_open: int = scene_node.dialogue_trigger_count
	var is_open: bool = ui.is_active()
	
	# Advance through line 1 -> line 2 -> line 3
	ui.advance_dialogue()
	await process_frame
	ui.advance_dialogue()
	await process_frame
	
	# Advance past line 3 to close dialogue
	var ev_press := InputEventKey.new()
	ev_press.physical_keycode = KEY_E
	ev_press.keycode = KEY_E
	ev_press.pressed = true
	ev_press.echo = false
	ui._unhandled_input(ev_press)
	await process_frame
	await physics_frame
	
	var count_after_close: int = scene_node.dialogue_trigger_count
	var is_closed: bool = not ui.is_active()
	
	scene_node.queue_free()
	await process_frame
	
	var no_double_trigger: bool = (count_after_open == 1) and (count_after_close == 1)
	if interact_success and is_open and is_closed and no_double_trigger:
		report_result("Test 7: Closing dialogue with interact action does NOT re-trigger world object", true)
	else:
		report_result("Test 7: Closing dialogue with interact action does NOT re-trigger world object", false,
			"interact=%s, is_open=%s, is_closed=%s, open_count=%d, close_count=%d" %
			[interact_success, is_open, is_closed, count_after_open, count_after_close])

# TEST 8: Dialogue re-triggering cleanly without stuck state
func test_8_retrigger_dialogue_cleanly() -> void:
	print("[TEST 8] Verifying dialogue can be re-triggered cleanly without state corruption...")
	var test_scene: PackedScene = load("res://scenes/test/dialogue_test.tscn")
	var scene_node: DialogueTestScene = test_scene.instantiate() as DialogueTestScene
	root.add_child(scene_node)
	await process_frame
	await physics_frame
	
	var player: Player = scene_node.player
	var ui: DialogueUI = scene_node.dialogue_ui
	
	# Position near NPC
	player.global_position = Vector2(225, 135)
	await physics_frame
	
	# Cycle 1: Open and complete
	player.try_interact()
	await process_frame
	ui.advance_dialogue()
	ui.advance_dialogue()
	ui.advance_dialogue() # Closes
	await process_frame
	await physics_frame
	
	var closed_1: bool = not ui.is_active()
	
	# Cycle 2: Open again
	player.try_interact()
	await process_frame
	
	var opened_2: bool = ui.is_active()
	var index_reset_2: bool = ui.get_current_index() == 0
	var text_reset_2: bool = ui.text_label.text == "This is the first dialogue line."
	var total_triggers: int = scene_node.dialogue_trigger_count
	
	# Complete cycle 2
	ui.advance_dialogue()
	ui.advance_dialogue()
	ui.advance_dialogue() # Closes
	await process_frame
	await physics_frame
	
	var closed_2: bool = not ui.is_active()
	
	scene_node.queue_free()
	await process_frame
	
	if closed_1 and opened_2 and index_reset_2 and text_reset_2 and total_triggers == 2 and closed_2:
		report_result("Test 8: Dialogue re-triggers cleanly with reset state and no stuck conditions", true)
	else:
		report_result("Test 8: Dialogue re-triggers cleanly with reset state and no stuck conditions", false,
			"c1=%s, o2=%s, idx2=%s, txt2=%s, trig=%d, c2=%s" %
			[closed_1, opened_2, index_reset_2, text_reset_2, total_triggers, closed_2])

# TEST 9: Static helper API (DialogueUI.start / display_dialogue)
func test_9_static_api_helper() -> void:
	print("[TEST 9] Verifying static API helper DialogueUI.start()...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	var test_data := [
		{"speaker": "System", "text": "Static call operational."}
	]
	
	DialogueUI.start(test_data)
	await process_frame
	
	var active_via_static: bool = ui.is_active()
	var text_via_static: bool = ui.text_label.text == "Static call operational."
	
	ui.advance_dialogue()
	await process_frame
	
	ui.queue_free()
	await process_frame
	
	if active_via_static and text_via_static:
		report_result("Test 9: Static API helper DialogueUI.start() successfully dispatches to instance", true)
	else:
		report_result("Test 9: Static API helper DialogueUI.start() successfully dispatches to instance", false,
			"active=%s, text_ok=%s" % [active_via_static, text_via_static])

# TEST 10: Decoupled architecture with arbitrary dialogue structures
func test_10_decoupled_architecture_arbitrary_data() -> void:
	print("[TEST 10] Verifying decoupled architecture with narration (no speaker) & multi-character data...")
	var ui_scene: PackedScene = load("res://scenes/ui/dialogue_ui.tscn")
	var ui: DialogueUI = ui_scene.instantiate() as DialogueUI
	root.add_child(ui)
	await process_frame
	
	# Narration line with empty speaker
	var narration_data := [
		{"speaker": "", "text": "The damp sand crunches beneath your boots."}
	]
	ui.start_dialogue(narration_data)
	await process_frame
	
	var speaker_hidden_for_narration: bool = not ui.speaker_label.visible
	var narration_text_ok: bool = ui.text_label.text == "The damp sand crunches beneath your boots."
	
	ui.advance_dialogue()
	await process_frame
	
	# Multi-character conversation
	var multi_char_data := [
		{"speaker": "Sailor", "text": "The reef is completely bare!"},
		{"speaker": "Cartographer", "text": "I must map the seabed before it returns."}
	]
	ui.start_dialogue(multi_char_data)
	await process_frame
	
	var char1_speaker: bool = ui.speaker_label.visible and ui.speaker_label.text == "Sailor"
	var char1_text: bool = ui.text_label.text == "The reef is completely bare!"
	
	ui.advance_dialogue()
	await process_frame
	
	var char2_speaker: bool = ui.speaker_label.visible and ui.speaker_label.text == "Cartographer"
	var char2_text: bool = ui.text_label.text == "I must map the seabed before it returns."
	
	ui.advance_dialogue()
	await process_frame
	
	ui.queue_free()
	await process_frame
	
	var pass_all: bool = speaker_hidden_for_narration and narration_text_ok and char1_speaker and char1_text and char2_speaker and char2_text
	if pass_all:
		report_result("Test 10: Dialogue system is decoupled; handles narration and multi-character dialogue seamlessly", true)
	else:
		report_result("Test 10: Dialogue system is decoupled; handles narration and multi-character dialogue seamlessly", false,
			"narration_spk_hidden=%s, txt_ok=%s, c1_spk=%s, c2_spk=%s" %
			[speaker_hidden_for_narration, narration_text_ok, char1_speaker, char2_speaker])

# TEST 11: Milestones 7 & 8 Regressions (OceanState, Shells, POI collisions, Village NoticeBoard)
func test_11_milestones_7_and_8_regression() -> void:
	print("[TEST 11] Verifying Milestones 7 & 8 regression integrity...")
	
	# OceanState retreat
	OceanStateController.reset_ocean_state()
	var init_state_ok: bool = OceanStateController.get_current_state() == OceanStateController.State.NORMAL_OCEAN
	OceanStateController.trigger_ocean_retreat()
	var retreated_ok: bool = OceanStateController.is_ocean_retreated()
	
	# Environmental signs (Village birds inland, Seabed shell active)
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	var birds: CoastalBirdsSign = village.get_node("CoastalBirds") as CoastalBirdsSign
	var birds_ok: bool = birds != null and birds.is_inland
	
	var notice_board: NoticeBoard = village.get_node("Interactables/NoticeBoard") as NoticeBoard
	var board_ok: bool = notice_board != null and notice_board.is_interactable
	
	village.queue_free()
	await process_frame
	
	# Seabed POI collisions
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var shell: SeabedShell = seabed.get_node("StrangeSigns/ShellTidePools") as SeabedShell
	var shell_ok: bool = shell != null and shell.is_interactable
	
	var shipwreck_hull: StaticBody2D = seabed.get_node("ShipwreckArea/Shipwreck") as StaticBody2D
	var cave_rock: StaticBody2D = seabed.get_node("CaveArea/CaveRidge") as StaticBody2D
	var poi_ok: bool = shipwreck_hull != null and cave_rock != null
	
	seabed.queue_free()
	await process_frame
	
	var pass_all: bool = init_state_ok and retreated_ok and birds_ok and board_ok and shell_ok and poi_ok
	if pass_all:
		report_result("Test 11: OceanState, strange signs, Village NoticeBoard, and Seabed POIs 100% intact", true)
	else:
		report_result("Test 11: OceanState, strange signs, Village NoticeBoard, and Seabed POIs 100% intact", false,
			"init=%s, retreated=%s, birds=%s, board=%s, shell=%s, poi=%s" %
			[init_state_ok, retreated_ok, birds_ok, board_ok, shell_ok, poi_ok])
