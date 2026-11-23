extends SceneTree

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 20 VERIFICATION SUITE ---")
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
	await test_2_player_sprite_exists()
	await test_3_directional_player_assets_available()
	await test_4_texture_filtering_pixel_art()
	await test_5_m19_4direction_compatibility()
	await test_6_eight_animation_states()
	await test_7_facing_direction_changes_and_persists()
	await test_8_movement_locking_integrity()
	await test_9_pixel_art_guide_documentation()

	print("\n==================================================")
	print("--- MILESTONE 20 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_count, failed_count])
	print("==================================================\n")
	
	quit(0 if failed_count == 0 else 1)

# Helper to spawn a clean Player in tree
func _spawn_player() -> Player:
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	var p: Player = scene.instantiate() as Player
	root.add_child(p)
	p.global_position = Vector2(200, 200)
	p.clear_simulated_inputs()
	return p

# TEST 1: Player scene loads
func test_1_player_scene_loads() -> void:
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	if scene == null:
		report_result("Test 1: Player scene loads", false, "Could not load res://scenes/player/player.tscn")
		return
	
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	
	var is_player: bool = (inst is Player and inst is CharacterBody2D)
	var has_anim_player: bool = inst.has_node("AnimationPlayer")
	
	inst.queue_free()
	await process_frame
	
	if is_player and has_anim_player:
		report_result("Test 1: Player scene loads and instantiates as CharacterBody2D with AnimationPlayer", true)
	else:
		report_result("Test 1: Player scene loads and instantiates as CharacterBody2D with AnimationPlayer", false,
			"is_player=%s, has_anim_player=%s" % [is_player, has_anim_player])

# TEST 2: Player sprite exists
func test_2_player_sprite_exists() -> void:
	var p := _spawn_player()
	await process_frame
	await physics_frame
	
	var sprite_exists: bool = (p.sprite != null and p.sprite is Sprite2D)
	var pos_ok: bool = (p.sprite.position == Vector2(0, -5))
	var texture_present: bool = (p.sprite.texture != null)
	
	p.queue_free()
	await process_frame
	
	if sprite_exists and pos_ok and texture_present:
		report_result("Test 2: Player sprite exists with standard feet offset (0, -5) and valid texture", true)
	else:
		report_result("Test 2: Player sprite exists with standard feet offset (0, -5) and valid texture", false,
			"sprite_exists=%s, pos_ok=%s, texture_present=%s" % [sprite_exists, pos_ok, texture_present])

# TEST 3: All four directional player assets are available
func test_3_directional_player_assets_available() -> void:
	var p := _spawn_player()
	await process_frame
	await physics_frame
	
	var directions := ["down", "up", "left", "right"]
	var all_assets_valid := true
	var all_dims_16x24 := true
	
	for d in directions:
		var tex: Texture2D = p.get_directional_texture(d)
		if tex == null:
			all_assets_valid = false
			continue
		var sz := tex.get_size()
		if int(sz.x) != 16 or int(sz.y) != 24:
			all_dims_16x24 = false
	
	p.queue_free()
	await process_frame
	
	if all_assets_valid and all_dims_16x24:
		report_result("Test 3: All four directional assets exist with consistent 16x24 target dimensions", true)
	else:
		report_result("Test 3: All four directional assets exist with consistent 16x24 target dimensions", false,
			"all_assets_valid=%s, all_dims_16x24=%s" % [all_assets_valid, all_dims_16x24])

# TEST 4: Texture filtering is appropriate for pixel art
func test_4_texture_filtering_pixel_art() -> void:
	var p := _spawn_player()
	await process_frame
	await physics_frame
	
	# Verify project-level nearest neighbor defaults
	var default_filter: int = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)
	var snap_transforms: bool = ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", false)
	var snap_vertices: bool = ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel", false)
	
	# Verify node-level texture filtering is Nearest (0 = Inherit Nearest, 1 = Nearest)
	var sprite_filter: int = p.sprite.texture_filter
	var filter_is_nearest: bool = (sprite_filter == CanvasItem.TEXTURE_FILTER_NEAREST or (sprite_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE and default_filter == 0))
	
	p.queue_free()
	await process_frame
	
	var t4_ok: bool = (default_filter == 0 and snap_transforms and snap_vertices and filter_is_nearest)
	if t4_ok:
		report_result("Test 4: Nearest-neighbor texture filtering and pixel snapping confirmed", true)
	else:
		report_result("Test 4: Nearest-neighbor texture filtering and pixel snapping confirmed", false,
			"default_filter=%d, snap_trans=%s, snap_vert=%s, sprite_filter=%d" % [default_filter, snap_transforms, snap_vertices, sprite_filter])

