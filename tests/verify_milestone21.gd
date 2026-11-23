extends SceneTree

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 21 VERIFICATION SUITE ---")
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
	await test_1_npc_scene_loads()
	await test_2_npc_is_characterbody2d()
	await test_3_required_nodes_exist()
	await test_4_strict_4direction_movement()
	await test_5_diagonal_velocity_impossible()
	await test_6_facing_direction_updates()
	await test_7_idle_and_walk_animation_states()
	await test_8_move_toward_waypoint()
	await test_9_stop_at_waypoint()
	await test_10_cycle_between_waypoints()
	await test_11_movement_locking()
	await test_12_movement_unlocking()
	await test_13_npc_interaction_compatibility()
	await test_14_seeded_randomness_reproducible()

	print("\n==================================================")
	print("--- MILESTONE 21 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# Helper to spawn a clean NPC in tree
func _spawn_npc(pos: Vector2 = Vector2(200, 200)) -> NPCBase:
	var scene: PackedScene = load("res://scenes/npcs/npc_base.tscn")
	var npc: NPCBase = scene.instantiate() as NPCBase
	root.add_child(npc)
	npc.global_position = pos
	return npc

# TEST 1: NPC scene loads
func test_1_npc_scene_loads() -> void:
	var scene: PackedScene = load("res://scenes/npcs/npc_base.tscn")
	if scene == null:
		report_result("Test 1: NPC scene loads", false, "Could not load res://scenes/npcs/npc_base.tscn")
		return
	
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	
	var is_valid := (inst != null and inst is Node2D)
	inst.queue_free()
	await process_frame
	
	if is_valid:
		report_result("Test 1: NPC scene loads and instantiates cleanly", true)
	else:
		report_result("Test 1: NPC scene loads and instantiates cleanly", false, "Instantiation failed")

# TEST 2: NPC is a CharacterBody2D
func test_2_npc_is_characterbody2d() -> void:
	var npc := _spawn_npc()
	await process_frame
	await physics_frame
	
	var is_cb2d: bool = (npc is CharacterBody2D)
	var is_npc_base: bool = (npc is NPCBase)
	
	npc.queue_free()
	await process_frame
	
	if is_cb2d and is_npc_base:
		report_result("Test 2: NPC inherits CharacterBody2D and NPCBase", true)
	else:
		report_result("Test 2: NPC inherits CharacterBody2D and NPCBase", false,
			"is_cb2d=%s, is_npc_base=%s" % [is_cb2d, is_npc_base])

# TEST 3: Required sprite/collision/interaction nodes exist
func test_3_required_nodes_exist() -> void:
	var npc := _spawn_npc()
	await process_frame
	await physics_frame
	
	var has_sprite: bool = (npc.sprite != null and npc.sprite is Sprite2D and npc.sprite.position == Vector2(0, -5))
	var has_col: bool = (npc.collision_shape != null and npc.collision_shape.shape is RectangleShape2D)
	var has_area: bool = (npc.interaction_area != null and npc.interaction_area is Interactable)
	var has_anim: bool = (npc.animation_player != null)
	
	npc.queue_free()
	await process_frame
	
	if has_sprite and has_col and has_area and has_anim:
		report_result("Test 3: Required Sprite2D, CollisionShape2D, InteractionArea, and AnimationPlayer exist", true)
	else:
		report_result("Test 3: Required Sprite2D, CollisionShape2D, InteractionArea, and AnimationPlayer exist", false,
			"sprite=%s, col=%s, area=%s, anim=%s" % [has_sprite, has_col, has_area, has_anim])

# TEST 4: NPC supports strict 4-direction movement
func test_4_strict_4direction_movement() -> void:
	var npc := _spawn_npc()
	await process_frame
	await physics_frame
	
	# Up
	npc.walk_in_direction(Vector2.UP)
	npc._physics_process(0.016)
	var up_ok: bool = npc.velocity.is_equal_approx(Vector2(0, -npc.speed))
	
	# Down
	npc.walk_in_direction(Vector2.DOWN)
	npc._physics_process(0.016)
	var down_ok: bool = npc.velocity.is_equal_approx(Vector2(0, npc.speed))
	
	# Left
	npc.walk_in_direction(Vector2.LEFT)
	npc._physics_process(0.016)
	var left_ok: bool = npc.velocity.is_equal_approx(Vector2(-npc.speed, 0))
	
	# Right
	npc.walk_in_direction(Vector2.RIGHT)
	npc._physics_process(0.016)
	var right_ok: bool = npc.velocity.is_equal_approx(Vector2(npc.speed, 0))
	
	npc.stop_moving()
	npc.queue_free()
	await process_frame
	
	var t4_ok: bool = (up_ok and down_ok and left_ok and right_ok)
	if t4_ok:
		report_result("Test 4: Strict 4-direction velocity confirmed across all cardinal axes", true)
	else:
		report_result("Test 4: Strict 4-direction velocity confirmed across all cardinal axes", false,
			"up=%s, down=%s, left=%s, right=%s" % [up_ok, down_ok, left_ok, right_ok])

# TEST 5: Diagonal velocity is impossible
func test_5_diagonal_velocity_impossible() -> void:
	var npc := _spawn_npc(Vector2(100, 100))
	await process_frame
	await physics_frame
	
	# Set a diagonally offset waypoint (200, 180)
	npc.set_waypoints([Vector2(200, 180)])
	
	var never_diagonal := true
	# Step through 30 physics ticks
	for i in range(30):
		npc._physics_process(0.016)
		# Velocity must never have both non-zero X and non-zero Y
		if npc.velocity.x != 0.0 and npc.velocity.y != 0.0:
			never_diagonal = false
	
	npc.queue_free()
	await process_frame
	
	if never_diagonal:
		report_result("Test 5: Diagonal velocity is strictly impossible during waypoint navigation", true)
	else:
		report_result("Test 5: Diagonal velocity is strictly impossible during waypoint navigation", false, "Diagonal velocity observed")

# TEST 6: Facing direction updates correctly
func test_6_facing_direction_updates() -> void:
	var npc := _spawn_npc(Vector2(100, 100))
	await process_frame
	await physics_frame
	
	npc.face_direction(Vector2.UP)
	var up_ok: bool = (npc.facing_direction == Vector2.UP and npc.get_facing_direction_name() == "up")
	
	npc.face_direction(Vector2.DOWN)
	var down_ok: bool = (npc.facing_direction == Vector2.DOWN and npc.get_facing_direction_name() == "down")
	
	npc.face_direction(Vector2.LEFT)
	var left_ok: bool = (npc.facing_direction == Vector2.LEFT and npc.get_facing_direction_name() == "left")
	
	npc.face_direction(Vector2.RIGHT)
	var right_ok: bool = (npc.facing_direction == Vector2.RIGHT and npc.get_facing_direction_name() == "right")
	
	# face_towards a target to the right
	npc.face_towards(Vector2(300, 100))
	var towards_ok: bool = (npc.facing_direction == Vector2.RIGHT)
	
	npc.queue_free()
	await process_frame
	
	var t6_ok: bool = (up_ok and down_ok and left_ok and right_ok and towards_ok)
	if t6_ok:
		report_result("Test 6: Facing direction updates and face_towards() operates accurately", true)
	else:
		report_result("Test 6: Facing direction updates and face_towards() operates accurately", false,
			"up=%s, down=%s, left=%s, right=%s, towards=%s" % [up_ok, down_ok, left_ok, right_ok, towards_ok])

# TEST 7: Idle/walk animation states exist
func test_7_idle_and_walk_animation_states() -> void:
	var npc := _spawn_npc()
	await process_frame
	await physics_frame
	
	var states: Array[String] = NPCBase.ANIM_STATES
	var has_all_8 := true
	for s in ["idle_up", "idle_down", "idle_left", "idle_right", "walk_up", "walk_down", "walk_left", "walk_right"]:
		if not states.has(s) or not npc.animation_player.has_animation(s):
			has_all_8 = false
	
	# Walking state
	npc.walk_in_direction(Vector2.RIGHT)
	npc._physics_process(0.016)
	var is_walk_right: bool = (npc.get_animation_state() == "walk_right")
	
	# Idle state
	npc.stop_moving()
	npc._physics_process(0.016)
	var is_idle_right: bool = (npc.get_animation_state() == "idle_right")
	
	npc.queue_free()
	await process_frame
	
	var t7_ok: bool = (has_all_8 and is_walk_right and is_idle_right)
	if t7_ok:
		report_result("Test 7: All 8 animation states exist and transition between walk/idle correctly", true)
	else:
		report_result("Test 7: All 8 animation states exist and transition between walk/idle correctly", false,
			"has_all_8=%s, is_walk_right=%s, is_idle_right=%s" % [has_all_8, is_walk_right, is_idle_right])

# TEST 8: NPC can move toward a waypoint
func test_8_move_toward_waypoint() -> void:
	var npc := _spawn_npc(Vector2(100, 100))
	await process_frame
	await physics_frame
	
	npc.set_waypoints([Vector2(150, 100)])
	var initial_x: float = npc.global_position.x
	
	# Process 10 ticks
	for i in range(10):
		npc._physics_process(0.016)
	
	var moved: bool = (npc.global_position.x > initial_x and npc.global_position.x <= 150.0)
	
	npc.queue_free()
	await process_frame
	
	if moved:
		report_result("Test 8: NPC moves toward target waypoint along cardinal path", true)
	else:
		report_result("Test 8: NPC moves toward target waypoint along cardinal path", false,
			"initial_x=%.1f, current_x=%.1f" % [initial_x, npc.global_position.x])

# TEST 9: NPC can stop at a waypoint
func test_9_stop_at_waypoint() -> void:
	var npc := _spawn_npc(Vector2(100, 100))
	await process_frame
	await physics_frame
	
	var reached_signal_box := [false]
	npc.waypoint_reached.connect(func(_idx, _pos): reached_signal_box[0] = true)
	
	# Set waypoint close by so it arrives quickly
	npc.set_waypoints([Vector2(101, 100)])
	npc.waypoint_wait_time = 2.0
	
	# Process ticks until arrival
	for i in range(10):
		npc._physics_process(0.016)
	
	var stopped_at_wp: bool = (
		npc.global_position.is_equal_approx(Vector2(101, 100)) and
		npc.velocity == Vector2.ZERO and
		npc.current_state == NPCBase.State.IDLE and
		reached_signal_box[0]
	)
	var final_pos := npc.global_position
	var final_vel := npc.velocity
	var final_state := npc.get_state_name()
	var signal_fired: bool = reached_signal_box[0]
	
	npc.queue_free()
	await process_frame
	
	if stopped_at_wp:
		report_result("Test 9: NPC snaps to waypoint, zeroes velocity, transitions to IDLE, and emits signal", true)
	else:
		report_result("Test 9: NPC snaps to waypoint, zeroes velocity, transitions to IDLE, and emits signal", false,
			"pos=%s, vel=%s, state=%s, reached=%s" % [final_pos, final_vel, final_state, signal_fired])

# TEST 10: NPC can cycle between waypoints
func test_10_cycle_between_waypoints() -> void:
	var npc := _spawn_npc(Vector2(100, 100))
	await process_frame
	await physics_frame
	
	npc.set_waypoints([Vector2(101, 100), Vector2(102, 100)])
	npc.loop_waypoints = true
	npc.waypoint_wait_time = 0.0 # Instant advance
	
	# Step 1: Reach waypoint 0
	for i in range(5):
		npc._physics_process(0.016)
	var at_wp0: bool = (npc.current_waypoint_index == 0)
	
	# Step 2: Advance to waypoint 1
	npc._advance_waypoint()
	var at_wp1: bool = (npc.current_waypoint_index == 1)
	
	# Step 3: Cycle back to waypoint 0
	npc._advance_waypoint()
	var cycled_back: bool = (npc.current_waypoint_index == 0)
	
	npc.queue_free()
	await process_frame
	
	var t10_ok: bool = (at_wp0 and at_wp1 and cycled_back)
	if t10_ok:
		report_result("Test 10: NPC waypoint index increments and cycles cleanly", true)
	else:
		report_result("Test 10: NPC waypoint index increments and cycles cleanly", false,
			"at_wp0=%s, at_wp1=%s, cycled_back=%s" % [at_wp0, at_wp1, cycled_back])

# TEST 11: Movement locking works
func test_11_movement_locking() -> void:
	var npc := _spawn_npc(Vector2(100, 100))
	await process_frame
	await physics_frame
	
	npc.set_waypoints([Vector2(150, 100)])
	npc.lock_movement()
	
	var pos_before: Vector2 = npc.global_position
	for i in range(10):
		npc._physics_process(0.016)
	
	var locked_ok: bool = (
		npc.is_movement_locked and
		npc.velocity == Vector2.ZERO and
		npc.global_position == pos_before
	)
	
	npc.queue_free()
	await process_frame
	
	if locked_ok:
		report_result("Test 11: lock_movement() freezes velocity and halts waypoint progression", true)
	else:
		report_result("Test 11: lock_movement() freezes velocity and halts waypoint progression", false,
			"locked=%s, vel=%s, moved=%s" % [npc.is_movement_locked, npc.velocity, npc.global_position != pos_before])

# TEST 12: Movement unlocking works
func test_12_movement_unlocking() -> void:
	var npc := _spawn_npc(Vector2(100, 100))
	await process_frame
	await physics_frame
	
	npc.set_waypoints([Vector2(150, 100)])
	npc.lock_movement()
	npc.unlock_movement()
	
	for i in range(10):
		npc._physics_process(0.016)
	
	var unlocked_ok: bool = (not npc.is_movement_locked and npc.global_position.x > 100.0)
	
	npc.queue_free()
	await process_frame
	
	if unlocked_ok:
		report_result("Test 12: unlock_movement() restores movement towards target", true)
	else:
		report_result("Test 12: unlock_movement() restores movement towards target", false,
			"locked=%s, pos_x=%.1f" % [npc.is_movement_locked, npc.global_position.x])

# TEST 13: NPC interaction remains compatible
func test_13_npc_interaction_compatibility() -> void:
	var npc := _spawn_npc(Vector2(200, 200))
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player.global_position = Vector2(190, 200) # 10px to the left of NPC
	await process_frame
	await physics_frame
	
	var npc_interacted_box := [false]
	npc.interacted.connect(func(_p): npc_interacted_box[0] = true)
	
	# Register interaction area
	player.nearby_interactables.clear()
	player.nearby_interactables.append(npc.interaction_area)
	
	# Player attempts interaction
	var did_interact: bool = player.try_interact()
	
	# NPC should face player (player is to the left, so NPC should face LEFT)
	var faced_player: bool = (npc.facing_direction == Vector2.LEFT)
	var signal_fired: bool = npc_interacted_box[0]
	
	player.queue_free()
	npc.queue_free()
	await process_frame
	
	var t13_ok: bool = (did_interact and signal_fired and faced_player)
	if t13_ok:
		report_result("Test 13: NPC integrates with Player interaction and faces approaching player", true)
	else:
		report_result("Test 13: NPC integrates with Player interaction and faces approaching player", false,
			"interact=%s, signal=%s, faced_left=%s" % [did_interact, signal_fired, faced_player])

# TEST 14: Seeded randomness produces reproducible results
func test_14_seeded_randomness_reproducible() -> void:
	var npc_a := _spawn_npc()
	var npc_b := _spawn_npc()
	await process_frame
	await physics_frame
	
	npc_a.set_rng_seed(98765)
	npc_b.set_rng_seed(98765)
	
	var seq_a: Array[float] = []
	var seq_b: Array[float] = []
	
	for i in range(5):
		seq_a.append(npc_a.get_random_float(0.0, 100.0))
		seq_b.append(npc_b.get_random_float(0.0, 100.0))
	
	var seq_match := true
	for i in range(5):
		if not is_equal_approx(seq_a[i], seq_b[i]):
			seq_match = false
	
	npc_a.queue_free()
	npc_b.queue_free()
	await process_frame
	
	if seq_match:
		report_result("Test 14: Seeded randomness produces 100% identical, reproducible output sequences", true)
	else:
		report_result("Test 14: Seeded randomness produces 100% identical, reproducible output sequences", false,
			"seq_a=%s, seq_b=%s" % [seq_a, seq_b])
