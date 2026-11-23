class_name OpeningSequence
extends Node2D

## Emitted when the opening story sequence begins.
signal sequence_started

## Emitted when the opening story sequence reaches full completion.
signal sequence_completed

## Emitted when the sequence transitions between individual narrative steps.
signal step_advanced(step_name: String)

## Static singleton reference for global scene access if needed.
static var instance: OpeningSequence = null

## Target village node. If null, auto-discovered in tree.
@export var target_village: Village = null

## Target player node (Sens). If null, auto-discovered in tree.
@export var target_player: Player = null

## Whether to automatically begin the sequence on _ready() if not already completed.
@export var auto_start: bool = true

## If true, accelerates transitions and timers (used for unit tests / fast execution).
@export var fast_mode: bool = false

## Coordinates for the coastal establishing shot.
const COASTAL_SHOT_POSITION: Vector2 = Vector2(680, 400)

## Default coordinates outside Sens's house where Sens starts.
const SENS_START_POSITION: Vector2 = Vector2(240, 200)

## Atmospheric dialogue introducing Sens and establishing the strange morning calm.
const OPENING_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Sens",
		"text": "The sea is quiet today... unnaturally quiet."
	},
	{
		"speaker": "Sens",
		"text": "Even the morning tide seems to have paused at the edge of the rocks."
	},
	{
		"speaker": "Sens",
		"text": "I should walk through the village and see if anyone else has noticed."
	}
]

var is_active: bool = false
var current_step: String = ""

var _cinematic_camera: Camera2D = null
var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _active_tween: Tween = null
var _step_timer: SceneTreeTimer = null

func _enter_tree() -> void:
	if instance == null:
		instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

func _ready() -> void:
	_setup_nodes()
	_find_dependencies()
	
	# Check whether sequence should run or was already completed
	if StoryStateController.has_story_flag("opening_sequence_completed"):
		_finish_cleanup(false)
		return
	
	if auto_start:
		call_deferred("start_sequence")

## Prepares internal cinematic camera and fade overlay canvas layer.
func _setup_nodes() -> void:
	if not _cinematic_camera:
		_cinematic_camera = get_node_or_null("CinematicCamera") as Camera2D
	if not _cinematic_camera:
		_cinematic_camera = Camera2D.new()
		_cinematic_camera.name = "CinematicCamera"
		_cinematic_camera.enabled = false
		add_child(_cinematic_camera)
	
	# Match world camera limits (0, 0, 960, 540)
	_cinematic_camera.limit_left = 0
	_cinematic_camera.limit_top = 0
	_cinematic_camera.limit_right = 960
	_cinematic_camera.limit_bottom = 540
	
	if not _fade_layer:
		_fade_layer = get_node_or_null("FadeLayer") as CanvasLayer
	if not _fade_layer:
		_fade_layer = CanvasLayer.new()
		_fade_layer.name = "FadeLayer"
		_fade_layer.layer = 100
		add_child(_fade_layer)
	
	if not _fade_rect:
		_fade_rect = _fade_layer.get_node_or_null("FadeRect") as ColorRect
	if not _fade_rect:
		_fade_rect = ColorRect.new()
		_fade_rect.name = "FadeRect"
		_fade_rect.color = Color(0.04, 0.05, 0.07, 1.0)
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_rect.modulate.a = 0.0
		_fade_layer.add_child(_fade_rect)

## Finds village and player dependencies from tree or parent hierarchy.
func _find_dependencies() -> void:
	if not target_village and is_inside_tree():
		if get_parent() is Village:
			target_village = get_parent() as Village
		elif get_parent():
			target_village = get_parent().get_node_or_null("Village") as Village
		if not target_village:
			var village_nodes := get_tree().get_nodes_in_group("village")
			if not village_nodes.is_empty():
				target_village = village_nodes[0] as Village
	
	if not target_player and is_inside_tree():
		target_player = get_tree().get_first_node_in_group("player") as Player
		if not target_player and get_parent():
			target_player = get_parent().get_node_or_null("Player") as Player

## Initializes or configures opening sequence with explicit node references.
func initialize(p_village: Village = null, p_player: Player = null) -> void:
	if p_village:
		target_village = p_village
	if p_player:
		target_player = p_player
	_setup_nodes()
	_find_dependencies()

## Returns true if the sequence is currently actively executing.
func is_playing() -> bool:
	return is_active

