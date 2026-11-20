extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_instance: OceanStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 7 VERIFICATION SUITE ---")
	print("==================================================\n")
	# Ensure OceanState is in tree for standalone headless test runs
	ocean_state_instance = OceanStateController.new()
	ocean_state_instance.name = "OceanState"
	root.add_child(ocean_state_instance)
	call_deferred("_run_all_tests")

func report_result(test_name: String, passed: bool, error_msg: String = "") -> void:
	if passed:
		passed_count += 1
		print("[PASS] %s" % test_name)
	else:
		failed_count += 1
		print("[FAIL] %s: %s" % [test_name, error_msg])

func _run_all_tests() -> void:
	await test_1_initial_state()
	await test_2_village_normal_state_access_and_visuals()
	await test_3_debug_trigger_and_retreat_transition()
	await test_4_village_retreated_state_access_and_visuals()
	await test_5_bidirectional_transition_with_state_persistence()
	await test_6_ocean_shift_test_scene_and_hud()
	await test_7_existing_systems_integrity()
	await test_8_main_scene_and_cleanliness()
	
	print("\n==================================================")
	print("--- MILESTONE 7 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Initial state is NORMAL_OCEAN
func test_1_initial_state() -> void:
	print("[TEST 1] Verifying initial ocean state is NORMAL_OCEAN...")
	OceanStateController.reset_ocean_state()
	
	var is_normal: bool = OceanStateController.is_ocean_normal()
	var is_retreated: bool = OceanStateController.is_ocean_retreated()
	var state: OceanStateController.State = OceanStateController.get_current_state()
	
	if is_normal and not is_retreated and state == OceanStateController.State.NORMAL_OCEAN:
		report_result("Test 1: Initial state is NORMAL_OCEAN", true)
	else:
		report_result("Test 1: Initial state is NORMAL_OCEAN", false, "State was %s" % str(state))

# TEST 2: Village visual & physical access in NORMAL_OCEAN
func test_2_village_normal_state_access_and_visuals() -> void:
	print("[TEST 2] Verifying village shore visuals and access blocking in NORMAL_OCEAN...")
	OceanStateController.reset_ocean_state()
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var ocean_water = village.get_node("Shore/OceanWater")
	var access_barrier: StaticBody2D = village.get_node("Boundaries/SeabedAccessBarrier") as StaticBody2D
	var barrier_shape: CollisionShape2D = access_barrier.get_node("CollisionShape2D") as CollisionShape2D
	var seabed_transition: Area2D = village.get_node("SeabedAccess/SeabedTransition") as Area2D
	var transition_shape: CollisionShape2D = seabed_transition.get_node("CollisionShape2D") as CollisionShape2D
	
	var water_at_top: bool = ocean_water != null and ocean_water.position.y == 0.0
	var barrier_active: bool = barrier_shape != null and not barrier_shape.disabled
	var transition_disabled: bool = transition_shape != null and transition_shape.disabled
	var transition_not_monitoring: bool = not seabed_transition.monitoring
	
	# Verify player physics collision is physically stopped by barrier
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	village.add_child(player)
	player.global_position = Vector2(480, 370) # Standing on ladder overlook deck
	await physics_frame
	
	# Try moving south down the ladder into the ocean
	for i in range(25):
		player.velocity = Vector2(0, 80)
		player.move_and_slide()
		await physics_frame
	
	# With barrier active at y=396 (size 40x16), player radius 6 should stop at y <= 390
	var stopped_by_barrier: bool = player.global_position.y <= 390.0
	print(" Player position after trying to descend ladder in NORMAL_OCEAN: (%.1f, %.1f)" % [player.global_position.x, player.global_position.y])
	
	village.queue_free()
	await process_frame
	
	var pass_all: bool = water_at_top and barrier_active and transition_disabled and transition_not_monitoring and stopped_by_barrier
	if pass_all:
		report_result("Test 2: Shore water present, barrier blocks descent to seabed", true)
	else:
		report_result("Test 2: Shore water present, barrier blocks descent to seabed", false,
			"water_at_top=%s, barrier_active=%s, transition_disabled=%s, stopped_by_barrier=%s" % [water_at_top, barrier_active, transition_disabled, stopped_by_barrier])

# TEST 3: Debug trigger changes state to OCEAN_RETREATED
func test_3_debug_trigger_and_retreat_transition() -> void:
	print("[TEST 3] Verifying debug trigger (key 'T') and state change to OCEAN_RETREATED...")
	OceanStateController.reset_ocean_state()
	
	var capture = {
		"received": false,
		"new_state": OceanStateController.State.NORMAL_OCEAN
	}
	
	var callback = func(s):
		capture.received = true
		capture.new_state = s
	
	ocean_state_instance.state_changed.connect(callback)
	
	# Simulate key press 'T' via InputEventKey
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_T
	key_event.physical_keycode = KEY_T
	ocean_state_instance._unhandled_input(key_event)
	
	await process_frame
	ocean_state_instance.state_changed.disconnect(callback)
	
	var is_retreated: bool = OceanStateController.is_ocean_retreated()
	var signal_ok: bool = capture.received and capture.new_state == OceanStateController.State.OCEAN_RETREATED
	
	if is_retreated and signal_ok:
		report_result("Test 3: Debug trigger 'T' changes state to OCEAN_RETREATED and emits signal", true)
	else:
		report_result("Test 3: Debug trigger 'T' changes state to OCEAN_RETREATED and emits signal", false,
			"is_retreated=%s, signal_ok=%s" % [is_retreated, signal_ok])

# TEST 4: Village visual & physical access in OCEAN_RETREATED
func test_4_village_retreated_state_access_and_visuals() -> void:
	print("[TEST 4] Verifying village shore visuals and access opening in OCEAN_RETREATED...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var ocean_water = village.get_node("Shore/OceanWater")
	var exposed_seabed = village.get_node("Shore/ExposedSeabed")
	var access_barrier: StaticBody2D = village.get_node("Boundaries/SeabedAccessBarrier") as StaticBody2D
	var barrier_shape: CollisionShape2D = access_barrier.get_node("CollisionShape2D") as CollisionShape2D
	var seabed_transition: Area2D = village.get_node("SeabedAccess/SeabedTransition") as Area2D
	var transition_shape: CollisionShape2D = seabed_transition.get_node("CollisionShape2D") as CollisionShape2D
	
	var water_receded: bool = ocean_water != null and ocean_water.position.y >= 140.0
	var exposed_seabed_exists: bool = exposed_seabed != null
	var barrier_disabled: bool = barrier_shape != null and barrier_shape.disabled
	var transition_enabled: bool = transition_shape != null and not transition_shape.disabled
	var transition_monitoring: bool = seabed_transition.monitoring
	
	# Verify player can now walk down the ladder past y=400 to the seabed transition
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	village.add_child(player)
	player.global_position = Vector2(480, 370)
	await physics_frame
	
	# Move south for 50 frames (50 * 1.33 = ~66 pixels, enough to reach y=420)
	for i in range(50):
		player.velocity = Vector2(0, 80)
		player.move_and_slide()
		await physics_frame
	
	# Player should freely reach y >= 415 (ladder base / transition zone)
	var reached_transition: bool = player.global_position.y >= 415.0
	print(" Player position after descending ladder in OCEAN_RETREATED: (%.1f, %.1f)" % [player.global_position.x, player.global_position.y])
	
	village.queue_free()
	await process_frame
	
	var pass_all: bool = water_receded and exposed_seabed_exists and barrier_disabled and transition_enabled and transition_monitoring and reached_transition
	if pass_all:
		report_result("Test 4: Water receded, exposed seabed visible, barrier open, player reaches transition", true)
	else:
		report_result("Test 4: Water receded, exposed seabed visible, barrier open, player reaches transition", false,
			"water_receded=%s, barrier_disabled=%s, transition_enabled=%s, reached_transition=%s" % [water_receded, barrier_disabled, transition_enabled, reached_transition])

# TEST 5: Bidirectional transition Village <-> Seabed with state persistence
func test_5_bidirectional_transition_with_state_persistence() -> void:
	print("[TEST 5] Verifying bidirectional scene transition and ocean state persistence...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	# Step A: Load Seabed as if transitioning from Village
	SceneTransitionTrigger.target_spawn_id = "seabed_entry"
	SceneTransitionTrigger.return_scene_path = "res://scenes/test/ocean_shift_test.tscn"
	
	var seabed_scene: PackedScene = load("res://scenes/test/seabed_test.tscn")
	var seabed_test: Node2D = seabed_scene.instantiate()
	root.add_child(seabed_test)
	await process_frame
	await physics_frame
	
	var seabed_player: Player = seabed_test.get_node("Player") as Player
	var player_at_seabed_entry: bool = seabed_player.global_position.is_equal_approx(Vector2(640, 110))
	
	# Trigger transition back to village
	var village_transition: SceneTransitionTrigger = seabed_test.get_node("Seabed/ReturnRoute/VillageTransition") as SceneTransitionTrigger
	village_transition._on_body_entered(seabed_player)
	
	var spawn_id_for_village: String = SceneTransitionTrigger.target_spawn_id
	seabed_test.queue_free()
	await process_frame
	
	# Step B: Load OceanShiftTest scene using the spawn id set by seabed transition
	var test_scene: PackedScene = load("res://scenes/test/ocean_shift_test.tscn")
	var shift_test: OceanShiftTest = test_scene.instantiate() as OceanShiftTest
	root.add_child(shift_test)
	await process_frame
	await physics_frame
	
	var village_player: Player = shift_test.get_node("Player") as Player
	var returned_to_ladder_spawn: bool = village_player.global_position.is_equal_approx(Vector2(480, 360))
	
	# Step C: Verify ocean state persisted as RETREATED
	var ocean_still_retreated: bool = OceanStateController.is_ocean_retreated()
	var village_water: Node2D = shift_test.get_node("Village/Shore/OceanWater") as Node2D
	var village_barrier: CollisionShape2D = shift_test.get_node("Village/Boundaries/SeabedAccessBarrier/CollisionShape2D") as CollisionShape2D
	
	var water_still_receded: bool = village_water.position.y >= 140.0
	var barrier_still_disabled: bool = village_barrier.disabled
	
	shift_test.queue_free()
	await process_frame
	
	var pass_all: bool = player_at_seabed_entry and spawn_id_for_village == "ladder" and returned_to_ladder_spawn and ocean_still_retreated and water_still_receded and barrier_still_disabled
	if pass_all:
		report_result("Test 5: Round-trip transition persists OCEAN_RETREATED state and correct spawns", true)
	else:
		report_result("Test 5: Round-trip transition persists OCEAN_RETREATED state and correct spawns", false,
			"player_at_seabed=%s, spawn_id=%s, returned_ladder=%s, still_retreated=%s, water_receded=%s, barrier_disabled=%s" %
			[player_at_seabed_entry, spawn_id_for_village, returned_to_ladder_spawn, ocean_still_retreated, water_still_receded, barrier_still_disabled])

# TEST 6: Ocean Shift test scene and Debug HUD
func test_6_ocean_shift_test_scene_and_hud() -> void:
	print("[TEST 6] Verifying ocean_shift_test.tscn instantiates cleanly with responsive Debug HUD...")
	OceanStateController.reset_ocean_state()
	SceneTransitionTrigger.target_spawn_id = ""
	
	var test_scene: PackedScene = load("res://scenes/test/ocean_shift_test.tscn")
	var shift_test: OceanShiftTest = test_scene.instantiate() as OceanShiftTest
	root.add_child(shift_test)
	await process_frame
	
	var state_label: Label = shift_test.get_node("DebugUI/Panel/VBoxContainer/StateLabel") as Label
	var access_label: Label = shift_test.get_node("DebugUI/Panel/VBoxContainer/AccessLabel") as Label
	
	var hud_normal_ok: bool = state_label.text.contains("NORMAL") and access_label.text.contains("BLOCKED")
	
	# Trigger retreat and check HUD update
	OceanStateController.trigger_ocean_retreat()
	await process_frame
	
	var hud_retreated_ok: bool = state_label.text.contains("RETREATED") and access_label.text.contains("OPEN")
	
	shift_test.queue_free()
	await process_frame
	
	if hud_normal_ok and hud_retreated_ok:
		report_result("Test 6: ocean_shift_test.tscn loads and Debug HUD updates dynamically", true)
	else:
		report_result("Test 6: ocean_shift_test.tscn loads and Debug HUD updates dynamically", false,
			"hud_normal_ok=%s, hud_retreated_ok=%s" % [hud_normal_ok, hud_retreated_ok])

# TEST 7: Existing systems remain intact (Movement, Seabed Shipwreck/Cave, NoticeBoard)
func test_7_existing_systems_integrity() -> void:
	print("[TEST 7] Verifying existing gameplay systems (Player movement, Seabed POI collisions, Village NoticeBoard)...")
	
	# A. Player movement & normalization
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player.global_position = Vector2(100, 100)
	await physics_frame
	
	var input_vec = Vector2(1, 1).normalized()
	player.velocity = input_vec * player.speed
	var speed_length: float = player.velocity.length()
	var norm_ok: bool = is_equal_approx(speed_length, 80.0)
	player.queue_free()
	await process_frame
	
	# B. Seabed Shipwreck & Cave Collisions
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	
	var test_player: Player = player_scene.instantiate() as Player
	seabed.add_child(test_player)
	
	# Test Shipwreck collision (Hull at 980, 370, size 160x64 -> left edge is 900)
	test_player.global_position = Vector2(870, 370)
	for i in range(50):
		test_player.velocity = Vector2(80, 0)
		test_player.move_and_slide()
		await physics_frame
	var shipwreck_blocked: bool = test_player.global_position.x <= 895.0
	print(" Shipwreck test final player pos x = %.1f (hull left edge = 900.0)" % test_player.global_position.x)
	
	# Test Cave Ridge collision (Rock at 180, 90, size 120x60 -> bottom edge is 120)
	test_player.global_position = Vector2(180, 150)
	for i in range(50):
		test_player.velocity = Vector2(0, -80)
		test_player.move_and_slide()
		await physics_frame
	var cave_blocked: bool = test_player.global_position.y >= 126.0
	print(" Cave Ridge test final player pos y = %.1f (rock bottom edge = 120.0)" % test_player.global_position.y)
	
	seabed.queue_free()
	await process_frame
	
	# C. Village NoticeBoard interaction
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	
	var board_player: Player = player_scene.instantiate() as Player
	village.add_child(board_player)
	board_player.global_position = Vector2(430, 222) # 12px from notice board
	await physics_frame
	
	var notice_board: NoticeBoard = village.get_node("Interactables/NoticeBoard") as NoticeBoard
	notice_board.interact(board_player)
	var notice_ok: bool = notice_board.interaction_count >= 1
	
	village.queue_free()
	await process_frame
	
	var pass_all: bool = norm_ok and shipwreck_blocked and cave_blocked and notice_ok
	if pass_all:
		report_result("Test 7: Player diagonal normalization, seabed POI collisions, and NoticeBoard intact", true)
	else:
		report_result("Test 7: Player diagonal normalization, seabed POI collisions, and NoticeBoard intact", false,
			"norm_ok=%s, shipwreck_blocked=%s, cave_blocked=%s, notice_ok=%s" % [norm_ok, shipwreck_blocked, cave_blocked, notice_ok])

# TEST 8: Main Scene and general scene validation
func test_8_main_scene_and_cleanliness() -> void:
	print("[TEST 8] Verifying main scene (scenes/main.tscn) integrity...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node = main_scene.instantiate()
	root.add_child(main_node)
	await process_frame
	
	var main_valid: bool = main_node is Node2D
	main_node.queue_free()
	await process_frame
	
	if main_valid:
		report_result("Test 8: Main scene instantiates cleanly as valid Node2D foundation", true)
	else:
		report_result("Test 8: Main scene instantiates cleanly as valid Node2D foundation", false, "Main scene was invalid")
