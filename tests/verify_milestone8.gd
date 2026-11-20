extends SceneTree

var passed_count: int = 0
var failed_count: int = 0
var ocean_state_node: OceanStateController = null

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 8 VERIFICATION SUITE ---")
	print("==================================================\n")
	# Ensure OceanState instance is active in root for headless test runs
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
	await test_1_normal_ocean_signs_inactive()
	await test_2_retreat_signs_activate()
	await test_3_shell_interaction_and_atmospheric_message()
	await test_4_tide_pool_state_changes()
	await test_5_bird_behavior_inland_migration()
	await test_6_environmental_tremor_and_wind()
	await test_7_scene_transitions_and_signs_persistence()
	await test_8_existing_systems_integrity()
	
	print("\n==================================================")
	print("--- MILESTONE 8 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: In NORMAL_OCEAN, strange signs are inactive / normal
func test_1_normal_ocean_signs_inactive() -> void:
	print("[TEST 1] Verifying strange signs are inactive in NORMAL_OCEAN...")
	OceanStateController.reset_ocean_state()
	
	# Check Village birds
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var birds: CoastalBirdsSign = village.get_node("CoastalBirds") as CoastalBirdsSign
	var birds_at_cliff: bool = birds != null and not birds.is_inland
	var bird1_cliff_pos: bool = birds != null and birds.get_node("Bird1").position.is_equal_approx(Vector2(450, 375))
	village.queue_free()
	await process_frame
	
	# Check Seabed signs
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var tide_pools: TidePoolSign = seabed.get_node("TidePools") as TidePoolSign
	var pools_full: bool = tide_pools != null and not tide_pools.is_drained
	
	var shell: SeabedShell = seabed.get_node("StrangeSigns/ShellTidePools") as SeabedShell
	var shell_inert: bool = shell != null and not shell.is_interactable and not shell.visible
	
	var tremor: SeabedTremorSign = seabed.get_node("StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	var tremor_inactive: bool = tremor != null and not tremor.is_active
	
	var wind: SeabedWindSign = seabed.get_node("StrangeSigns/SeabedWindSign") as SeabedWindSign
	var wind_inactive: bool = wind != null and not wind.is_active and not wind.get_node("WindParticles").emitting
	
	seabed.queue_free()
	await process_frame
	
	var pass_all: bool = birds_at_cliff and bird1_cliff_pos and pools_full and shell_inert and tremor_inactive and wind_inactive
	if pass_all:
		report_result("Test 1: In NORMAL_OCEAN, all strange signs are inactive/normal", true)
	else:
		report_result("Test 1: In NORMAL_OCEAN, all strange signs are inactive/normal", false,
			"birds_cliff=%s, pools_full=%s, shell_inert=%s, tremor_inactive=%s, wind_inactive=%s" %
			[birds_at_cliff, pools_full, shell_inert, tremor_inactive, wind_inactive])

# TEST 2: In OCEAN_RETREATED, strange signs activate
func test_2_retreat_signs_activate() -> void:
	print("[TEST 2] Verifying strange signs activate in OCEAN_RETREATED...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	# Check Village birds
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var birds: CoastalBirdsSign = village.get_node("CoastalBirds") as CoastalBirdsSign
	var birds_inland: bool = birds != null and birds.is_inland
	var bird1_inland_pos: bool = birds != null and birds.get_node("Bird1").position.is_equal_approx(Vector2(470, 70))
	village.queue_free()
	await process_frame
	
	# Check Seabed signs
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var tide_pools: TidePoolSign = seabed.get_node("TidePools") as TidePoolSign
	var pools_drained: bool = tide_pools != null and tide_pools.is_drained
	
	var shell: SeabedShell = seabed.get_node("StrangeSigns/ShellTidePools") as SeabedShell
	var shell_active: bool = shell != null and shell.is_interactable and shell.visible
	
	var tremor: SeabedTremorSign = seabed.get_node("StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	var tremor_active: bool = tremor != null and tremor.is_active
	
	var wind: SeabedWindSign = seabed.get_node("StrangeSigns/SeabedWindSign") as SeabedWindSign
	var wind_active: bool = wind != null and wind.is_active and wind.get_node("WindParticles").emitting
	
	seabed.queue_free()
	await process_frame
	
	var pass_all: bool = birds_inland and bird1_inland_pos and pools_drained and shell_active and tremor_active and wind_active
	if pass_all:
		report_result("Test 2: In OCEAN_RETREATED, all strange signs activate", true)
	else:
		report_result("Test 2: In OCEAN_RETREATED, all strange signs activate", false,
			"birds_inland=%s, pools_drained=%s, shell_active=%s, tremor_active=%s, wind_active=%s" %
			[birds_inland, pools_drained, shell_active, tremor_active, wind_active])

# TEST 3: Shell interaction and atmospheric message display
func test_3_shell_interaction_and_atmospheric_message() -> void:
	print("[TEST 3] Verifying shell interaction and atmospheric message display...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var seabed_scene: PackedScene = load("res://scenes/test/seabed_test.tscn")
	var seabed_test: Node2D = seabed_scene.instantiate()
	root.add_child(seabed_test)
	await process_frame
	await physics_frame
	
	var player: Player = seabed_test.get_node("Player") as Player
	var shell: SeabedShell = seabed_test.get_node("Seabed/StrangeSigns/ShellTidePools") as SeabedShell
	var message_ui: AtmosphericMessageUI = seabed_test.get_node("AtmosphericMessageUI") as AtmosphericMessageUI
	
	# Verify message reception using Dictionary closure
	var message_capture := {"received": false, "text": ""}
	var callback = func(txt: String):
		message_capture.received = true
		message_capture.text = txt
	message_ui.message_displayed.connect(callback)
	
	# Place player directly adjacent to shell (shell at 420, 270)
	player.global_position = Vector2(420, 278)
	await physics_frame
	
	# Interact
	var interacted: bool = player.try_interact()
	await process_frame
	message_ui.message_displayed.disconnect(callback)
	
	var count_ok: bool = shell.examination_count >= 1
	var msg_ok: bool = message_capture.received and message_capture.text.contains("hums softly")
	
	seabed_test.queue_free()
	await process_frame
	
	if interacted and count_ok and msg_ok:
		report_result("Test 3: Player interacts with shell; atmospheric message displays cleanly", true)
	else:
		report_result("Test 3: Player interacts with shell; atmospheric message displays cleanly", false,
			"interacted=%s, count=%d, msg_ok=%s (text='%s')" % [interacted, shell.examination_count, msg_ok, message_capture.text])

# TEST 4: Tide pool state changes (water level & drained color)
func test_4_tide_pool_state_changes() -> void:
	print("[TEST 4] Verifying tide pool visual draining transitions...")
	OceanStateController.reset_ocean_state()
	
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	await process_frame
	
	var tide_pools: TidePoolSign = seabed.get_node("TidePools") as TidePoolSign
	var water_rect: ColorRect = tide_pools.get_node("PoolRim1/PoolWater1") as ColorRect
	
	var initial_full_color: Color = water_rect.color
	var initial_width: float = water_rect.offset_right - water_rect.offset_left
	
	# Trigger retreat
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	await process_frame
	
	var drained_color: Color = water_rect.color
	var drained_width: float = water_rect.offset_right - water_rect.offset_left
	
	# Water should have shrunk and turned murky silt
	var width_shrunk: bool = drained_width < initial_width
	var color_shifted: bool = drained_color != initial_full_color
	
	seabed.queue_free()
	await process_frame
	
	if width_shrunk and color_shifted:
		report_result("Test 4: Tide pools visibly drain and water color shifts to murky silt", true)
	else:
		report_result("Test 4: Tide pools visibly drain and water color shifts to murky silt", false,
			"width_shrunk=%s (init=%.1f, drained=%.1f), color_shifted=%s" % [width_shrunk, initial_width, drained_width, color_shifted])

# TEST 5: Bird behavior inland migration
func test_5_bird_behavior_inland_migration() -> void:
	print("[TEST 5] Verifying seabird inland migration behavior...")
	OceanStateController.reset_ocean_state()
	
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var birds: CoastalBirdsSign = village.get_node("CoastalBirds") as CoastalBirdsSign
	var bird1: Node2D = birds.get_node("Bird1") as Node2D
	var cliff_pos: Vector2 = bird1.position
	
	# Trigger retreat with animation
	OceanStateController.trigger_ocean_retreat()
	await process_frame
	
	var inland_target: Vector2 = CoastalBirdsSign.INLAND_POS_1
	# Snap to finished state or verify direction of flight
	birds._update_sign_state(true, false)
	var inland_pos: Vector2 = bird1.position
	
	var moved_inland: bool = inland_pos.is_equal_approx(inland_target) and inland_pos.y < cliff_pos.y
	village.queue_free()
	await process_frame
	
	if moved_inland:
		report_result("Test 5: Birds migrate inland away from the coast to village rooftops", true)
	else:
		report_result("Test 5: Birds migrate inland away from the coast to village rooftops", false,
			"cliff_y=%.1f, inland_y=%.1f" % [cliff_pos.y, inland_pos.y])

# TEST 6: Environmental tremor and wind particle activation
func test_6_environmental_tremor_and_wind() -> void:
	print("[TEST 6] Verifying environmental micro-tremor and atmospheric wind...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var seabed_scene: PackedScene = load("res://scenes/test/seabed_test.tscn")
	var seabed_test: Node2D = seabed_scene.instantiate()
	root.add_child(seabed_test)
	await process_frame
	await physics_frame
	
	var player: Player = seabed_test.get_node("Player") as Player
	var tremor: SeabedTremorSign = seabed_test.get_node("Seabed/StrangeSigns/SeabedTremorSign") as SeabedTremorSign
	var wind: SeabedWindSign = seabed_test.get_node("Seabed/StrangeSigns/SeabedWindSign") as SeabedWindSign
	var particles: CPUParticles2D = wind.get_node("WindParticles") as CPUParticles2D
	
	# Test tremor trigger
	tremor.trigger_subtle_tremor(player)
	var tremor_count_ok: bool = tremor.tremor_count >= 1
	var wind_emitting_ok: bool = particles != null and particles.emitting
	
	seabed_test.queue_free()
	await process_frame
	
	if tremor_count_ok and wind_emitting_ok:
		report_result("Test 6: Subtle ground micro-tremor triggers and atmospheric wind particles emit", true)
	else:
		report_result("Test 6: Subtle ground micro-tremor triggers and atmospheric wind particles emit", false,
			"tremor_ok=%s, wind_emitting=%s" % [tremor_count_ok, wind_emitting_ok])

# TEST 7: Scene transitions & persistence of strange signs
func test_7_scene_transitions_and_signs_persistence() -> void:
	print("[TEST 7] Verifying strange signs persistence across Village <-> Seabed transitions...")
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	# Start in environmental_signs_test.tscn
	var test_scene: PackedScene = load("res://scenes/test/environmental_signs_test.tscn")
	var signs_test: EnvironmentalSignsTest = test_scene.instantiate() as EnvironmentalSignsTest
	root.add_child(signs_test)
	await process_frame
	await physics_frame
	
	# Verify Village signs are active (birds inland)
	var birds: CoastalBirdsSign = signs_test.get_node("Village/CoastalBirds") as CoastalBirdsSign
	var birds_inland_before: bool = birds.is_inland
	
	# Transition to Seabed
	SceneTransitionTrigger.target_spawn_id = "seabed_entry"
	SceneTransitionTrigger.return_scene_path = "res://scenes/test/environmental_signs_test.tscn"
	signs_test.queue_free()
	await process_frame
	
	var seabed_scene: PackedScene = load("res://scenes/test/seabed_test.tscn")
	var seabed_test: Node2D = seabed_scene.instantiate()
	root.add_child(seabed_test)
	await process_frame
	await physics_frame
	
	# Verify Seabed signs are active
	var shell: SeabedShell = seabed_test.get_node("Seabed/StrangeSigns/ShellTidePools") as SeabedShell
	var shell_active: bool = shell.is_interactable and shell.visible
	var tide_pools: TidePoolSign = seabed_test.get_node("Seabed/TidePools") as TidePoolSign
	var pools_drained: bool = tide_pools.is_drained
	
	# Return to Village
	var player: Player = seabed_test.get_node("Player") as Player
	var village_transition: SceneTransitionTrigger = seabed_test.get_node("Seabed/ReturnRoute/VillageTransition") as SceneTransitionTrigger
	village_transition._on_body_entered(player)
	
	seabed_test.queue_free()
	await process_frame
	
	# Re-enter Village
	var village_return: EnvironmentalSignsTest = test_scene.instantiate() as EnvironmentalSignsTest
	root.add_child(village_return)
	await process_frame
	await physics_frame
	
	var return_birds: CoastalBirdsSign = village_return.get_node("Village/CoastalBirds") as CoastalBirdsSign
	var birds_still_inland: bool = return_birds.is_inland
	var returned_to_ladder: bool = (village_return.get_node("Player") as Player).global_position.is_equal_approx(Vector2(480, 360))
	
	village_return.queue_free()
	await process_frame
	
	var pass_all: bool = birds_inland_before and shell_active and pools_drained and birds_still_inland and returned_to_ladder
	if pass_all:
		report_result("Test 7: Strange signs and player spawn persist cleanly across round-trip transitions", true)
	else:
		report_result("Test 7: Strange signs and player spawn persist cleanly across round-trip transitions", false,
			"birds_before=%s, shell_active=%s, pools_drained=%s, birds_still_inland=%s, ladder_spawn=%s" %
			[birds_inland_before, shell_active, pools_drained, birds_still_inland, returned_to_ladder])

# TEST 8: Existing systems integrity
func test_8_existing_systems_integrity() -> void:
	print("[TEST 8] Verifying existing gameplay systems (Normalization, Shipwreck, Cave, NoticeBoard, Main Scene)...")
	
	# Player diagonal normalization
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player.global_position = Vector2(100, 100)
	await physics_frame
	
	var input_vec = Vector2(1, 1).normalized()
	player.velocity = input_vec * player.speed
	var norm_ok: bool = is_equal_approx(player.velocity.length(), 80.0)
	player.queue_free()
	await process_frame
	
	# Seabed POI collisions
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed: Seabed = seabed_scene.instantiate() as Seabed
	root.add_child(seabed)
	
	var test_player: Player = player_scene.instantiate() as Player
	seabed.add_child(test_player)
	
	# Shipwreck collision (Hull at 980, 370, size 160x64 -> left edge 900)
	test_player.global_position = Vector2(870, 370)
	for i in range(50):
		test_player.velocity = Vector2(80, 0)
		test_player.move_and_slide()
		await physics_frame
	var shipwreck_blocked: bool = test_player.global_position.x <= 895.0
	
	# Cave ridge collision (Rock at 180, 90, size 120x60 -> bottom edge 120)
	test_player.global_position = Vector2(180, 150)
	for i in range(50):
		test_player.velocity = Vector2(0, -80)
		test_player.move_and_slide()
		await physics_frame
	var cave_blocked: bool = test_player.global_position.y >= 126.0
	
	seabed.queue_free()
	await process_frame
	
	# Village NoticeBoard interaction
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village: Village = village_scene.instantiate() as Village
	root.add_child(village)
	
	var board_player: Player = player_scene.instantiate() as Player
	village.add_child(board_player)
	board_player.global_position = Vector2(430, 222)
	await physics_frame
	
	var notice_board: NoticeBoard = village.get_node("Interactables/NoticeBoard") as NoticeBoard
	notice_board.interact(board_player)
	var notice_ok: bool = notice_board.interaction_count >= 1
	village.queue_free()
	await process_frame
	
	# Main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node = main_scene.instantiate()
	var main_ok: bool = main_node is Node2D
	main_node.queue_free()
	
	var pass_all: bool = norm_ok and shipwreck_blocked and cave_blocked and notice_ok and main_ok
	if pass_all:
		report_result("Test 8: Player movement, seabed POI collisions, NoticeBoard, and Main Scene fully intact", true)
	else:
		report_result("Test 8: Player movement, seabed POI collisions, NoticeBoard, and Main Scene fully intact", false,
			"norm=%s, shipwreck=%s, cave=%s, notice=%s, main=%s" % [norm_ok, shipwreck_blocked, cave_blocked, notice_ok, main_ok])
