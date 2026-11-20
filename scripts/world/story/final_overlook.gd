class_name FinalOverlook
extends Interactable

## Emitted when player attempts to interact. [param was_gated] is true if blocked by prerequisites.
signal overlook_attempted(was_gated: bool)

## Emitted when the final narrative resolution dialogue begins.
signal resolution_started

## Emitted when the narrative resolution dialogue concludes.
signal resolution_ended

## Emitted when the ending overlay is triggered.
signal ending_triggered

## Pre-survival atmospheric text when interacting before wave is survived.
@export_multiline var atmospheric_pre_text: String = "The cliff edge overlooks the bay. The wind is howling too fiercely to approach."

## Post-ending atmospheric text when interacting after ending has completed.
@export_multiline var atmospheric_post_text: String = "The sea churns calmly below the cliff. We are safe on high ground."

## Scripted concluding narrative resolution dialogue connecting back to the theme: SHIFT.
const RESOLUTION_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Sens",
		"text": "The sea has returned."
	},
	{
		"speaker": "Sens",
		"text": "The village will rebuild."
	},
	{
		"speaker": "Sens",
		"text": "People will remember what happened."
	},
	{
		"speaker": "Sens",
		"text": "The Great Receding will never be celebrated the same way again."
	},
	{
		"speaker": "Sens",
		"text": "The sea did not leave."
	},
	{
		"speaker": "Sens",
		"text": "It only shifted."
	}
]

## Whether the final resolution dialogue is currently actively playing.
var is_resolution_active: bool = false

## Whether the ending sequence has completed.
var has_completed: bool = false

## Visual prompt label in-world.
@onready var prompt_label: Label = get_node_or_null("PromptLabel")

func _ready() -> void:
	_update_prompt()
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_story_flag_changed)
	
	if StoryStateController.is_game_ended():
		has_completed = true

func _process(_delta: float) -> void:
	_update_prompt()

func _on_story_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_prompt()

## Returns true if prerequisite is met to trigger final overlook.
func can_trigger_overlook() -> bool:
	return StoryStateController.has_player_survived()

func _update_prompt() -> void:
	var can_interact: bool = can_trigger_overlook()
	var ended: bool = StoryStateController.is_game_ended() or has_completed
	
	if ended:
		prompt_message = "Look Out Over the Sea"
	elif can_interact:
		prompt_message = "Look Out Over the Sea"
	else:
		prompt_message = "Cliff Overlook"
	
	if prompt_label:
		if ended:
			prompt_label.text = "Look Out Over the Sea"
			prompt_label.modulate = Color(0.7, 0.8, 0.85)
		elif can_interact:
			prompt_label.text = "Look Out Over the Sea [E]"
			prompt_label.modulate = Color(0.95, 0.9, 0.6)
		else:
			prompt_label.text = "Cliff Overlook"
			prompt_label.modulate = Color(0.5, 0.5, 0.5)

## Main interaction entry point.
func interact(player: Player) -> void:
	if not is_interactable:
		return
	
	super.interact(player)
	
	# Case 1: Already completed ending — Idempotent safe handling
	if has_completed or StoryStateController.is_game_ended():
		overlook_attempted.emit(false)
		AtmosphericMessageUI.display(atmospheric_post_text)
		return
	
	# Case 2: Not yet survived wave — Gated!
	if not can_trigger_overlook():
		overlook_attempted.emit(true)
		AtmosphericMessageUI.display(atmospheric_pre_text)
		return
	
	# Case 3: Already active
	if is_resolution_active:
		return
	
	# Case 4: First valid interaction — Initiate resolution sequence
	overlook_attempted.emit(false)
	is_resolution_active = true
	resolution_started.emit()
	
	_start_resolution_sequence(player)

func _start_resolution_sequence(player: Player) -> void:
	if player and is_instance_valid(player):
		player.lock_movement()
		player.velocity = Vector2.ZERO
	
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(RESOLUTION_DIALOGUE, player)
	else:
		_on_dialogue_ended()

func _on_dialogue_ended() -> void:
	is_resolution_active = false
	resolution_ended.emit()
	_trigger_ending_overlay()

func _trigger_ending_overlay() -> void:
	has_completed = true
	StoryStateController.set_story_flag("ending_completed", true)
	ending_triggered.emit()
	
	if EndingUI.instance:
		EndingUI.instance.show_ending()
	
	print("[FinalOverlook] Final ending sequence completed: ending_completed = true")

## Direct helper to trigger overlook programmatically in tests.
func trigger_overlook(player: Player = null) -> void:
	interact(player)