## Begins the opening cinematic sequence.
func start_sequence() -> void:
	if is_active:
		return
	
	# If already completed in StoryState, do not replay
	if StoryStateController.has_story_flag("opening_sequence_completed"):
		_finish_cleanup(false)
		return
	
	_find_dependencies()
	
	is_active = true
	sequence_started.emit()
	
	# Lock player movement and position Sens at his house facing right
	if target_player:
		target_player.lock_movement()
		if target_village and target_village.player_spawn:
			target_player.global_position = target_village.player_spawn.global_position
		else:
			target_player.global_position = SENS_START_POSITION
		target_player.facing_direction = Vector2.DOWN
		target_player.velocity = Vector2.ZERO
		if target_player.has_method("_update_sprite_direction"):
			target_player._update_sprite_direction(Vector2.ZERO)
	
	# Start camera at coastal establishing shot
	if _cinematic_camera:
		_cinematic_camera.global_position = COASTAL_SHOT_POSITION
		_cinematic_camera.enabled = true
		_cinematic_camera.make_current()
	
	# Begin initial fade from black
	if _fade_rect:
		_fade_rect.modulate.a = 1.0
	
	_step_fade_in()

## Step 1: Smooth fade from black introducing the coastal dawn.
func _step_fade_in() -> void:
	current_step = "fade_in"
	step_advanced.emit(current_step)
	
	var fade_time: float = 0.05 if fast_mode else 1.2
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	
	_active_tween = create_tween()
	if _fade_rect:
		_active_tween.tween_property(_fade_rect, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE)
	
	_active_tween.finished.connect(func():
		_step_coastal_view()
	)

## Step 2: Coastal establishing view with atmospheric toast.
func _step_coastal_view() -> void:
	current_step = "coastal_view"
	step_advanced.emit(current_step)
	
	AtmosphericMessageUI.display("The southern coast. An unusually quiet dawn.")
	
	var dwell_time: float = 0.05 if fast_mode else 2.5
	if not is_inside_tree():
		_step_pan_to_village()
		return
	
	_step_timer = get_tree().create_timer(dwell_time)
	_step_timer.timeout.connect(func():
		if is_active:
			_step_pan_to_village()
	)

## Step 3: Cinematic camera pans across village towards Sens.
func _step_pan_to_village() -> void:
	current_step = "camera_pan"
	step_advanced.emit(current_step)
	
	var target_pos: Vector2 = target_player.global_position if target_player else SENS_START_POSITION
	var pan_time: float = 0.1 if fast_mode else 3.5
	
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	
	if _cinematic_camera:
		_active_tween = create_tween()
		_active_tween.tween_property(_cinematic_camera, "global_position", target_pos, pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_active_tween.finished.connect(func():
			_step_sens_intro()
		)
	else:
		_step_sens_intro()

## Step 4: Sens is framed outside his home.
func _step_sens_intro() -> void:
	current_step = "sens_intro"
	step_advanced.emit(current_step)
	
	if target_player:
		# Sens turns to face east towards the sea
		target_player.facing_direction = Vector2.RIGHT
		if target_player.has_method("_update_sprite_direction"):
			target_player._update_sprite_direction(Vector2.ZERO)
	
	var pause_time: float = 0.05 if fast_mode else 0.8
	if not is_inside_tree():
		_step_dialogue()
		return
	
	_step_timer = get_tree().create_timer(pause_time)
	_step_timer.timeout.connect(func():
		if is_active:
			_step_dialogue()
	)

## Step 5: Displays Sens's opening internal dialogue.
func _step_dialogue() -> void:
	current_step = "dialogue"
	step_advanced.emit(current_step)
	
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(OPENING_DIALOGUE, target_player)
	else:
		# Fallback if DialogueUI is not loaded in scene/test
		AtmosphericMessageUI.display("The sea is quiet today... unnaturally quiet.")
		var delay: float = 0.05 if fast_mode else 1.5
		if is_inside_tree():
			var t := get_tree().create_timer(delay)
			t.timeout.connect(func():
				complete_sequence()
			)
		else:
			complete_sequence()

func _on_dialogue_ended() -> void:
	complete_sequence()

## Completes the sequence, unlocks player control, and records persistent story completion.
func complete_sequence() -> void:
	if not is_active and StoryStateController.has_story_flag("opening_sequence_completed"):
		return
	
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	
	# Mark StoryState flag
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	
	# Restore player control and player camera
	_finish_cleanup(true)
	
	AtmosphericMessageUI.display("Explore the village and talk with the townsfolk.")
	
	is_active = false
	current_step = "completed"
	sequence_completed.emit()
	print("[OpeningSequence] Completed: player unlocked, opening_sequence_completed = true")

## Cleans up camera and unlocks player movement.
func _finish_cleanup(unlock_player: bool) -> void:
	if _fade_rect:
		_fade_rect.modulate.a = 0.0
	
	if _cinematic_camera:
		_cinematic_camera.enabled = false
	
	if target_player:
		if target_player.camera:
			target_player.camera.enabled = true
			target_player.camera.make_current()
		if unlock_player:
			target_player.unlock_movement()
