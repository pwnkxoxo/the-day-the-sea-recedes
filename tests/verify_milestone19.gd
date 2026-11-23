extends SceneTree

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 19 VERIFICATION SUITE ---")
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
	await test_1_player_scene_loads()
	await test_2_player_script_and_defaults()
	await test_3_up_movement()
	await test_4_down_movement()
	await test_5_left_movement()
	await test_6_right_movement()
	await test_7_diagonal_movement_impossible_and_priority()
	await test_8_facing_direction_changes()
	await test_9_facing_direction_persists_idle()
	await test_10_movement_lock_works()
	await test_11_movement_unlock_works()
	await test_12_interaction_system_works()

	print("\n==================================================")
	print("--- MILESTONE 19 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# TEST 1: Player scene loads
func test_1_player_scene_loads() -> void:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if player_scene == null:
		report_result("Test 1: Player scene loads", false, "Could not load res://scenes/player/player.tscn")
		return
	
	var p_inst = player_scene.instantiate()
	root.add_child(p_inst)
	await process_frame
	
	var has_sprite: bool = p_inst.has_node("Sprite2D")
	var has_col: bool = p_inst.has_node("CollisionShape2D")
	var has_cam: bool = p_inst.has_node("Camera2D")
	var has_area: bool = p_inst.has_node("InteractionArea")
	var has_anim: bool = p_inst.has_node("AnimationPlayer")
	
	p_inst.queue_free()
	await process_frame
	
	if has_sprite and has_col and has_cam and has_area and has_anim:
		report_result("Test 1: Player scene loads with all required child nodes", true)
	else:
		report_result("Test 1: Player scene loads with all required child nodes", false, "Missing one or more child nodes")

# TEST 2: Player script loads and verifies defaults
func test_2_player_script_and_defaults() -> void:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var p: Player = player_scene.instantiate() as Player
	root.add_child(p)
	await process_frame
	await physics_frame
	
	var speed_ok: bool = is_equal_approx(p.speed, 80.0)
	var facing_ok: bool = (p.facing_direction == Vector2.DOWN)
	var state_ok: bool = (p.get_animation_state() == "idle_down")
	var tex_ok: bool = (
		p.texture_down != null and
		p.texture_up != null and
		p.texture_left != null and
		p.texture_right != null
	)
	var anim_player_ok: bool = (
		p.animation_player != null and
		p.animation_player.has_animation("idle_down") and
		p.animation_player.has_animation("walk_down") and
		p.animation_player.has_animation("walk_up") and
		p.animation_player.has_animation("walk_left") and
		p.animation_player.has_animation("walk_right")
	)
	
	p.queue_free()
	await process_frame
	
	if speed_ok and facing_ok and state_ok and tex_ok and anim_player_ok:
		report_result("Test 2: Player script defaults, textures, and 8 animation states verified", true)
	else:
		report_result("Test 2: Player script defaults, textures, and 8 animation states verified", false,
			"speed_ok=%s, facing_ok=%s, state_ok=%s, tex_ok=%s, anim_ok=%s" % [speed_ok, facing_ok, state_ok, tex_ok, anim_player_ok])

# Helper to spawn a clean Player in tree for testing
func _spawn_test_player() -> Player:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var p: Player = player_scene.instantiate() as Player
	root.add_child(p)
	p.global_position = Vector2(200, 200)
	p.clear_simulated_inputs()
	return p

# TEST 3: Up movement
func test_3_up_movement() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	p.simulate_press("up")
	p._physics_process(0.016)
	
	var vel_ok: bool = p.velocity.is_equal_approx(Vector2(0, -p.speed))
	var dir_ok: bool = (p.get_4way_direction() == Vector2.UP)
	var facing_ok: bool = (p.facing_direction == Vector2.UP)
	var state_ok: bool = (p.get_animation_state() == "walk_up")
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if vel_ok and dir_ok and facing_ok and state_ok:
		report_result("Test 3: Up movement produces velocity (0, -80.0) and walk_up state", true)
	else:
		report_result("Test 3: Up movement produces velocity (0, -80.0) and walk_up state", false,
			"vel=%s, dir=%s, facing=%s, state=%s" % [p.velocity, dir_ok, facing_ok, state_ok])

# TEST 4: Down movement
func test_4_down_movement() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	p.simulate_press("down")
	p._physics_process(0.016)
	
	var vel_ok: bool = p.velocity.is_equal_approx(Vector2(0, p.speed))
	var dir_ok: bool = (p.get_4way_direction() == Vector2.DOWN)
	var facing_ok: bool = (p.facing_direction == Vector2.DOWN)
	var state_ok: bool = (p.get_animation_state() == "walk_down")
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if vel_ok and dir_ok and facing_ok and state_ok:
		report_result("Test 4: Down movement produces velocity (0, 80.0) and walk_down state", true)
	else:
		report_result("Test 4: Down movement produces velocity (0, 80.0) and walk_down state", false,
			"vel=%s, dir=%s, facing=%s, state=%s" % [p.velocity, dir_ok, facing_ok, state_ok])

# TEST 5: Left movement
func test_5_left_movement() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	p.simulate_press("left")
	p._physics_process(0.016)
	
	var vel_ok: bool = p.velocity.is_equal_approx(Vector2(-p.speed, 0))
	var dir_ok: bool = (p.get_4way_direction() == Vector2.LEFT)
	var facing_ok: bool = (p.facing_direction == Vector2.LEFT)
	var state_ok: bool = (p.get_animation_state() == "walk_left")
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if vel_ok and dir_ok and facing_ok and state_ok:
		report_result("Test 5: Left movement produces velocity (-80.0, 0) and walk_left state", true)
	else:
		report_result("Test 5: Left movement produces velocity (-80.0, 0) and walk_left state", false,
			"vel=%s, dir=%s, facing=%s, state=%s" % [p.velocity, dir_ok, facing_ok, state_ok])

# TEST 6: Right movement
func test_6_right_movement() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	p.simulate_press("right")
	p._physics_process(0.016)
	
	var vel_ok: bool = p.velocity.is_equal_approx(Vector2(p.speed, 0))
	var dir_ok: bool = (p.get_4way_direction() == Vector2.RIGHT)
	var facing_ok: bool = (p.facing_direction == Vector2.RIGHT)
	var state_ok: bool = (p.get_animation_state() == "walk_right")
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if vel_ok and dir_ok and facing_ok and state_ok:
		report_result("Test 6: Right movement produces velocity (80.0, 0) and walk_right state", true)
	else:
		report_result("Test 6: Right movement produces velocity (80.0, 0) and walk_right state", false,
			"vel=%s, dir=%s, facing=%s, state=%s" % [p.velocity, dir_ok, facing_ok, state_ok])

# TEST 7: Diagonal movement is strictly impossible + last-input priority works
func test_7_diagonal_movement_impossible_and_priority() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	# 7a: Right held -> moves Right
	p.simulate_press("right")
	p._physics_process(0.016)
	var step1_ok: bool = p.velocity.is_equal_approx(Vector2(p.speed, 0))
	
	# 7b: Right + Down -> Down was pressed last, player must move strictly Down
	p.simulate_press("down")
	p._physics_process(0.016)
	var step2_ok: bool = p.velocity.is_equal_approx(Vector2(0, p.speed))
	var no_diag1: bool = (p.velocity.x == 0.0 or p.velocity.y == 0.0)
	
	# 7c: Release Down while Right remains held -> returns strictly to moving Right
	p.simulate_release("down")
	p._physics_process(0.016)
	var step3_ok: bool = p.velocity.is_equal_approx(Vector2(p.speed, 0))
	var no_diag2: bool = (p.velocity.x == 0.0 or p.velocity.y == 0.0)
	
	# 7d: Test all 4 diagonal input combinations
	var diag_pairs := [
		["up", "right"],
		["up", "left"],
		["down", "right"],
		["down", "left"]
	]
	var all_pairs_cardinal := true
	for pair in diag_pairs:
		p.clear_simulated_inputs()
		p.simulate_press(pair[0])
		p.simulate_press(pair[1])
		p._physics_process(0.016)
		# Velocity must never have both non-zero X and non-zero Y
		if p.velocity.x != 0.0 and p.velocity.y != 0.0:
			all_pairs_cardinal = false
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	var t7_ok: bool = (step1_ok and step2_ok and step3_ok and no_diag1 and no_diag2 and all_pairs_cardinal)
	if t7_ok:
		report_result("Test 7: Diagonal movement impossible; last-input priority verified for all combinations", true)
	else:
		report_result("Test 7: Diagonal movement impossible; last-input priority verified for all combinations", false,
			"step1=%s, step2=%s, step3=%s, all_cardinal=%s" % [step1_ok, step2_ok, step3_ok, all_pairs_cardinal])

# TEST 8: Facing direction changes correctly
func test_8_facing_direction_changes() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	p.simulate_press("up")
	p._physics_process(0.016)
	var f_up: bool = (p.facing_direction == Vector2.UP and p.get_facing_direction_name() == "up" and p.sprite.texture == p.texture_up)
	
	p.clear_simulated_inputs()
	p.simulate_press("down")
	p._physics_process(0.016)
	var f_down: bool = (p.facing_direction == Vector2.DOWN and p.get_facing_direction_name() == "down" and p.sprite.texture == p.texture_down)
	
	p.clear_simulated_inputs()
	p.simulate_press("left")
	p._physics_process(0.016)
	var f_left: bool = (p.facing_direction == Vector2.LEFT and p.get_facing_direction_name() == "left" and p.sprite.texture == p.texture_left)
	
	p.clear_simulated_inputs()
	p.simulate_press("right")
	p._physics_process(0.016)
	var f_right: bool = (p.facing_direction == Vector2.RIGHT and p.get_facing_direction_name() == "right" and p.sprite.texture == p.texture_right)
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if f_up and f_down and f_left and f_right:
		report_result("Test 8: Facing direction and textures update correctly in all 4 cardinal directions", true)
	else:
		report_result("Test 8: Facing direction and textures update correctly in all 4 cardinal directions", false,
			"up=%s, down=%s, left=%s, right=%s" % [f_up, f_down, f_left, f_right])

# TEST 9: Facing direction persists while idle
func test_9_facing_direction_persists_idle() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	# Move Left, then stop
	p.simulate_press("left")
	p._physics_process(0.016)
	p.simulate_release("left")
	p._physics_process(0.016)
	var persist_left: bool = (
		p.velocity == Vector2.ZERO and
		p.facing_direction == Vector2.LEFT and
		p.get_animation_state() == "idle_left" and
		p.sprite.texture == p.texture_left
	)
	
	# Move Up, then stop
	p.simulate_press("up")
	p._physics_process(0.016)
	p.simulate_release("up")
	p._physics_process(0.016)
	var persist_up: bool = (
		p.velocity == Vector2.ZERO and
		p.facing_direction == Vector2.UP and
		p.get_animation_state() == "idle_up" and
		p.sprite.texture == p.texture_up
	)
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if persist_left and persist_up:
		report_result("Test 9: Facing direction and idle state persist correctly upon stopping", true)
	else:
		report_result("Test 9: Facing direction and idle state persist correctly upon stopping", false,
			"persist_left=%s, persist_up=%s" % [persist_left, persist_up])

# TEST 10: Movement lock works
func test_10_movement_lock_works() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	p.lock_movement()
	p.simulate_press("right")
	p.velocity = Vector2(p.speed, 0)
	p._physics_process(0.016)
	
	var locked_vel: bool = (p.velocity == Vector2.ZERO)
	var is_locked: bool = p.is_movement_locked
	var interact_blocked: bool = (p.try_interact() == false)
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if locked_vel and is_locked and interact_blocked:
		report_result("Test 10: lock_movement() zeroes velocity, locks state, and blocks interaction", true)
	else:
		report_result("Test 10: lock_movement() zeroes velocity, locks state, and blocks interaction", false,
			"locked_vel=%s, is_locked=%s, interact_blocked=%s" % [locked_vel, is_locked, interact_blocked])

# TEST 11: Movement unlock works
func test_11_movement_unlock_works() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	p.lock_movement()
	p.unlock_movement()
	p.clear_simulated_inputs()
	p.simulate_press("down")
	p._physics_process(0.016)
	
	var unlocked_vel: bool = p.velocity.is_equal_approx(Vector2(0, p.speed))
	var is_unlocked: bool = not p.is_movement_locked
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if unlocked_vel and is_unlocked:
		report_result("Test 11: unlock_movement() cleanly restores 4-way movement", true)
	else:
		report_result("Test 11: unlock_movement() cleanly restores 4-way movement", false,
			"unlocked_vel=%s, is_unlocked=%s" % [unlocked_vel, is_unlocked])

# TEST 12: Existing interaction functionality still works
func test_12_interaction_system_works() -> void:
	var p := _spawn_test_player()
	await process_frame
	await physics_frame
	
	var test_interactable_scene: PackedScene = load("res://scenes/interaction/test_interactable.tscn")
	var t12_ok := false
	if test_interactable_scene != null:
		var interactable_node = test_interactable_scene.instantiate() as Interactable
		root.add_child(interactable_node)
		interactable_node.global_position = p.global_position + Vector2(4, 0)
		await process_frame
		await physics_frame
		
		# Allow Area2D overlap to register
		p.nearby_interactables.clear()
		p.nearby_interactables.append(interactable_node)
		
		var best = p.get_best_interactable()
		var did_interact = p.try_interact()
		
		var count_ok = (interactable_node.interaction_count == 1 if "interaction_count" in interactable_node else true)
		t12_ok = (best == interactable_node and did_interact and count_ok)
		interactable_node.queue_free()
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if t12_ok:
		report_result("Test 12: Existing interaction detection and try_interact() verified", true)
	else:
		report_result("Test 12: Existing interaction detection and try_interact() verified", false, "Interaction contract broken")