# TEST 5: Player remains compatible with M19's 4-direction movement
func test_5_m19_4direction_compatibility() -> void:
	var p := _spawn_player()
	await process_frame
	await physics_frame
	
	# Up
	p.simulate_press("up")
	p._physics_process(0.016)
	var up_ok: bool = p.velocity.is_equal_approx(Vector2(0, -p.speed))
	
	# Down
	p.clear_simulated_inputs()
	p.simulate_press("down")
	p._physics_process(0.016)
	var down_ok: bool = p.velocity.is_equal_approx(Vector2(0, p.speed))
	
	# Left
	p.clear_simulated_inputs()
	p.simulate_press("left")
	p._physics_process(0.016)
	var left_ok: bool = p.velocity.is_equal_approx(Vector2(-p.speed, 0))
	
	# Right
	p.clear_simulated_inputs()
	p.simulate_press("right")
	p._physics_process(0.016)
	var right_ok: bool = p.velocity.is_equal_approx(Vector2(p.speed, 0))
	
	# Diagonal impossible + priority
	p.simulate_press("down")
	p._physics_process(0.016)
	var diag_priority_ok: bool = p.velocity.is_equal_approx(Vector2(0, p.speed)) and (p.velocity.x == 0.0 or p.velocity.y == 0.0)
	
	p.simulate_release("down")
	p._physics_process(0.016)
	var return_right_ok: bool = p.velocity.is_equal_approx(Vector2(p.speed, 0))
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	var t5_ok: bool = (up_ok and down_ok and left_ok and right_ok and diag_priority_ok and return_right_ok)
	if t5_ok:
		report_result("Test 5: Strict 4-direction movement and last-input priority remain fully intact", true)
	else:
		report_result("Test 5: Strict 4-direction movement and last-input priority remain fully intact", false,
			"up=%s, down=%s, left=%s, right=%s, diag=%s, return=%s" % [up_ok, down_ok, left_ok, right_ok, diag_priority_ok, return_right_ok])

# TEST 6: All eight animation states still exist
func test_6_eight_animation_states() -> void:
	var p := _spawn_player()
	await process_frame
	await physics_frame
	
	var expected_states := [
		"idle_up", "idle_down", "idle_left", "idle_right",
		"walk_up", "walk_down", "walk_left", "walk_right"
	]
	
	var player_states: Array[String] = Player.get_animation_states()
	var all_in_const := true
	for s in expected_states:
		if not player_states.has(s):
			all_in_const = false
	
	var all_in_anim_player := true
	if p.animation_player:
		for s in expected_states:
			if not p.animation_player.has_animation(s):
				all_in_anim_player = false
	else:
		all_in_anim_player = false
	
	p.queue_free()
	await process_frame
	
	if all_in_const and all_in_anim_player:
		report_result("Test 6: All eight canonical animation states exist in script and AnimationPlayer", true)
	else:
		report_result("Test 6: All eight canonical animation states exist in script and AnimationPlayer", false,
			"all_in_const=%s, all_in_anim_player=%s" % [all_in_const, all_in_anim_player])

# TEST 7: Facing direction still changes correctly and persists
func test_7_facing_direction_changes_and_persists() -> void:
	var p := _spawn_player()
	await process_frame
	await physics_frame
	
	p.simulate_press("left")
	p._physics_process(0.016)
	var moving_left: bool = (p.facing_direction == Vector2.LEFT and p.get_animation_state() == "walk_left")
	
	p.simulate_release("left")
	p._physics_process(0.016)
	var idle_left: bool = (p.velocity == Vector2.ZERO and p.facing_direction == Vector2.LEFT and p.get_animation_state() == "idle_left")
	
	p.simulate_press("up")
	p._physics_process(0.016)
	var moving_up: bool = (p.facing_direction == Vector2.UP and p.get_animation_state() == "walk_up")
	
	p.simulate_release("up")
	p._physics_process(0.016)
	var idle_up: bool = (p.velocity == Vector2.ZERO and p.facing_direction == Vector2.UP and p.get_animation_state() == "idle_up")
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	var t7_ok: bool = (moving_left and idle_left and moving_up and idle_up)
	if t7_ok:
		report_result("Test 7: Facing direction and animation states update dynamically and persist when idle", true)
	else:
		report_result("Test 7: Facing direction and animation states update dynamically and persist when idle", false,
			"moving_left=%s, idle_left=%s, moving_up=%s, idle_up=%s" % [moving_left, idle_left, moving_up, idle_up])

# TEST 8: Existing movement locking still works
func test_8_movement_locking_integrity() -> void:
	var p := _spawn_player()
	await process_frame
	await physics_frame
	
	p.lock_movement()
	p.simulate_press("right")
	p._physics_process(0.016)
	var locked_ok: bool = (p.is_movement_locked and p.velocity == Vector2.ZERO)
	
	p.unlock_movement()
	p._physics_process(0.016)
	var unlocked_ok: bool = (not p.is_movement_locked and p.velocity.is_equal_approx(Vector2(p.speed, 0)))
	
	p.clear_simulated_inputs()
	p.queue_free()
	await process_frame
	
	if locked_ok and unlocked_ok:
		report_result("Test 8: lock_movement() and unlock_movement() contracts operate correctly", true)
	else:
		report_result("Test 8: lock_movement() and unlock_movement() contracts operate correctly", false,
			"locked_ok=%s, unlocked_ok=%s" % [locked_ok, unlocked_ok])

# TEST 9: Pixel-Art Documentation verified
func test_9_pixel_art_guide_documentation() -> void:
	var file := FileAccess.open("res://docs/PIXEL_ART_GUIDE.md", FileAccess.READ)
	var guide_exists: bool = (file != null)
	var has_content: bool = false
	if file != null:
		var text: String = file.get_as_text()
		has_content = text.contains("320×180") and text.contains("16×16") and text.contains("16 × 24")
		file.close()
	
	if guide_exists and has_content:
		report_result("Test 9: docs/PIXEL_ART_GUIDE.md exists and documents core pixel-art standards", true)
	else:
		report_result("Test 9: docs/PIXEL_ART_GUIDE.md exists and documents core pixel-art standards", false,
			"guide_exists=%s, has_content=%s" % [guide_exists, has_content])
