class_name SeabedShell
extends Interactable

## Descriptive identifier for this shell landmark.
@export var shell_id: String = "shell_1"

## Atmospheric message displayed when examined.
@export_multiline var atmospheric_text: String = "The shell hums softly with a faint, rhythmic vibration."

## Tracks number of times this shell has been inspected.
var examination_count: int = 0

@onready var visual: Node2D = $Visual
@onready var shell_base: ColorRect = $Visual/ShellBase
@onready var shell_rim: ColorRect = $Visual/ShellRim
@onready var glow_point: ColorRect = $Visual/GlowPoint
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _pulse_tween: Tween = null

func _ready() -> void:
	prompt_message = "Examine Strange Shell"
	
	if OceanStateController.instance:
		OceanStateController.instance.state_changed.connect(_on_ocean_state_changed)
	
	_update_shell_state(OceanStateController.is_ocean_retreated())

func _on_ocean_state_changed(new_state: OceanStateController.State) -> void:
	_update_shell_state(new_state == OceanStateController.State.OCEAN_RETREATED)

func _update_shell_state(retreated: bool) -> void:
	is_interactable = retreated
	visible = retreated
	if collision_shape:
		collision_shape.set_deferred("disabled", not retreated)
	
	if retreated:
		_start_humming_pulse()
	else:
		_stop_humming_pulse()

func _start_humming_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	
	if not visual:
		return
	
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(visual, "modulate", Color(1.2, 1.25, 1.15, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(visual, "modulate", Color(0.85, 0.9, 0.9, 0.85), 0.9).set_trans(Tween.TRANS_SINE)

func _stop_humming_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if visual:
		visual.modulate = Color.WHITE

func interact(player: Player) -> void:
	if not is_interactable:
		return
	super.interact(player)
	examination_count += 1
	AtmosphericMessageUI.display(atmospheric_text)
	
	# Record shell observation in StoryState
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("shell_sign_seen", true)
	else:
		StoryStateController.set_story_flag("shell_sign_seen", true)
	
	# Brief visual pulse flare on interaction
	if visual:
		var flash = create_tween()
		flash.tween_property(visual, "modulate", Color(1.5, 1.6, 1.4, 1.0), 0.1)
		flash.tween_property(visual, "modulate", Color.WHITE, 0.3)
