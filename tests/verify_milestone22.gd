extends SceneTree

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 22 VERIFICATION SUITE ---")
	print("==================================================\n")
	call_deferred("_run_all_tests")

func report_result(test_name: String, passed: bool, error_msg: String = "") -> void:
	if passed:
		passed_count += 1
		print("[PASS] %s" % test_name)
	else:
		failed_count += 1
		print("[FAIL] %s: %s" % [test_name, error_msg])

func _run_all_tests() -> void:
	await test_1_village_scene_loads()
	await test_2_npc_instances_exist()
	await test_3_npc_count_in_intended_range()
	await test_4_npcs_use_npc_base()
	await test_5_npcs_have_valid_character_sprites()
	await test_6_npcs_have_collision()
	await test_7_npcs_have_interaction_areas()
	await test_8_npcs_have_valid_waypoints()
	await test_9_npcs_use_strict_cardinal_movement()
	await test_10_npcs_do_not_block_critical_positions()
	await test_11_npc_seeded_rng_configured()
	await test_12_elder_cael_present_and_usable()
	await test_13_main_scene_launches_with_npcs()
	await test_14_player_collision_independence()
	await test_15_npc_collision_no_permanent_lock()
	await test_16_waypoint_recovery_after_obstruction()
	await test_17_critical_routes_safety()

	print("\n==================================================")
	print("--- MILESTONE 22 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Main village scene loads cleanly
func test_1_village_scene_loads() -> void:
	var scene: PackedScene = load("res://scenes/world/village/village.tscn")
	if scene == null:
		report_result("Test 1: Main village scene loads cleanly", false, "Could not load village.tscn")
		return
	
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	await process_frame
	
	var ok: bool = (inst != null and inst is Village)
	inst.queue_free()
	await process_frame
	
	if ok:
		report_result("Test 1: Main village scene loads cleanly", true)
	else:
		report_result("Test 1: Main village scene loads cleanly", false, "Instantiation failed or not Village")

# TEST 2: NPC instances exist in the village
func test_2_npc_instances_exist() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var has_npcs: bool = not npcs.is_empty()
	
	village.queue_free()
	await process_frame
	
	if has_npcs:
		report_result("Test 2: NPC instances exist in the village", true)
	else:
		report_result("Test 2: NPC instances exist in the village", false, "No NPCs found in village")

# TEST 3: NPC count is within the intended range (15–25)
func test_3_npc_count_in_intended_range() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var count: int = npcs.size()
	var in_range: bool = (count >= 15 and count <= 25)
	
	village.queue_free()
	await process_frame
	
	if in_range:
		report_result("Test 3: NPC count (%d) is within intended range (15-25)" % count, true)
	else:
		report_result("Test 3: NPC count (%d) is within intended range (15-25)" % count, false, "Count was %d" % count)

# TEST 4: All NPCs inherit from NPCBase and CharacterBody2D
func test_4_npcs_use_npc_base() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var all_npc_base: bool = true
	var failed_node: String = ""
	
	for npc in npcs:
		if not (npc is NPCBase) or not (npc is CharacterBody2D):
			all_npc_base = false
			failed_node = npc.name
			break
	
	village.queue_free()
	await process_frame
	
	if all_npc_base and not npcs.is_empty():
		report_result("Test 4: All village NPCs inherit NPCBase and CharacterBody2D", true)
	else:
		report_result("Test 4: All village NPCs inherit NPCBase and CharacterBody2D", false, "Failed on %s" % failed_node)

# TEST 5: NPCs have valid character sprites with nearest-neighbor filtering and 16x24 size
func test_5_npcs_have_valid_character_sprites() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var all_sprites_valid: bool = true
	var err_msg: String = ""
	
	for npc in npcs:
		var sprite: Sprite2D = npc.get_node_or_null("Sprite2D")
		if sprite == null or sprite.texture == null:
			all_sprites_valid = false
			err_msg = "%s missing Sprite2D or texture" % npc.name
			break
		if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			all_sprites_valid = false
			err_msg = "%s texture_filter is not NEAREST" % npc.name
			break
		var tex_size: Vector2 = sprite.texture.get_size()
		if tex_size != Vector2(16, 24):
			all_sprites_valid = false
			err_msg = "%s texture size is %s, expected 16x24" % [npc.name, tex_size]
			break
	
	village.queue_free()
	await process_frame
	
	if all_sprites_valid and not npcs.is_empty():
		report_result("Test 5: NPCs have valid 16x24 character sprites with nearest filtering", true)
	else:
		report_result("Test 5: NPCs have valid 16x24 character sprites with nearest filtering", false, err_msg)

# TEST 6: NPCs have valid collision shapes
func test_6_npcs_have_collision() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var all_collision_ok: bool = true
	var err_msg: String = ""
	
	for npc in npcs:
		var col: CollisionShape2D = npc.get_node_or_null("CollisionShape2D")
		if col == null or col.shape == null:
			all_collision_ok = false
			err_msg = "%s has missing or null CollisionShape2D" % npc.name
			break
		if not (col.shape is RectangleShape2D):
			all_collision_ok = false
			err_msg = "%s collision shape is not RectangleShape2D" % npc.name
			break
	
	village.queue_free()
	await process_frame
	
	if all_collision_ok and not npcs.is_empty():
		report_result("Test 6: All NPCs have valid CollisionShape2D shapes", true)
	else:
		report_result("Test 6: All NPCs have valid CollisionShape2D shapes", false, err_msg)

# TEST 7: NPCs have interaction areas registered on collision layer 2
func test_7_npcs_have_interaction_areas() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var all_areas_ok: bool = true
	var err_msg: String = ""
	
	for npc in npcs:
		var area: Area2D = npc.get_node_or_null("InteractionArea")
		if area == null:
			all_areas_ok = false
			err_msg = "%s has no InteractionArea node" % npc.name
			break
		if not (area is Interactable):
			all_areas_ok = false
			err_msg = "%s InteractionArea does not inherit Interactable" % npc.name
			break
		if area.collision_layer != 2:
			all_areas_ok = false
			err_msg = "%s InteractionArea is on layer %d, expected 2" % [npc.name, area.collision_layer]
			break
	
	village.queue_free()
	await process_frame
	
	if all_areas_ok and not npcs.is_empty():
		report_result("Test 7: All NPCs possess layer-2 InteractionArea instances", true)
	else:
		report_result("Test 7: All NPCs possess layer-2 InteractionArea instances", false, err_msg)

# TEST 8: NPCs have valid waypoint configuration where applicable
func test_8_npcs_have_valid_waypoints() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var walkers: int = 0
	var idlers: int = 0
	var waypoints_valid: bool = true
	var err_msg: String = ""
	
	for npc in npcs:
		if not npc.waypoints.is_empty():
			walkers += 1
			if npc.waypoints.size() < 2:
				waypoints_valid = false
				err_msg = "%s has fewer than 2 waypoints in route" % npc.name
				break
			# Verify each waypoint is strictly cardinal to the next
			for i in range(npc.waypoints.size()):
				var p1: Vector2 = npc.waypoints[i]
				var p2: Vector2 = npc.waypoints[(i + 1) % npc.waypoints.size()]
				var diff := p2 - p1
				if diff.x != 0.0 and diff.y != 0.0:
					waypoints_valid = false
					err_msg = "%s has diagonal waypoint leg from %s to %s" % [npc.name, p1, p2]
					break
			if not waypoints_valid:
				break
		else:
			idlers += 1
	
	village.queue_free()
	await process_frame
	
	var variety_ok: bool = (walkers >= 6 and idlers >= 4 and waypoints_valid)
	if variety_ok:
		report_result("Test 8: Valid waypoint routes and role variety confirmed (%d walkers, %d idlers)" % [walkers, idlers], true)
	else:
		report_result("Test 8: Valid waypoint routes and role variety confirmed", false,
			"%s (walkers=%d, idlers=%d)" % [err_msg, walkers, idlers])

# TEST 9: NPCs adhere to strict cardinal movement (diagonal impossible)
func test_9_npcs_use_strict_cardinal_movement() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var walking_npc: NPCBase = null
	for npc in npcs:
		if not npc.waypoints.is_empty():
			walking_npc = npc
			break
	
	var never_diagonal: bool = true
	var did_move: bool = false
	if walking_npc != null:
		# If paused at waypoint 0 arrival, advance to next waypoint to walk leg
		if walking_npc.current_state == NPCBase.State.IDLE:
			walking_npc._advance_waypoint()
		
		var start_pos: Vector2 = walking_npc.global_position
		for i in range(20):
			walking_npc._physics_process(0.016)
			if walking_npc.velocity.x != 0.0 and walking_npc.velocity.y != 0.0:
				never_diagonal = false
				break
		if walking_npc.global_position != start_pos:
			did_move = true
	
	var has_walker: bool = (walking_npc != null)
	var t9_ok: bool = (never_diagonal and has_walker and did_move)
	
	village.queue_free()
	await process_frame
	
	if t9_ok:
		report_result("Test 9: Walking NPCs maintain strict cardinal movement without diagonal velocity", true)
	else:
		report_result("Test 9: Walking NPCs maintain strict cardinal movement without diagonal velocity", false,
			"found_walker=%s, never_diagonal=%s, did_move=%s" % [has_walker, never_diagonal, did_move])

# TEST 10: NPCs do not spawn on or permanently block critical player and story positions
func test_10_npcs_do_not_block_critical_positions() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var critical_points: Dictionary = {
		"PlayerSpawn": Vector2(240, 200),
		"TownWarning": Vector2(480, 130),
		"CliffOverlook": Vector2(480, 360),
		"SeabedTransition": Vector2(480, 420),
		"HighGroundPlateau": Vector2(870, 55),
		"FinalOverlook": Vector2(915, 45)
	}
	
	var min_clearance: float = 24.0 # pixels
	var no_blocking: bool = true
	var blocked_info: String = ""
	
	var npcs: Array[NPCBase] = village.get_npcs()
	for npc in npcs:
		for pt_name in critical_points:
			var pt_pos: Vector2 = critical_points[pt_name]
			var dist: float = npc.position.distance_to(pt_pos)
			if dist < min_clearance:
				no_blocking = false
				blocked_info = "%s spawned at %s too close to %s at %s (dist=%.1f < %.1f)" % [
					npc.name, npc.position, pt_name, pt_pos, dist, min_clearance
				]
				break
		if not no_blocking:
			break
	
	village.queue_free()
	await process_frame
	
	if no_blocking:
		report_result("Test 10: All NPCs maintain clearance from critical player/story positions", true)
	else:
		report_result("Test 10: All NPCs maintain clearance from critical player/story positions", false, blocked_info)

# TEST 11: NPC seeded RNG is configured and deterministic
func test_11_npc_seeded_rng_configured() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	var all_seeded: bool = true
	var seeds_seen: Dictionary = {}
	var has_duplicate_seed: bool = false
	var duplicate_msg: String = ""
	
	for npc in npcs:
		if npc.rng_seed == 0:
			all_seeded = false
			break
		if seeds_seen.has(npc.rng_seed):
			has_duplicate_seed = true
			duplicate_msg = "Duplicate seed %d on %s and %s" % [npc.rng_seed, seeds_seen[npc.rng_seed], npc.name]
			break
		seeds_seen[npc.rng_seed] = npc.name
	
	village.queue_free()
	await process_frame
	
	var seed_ok: bool = (all_seeded and not has_duplicate_seed and not npcs.is_empty())
	if seed_ok:
		report_result("Test 11: All NPCs possess distinct, deterministic RNG seeds", true)
	else:
		report_result("Test 11: All NPCs possess distinct, deterministic RNG seeds", false,
			"all_seeded=%s, duplicate=%s" % [all_seeded, duplicate_msg])

# TEST 12: Elder Cael remains present and usable
func test_12_elder_cael_present_and_usable() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	# Check 1: Populated town Elder Cael NPC exists
	var elder_npc: NPCBase = village.get_npc_by_name("Elder_Cael")
	if elder_npc == null:
		elder_npc = village.get_npc_by_name("Elder Cael")
	var town_elder_ok: bool = (elder_npc != null and elder_npc is NPCBase and elder_npc.npc_name == "Elder Cael")
	
	# Check 2: Survivors group Elder Cael remains for aftermath
	var survivor_elder = village.get_node_or_null("Survivors/ElderCael")
	var survivor_elder_ok: bool = (survivor_elder != null and survivor_elder is SurvivorInteractable)
	
	# Check 3: Town Warning interaction spot remains intact
	var warning_spot = village.get_node_or_null("Interactables/TownWarning")
	var warning_ok: bool = (warning_spot != null and warning_spot is TownWarning)
	
	village.queue_free()
	await process_frame
	
	var t12_ok: bool = (town_elder_ok and survivor_elder_ok and warning_ok)
	if t12_ok:
		report_result("Test 12: Elder Cael town NPC and story/aftermath entities remain present and usable", true)
	else:
		report_result("Test 12: Elder Cael town NPC and story/aftermath entities remain present and usable", false,
			"town_elder=%s, survivor_elder=%s, warning=%s" % [town_elder_ok, survivor_elder_ok, warning_ok])

# TEST 13: Main scene loads and boots cleanly with populated village
func test_13_main_scene_launches_with_npcs() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		report_result("Test 13: Main scene loads and boots cleanly", false, "Could not load main.tscn")
		return
	
	var main_node: Node = main_scene.instantiate()
	root.add_child(main_node)
	await process_frame
	await physics_frame
	
	var village_test_scene: PackedScene = load("res://scenes/test/village_test.tscn")
	var vtest_node: Node = village_test_scene.instantiate()
	root.add_child(vtest_node)
	await process_frame
	await physics_frame
	
	var v_node: Village = vtest_node.get_node_or_null("Village") as Village
	var npcs_in_game: int = v_node.get_npcs().size() if v_node else 0
	var main_ok: bool = (main_node != null and vtest_node != null and npcs_in_game >= 15)
	
	main_node.queue_free()
	vtest_node.queue_free()
	await process_frame
	
	if main_ok:
		report_result("Test 13: Main scene and test environment boot cleanly with %d active NPCs" % npcs_in_game, true)
	else:
		report_result("Test 13: Main scene and test environment boot cleanly with active NPCs", false,
			"main=%s, vtest=%s, npcs=%d" % [main_node != null, vtest_node != null, npcs_in_game])

# TEST 14: Player collision does not displace, drag, or corrupt NPC
func test_14_player_collision_independence() -> void:
	var npc_scene: PackedScene = load("res://scenes/npcs/npc_base.tscn")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	
	var npc: NPCBase = npc_scene.instantiate() as NPCBase
	var player: Player = player_scene.instantiate() as Player
	root.add_child(npc)
	root.add_child(player)
	
	npc.global_position = Vector2(200, 200)
	player.global_position = Vector2(185, 200) # 15px to left of NPC
	await process_frame
	await physics_frame
	
	var initial_npc_pos := npc.global_position
	
	# Player attempts to walk directly right into the NPC for 30 physics ticks
	player.velocity = Vector2(80.0, 0.0)
	for i in range(30):
		player.move_and_slide()
		npc._physics_process(0.016)
	
	# NPC must not have been pushed, dragged, or inherited velocity
	var npc_not_dragged: bool = (npc.global_position.distance_to(initial_npc_pos) < 0.1)
	var npc_vel_zero: bool = (npc.velocity == Vector2.ZERO)
	
	# Move player away to the left
	player.velocity = Vector2(-80.0, 0.0)
	for i in range(20):
		player.move_and_slide()
		npc._physics_process(0.016)
	
	# NPC remains intact and at initial position
	var post_clear_pos: bool = (npc.global_position.distance_to(initial_npc_pos) < 0.1)
	
	var t14_ok: bool = (npc_not_dragged and npc_vel_zero and post_clear_pos)
	
	player.queue_free()
	npc.queue_free()
	await process_frame
	
	if t14_ok:
		report_result("Test 14: Player collision does not displace, drag, or corrupt NPC state", true)
	else:
		report_result("Test 14: Player collision does not displace, drag, or corrupt NPC state", false,
			"not_dragged=%s, vel_zero=%s, post_clear=%s" % [npc_not_dragged, npc_vel_zero, post_clear_pos])

# TEST 15: Two colliding NPCs do not permanently lock each other
func test_15_npc_collision_no_permanent_lock() -> void:
	var npc_scene: PackedScene = load("res://scenes/npcs/npc_base.tscn")
	var npc_a: NPCBase = npc_scene.instantiate() as NPCBase
	var npc_b: NPCBase = npc_scene.instantiate() as NPCBase
	root.add_child(npc_a)
	root.add_child(npc_b)
	
	# Place them 20px apart along X axis facing each other
	npc_a.global_position = Vector2(200, 200)
	npc_b.global_position = Vector2(230, 200)
	npc_a.set_rng_seed(101)
	npc_b.set_rng_seed(102)
	
	# Set conflicting routes: A walks east to (260, 200), B walks west to (170, 200)
	npc_a.set_waypoints([Vector2(260, 200), Vector2(170, 200)])
	npc_b.set_waypoints([Vector2(170, 200), Vector2(260, 200)])
	await process_frame
	await physics_frame
	
	var observed_yield: bool = false
	# Step through 80 physics ticks (enough time to collide and trigger recovery/yielding)
	for i in range(80):
		npc_a._physics_process(0.016)
		npc_b._physics_process(0.016)
		if npc_a._is_yielding or npc_b._is_yielding or npc_a.current_state == NPCBase.State.IDLE or npc_b.current_state == NPCBase.State.IDLE:
			observed_yield = true
	
	# Verify neither NPC has corrupted/diagonal velocity
	var vel_cardinal_a: bool = (npc_a.velocity.x == 0.0 or npc_a.velocity.y == 0.0)
	var vel_cardinal_b: bool = (npc_b.velocity.x == 0.0 or npc_b.velocity.y == 0.0)
	var t15_ok: bool = (observed_yield and vel_cardinal_a and vel_cardinal_b)
	
	npc_a.queue_free()
	npc_b.queue_free()
	await process_frame
	
	if t15_ok:
		report_result("Test 15: Colliding NPCs yield cleanly without mutual permanent locking", true)
	else:
		report_result("Test 15: Colliding NPCs yield cleanly without mutual permanent locking", false,
			"observed_yield=%s, cardinal_a=%s, cardinal_b=%s" % [observed_yield, vel_cardinal_a, vel_cardinal_b])

# TEST 16: NPC recovers and resumes waypoint progress after temporary obstruction is removed
func test_16_waypoint_recovery_after_obstruction() -> void:
	var npc_scene: PackedScene = load("res://scenes/npcs/npc_base.tscn")
	var npc: NPCBase = npc_scene.instantiate() as NPCBase
	root.add_child(npc)
	npc.global_position = Vector2(100, 100)
	npc.set_rng_seed(333)
	npc.set_waypoints([Vector2(160, 100)])
	await process_frame
	await physics_frame
	
	# Spawn a static obstacle directly in front at (120, 100)
	var obstacle := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(16, 20)
	col.shape = box
	obstacle.add_child(col)
	root.add_child(obstacle)
	obstacle.global_position = Vector2(120, 100)
	await process_frame
	await physics_frame
	
	# Run 50 ticks into obstacle: NPC hits obstacle and triggers stuck recovery
	for i in range(50):
		npc._physics_process(0.016)
	
	var blocked_pos: Vector2 = npc.global_position
	var detected_obstruction: bool = (npc._stuck_timer > 0.0 or npc._is_yielding or npc._consecutive_stuck_count > 0)
	
	# Remove the obstacle
	obstacle.queue_free()
	await process_frame
	
	# Run another 60 ticks: NPC resumes route and progresses past blocked_pos toward target
	for i in range(60):
		npc._physics_process(0.016)
	
	var resumed_and_progressed: bool = (npc.global_position.x > blocked_pos.x)
	var t16_ok: bool = (detected_obstruction and resumed_and_progressed)
	
	npc.queue_free()
	await process_frame
	
	if t16_ok:
		report_result("Test 16: NPC successfully recovers and resumes route after temporary obstruction", true)
	else:
		report_result("Test 16: NPC successfully recovers and resumes route after temporary obstruction", false,
			"detected_obstruction=%s, progressed=%s (blocked_x=%.1f, final_x=%.1f)" % [
				detected_obstruction, resumed_and_progressed, blocked_pos.x, npc.global_position.x
			])

# TEST 17: Critical game routes (Town Hall entrance & Seabed transition) are completely safe
func test_17_critical_routes_safety() -> void:
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	
	var npcs: Array[NPCBase] = village.get_npcs()
	
	# Check 1: Town Hall entrance / door at (480, 126) - no NPC within 24px
	var th_door := Vector2(480, 126)
	var th_clear: bool = true
	var th_blocker: String = ""
	for npc in npcs:
		if npc.position.distance_to(th_door) < 24.0:
			th_clear = false
			th_blocker = "%s at %s" % [npc.name, npc.position]
			break
	
	# Check 2: Seabed access ladder & transition zone (X: 460-500, Y: 370-435) - no NPC inside
	var seabed_rect := Rect2(Vector2(460, 370), Vector2(40, 65))
	var seabed_clear: bool = true
	var seabed_blocker: String = ""
	for npc in npcs:
		if seabed_rect.has_point(npc.position):
			seabed_clear = false
			seabed_blocker = "%s at %s" % [npc.name, npc.position]
			break
		# Check all waypoints
		for wp in npc.waypoints:
			if seabed_rect.has_point(wp):
				seabed_clear = false
				seabed_blocker = "%s waypoint at %s" % [npc.name, wp]
				break
		if not seabed_clear:
			break
	
	village.queue_free()
	await process_frame
	
	var t17_ok: bool = (th_clear and seabed_clear)
	if t17_ok:
		report_result("Test 17: Critical routes (Town Hall entrance and Seabed transition) are completely clear", true)
	else:
		report_result("Test 17: Critical routes are completely clear", false,
			"th_clear=%s (%s), seabed_clear=%s (%s)" % [th_clear, th_blocker, seabed_clear, seabed_blocker])
