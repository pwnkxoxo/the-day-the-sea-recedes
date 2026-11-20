class_name StoryStateTestScene
extends Node2D

@onready var player: Player = $Player
@onready var progress_label: Label = $DebugHUD/Panel/VBoxContainer/ProgressLabel
@onready var investigation_label: Label = $DebugHUD/Panel/VBoxContainer/InvestigationLabel
@onready var truth_label: Label = $DebugHUD/Panel/VBoxContainer/TruthLabel
@onready var flags_label: Label = $DebugHUD/Panel/VBoxContainer/FlagsLabel

@onready var shell_marker: Interactable = $Interactables/ShellMarker
@onready var pool_marker: Interactable = $Interactables/PoolMarker
@onready var birds_marker: Interactable = $Interactables/BirdsMarker
@onready var tremor_marker: Interactable = $Interactables/TremorMarker
@onready var wind_marker: Interactable = $Interactables/WindMarker
@onready var shipwreck_marker: Interactable = $Interactables/ShipwreckMarker
@onready var truth_marker: Interactable = $Interactables/TruthMarker

func _ready() -> void:
	if player:
		# Bounded test arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	_connect_markers()
	
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_flag_changed)
	
	if OceanStateController.instance:
		OceanStateController.instance.state_changed.connect(_on_ocean_state_changed)
	
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			StoryStateController.reset_story_state()
			_update_hud()
			AtmosphericMessageUI.display("StoryState reset to baseline.")
		elif event.physical_keycode == KEY_T:
			if OceanStateController.is_ocean_normal():
				OceanStateController.trigger_ocean_retreat()
			else:
				OceanStateController.reset_ocean_state()
			_update_hud()

func _connect_markers() -> void:
	if shell_marker:
		shell_marker.interacted.connect(func(_p):
			_record_and_announce("shell_sign_seen", "The shell hums with a faint rhythm.")
		)
	if pool_marker:
		pool_marker.interacted.connect(func(_p):
			_record_and_announce("tide_pool_sign_seen", "The tide pool is strangely drained.")
		)
	if birds_marker:
		birds_marker.interacted.connect(func(_p):
			_record_and_announce("birds_sign_seen", "Seabirds have abandoned the shoreline.")
		)
	if tremor_marker:
		tremor_marker.interacted.connect(func(_p):
			_record_and_announce("tremor_sign_seen", "A low tremor rumbles beneath the floor.")
		)
	if wind_marker:
		wind_marker.interacted.connect(func(_p):
			_record_and_announce("wind_sign_seen", "An unnatural draft blows across the sand.")
		)
	if shipwreck_marker:
		shipwreck_marker.interacted.connect(func(_p):
			_record_and_announce("shipwreck_clue_found", "Discovered a weathered nautical notation.")
		)
	if truth_marker:
		truth_marker.interacted.connect(func(_p):
			var can_reveal: bool = StoryStateController.can_reveal_truth() if StoryStateController.instance == null else StoryStateController.instance.can_discover_truth()
			if can_reveal:
				_record_and_announce("major_truth_discovered", "THE TRUTH: The ocean retreat heralds a great wall of water.")
			else:
				AtmosphericMessageUI.display("Incomplete clues. Must start investigation and find shipwreck log first.")
		)

func _record_and_announce(flag_name: String, msg: String) -> void:
	AtmosphericMessageUI.display(msg)
	if StoryStateController.instance:
		StoryStateController.instance.set_flag(flag_name, true)
	else:
		StoryStateController.set_story_flag(flag_name, true)
	_update_hud()

func _on_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_hud()

func _on_ocean_state_changed(_new_state: OceanStateController.State) -> void:
	_update_hud()

func _update_hud() -> void:
	if not progress_label:
		return
	
	var progress: float = StoryStateController.get_story_progress()
	var sign_count: int = StoryStateController.get_sign_count()
	var is_inv: bool = StoryStateController.is_investigating()
	var can_truth: bool = StoryStateController.can_reveal_truth() if StoryStateController.instance == null else StoryStateController.instance.can_discover_truth()
	var truth_found: bool = StoryStateController.is_truth_known()
	
	progress_label.text = "Story Progress: %d%% | Strange Signs: %d/3" % [int(progress * 100), sign_count]
	
	if is_inv:
		investigation_label.text = "Investigation Phase: ACTIVE"
		investigation_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		investigation_label.text = "Investigation Phase: INACTIVE (Need %d more sign%s)" % [
			maxi(0, 3 - sign_count), "s" if (3 - sign_count) != 1 else ""
		]
		investigation_label.modulate = Color(0.8, 0.8, 0.8)
	
	truth_label.text = "Can Reveal Truth: %s | Major Truth Uncovered: %s" % [
		"YES" if can_truth else "NO", "YES" if truth_found else "NO"
	]
	truth_label.modulate = Color(1.0, 0.8, 0.4) if truth_found else Color(0.7, 0.85, 1.0)
	
	var flags_text: String = "Active Flags: "
	var active_list: Array[String] = []
	for f in StoryStateController.DEFAULT_FLAGS.keys():
		var has_f: bool = StoryStateController.has_story_flag(f)
		if has_f:
			active_list.append(f)
	if active_list.is_empty():
		flags_text += "(None)"
	else:
		flags_text += ", ".join(active_list)
	flags_label.text = flags_text
