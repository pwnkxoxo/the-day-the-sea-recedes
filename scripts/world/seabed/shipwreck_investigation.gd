class_name ShipwreckInvestigation
extends Interactable

## Emitted when an investigation interaction is attempted.
## [param was_gated]: true if blocked because investigation hasn't started yet.
signal investigation_attempted(was_gated: bool)

## Emitted when the discovery sequence dialogue begins.
signal discovery_started

## Emitted when the discovery sequence finishes and the clue is recorded.
signal clue_discovered

## Atmospheric text shown when player inspects the wreck BEFORE investigation starts.
@export_multiline var atmospheric_uninvestigated_text: String = "The hull of an ancient vessel, shattered against the reef. Without context, the scattered charts mean little."

## Atmospheric text shown on repeated interactions AFTER the clue has been discovered.
@export_multiline var atmospheric_repeat_text: String = "The captain's log remains open: 'The receding is not the disaster. The receding is the water drawing breath.'"

## Discovery dialogue sequence shown when investigating after investigation has started.
const DISCOVERY_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Shipwreck Record",
		"text": "Beneath a shattered timber in the captain's quarters lies an ironbound nautical ledger, preserved by resin."
	},
	{
		"speaker": "Shipwreck Record",
		"text": "'Voyage Log — Century Turn. The sea has receded past the barrier reef, exactly as recorded one hundred years ago.'"
	},
	{
		"speaker": "Shipwreck Record",
		"text": "'The settlers take it for a quiet miracle. They do not comprehend what draws the ocean back...'"
	},
	{
		"speaker": "Shipwreck Record",
		"text": "'The receding is not the disaster. The receding is the water drawing breath before the gathering wave.'"
	},
	{
		"speaker": "Sens",
		"text": "The ocean didn't simply leave... it was pulled back. And when it returns, it won't be gentle."
	}
]

## Number of times the shipwreck interaction has been triggered.
var interaction_count: int = 0

## Reference to collision shape for enabling/disabling if needed.
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	_update_prompt()
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_story_flag_changed)

func _process(_delta: float) -> void:
	_update_prompt()

func _on_story_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_prompt()

## Updates the interaction prompt string based on current StoryState flags.
func _update_prompt() -> void:
	var clue_found: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	var is_inv: bool = StoryStateController.is_investigating()
	
	if clue_found:
		prompt_message = "Examine Log Remnants"
	elif is_inv:
		prompt_message = "Search Captain's Quarters"
	else:
		prompt_message = "Examine Wreckage"

## Base interaction entry point.
func interact(player: Player) -> void:
	if not is_interactable:
		return
	
	super.interact(player)
	interaction_count += 1
	
	var is_inv: bool = StoryStateController.is_investigating()
	var clue_found: bool = StoryStateController.has_story_flag("shipwreck_clue_found")
	
	# Case 1: Pre-investigation — Gated from key discovery
	if not is_inv:
		investigation_attempted.emit(true)
		AtmosphericMessageUI.display(atmospheric_uninvestigated_text)
		return
	
	# Case 2: Already discovered — Short observation, no dialogue replay
	if clue_found:
		investigation_attempted.emit(false)
		AtmosphericMessageUI.display(atmospheric_repeat_text)
		return
	
	# Case 3: Meaningful investigation discovery sequence
	investigation_attempted.emit(false)
	discovery_started.emit()
	_start_discovery_sequence(player)

## Launches the discovery dialogue sequence and connects completion to clue recording.
func _start_discovery_sequence(player: Player) -> void:
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_discovery_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_discovery_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(DISCOVERY_DIALOGUE, player)
	else:
		# Fallback if DialogueUI is not instantiated in test scene
		_finalize_clue_discovery()

func _on_discovery_dialogue_ended() -> void:
	_finalize_clue_discovery()

## Finalizes the clue discovery by setting StoryState and updating prompt.
func _finalize_clue_discovery() -> void:
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("shipwreck_clue_found", true)
	else:
		StoryStateController.set_story_flag("shipwreck_clue_found", true)
	
	_update_prompt()
	clue_discovered.emit()
	print("[Shipwreck] Nautical ledger discovered: shipwreck_clue_found = true")

## Direct helper to trigger investigation programmatically.
func investigate(player: Player = null) -> void:
	interact(player)
