class_name MajorTruthDiscoveryTestScene
extends Node2D

@onready var player: Player = $Player
@onready var overlook: MajorTruthDiscovery = $OverlookArea/MajorTruthDiscovery
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var message_ui: AtmosphericMessageUI = $AtmosphericMessageUI

@onready var investigation_status_label: Label = $DebugHUD/Panel/VBoxContainer/InvestigationStatusLabel
@onready var clue_status_label: Label = $DebugHUD/Panel/VBoxContainer/ClueStatusLabel
@onready var truth_status_label: Label = $DebugHUD/Panel/VBoxContainer/TruthStatusLabel
@onready var prompt_status_label: Label = $DebugHUD/Panel/VBoxContainer/PromptStatusLabel
@onready var progress_status_label: Label = $DebugHUD/Panel/VBoxContainer/ProgressStatusLabel

func _ready() -> void:
	if player:
		# Bounded test arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	if overlook:
		overlook.truth_attempted.connect(_on_truth_attempted)
		overlook.truth_sequence_started.connect(_on_truth_sequence_started)
		overlook.truth_revealed.connect(_on_truth_revealed)
	
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_flag_changed)
	
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_I:
			var current: bool = StoryStateController.is_investigating()
			StoryStateController.set_story_flag("investigation_started", not current)
			_update_hud()
			AtmosphericMessageUI.display("Toggled investigation_started: %s" % str(not current))
		elif event.physical_keycode == KEY_C:
			var current: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
			StoryStateController.set_story_flag("shipwreck_clue_found", not current)
			_update_hud()
			AtmosphericMessageUI.display("Toggled shipwreck_clue_found: %s" % str(not current))
		elif event.physical_keycode == KEY_R:
			StoryStateController.reset_story_state()
			_update_hud()
			AtmosphericMessageUI.display("StoryState reset to baseline.")

func _on_truth_attempted(was_gated: bool) -> void:
	print("[TruthTest] Overlook interaction attempted. was_gated=%s" % str(was_gated))
	_update_hud()

func _on_truth_sequence_started() -> void:
	print("[TruthTest] Major truth discovery sequence initiated.")
	_update_hud()

func _on_truth_revealed() -> void:
	print("[TruthTest] Major truth revealed and recorded in StoryState.")
	_update_hud()

func _on_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_hud()

func _update_hud() -> void:
	if not investigation_status_label:
		return
	
	var is_inv: bool = StoryStateController.is_investigating()
	var clue_found: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	var truth_found: bool = StoryStateController.is_truth_known()
	var can_truth: bool = StoryStateController.can_reveal_truth() if StoryStateController.instance == null else StoryStateController.instance.can_discover_truth()
	var progress: float = StoryStateController.get_story_progress()
	
	if is_inv:
		investigation_status_label.text = "Investigation Phase: ACTIVE [I to toggle]"
		investigation_status_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		investigation_status_label.text = "Investigation Phase: INACTIVE [I to toggle]"
		investigation_status_label.modulate = Color(1.0, 0.6, 0.4)
	
	if clue_found:
		clue_status_label.text = "Shipwreck Ledger: DISCOVERED [C to toggle]"
		clue_status_label.modulate = Color(0.4, 1.0, 0.6)
	else:
		clue_status_label.text = "Shipwreck Ledger: UNDISCOVERED [C to toggle]"
		clue_status_label.modulate = Color(0.8, 0.8, 0.8)
	
	if truth_found:
		truth_status_label.text = "Major Truth: REVEALED (major_truth_discovered = true)"
		truth_status_label.modulate = Color(0.3, 1.0, 0.9)
	elif can_truth:
		truth_status_label.text = "Can Reveal Truth: READY (Conditions Met)"
		truth_status_label.modulate = Color(1.0, 0.9, 0.3)
	else:
		truth_status_label.text = "Can Reveal Truth: LOCKED (Requires Investigation + Clue)"
		truth_status_label.modulate = Color(1.0, 0.4, 0.4)
	
	if prompt_status_label and overlook:
		prompt_status_label.text = "Overlook Prompt: \"%s\"" % overlook.prompt_message
	
	if progress_status_label:
		progress_status_label.text = "Story Progress: %d%%" % int(progress * 100.0)
