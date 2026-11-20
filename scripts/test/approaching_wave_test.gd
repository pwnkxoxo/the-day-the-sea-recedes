class_name ApproachingWaveTestScene
extends Node2D

@onready var player: Player = $Player
@onready var approaching_wave: ApproachingWave = $ApproachingWave
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var message_ui: AtmosphericMessageUI = $AtmosphericMessageUI

@onready var town_warned_label: Label = $DebugHUD/Panel/VBoxContainer/TownWarnedLabel
@onready var evac_started_label: Label = $DebugHUD/Panel/VBoxContainer/EvacStartedLabel
@onready var high_ground_label: Label = $DebugHUD/Panel/VBoxContainer/HighGroundLabel
@onready var wave_started_label: Label = $DebugHUD/Panel/VBoxContainer/WaveStartedLabel
@onready var wave_arrived_label: Label = $DebugHUD/Panel/VBoxContainer/WaveArrivedLabel
@onready var survived_label: Label = $DebugHUD/Panel/VBoxContainer/SurvivedLabel
@onready var wave_state_label: Label = $DebugHUD/Panel/VBoxContainer/WaveStateLabel
@onready var progress_label: Label = $DebugHUD/Panel/VBoxContainer/ProgressLabel

func _ready() -> void:
	if player:
		# Bounded arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	if approaching_wave:
		approaching_wave.wave_started.connect(_on_wave_started)
		approaching_wave.wave_approaching.connect(_on_wave_approaching)
		approaching_wave.wave_impacted.connect(_on_wave_impacted)
		approaching_wave.wave_completed.connect(_on_wave_completed)
		approaching_wave.wave_attempted.connect(_on_wave_attempted)
	
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_flag_changed)
	
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			var current: bool = StoryStateController.is_high_ground_reached()
			var new_val: bool = not current
			if new_val:
				# Ensure prerequisites are set for testing
				StoryStateController.set_story_flag("ocean_retreat_seen", true)
				StoryStateController.set_story_flag("investigation_started", true)
				StoryStateController.set_story_flag("shipwreck_clue_found", true)
				StoryStateController.set_story_flag("major_truth_discovered", true)
				StoryStateController.set_story_flag("town_warned", true)
				StoryStateController.set_story_flag("evacuation_started", true)
			StoryStateController.set_story_flag("evacuation_reached_high_ground", new_val)
			_update_hud()
			AtmosphericMessageUI.display("Toggled evacuation_reached_high_ground: %s" % str(new_val))
		elif event.physical_keycode == KEY_W:
			print("[ApproachingWaveTest] Manual wave trigger (W pressed). Checking gate...")
			if approaching_wave:
				var success: bool = approaching_wave.start_wave_event(player)
				if not success and not StoryStateController.can_trigger_wave_event():
					AtmosphericMessageUI.display("Wave event gated: Reach high ground first! (Press T)")
			_update_hud()
		elif event.physical_keycode == KEY_R:
			StoryStateController.reset_story_state()
			if approaching_wave:
				approaching_wave.current_state = ApproachingWave.WaveState.IDLE
				approaching_wave._setup_visuals()
			_update_hud()
			AtmosphericMessageUI.display("StoryState and wave event reset to baseline.")

func _on_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_hud()

func _on_wave_started() -> void:
	print("[ApproachingWaveTest] Wave started event received.")
	_update_hud()

func _on_wave_approaching() -> void:
	print("[ApproachingWaveTest] Wave approaching event received.")
	_update_hud()

func _on_wave_impacted() -> void:
	print("[ApproachingWaveTest] Wave arrival impact event received.")
	_update_hud()

func _on_wave_completed() -> void:
	print("[ApproachingWaveTest] Wave completion event received.")
	_update_hud()

func _on_wave_attempted(was_gated: bool) -> void:
	print("[ApproachingWaveTest] Wave attempt: was_gated=%s" % str(was_gated))
	_update_hud()

func _update_hud() -> void:
	if not town_warned_label:
		return
	
	var warned: bool = StoryStateController.is_village_warned()
	var evac: bool = StoryStateController.has_story_flag("evacuation_started")
	var hg: bool = StoryStateController.is_high_ground_reached()
	var w_started: bool = StoryStateController.is_wave_approaching()
	var w_arrived: bool = StoryStateController.is_wave_hit()
	var survived: bool = StoryStateController.has_player_survived()
	var progress: float = StoryStateController.get_story_progress()
	var state_str: String = approaching_wave.get_state_string() if approaching_wave else "UNKNOWN"
	
	town_warned_label.text = "town_warned: %s" % str(warned).to_upper()
	town_warned_label.modulate = Color(0.4, 1.0, 0.4) if warned else Color(0.8, 0.8, 0.8)
	
	evac_started_label.text = "evacuation_started: %s" % str(evac).to_upper()
	evac_started_label.modulate = Color(0.4, 1.0, 0.4) if evac else Color(0.8, 0.8, 0.8)
	
	high_ground_label.text = "evacuation_reached_high_ground: %s [T to toggle]" % str(hg).to_upper()
	high_ground_label.modulate = Color(0.3, 1.0, 0.9) if hg else Color(1.0, 0.6, 0.4)
	
	wave_started_label.text = "wave_event_started: %s" % str(w_started).to_upper()
	wave_started_label.modulate = Color(1.0, 0.85, 0.3) if w_started else Color(0.8, 0.8, 0.8)
	
	wave_arrived_label.text = "wave_arrived: %s" % str(w_arrived).to_upper()
	wave_arrived_label.modulate = Color(1.0, 0.4, 0.4) if w_arrived else Color(0.8, 0.8, 0.8)
	
	survived_label.text = "survived_wave: %s" % str(survived).to_upper()
	survived_label.modulate = Color(0.4, 1.0, 0.4) if survived else Color(0.8, 0.8, 0.8)
	
	wave_state_label.text = "Wave State: %s (Press W to trigger)" % state_str
	match state_str:
		"IDLE": wave_state_label.modulate = Color(0.8, 0.8, 0.8)
		"APPROACHING": wave_state_label.modulate = Color(1.0, 0.85, 0.3)
		"ARRIVING": wave_state_label.modulate = Color(1.0, 0.4, 0.4)
		"COMPLETE": wave_state_label.modulate = Color(0.4, 1.0, 0.4)
	
	if progress_label:
		progress_label.text = "Story Progress: %d%%" % int(progress * 100.0)
