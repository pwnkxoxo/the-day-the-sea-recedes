class_name EvacuationEscapeTestScene
extends Node2D

@onready var player: Player = $Player
@onready var town_hall_door: ColorRect = get_node_or_null("Buildings/TownHall/Door")
@onready var alarm_beacon: Node2D = get_node_or_null("Buildings/TownHall/AlarmBeacon")
@onready var town_warning: TownWarning = get_node_or_null("Interactables/TownWarning")
@onready var high_ground_zone: HighGroundZone = $HighGroundZone
@onready var evacuation_props: Node2D = get_node_or_null("EvacuationProps")
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var message_ui: AtmosphericMessageUI = $AtmosphericMessageUI

@onready var town_warned_label: Label = $DebugHUD/Panel/VBoxContainer/TownWarnedLabel
@onready var evacuation_started_label: Label = $DebugHUD/Panel/VBoxContainer/EvacuationStartedLabel
@onready var high_ground_reached_label: Label = $DebugHUD/Panel/VBoxContainer/HighGroundReachedLabel
@onready var high_ground_status_label: Label = $DebugHUD/Panel/VBoxContainer/HighGroundStatusLabel
@onready var progress_label: Label = $DebugHUD/Panel/VBoxContainer/ProgressLabel

## Scripted dialogue initiating the evacuation.
const EVACUATION_INTRO_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Sens",
		"text": "People are abandoning the lower village... everyone is heading uphill!"
	},
	{
		"speaker": "Sens",
		"text": "The wind is turning cold. I need to reach the high ground cliff lookout before the water strikes!"
	}
]

var _is_evacuation_transitioning: bool = false

func _ready() -> void:
	if player:
		# Bounded test arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	if high_ground_zone:
		high_ground_zone.high_ground_reached.connect(_on_high_ground_reached)
		high_ground_zone.high_ground_attempted.connect(_on_high_ground_attempted)
	
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_flag_changed)
	
	_update_visuals()
	_update_hud()
	call_deferred("_check_evacuation_start")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			var current: bool = StoryStateController.is_village_warned()
			StoryStateController.set_story_flag("town_warned", not current)
			if not current:
				# Also ensure prerequisites are set if testing town_warned directly
				StoryStateController.set_story_flag("ocean_retreat_seen", true)
				StoryStateController.set_story_flag("investigation_started", true)
				StoryStateController.set_story_flag("shipwreck_clue_found", true)
				StoryStateController.set_story_flag("major_truth_discovered", true)
			_update_visuals()
			_update_hud()
			AtmosphericMessageUI.display("Toggled town_warned: %s" % str(not current))
			if not current:
				_check_evacuation_start()
		elif event.physical_keycode == KEY_R:
			StoryStateController.reset_story_state()
			if high_ground_zone:
				high_ground_zone.has_triggered = false
				high_ground_zone.is_active = true
			_is_evacuation_transitioning = false
			_update_visuals()
			_update_hud()
			AtmosphericMessageUI.display("StoryState reset to baseline.")

func _on_flag_changed(flag_name: String, _new_val: bool) -> void:
	_update_visuals()
	_update_hud()
	if flag_name == "town_warned":
		_check_evacuation_start()

func _on_high_ground_reached() -> void:
	print("[EvacuationEscapeTest] High ground reached signal received!")
	_update_visuals()
	_update_hud()

func _on_high_ground_attempted(was_gated: bool) -> void:
	print("[EvacuationEscapeTest] High ground entry attempted. was_gated=%s" % str(was_gated))
	_update_hud()

## Evaluates whether evacuation start sequence should initiate.
func _check_evacuation_start() -> void:
	var is_warned: bool = StoryStateController.is_village_warned()
	if not is_warned:
		return
	if StoryStateController.has_story_flag("evacuation_started"):
		return
	if _is_evacuation_transitioning:
		return
	_is_evacuation_transitioning = true
	
	AtmosphericMessageUI.display("People are leaving the lower village. Head for high ground.")
	
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_evacuation_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_evacuation_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(EVACUATION_INTRO_DIALOGUE, player)
	else:
		_finalize_evacuation_start()

func _on_evacuation_dialogue_ended() -> void:
	_finalize_evacuation_start()

func _finalize_evacuation_start() -> void:
	_is_evacuation_transitioning = false
	StoryStateController.set_story_flag("evacuation_started", true)
	_update_visuals()
	_update_hud()
	print("[EvacuationEscapeTest] Evacuation started: evacuation_started = true")

func _update_visuals() -> void:
	var is_warned: bool = StoryStateController.is_village_warned()
	if alarm_beacon:
		alarm_beacon.visible = is_warned
	if town_hall_door:
		town_hall_door.color = Color(0.08, 0.05, 0.04, 1) if is_warned else Color(0.25, 0.18, 0.12, 1)
	if evacuation_props:
		evacuation_props.visible = is_warned

func _update_hud() -> void:
	if not town_warned_label:
		return
	
	var town_warned: bool = StoryStateController.is_village_warned()
	var evac_started: bool = StoryStateController.has_story_flag("evacuation_started")
	var high_ground_reached: bool = StoryStateController.has_story_flag("evacuation_reached_high_ground")
	var progress: float = StoryStateController.get_story_progress()
	
	if town_warned:
		town_warned_label.text = "town_warned: TRUE [T to toggle]"
		town_warned_label.modulate = Color(0.3, 1.0, 0.9)
	else:
		town_warned_label.text = "town_warned: FALSE [T to toggle]"
		town_warned_label.modulate = Color(1.0, 0.6, 0.4)
	
	if evac_started:
		evacuation_started_label.text = "evacuation_started: TRUE (Active Urgency)"
		evacuation_started_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		evacuation_started_label.text = "evacuation_started: FALSE (Normal State)"
		evacuation_started_label.modulate = Color(0.8, 0.8, 0.8)
	
	if high_ground_reached:
		high_ground_reached_label.text = "evacuation_reached_high_ground: TRUE"
		high_ground_reached_label.modulate = Color(0.4, 1.0, 0.4)
		high_ground_status_label.text = "High-Ground Status: SAFE (Wave Imminent)"
		high_ground_status_label.modulate = Color(0.4, 1.0, 0.4)
	elif town_warned:
		high_ground_reached_label.text = "evacuation_reached_high_ground: FALSE"
		high_ground_reached_label.modulate = Color(1.0, 0.9, 0.3)
		high_ground_status_label.text = "High-Ground Status: ACCESSIBLE (Climb the Ridge!)"
		high_ground_status_label.modulate = Color(1.0, 0.9, 0.3)
	else:
		high_ground_reached_label.text = "evacuation_reached_high_ground: FALSE"
		high_ground_reached_label.modulate = Color(0.8, 0.8, 0.8)
		high_ground_status_label.text = "High-Ground Status: GATED (Town Not Warned)"
		high_ground_status_label.modulate = Color(0.8, 0.8, 0.8)
	
	if progress_label:
		progress_label.text = "Story Progress: %d%%" % int(progress * 100.0)
