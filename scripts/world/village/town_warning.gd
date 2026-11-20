class_name TownWarning
extends Interactable

## Emitted when player attempts to interact with the town warning location.
## [param was_gated]: true if blocked because major truth hasn't been discovered yet.
signal warning_attempted(was_gated: bool)

## Emitted when the town warning dialogue sequence begins.
signal warning_sequence_started

## Emitted when the warning dialogue finishes and the town enters the warned state.
signal warning_completed

## Atmospheric text shown when player interacts BEFORE major truth is discovered.
@export_multiline var atmospheric_pre_text: String = "The Town Hall stands quiet. The council is in recess, and the warning conch rests silent on its pedestal."

## Atmospheric toast shown as the warning sequence begins.
@export_multiline var atmospheric_intro_text: String = "Sens rushes to the Town Hall steps, sounding the alarm to the council."

## Atmospheric text shown on repeated interactions AFTER town has already been warned.
@export_multiline var atmospheric_post_text: String = "The warning has spread through the village. Families are already moving toward the high ground."

## Scripted town warning dialogue sequence between Sens and Elder Cael.
const WARNING_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Sens",
		"text": "Elder Cael! Everyone! The sea hasn't simply left—the retreat is drawing back water to feed a wave!"
	},
	{
		"speaker": "Sens",
		"text": "The century-turn ledger in the shipwreck describes the exact same cycle. The ocean isn't gone—it's making room!"
	},
	{
		"speaker": "Elder Cael",
		"text": "Sens, calm yourself. The Great Receding is a blessing our ancestors celebrated. Are you certain of this?"
	},
	{
		"speaker": "Sens",
		"text": "The shells along the reef are vibrating, the tide pools drained to dry silt, and the gulls have fled inland to our rooftops!"
	},
	{
		"speaker": "Elder Cael",
		"text": "The gulls... they did leave the shore this morning. By the ancestors... the old legends weren't metaphors."
	},
	{
		"speaker": "Elder Cael",
		"text": "Then we warn everyone! Sound the conch from the hall! Call every soul away from the lower shore!"
	},
	{
		"speaker": "Sens",
		"text": "Sound the alarm! Tell everyone to abandon the lower paths and get to the high ground!"
	}
]

## Number of times this warning location has been interacted with.
var interaction_count: int = 0

## Reference to collision shape for enabling/disabling if needed.
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var conch_visual: Node2D = get_node_or_null("ConchVisual")
@onready var alarm_beacon: Node2D = get_node_or_null("AlarmBeacon")
@onready var prompt_label: Label = get_node_or_null("PromptLabel")

var _horn_stream: AudioStream = preload("res://audio/conch_warning.wav")
var _horn_player: AudioStreamPlayer = null

func _ready() -> void:
	_horn_player = AudioStreamPlayer.new()
	_horn_player.stream = _horn_stream
	_horn_player.volume_db = -6.0
	add_child(_horn_player)
	_update_prompt()
	_update_visuals()
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_story_flag_changed)

func _process(_delta: float) -> void:
	_update_prompt()
	_update_visuals()

func _on_story_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_prompt()
	_update_visuals()

## Updates the prompt text according to current progression state.
func _update_prompt() -> void:
	var is_warned: bool = StoryStateController.is_village_warned() if StoryStateController.instance == null else StoryStateController.instance.is_town_warned()
	var can_warn: bool = StoryStateController.can_trigger_town_warning() if StoryStateController.instance == null else StoryStateController.instance.can_warn_town()
	
	if is_warned:
		prompt_message = "Town Hall"
	elif can_warn:
		prompt_message = "Warn the Town"
	else:
		prompt_message = "Town Hall"
	
	if prompt_label:
		if is_warned:
			prompt_label.text = "Town Hall [Alert Active]"
			prompt_label.modulate = Color(1.0, 0.4, 0.4)
		elif can_warn:
			prompt_label.text = "Warn the Town [E]"
			prompt_label.modulate = Color(1.0, 0.85, 0.3)
		else:
			prompt_label.text = "Town Hall [E]"
			prompt_label.modulate = Color(0.9, 0.9, 0.9)

## Updates visual state of conch and alarm beacon.
func _update_visuals() -> void:
	var is_warned: bool = StoryStateController.is_village_warned() if StoryStateController.instance == null else StoryStateController.instance.is_town_warned()
	if alarm_beacon:
		alarm_beacon.visible = is_warned
	if conch_visual:
		if is_warned:
			conch_visual.modulate = Color(1.0, 0.7, 0.3)
		else:
			conch_visual.modulate = Color(1.0, 1.0, 1.0)

## Base interaction entry point.
func interact(player: Player) -> void:
	if not is_interactable:
		return
	
	super.interact(player)
	interaction_count += 1
	
	var is_warned: bool = StoryStateController.is_village_warned() if StoryStateController.instance == null else StoryStateController.instance.is_town_warned()
	var can_warn: bool = StoryStateController.can_trigger_town_warning() if StoryStateController.instance == null else StoryStateController.instance.can_warn_town()
	
	# Case 1: Already warned — Short observation, no dialogue replay
	if is_warned:
		warning_attempted.emit(false)
		AtmosphericMessageUI.display(atmospheric_post_text)
		return
	
	# Case 2: Not yet unlocked — Pre-warning state, cannot raise alarm
	if not can_warn:
		warning_attempted.emit(true)
		AtmosphericMessageUI.display(atmospheric_pre_text)
		return
	
	# Case 3: Major Truth known — Initiate warning sequence
	warning_attempted.emit(false)
	warning_sequence_started.emit()
	_start_warning_sequence(player)

## Launches the warning dialogue sequence preceded by atmospheric toast.
func _start_warning_sequence(player: Player) -> void:
	if _horn_player:
		_horn_player.play()
	AtmosphericMessageUI.display(atmospheric_intro_text)
	
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_warning_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_warning_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(WARNING_DIALOGUE, player)
	else:
		# Fallback if DialogueUI is not instantiated in test scene
		_finalize_town_warning()

func _on_warning_dialogue_ended() -> void:
	_finalize_town_warning()

## Finalizes the warning by setting StoryState and emitting warning_completed.
func _finalize_town_warning() -> void:
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("town_warned", true)
	else:
		StoryStateController.set_story_flag("town_warned", true)
	
	_update_prompt()
	_update_visuals()
	warning_completed.emit()
	print("[TownWarning] Town has been warned: town_warned = true")

## Direct helper to trigger warning programmatically.
func warn_town(player: Player = null) -> void:
	interact(player)
