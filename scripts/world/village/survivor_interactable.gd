class_name SurvivorInteractable
extends Interactable

## Emitted when an interaction is attempted. [param was_gated] is true if blocked by prerequisites.
signal survivor_interacted(was_gated: bool)

## Emitted when the survivor dialogue begins.
signal survivor_dialogue_started

## Emitted when the survivor dialogue completes.
signal survivor_dialogue_completed

## Display name of the survivor.
@export var survivor_name: String = "Elder Cael"

## Scripted dialogue sequence for this survivor.
@export var dialogue_entries: Array[Dictionary] = []

## Atmospheric message displayed on repeated interactions or quick reflections.
@export var repeated_message: String = ""

## Message displayed if interacted before wave survival prerequisite is met.
@export var gated_message: String = "No one has reached the high ground yet."

## Visual label showing interaction prompt in-world.
@onready var prompt_label: Label = get_node_or_null("PromptLabel")

var has_spoken: bool = false

func _ready() -> void:
	if dialogue_entries.is_empty():
		_setup_default_dialogue()
	_update_prompt()
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_story_flag_changed)

func _process(_delta: float) -> void:
	_update_prompt()

func _on_story_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_prompt()

func _setup_default_dialogue() -> void:
	if survivor_name == "Elder Cael":
		dialogue_entries = [
			{
				"speaker": "Elder Cael",
				"text": "The old stories said the sea would return."
			},
			{
				"speaker": "Elder Cael",
				"text": "I never believed they meant this."
			},
			{
				"speaker": "Elder Cael",
				"text": "You saw the signs before any of us."
			},
			{
				"speaker": "Elder Cael",
				"text": "Because you warned us, the village had time to climb."
			},
			{
				"speaker": "Elder Cael",
				"text": "We lost much of the lower shore... but we survived."
			},
			{
				"speaker": "Elder Cael",
				"text": "The Great Receding was never a celebration."
			},
			{
				"speaker": "Elder Cael",
				"text": "It was a warning."
			}
		]
		repeated_message = "The Great Receding was never a celebration. It was a warning."
	else:
		dialogue_entries = [
			{
				"speaker": survivor_name,
				"text": "We reached the ridge just as the surge reached the doors."
			},
			{
				"speaker": survivor_name,
				"text": "The lower docks and boats are gone, but everyone made it to the cliffs."
			},
			{
				"speaker": survivor_name,
				"text": "If you hadn't warned the town, we wouldn't have survived."
			}
		]
		repeated_message = "The water is still out there, but we are safe up here."

func can_interact_survivor() -> bool:
	return StoryStateController.has_player_survived()

func _update_prompt() -> void:
	var can_talk: bool = can_interact_survivor()
	if can_talk:
		prompt_message = "Talk to %s" % survivor_name
	else:
		prompt_message = survivor_name
	
	if prompt_label:
		if can_talk:
			prompt_label.text = "Talk to %s [E]" % survivor_name
			prompt_label.modulate = Color(0.9, 0.95, 1.0)
		else:
			prompt_label.text = "%s" % survivor_name
			prompt_label.modulate = Color(0.6, 0.6, 0.6)

func interact(player: Player) -> void:
	if not is_interactable:
		return
	
	super.interact(player)
	
	var can_talk: bool = can_interact_survivor()
	if not can_talk:
		survivor_interacted.emit(true)
		AtmosphericMessageUI.display(gated_message)
		return
	
	survivor_interacted.emit(false)
	survivor_dialogue_started.emit()
	
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(dialogue_entries, player)
	else:
		_on_dialogue_ended()

func _on_dialogue_ended() -> void:
	has_spoken = true
	survivor_dialogue_completed.emit()
	if not repeated_message.is_empty():
		AtmosphericMessageUI.display(repeated_message)
