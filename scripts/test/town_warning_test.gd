class_name TownWarningTestScene
extends Node2D

@onready var player: Player = $Player
@onready var town_warning: TownWarning = $TownWarning
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var message_ui: AtmosphericMessageUI = $AtmosphericMessageUI

@onready var truth_status_label: Label = $DebugHUD/Panel/VBoxContainer/TruthStatusLabel
@onready var warning_status_label: Label = $DebugHUD/Panel/VBoxContainer/WarningStatusLabel
@onready var prompt_status_label: Label = $DebugHUD/Panel/VBoxContainer/PromptStatusLabel
@onready var progress_status_label: Label = $DebugHUD/Panel/VBoxContainer/ProgressStatusLabel

func _ready() -> void:
	if player:
		# Bounded test arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	if town_warning:
		town_warning.warning_attempted.connect(_on_warning_attempted)
		town_warning.warning_sequence_started.connect(_on_warning_sequence_started)
		town_warning.warning_completed.connect(_on_warning_completed)
	
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_flag_changed)
	
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			var current: bool = StoryStateController.is_truth_known()
			StoryStateController.set_story_flag("major_truth_discovered", not current)
			_update_hud()
			AtmosphericMessageUI.display("Toggled major_truth_discovered: %s" % str(not current))
		elif event.physical_keycode == KEY_R:
			StoryStateController.reset_story_state()
			_update_hud()
			AtmosphericMessageUI.display("StoryState reset to baseline.")

func _on_warning_attempted(was_gated: bool) -> void:
	print("[TownWarningTest] Warning attempted. was_gated=%s" % str(was_gated))
	_update_hud()

func _on_warning_sequence_started() -> void:
	print("[TownWarningTest] Warning sequence initiated.")
	_update_hud()

func _on_warning_completed() -> void:
	print("[TownWarningTest] Warning completed and recorded in StoryState.")
	_update_hud()

func _on_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_hud()

func _update_hud() -> void:
	if not truth_status_label:
		return
	
	var truth_found: bool = StoryStateController.is_truth_known()
	var town_warned: bool = StoryStateController.is_village_warned()
	var can_warn: bool = StoryStateController.can_trigger_town_warning() if StoryStateController.instance == null else StoryStateController.instance.can_warn_town()
	var progress: float = StoryStateController.get_story_progress()
	
	if truth_found:
		truth_status_label.text = "Major Truth: DISCOVERED [T to toggle]"
		truth_status_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		truth_status_label.text = "Major Truth: LOCKED [T to toggle]"
		truth_status_label.modulate = Color(1.0, 0.6, 0.4)
	
	if town_warned:
		warning_status_label.text = "Town State: WARNED (Emergency Active)"
		warning_status_label.modulate = Color(0.3, 1.0, 0.9)
	elif can_warn:
		warning_status_label.text = "Town State: READY TO WARN (Interact at Hall)"
		warning_status_label.modulate = Color(1.0, 0.9, 0.3)
	else:
		warning_status_label.text = "Town State: NORMAL (Gate Locked — Discover Truth First)"
		warning_status_label.modulate = Color(0.8, 0.8, 0.8)
	
	if prompt_status_label and town_warning:
		prompt_status_label.text = "Warning Prompt: \"%s\"" % town_warning.prompt_message
	
	if progress_status_label:
		progress_status_label.text = "Story Progress: %d%%" % int(progress * 100.0)
