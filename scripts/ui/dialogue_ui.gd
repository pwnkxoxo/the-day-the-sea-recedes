class_name DialogueUI
extends CanvasLayer

## Emitted when dialogue begins.
signal dialogue_started

## Emitted when the dialogue advances to a new line index.
signal line_advanced(index: int)

## Emitted when the dialogue sequence completes and closes.
signal dialogue_ended

## Static singleton reference for global scene access.
static var instance: DialogueUI = null

@onready var panel: PanelContainer = $PanelContainer
@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TextLabel
@onready var prompt_label: Label = $PanelContainer/MarginContainer/VBoxContainer/FooterContainer/PromptLabel

## Whether dialogue is currently actively being shown.
var is_dialogue_active: bool = false

## Current line index in the active dialogue sequence.
var current_line_index: int = 0

## The active array of dialogue dictionaries: [{"speaker": "...", "text": "..."}]
var current_entries: Array = []

## Reference to the player whose movement is locked during active dialogue.
var _locked_player: Player = null

## Engine frame count when dialogue was opened, preventing same-frame advance.
var _started_on_frame: int = -1

var _audio_player: AudioStreamPlayer = null
var _interact_sound: AudioStream = preload("res://audio/interact.wav")

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	if panel:
		panel.visible = false
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = _interact_sound
	_audio_player.volume_db = -8.0
	add_child(_audio_player)

func _play_click() -> void:
	if _audio_player and _audio_player.stream:
		_audio_player.play()

func _process(_delta: float) -> void:
	if is_dialogue_active and prompt_label:
		# Subtle retro pulse for the continue indicator
		prompt_label.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 200.0)

func _unhandled_input(event: InputEvent) -> void:
	if not is_dialogue_active:
		return
	
	if event.is_action_pressed("interact") and not event.is_echo():
		# Guard against advancing on the same frame that triggered dialogue open
		if Engine.get_process_frames() == _started_on_frame:
			return
		get_viewport().set_input_as_handled()
		advance_dialogue()

## Starts displaying a sequential dialogue array.
## [param entries] Array of Dictionaries with keys "speaker" and "text".
## [param target_player] Optional Player node to lock. If null, auto-discovers player.
func start_dialogue(entries: Array, target_player: Player = null) -> void:
	if entries.is_empty():
		return
	if is_dialogue_active:
		return
	
	current_entries = entries.duplicate()
	current_line_index = 0
	is_dialogue_active = true
	_started_on_frame = Engine.get_process_frames()
	
	_locked_player = target_player if target_player else _find_player()
	if _locked_player and is_instance_valid(_locked_player):
		_locked_player.lock_movement()
	
	if panel:
		panel.visible = true
	
	_display_entry(0)
	_play_click()
	dialogue_started.emit()

## Advances to the next dialogue entry, or closes dialogue if at the end.
func advance_dialogue() -> void:
	if not is_dialogue_active:
		return
	
	current_line_index += 1
	if current_line_index < current_entries.size():
		_display_entry(current_line_index)
		_play_click()
		line_advanced.emit(current_line_index)
	else:
		end_dialogue()

## Closes the dialogue UI, unlocks the player deferred, and emits dialogue_ended.
func end_dialogue() -> void:
	if not is_dialogue_active:
		return
	
	is_dialogue_active = false
	current_entries = []
	current_line_index = 0
	
	if panel:
		panel.visible = false
	if prompt_label:
		prompt_label.modulate.a = 1.0
	
	if _locked_player and is_instance_valid(_locked_player):
		call_deferred("_unlock_player", _locked_player)
	_locked_player = null
	
	dialogue_ended.emit()

## Displays the dialogue entry at the specified index.
func _display_entry(index: int) -> void:
	if index < 0 or index >= current_entries.size():
		return
	
	var entry = current_entries[index]
	var speaker: String = ""
	var text: String = ""
	
	if entry is Dictionary:
		speaker = str(entry.get("speaker", "")).strip_edges()
		text = str(entry.get("text", ""))
	else:
		text = str(entry)
	
	if speaker_label:
		if speaker.is_empty():
			speaker_label.visible = false
		else:
			speaker_label.visible = true
			speaker_label.text = speaker
	
	if text_label:
		text_label.text = text

## Deferred player unlocker ensuring the closing frame does not re-trigger interactions.
func _unlock_player(player_node: Player) -> void:
	if is_instance_valid(player_node):
		player_node.unlock_movement()

## Helper to locate the active Player in the scene tree.
func _find_player() -> Player:
	if not is_inside_tree():
		return null
	var node = get_tree().get_first_node_in_group("player")
	if node is Player:
		return node
	var root_node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	if root_node:
		return root_node.find_child("Player", true, false) as Player
	return null

## Static helper to start dialogue from any script.
static func display_dialogue(entries: Array, target_player: Player = null) -> void:
	if instance:
		instance.start_dialogue(entries, target_player)
	else:
		push_warning("[DialogueUI] No active DialogueUI instance found in scene tree.")

## Alias for display_dialogue.
static func start(entries: Array, target_player: Player = null) -> void:
	display_dialogue(entries, target_player)

## Returns true if dialogue is currently running.
func is_active() -> bool:
	return is_dialogue_active

## Returns the current line index in the active dialogue sequence.
func get_current_index() -> int:
	return current_line_index
