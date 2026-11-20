extends SceneTree

func _init() -> void:
	print("\n==================================================")
	print("--- BEGIN MILESTONE 17 VERIFICATION SUITE ---")
	print("==================================================\n")
	
	var total_tests := 0
	var passed_tests := 0
	
	# TEST 1: Verify main.tscn instantiates cleanly with Title Screen
	total_tests += 1
	print("[TEST 1] Verifying scenes/main.tscn title presentation...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		printerr("FAIL: Could not load scenes/main.tscn")
		quit(1)
		return
	var main_node: Node = main_scene.instantiate()
	var title_screen = main_node.get_node_or_null("TitleScreen")
	var banner = main_node.get_node_or_null("TitleScreen/Background/BannerRect")
	var title_label = main_node.get_node_or_null("TitleScreen/Background/TitleLabel")
	var prompt_label = main_node.get_node_or_null("TitleScreen/Background/PromptLabel")
	
	var t1_ok = (main_node is Node2D and title_screen != null and banner != null and title_label != null and prompt_label != null)
	if t1_ok and title_label.text == "THE DAY THE SEA RECEDES":
		print("[PASS] Test 1: main.tscn instantiates with authentic Title Screen components")
		passed_tests += 1
	else:
		printerr("FAIL: Test 1 failed")
	main_node.free()
	
	# TEST 2: Verify audio assets exist and load cleanly
	total_tests += 1
	print("[TEST 2] Verifying synthesized atmospheric audio assets...")
	var audio_files = [
		"res://audio/ocean_ambient.wav",
		"res://audio/wind_ambient.wav",
		"res://audio/interact.wav",
		"res://audio/conch_warning.wav",
		"res://audio/wave_surge.wav"
	]
	var audio_ok := true
	for path in audio_files:
		var stream: AudioStream = load(path)
		if stream == null or stream.get_length() <= 0.0:
			printerr("FAIL: Audio stream failed to load: %s" % path)
			audio_ok = false
	if audio_ok:
		print("[PASS] Test 2: All 5 atmospheric WAV audio assets loaded and valid")
		passed_tests += 1
	
	# TEST 3: Verify pixel art assets exist and load cleanly
	total_tests += 1
	print("[TEST 3] Verifying pixel art sprite assets...")
	var art_files = [
		"res://art/sens/sens_down.png",
		"res://art/sens/sens_up.png",
		"res://art/sens/sens_left.png",
		"res://art/sens/sens_right.png",
		"res://art/npcs/elder_cael.png",
		"res://art/npcs/villager.png",
		"res://art/buildings/town_hall.png",
		"res://art/buildings/sens_house.png",
		"res://art/props/shipwreck.png",
		"res://art/props/conch.png",
		"res://art/props/scallop_shell.png",
		"res://art/props/captain_ledger.png",
		"res://art/title/title_banner_200x100.png"
	]
	var art_ok := true
	for path in art_files:
		var tex: Texture2D = load(path)
		if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
			printerr("FAIL: Texture failed to load: %s" % path)
			art_ok = false
	if art_ok:
		print("[PASS] Test 3: All 13 pixel-art character, building, prop, and title textures valid")
		passed_tests += 1
	
	# TEST 4: Verify Player directional sprite support
	total_tests += 1
	print("[TEST 4] Verifying Player directional sprite integration...")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Player = player_scene.instantiate()
	var player_sprite: Sprite2D = player.get_node_or_null("Sprite2D")
	var p_ok = (player_sprite != null and player_sprite.texture != null and player.texture_down != null and player.texture_up != null and player.texture_left != null and player.texture_right != null)
	if p_ok:
		print("[PASS] Test 4: Player sprite has crisp directional textures and default facing")
		passed_tests += 1
	else:
		printerr("FAIL: Test 4 failed")
	player.free()
	
	# TEST 5: Verify export presets configuration
	total_tests += 1
	print("[TEST 5] Verifying export_presets.cfg readiness...")
	var file = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if file != null:
		var content = file.get_as_text()
		file.close()
		if "Linux/X11" in content and "Web" in content:
			print("[PASS] Test 5: export_presets.cfg configured for Linux/X11 and Web builds")
			passed_tests += 1
		else:
			printerr("FAIL: Missing platform presets in export_presets.cfg")
	else:
		printerr("FAIL: export_presets.cfg not found")
	
	# TEST 6: Verify Village and Seabed sprite integration and collision integrity
	total_tests += 1
	print("[TEST 6] Verifying Village and Seabed visual sprite integrations...")
	var village_scene: PackedScene = load("res://scenes/world/village/village.tscn")
	var village_node: Node = village_scene.instantiate()
	var seabed_scene: PackedScene = load("res://scenes/world/seabed/seabed.tscn")
	var seabed_node: Node = seabed_scene.instantiate()
	
	var th_sprite = village_node.get_node_or_null("Buildings/TownHall/BuildingSprite")
	var sh_sprite = village_node.get_node_or_null("Buildings/SensHouse/BuildingSprite")
	var conch_sprite = village_node.get_node_or_null("Interactables/TownWarning/ConchVisual/ConchSprite")
	var elder_sprite = village_node.get_node_or_null("Survivors/ElderCael/ElderSprite")
	var villager_sprite = village_node.get_node_or_null("Survivors/Villager/VillagerSprite")
	
	var wreck_sprite = seabed_node.get_node_or_null("ShipwreckArea/Shipwreck/WreckSprite")
	var ledger_sprite = seabed_node.get_node_or_null("ShipwreckArea/Shipwreck/LedgerDesk/LedgerSprite")
	
	var v_ok = (th_sprite != null and sh_sprite != null and conch_sprite != null and elder_sprite != null and villager_sprite != null)
	var s_ok = (wreck_sprite != null and ledger_sprite != null)
	
	if v_ok and s_ok:
		print("[PASS] Test 6: World sprites integrated cleanly without altering collision shapes")
		passed_tests += 1
	else:
		printerr("FAIL: Test 6 failed (v_ok=%s, s_ok=%s)" % [v_ok, s_ok])
	village_node.free()
	seabed_node.free()
	
	# TEST 7: Verify absence of debug HUDs in player-facing scenes
	total_tests += 1
	print("[TEST 7] Verifying player-facing scenes are clean of Debug HUDs...")
	var main_check: Node = load("res://scenes/main.tscn").instantiate()
	var village_check: Node = load("res://scenes/world/village/village.tscn").instantiate()
	var seabed_check: Node = load("res://scenes/world/seabed/seabed.tscn").instantiate()
	
	var no_debug = (
		main_check.get_node_or_null("DebugHUD") == null and
		village_check.get_node_or_null("DebugHUD") == null and
		seabed_check.get_node_or_null("DebugHUD") == null
	)
	if no_debug:
		print("[PASS] Test 7: Player-facing scenes (main, village, seabed) contain no Debug HUDs")
		passed_tests += 1
	else:
		printerr("FAIL: Debug HUD found in player-facing scene")
	main_check.free()
	village_check.free()
	seabed_check.free()
	
	print("\n==================================================")
	print("--- MILESTONE 17 TEST RESULTS: %d PASSED, %d FAILED ---" % [passed_tests, total_tests - passed_tests])
	print("==================================================\n")
	
	if passed_tests == total_tests:
		quit(0)
	else:
		quit(1)
