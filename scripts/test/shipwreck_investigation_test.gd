class_name ShipwreckInvestigationTestScene
extends Node2D

@onready var player: Player = $Player
@onready var investigation: ShipwreckInvestigation = $ShipwreckArea/ShipwreckInvestigation
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var message_ui: AtmosphericMessageUI = $AtmosphericMessageUI

@onready var investigation_status_label: Label = $DebugHUD/Panel/VBoxContainer/InvestigationStatusLabel
@onready var clue_status_label: Label = $DebugHUD/Panel/VBoxContainer/ClueStatusLabel
@onready var truth_status_label: Label = $DebugHUD/Panel/VBoxContainer/TruthStatusLabel
@onready var prompt_status_label: Label = $DebugHUD/Panel/VBoxContainer/PromptStatusLabel

func _ready() -> void:
	if player:
		# Bounded test arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	if investigation:
		investigation.investigation_attempted.connect(_on_investigation_attempted)
		investigation.discovery_started.connect(_on_discovery_started)
		investigation.clue_discovered.connect(_on_clue_discovered)
	
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_flag_changed)
	
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_I:
			var current: bool = StoryStateController.is_investigating()
			StoryStateController.set_story_flag("investigation_started", not current)
			_update_hud()
			AtmosphericMessageUI.display("Toggled investigation_started to: %s" % str(not current))
		elif event.physical_keycode == KEY_R:
			StoryStateController.reset_story_state()
			_update_hud()
			AtmosphericMessageUI.display("StoryState reset to baseline.")

func _on_investigation_attempted(was_gated: bool) -> void:
	print("[ShipwreckTest] Investigation attempted. was_gated=%s" % str(was_gated))
	_update_hud()

func _on_discovery_started() -> void:
	print("[ShipwreckTest] Discovery sequence initiated.")
	_update_hud()

func _on_clue_discovered() -> void:
	print("[ShipwreckTest] Clue discovered and recorded in StoryState.")
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
	
	if is_inv:
		investigation_status_label.text = "Investigation Phase: ACTIVE (Gate Open)"
		investigation_status_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		investigation_status_label.text = "Investigation Phase: INACTIVE (Gate Locked — Press I to toggle)"
		investigation_status_label.modulate = Color(1.0, 0.6, 0.4)
	
	if clue_found:
		clue_status_label.text = "Shipwreck Ledger: DISCOVERED (shipwreck_clue_found = true)"
		clue_status_label.modulate = Color(0.4, 1.0, 0.6)
	else:
		clue_status_label.text = "Shipwreck Ledger: UNDISCOVERED (Waiting for search)"
		clue_status_label.modulate = Color(0.8, 0.8, 0.8)
	
	truth_status_label.text = "Can Reveal Truth: %s | Major Truth Discovered: %s" % [
		"YES" if can_truth else "NO", "YES" if truth_found else "NO"
	]
	
	if investigation:
		prompt_status_label.text = "Shipwreck Action Prompt: \"%s\"" % investigation.prompt_message
