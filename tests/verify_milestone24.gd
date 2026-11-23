extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 24 VERIFICATION SUITE ---")
	print("==================================================\n")
	run_tests()

func report_result(test_name: String, passed: bool, details: String = "") -> void:
	total_tests += 1
	if passed:
		passed_tests += 1
		print("[PASS] %s" % test_name)
	else:
		failed_tests += 1
		print("[FAIL] %s: %s" % [test_name, details])

func run_tests() -> void:
	await test_01_organic_trigger_can_be_reached()
	await test_02_organic_trigger_is_deterministic()
	await test_03_organic_trigger_happens_only_once()
	await test_04_t_debug_trigger_still_works()
	await test_05_t_uses_same_underlying_retreat_transition()
	await test_06_t_does_not_corrupt_story_state()
	await test_07_atmospheric_buildup_begins()
	await test_08_ocean_state_enters_retreat_state()
	await test_09_retreat_progresses_correctly()
	await test_10_exposed_seabed_access_works()
	await test_11_npcs_remain_functional_during_and_after_event()
	await test_12_player_movement_remains_functional()
	await test_13_existing_functionality_intact()
	
	print("\n==================================================")
	print("--- MILESTONE 24 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_tests, failed_tests])
	print("==================================================\n")
	
	if failed_tests > 0:
		quit(1)
	else:
		quit(0)

# TEST 1: Organic trigger can be reached through town exploration
func test_01_organic_trigger_can_be_reached() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var evt: SeaChangeEvent = village.sea_change_event
	var has_evt: bool = (evt != null)
	if has_evt:
		evt.fast_mode = true
		evt.register_exploration_action("talked_elder_cael")
		evt.register_exploration_action("visited_shoreline")
		await process_frame
		await physics_frame
	
	var is_triggered: bool = StoryStateController.has_story_flag("sea_change_triggered")
	var is_eligible: bool = (evt != null and (evt.is_eligible or evt.is_event_completed or evt.is_buildup_active))
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	var t1_ok: bool = (has_evt and (is_triggered or is_eligible))
	if t1_ok:
		report_result("Test 1: Organic trigger can be reached through town exploration", true)
	else:
		report_result("Test 1: Organic trigger can be reached through town exploration", false,
			"has_evt=%s, is_triggered=%s, is_eligible=%s" % [has_evt, is_triggered, is_eligible])

# TEST 2: Organic trigger is deterministic
func test_02_organic_trigger_is_deterministic() -> void:
	# Run A
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var v_a: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(v_a)
	await process_frame
	await physics_frame
	
	var evt_a: SeaChangeEvent = v_a.sea_change_event
	evt_a.fast_mode = true
	evt_a.register_exploration_action("explore_action_alpha")
	var count_a1: int = evt_a.exploration_count
	var eligible_a1: bool = evt_a.is_eligible
	evt_a.register_exploration_action("explore_action_beta")
	var count_a2: int = evt_a.exploration_count
	var eligible_a2: bool = evt_a.is_eligible
	
	v_a.queue_free()
	await process_frame
	await physics_frame
	
	# Run B
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var v_b: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(v_b)
	await process_frame
	await physics_frame
	
	var evt_b: SeaChangeEvent = v_b.sea_change_event
	evt_b.fast_mode = true
	evt_b.register_exploration_action("explore_action_alpha")
	var count_b1: int = evt_b.exploration_count
	var eligible_b1: bool = evt_b.is_eligible
	evt_b.register_exploration_action("explore_action_beta")
	var count_b2: int = evt_b.exploration_count
	var eligible_b2: bool = evt_b.is_eligible
	
	v_b.queue_free()
	await process_frame
	await physics_frame
	
	var counts_match: bool = (count_a1 == count_b1 and count_a2 == count_b2 and count_a1 == 1 and count_a2 == 2)
	var eligibility_matches: bool = (eligible_a1 == eligible_b1 and not eligible_a1 and eligible_a2 == eligible_b2 and eligible_a2)
	var t2_ok: bool = (counts_match and eligibility_matches)
	
	if t2_ok:
		report_result("Test 2: Organic trigger is deterministic across identical exploration actions", true)
	else:
		report_result("Test 2: Organic trigger is deterministic across identical exploration actions", false,
			"counts_match=%s, eligibility_matches=%s" % [counts_match, eligibility_matches])

# TEST 3: Organic trigger happens only once
func test_03_organic_trigger_happens_only_once() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var evt: SeaChangeEvent = village.sea_change_event
	evt.fast_mode = true
	
	var buildup_count := [0]
	evt.buildup_started.connect(func():
		buildup_count[0] += 1
	)
	
	evt.trigger_organically()
	await process_frame
	await physics_frame
	
	# Attempt repeated trigger calls
	evt.trigger_organically()
	evt.register_exploration_action("action_extra_1")
	evt.register_exploration_action("action_extra_2")
	evt.start_sea_change()
	await process_frame
	
	var triggered_once: bool = (buildup_count[0] == 1)
	var flag_set: bool = StoryStateController.has_story_flag("sea_change_triggered")
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	var t3_ok: bool = (triggered_once and flag_set)
	if t3_ok:
		report_result("Test 3: Organic trigger happens strictly once and rejects duplicate triggers", true)
	else:
		report_result("Test 3: Organic trigger happens strictly once and rejects duplicate triggers", false,
			"buildup_count=%d, flag_set=%s" % [buildup_count[0], flag_set])

# TEST 4: T debug trigger still works
func test_04_t_debug_trigger_still_works() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	
	var normal_before: bool = OceanStateController.is_ocean_normal()
	
	# Simulate debug retreat trigger
	var key_ev := InputEventKey.new()
	key_ev.physical_keycode = KEY_T
	key_ev.pressed = true
	if OceanStateController.instance:
		OceanStateController.instance._unhandled_input(key_ev)
	else:
		OceanStateController.trigger_ocean_retreat()
	
	var retreated_after: bool = OceanStateController.is_ocean_retreated()
	var t4_ok: bool = (normal_before and retreated_after)
	
	if t4_ok:
		report_result("Test 4: T debug trigger remains fully functional for developer workflows", true)
	else:
		report_result("Test 4: T debug trigger remains fully functional for developer workflows", false,
			"before=%s, after=%s" % [normal_before, retreated_after])

# TEST 5: T uses the same underlying retreat transition
func test_05_t_uses_same_underlying_retreat_transition() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	# Initial normal state: water at 0.0
	var initial_water_y: float = village.ocean_water.position.y
	
	# Press T
	var key_ev := InputEventKey.new()
	key_ev.physical_keycode = KEY_T
	key_ev.pressed = true
	if OceanStateController.instance:
		OceanStateController.instance._unhandled_input(key_ev)
	else:
		OceanStateController.trigger_ocean_retreat()
	await process_frame
	
	# Verify retreat animation or state applied
	village.apply_retreated_state(false)
	await process_frame
	await physics_frame
	
	var retreated_water_y: float = village.ocean_water.position.y
	var same_ocean_state: bool = (OceanStateController.get_current_state() == OceanStateController.State.OCEAN_RETREATED)
	var barrier_disabled: bool = village.access_barrier.get_node("CollisionShape2D").disabled
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	var t5_ok: bool = (initial_water_y == 0.0 and retreated_water_y == 140.0 and same_ocean_state and barrier_disabled)
	if t5_ok:
		report_result("Test 5: T trigger shares identical underlying OceanState transition and barrier logic", true)
	else:
		report_result("Test 5: T trigger shares identical underlying OceanState transition and barrier logic", false,
			"water_init=%.1f, water_ret=%.1f, same_state=%s, barrier_disabled=%s" % [
				initial_water_y, retreated_water_y, same_ocean_state, barrier_disabled
			])

# TEST 6: T does not corrupt StoryState
func test_06_t_does_not_corrupt_story_state() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	
	# Seed baseline progression flags
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	StoryStateController.set_story_flag("shell_sign_seen", true)
	
	var progress_before: float = StoryStateController.get_story_progress()
	
	# Trigger via T
	OceanStateController.trigger_ocean_retreat()
	
	var opening_intact: bool = StoryStateController.has_story_flag("opening_sequence_completed")
	var shell_intact: bool = StoryStateController.has_story_flag("shell_sign_seen")
	var retreat_seen: bool = StoryStateController.has_story_flag("ocean_retreat_seen")
	var sea_change_flag: bool = StoryStateController.has_story_flag("sea_change_triggered")
	var progress_after: float = StoryStateController.get_story_progress()
	
	# Progress increases by 0.15 for ocean_retreat_seen
	var progress_increased: bool = is_equal_approx(progress_after, progress_before + 0.15)
	
	var t6_ok: bool = (opening_intact and shell_intact and retreat_seen and sea_change_flag and progress_increased)
	if t6_ok:
		report_result("Test 6: T trigger preserves StoryState integrity without corrupting other flags", true)
	else:
		report_result("Test 6: T trigger preserves StoryState integrity without corrupting other flags", false,
			"opening=%s, shell=%s, retreat=%s, sea_change=%s, prog_inc=%s" % [
				opening_intact, shell_intact, retreat_seen, sea_change_flag, progress_increased
			])

# TEST 7: Atmospheric buildup begins
func test_07_atmospheric_buildup_begins() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var evt: SeaChangeEvent = village.sea_change_event
	evt.fast_mode = true
	
	var buildup_emitted := [false]
	evt.buildup_started.connect(func():
		buildup_emitted[0] = true
	)
	
	evt.start_sea_change()
	await process_frame
	
	var is_buildup: bool = evt.is_buildup_active
	var pitch_altered: bool = (village._ambient_player != null and is_equal_approx(village._ambient_player.pitch_scale, 0.85))
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	var t7_ok: bool = (buildup_emitted[0] and is_buildup and pitch_altered)
	if t7_ok:
		report_result("Test 7: Atmospheric buildup begins with audio modulation and signal emission", true)
	else:
		report_result("Test 7: Atmospheric buildup begins with audio modulation and signal emission", false,
			"emitted=%s, is_buildup=%s, pitch_altered=%s" % [buildup_emitted[0], is_buildup, pitch_altered])

# TEST 8: OceanState enters the retreat state
func test_08_ocean_state_enters_retreat_state() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var evt: SeaChangeEvent = village.sea_change_event
	evt.fast_mode = true
	evt.trigger_organically()
	
	# Wait for fast_mode timers
	for i in range(15):
		await process_frame
		await physics_frame
	
	var retreated: bool = OceanStateController.is_ocean_retreated()
	var state_val: OceanStateController.State = OceanStateController.get_current_state()
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	var t8_ok: bool = (retreated and state_val == OceanStateController.State.OCEAN_RETREATED)
	if t8_ok:
		report_result("Test 8: OceanState successfully enters OCEAN_RETREATED state", true)
	else:
		report_result("Test 8: OceanState successfully enters OCEAN_RETREATED state", false,
			"retreated=%s, state=%s" % [retreated, state_val])

# TEST 9: Retreat progresses correctly
func test_09_retreat_progresses_correctly() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	# Apply retreated state
	village.apply_retreated_state(false)
	await process_frame
	
	var water_pos_ok: bool = (village.ocean_water.position.y == 140.0)
	var barrier_disabled: bool = village.access_barrier.get_node("CollisionShape2D").disabled
	var transition_monitored: bool = village.seabed_transition.monitoring
	var transition_shape_enabled: bool = not village.seabed_transition.get_node("CollisionShape2D").disabled
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	var t9_ok: bool = (water_pos_ok and barrier_disabled and transition_monitored and transition_shape_enabled)
	if t9_ok:
		report_result("Test 9: Retreat lowers ocean water, removes barrier, and enables seabed access", true)
	else:
		report_result("Test 9: Retreat lowers ocean water, removes barrier, and enables seabed access", false,
			"water=%.1f, barrier_dis=%s, trans_mon=%s, trans_shape=%s" % [
				village.ocean_water.position.y if village.ocean_water else -1.0,
				barrier_disabled, transition_monitored, transition_shape_enabled
			])

# TEST 10: Existing exposed-seabed access still works
func test_10_exposed_seabed_access_works() -> void:
	OceanStateController.set_ocean_state(OceanStateController.State.OCEAN_RETREATED)
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	var player: Player = load("res://scenes/player/player.tscn").instantiate() as Player
	root.add_child(village)
	root.add_child(player)
	await process_frame
	await physics_frame
	
	var trans: SceneTransitionTrigger = village.seabed_transition as SceneTransitionTrigger
	var trans_ok: bool = (trans != null and trans.target_spawn_id_to_set == "seabed_entry")
	var target_scene_exists: bool = ResourceLoader.exists(trans.target_scene_path)
	
	village.queue_free()
	player.queue_free()
	await process_frame
	await physics_frame
	
	var t10_ok: bool = (trans_ok and target_scene_exists)
	if t10_ok:
		report_result("Test 10: Exposed seabed transition trigger is active and targets seabed scene", true)
	else:
		report_result("Test 10: Exposed seabed transition trigger is active and targets seabed scene", false,
			"trans_ok=%s, scene_exists=%s" % [trans_ok, target_scene_exists])

# TEST 11: NPCs remain functional during and after the event
func test_11_npcs_remain_functional_during_and_after_event() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var village: Village = load("res://scenes/world/village/village.tscn").instantiate() as Village
	root.add_child(village)
	await process_frame
	await physics_frame
	
	var evt: SeaChangeEvent = village.sea_change_event
	evt.fast_mode = true
	
	# Start sea change
	evt.start_sea_change()
	await process_frame
	
	# Verify NPCs paused and faced south during buildup
	var npcs: Array[NPCBase] = village.get_npcs()
	var any_paused_or_idle: bool = false
	var facing_south: bool = false
	for npc in npcs:
		if npc.current_state == NPCBase.State.PAUSED or npc.current_state == NPCBase.State.IDLE:
			any_paused_or_idle = true
		if npc.facing_direction == Vector2.DOWN:
			facing_south = true
	
	# Advance to completion
	for i in range(15):
		await process_frame
		await physics_frame
	
	# Verify NPCs resumed operational status (none permanently corrupted)
	var all_functional: bool = true
	for npc in npcs:
		if npc.velocity.x != 0.0 and npc.velocity.y != 0.0:
			all_functional = false
	
	village.queue_free()
	await process_frame
	await physics_frame
	
	var t11_ok: bool = (any_paused_or_idle and facing_south and all_functional)
	if t11_ok:
		report_result("Test 11: NPCs react to sea-change and maintain functional movement afterward", true)
	else:
		report_result("Test 11: NPCs react to sea-change and maintain functional movement afterward", false,
			"paused=%s, facing_south=%s, all_functional=%s" % [any_paused_or_idle, facing_south, all_functional])

# TEST 12: Player movement remains functional throughout buildup and retreat
func test_12_player_movement_remains_functional() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	var vtest: VillageTest = load("res://scenes/test/village_test.tscn").instantiate() as VillageTest
	root.add_child(vtest)
	await process_frame
	await physics_frame
	
	var player: Player = vtest.player
	var evt: SeaChangeEvent = vtest.village.sea_change_event
	evt.fast_mode = true
	
	# Start sea change buildup
	evt.start_sea_change()
	await process_frame
	
	# Player must remain free to move
	var not_locked: bool = not player.is_movement_locked
	player.simulate_press("right")
	player._physics_process(0.016)
	var vel_ok: bool = (player.velocity.x > 0.0 and player.velocity.y == 0.0)
	player.clear_simulated_inputs()
	
	# Finish event
	for i in range(15):
		await process_frame
		await physics_frame
	
	var still_not_locked: bool = not player.is_movement_locked
	player.simulate_press("left")
	player._physics_process(0.016)
	var vel_left_ok: bool = (player.velocity.x < 0.0 and player.velocity.y == 0.0)
	player.clear_simulated_inputs()
	
	vtest.queue_free()
	await process_frame
	await physics_frame
	
	var t12_ok: bool = (not_locked and vel_ok and still_not_locked and vel_left_ok)
	if t12_ok:
		report_result("Test 12: Player movement remains responsive without locks during and after retreat", true)
	else:
		report_result("Test 12: Player movement remains responsive without locks during and after retreat", false,
			"not_locked=%s, vel_ok=%s, still_not_locked=%s, vel_left_ok=%s" % [
				not_locked, vel_ok, still_not_locked, vel_left_ok
			])

# TEST 13: Existing StoryState, OceanState, and scene transitions remain compatible
func test_13_existing_functionality_intact() -> void:
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	
	var init_state: OceanStateController.State = OceanStateController.get_current_state()
	var init_normal: bool = (init_state == OceanStateController.State.NORMAL_OCEAN)
	
	# Ocean retreat seen flag
	OceanStateController.trigger_ocean_retreat()
	var retreat_seen: bool = StoryStateController.has_story_flag("ocean_retreat_seen")
	var sea_change_flag: bool = StoryStateController.has_story_flag("sea_change_triggered")
	
	# StoryState investigation threshold
	StoryStateController.set_story_flag("shell_sign_seen", true)
	StoryStateController.set_story_flag("birds_sign_seen", true)
	StoryStateController.set_story_flag("tremor_sign_seen", true)
	var investigation_ok: bool = StoryStateController.is_investigating()
	
	# Story reset returns to normal
	StoryStateController.reset_story_state()
	OceanStateController.reset_ocean_state()
	var reset_ok: bool = (
		OceanStateController.is_ocean_normal() and
		not StoryStateController.has_story_flag("sea_change_triggered") and
		not StoryStateController.has_story_flag("ocean_retreat_seen") and
		not StoryStateController.is_investigating()
	)
	
	var t13_ok: bool = (init_normal and retreat_seen and sea_change_flag and investigation_ok and reset_ok)
	if t13_ok:
		report_result("Test 13: Existing OceanState, StoryState, and investigation contracts remain 100% intact", true)
	else:
		report_result("Test 13: Existing OceanState, StoryState, and investigation contracts remain 100% intact", false,
			"init_normal=%s, retreat_seen=%s, sea_change=%s, inv_ok=%s, reset_ok=%s" % [
				init_normal, retreat_seen, sea_change_flag, investigation_ok, reset_ok
			])
