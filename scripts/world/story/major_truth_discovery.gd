class_name MajorTruthDiscovery
extends Interactable

## Emitted when player attempts to interact with the overlook.
## [param was_gated]: true if blocked because prerequisites (investigation + shipwreck clue) aren't met yet.
signal truth_attempted(was_gated: bool)

## Emitted when the truth discovery sequence begins.
signal truth_sequence_started

## Emitted when the truth discovery sequence completes and the major truth flag is set.
signal truth_revealed

## Atmospheric text shown when player looks out before prerequisites are met.
@export_multiline var atmospheric_pre_text: String = "The exposed bay stretches into the haze. It seems peaceful, yet unsettlingly empty."

## Atmospheric toast shown as the truth discovery sequence begins.
@export_multiline var atmospheric_intro_text: String = "The exposed seabed stretches farther than before."

## Atmospheric text shown on repeated interactions after truth has already been discovered.
@export_multiline var atmospheric_post_text: String = "The empty horizon feels different now. The sea isn't leaving—it's making room."

## Full truth realization dialogue sequence synthesizing all clues and environmental signs.
const TRUTH_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Sens",
		"text": "From up here... the exposed seabed stretches farther than anyone in the village has ever seen."
	},
	{
		"speaker": "Sens",
		"text": "The singing shells along the reef... the drained tide pools... the gulls fleeing inland to the rooftops..."
	},
	{
		"speaker": "Sens",
		"text": "The captain's log from the century turn described the exact same signs before the disaster."
	},
	{
		"speaker": "Sens",
		"text": "'The receding is not the disaster. The receding is the water drawing breath before the gathering wave.'"
	},
	{
		"speaker": "Sens",
		"text": "The sea isn't leaving. It's making room."
	},
	{
		"speaker": "Sens",
		"text": "If the old record is right... what comes back after the Great Receding won't be a tide."
	}
]

## Number of times this overlook point has been interacted with.
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

## Updates the prompt text according to current progression state.
func _update_prompt() -> void:
	var truth_found: bool = StoryStateController.is_truth_known() if StoryStateController.instance == null else StoryStateController.instance.is_truth_discovered()
	var can_truth: bool = StoryStateController.can_reveal_truth() if StoryStateController.instance == null else StoryStateController.instance.can_discover_truth()
	
	if truth_found:
		prompt_message = "Observe the Horizon"
	elif can_truth:
		prompt_message = "Survey the Receded Ocean"
	else:
		prompt_message = "Look Out at Bay"

## Base interaction entry point.
func interact(player: Player) -> void:
	if not is_interactable:
		return
	
	super.interact(player)
	interaction_count += 1
	
	var truth_found: bool = StoryStateController.is_truth_known() if StoryStateController.instance == null else StoryStateController.instance.is_truth_discovered()
	var can_truth: bool = StoryStateController.can_reveal_truth() if StoryStateController.instance == null else StoryStateController.instance.can_discover_truth()
	
	# Case 1: Already discovered — Short observation, no dialogue replay
	if truth_found:
		truth_attempted.emit(false)
		AtmosphericMessageUI.display(atmospheric_post_text)
		return
	
	# Case 2: Not yet unlocked — Pre-discovery observation, no revelation
	if not can_truth:
		truth_attempted.emit(true)
		AtmosphericMessageUI.display(atmospheric_pre_text)
		return
	
	# Case 3: Major Truth Discovery sequence
	truth_attempted.emit(false)
	truth_sequence_started.emit()
	_start_truth_sequence(player)

## Launches the discovery dialogue sequence preceded by atmospheric toast.
func _start_truth_sequence(player: Player) -> void:
	AtmosphericMessageUI.display(atmospheric_intro_text)
	
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_truth_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_truth_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(TRUTH_DIALOGUE, player)
	else:
		# Fallback if DialogueUI is not instantiated in test scene
		_finalize_truth_discovery()

func _on_truth_dialogue_ended() -> void:
	_finalize_truth_discovery()

## Finalizes the truth discovery by setting StoryState and emitting truth_revealed.
func _finalize_truth_discovery() -> void:
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("major_truth_discovered", true)
	else:
		StoryStateController.set_story_flag("major_truth_discovered", true)
	
	_update_prompt()
	truth_revealed.emit()
	print("[MajorTruthDiscovery] The truth is revealed: major_truth_discovered = true")

## Direct helper to trigger observation programmatically.
func survey_horizon(player: Player = null) -> void:
	interact(player)
