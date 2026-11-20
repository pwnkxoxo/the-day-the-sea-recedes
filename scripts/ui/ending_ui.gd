class_name EndingUI
extends CanvasLayer

## Emitted when the ending overlay completes its fade in.
signal ending_shown

## Emitted when the user presses Enter/Restart after the ending sequence.
signal restart_requested

## Static singleton instance.
static var instance: EndingUI = null

@onready var background: ColorRect = $Background
@onready var title_label: Label = $Background/ContentContainer/TitleLabel
@onready var message_label: Label = $Background/ContentContainer/MessageLabel
@onready var prompt_label: Label = $Background/ContentContainer/PromptLabel

## Whether the ending screen is actively being presented.
var is_active: bool = false

## Whether the ending display has finished fading in and is awaiting player input.
var can_restart: bool = false

var _fade_tween: Tween = null

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if background:
		background.visible = false
		background.modulate.a = 0.0
	if prompt_label:
		prompt_label.visible = false

func _process(_delta: float) -> void:
	if can_restart and prompt_label:
		# Subtle retro pulse for restart prompt
		prompt_label.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 250.0)

func _unhandled_input(event: InputEvent) -> void:
	if not can_restart:
		return
	
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		get_viewport().set_input_as_handled()
		_handle_restart()

## Displays the final ending overlay with smooth fade in. Idempotent.
func show_ending(fade_duration: float = 1.2) -> void:
	if is_active:
		return
	
	is_active = true
	can_restart = false
	
	if background:
		background.visible = true
		background.modulate.a = 0.0
	
	if title_label:
		title_label.text = "THE DAY THE SEA RECEDES"
	
	if message_label:
		message_label.text = "The tide returned.\n\nWe were ready.\n\nSome things cannot be stopped.\n\nBut they can be understood."
	
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = "Press Enter to return to title / restart"
	
	if is_inside_tree():
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		if background:
			_fade_tween.tween_property(background, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_fade_tween.finished.connect(func():
			can_restart = true
			if prompt_label:
				prompt_label.visible = true
			ending_shown.emit()
		)
	else:
		if background:
			background.modulate.a = 1.0
		can_restart = true
		if prompt_label:
			prompt_label.visible = true
		ending_shown.emit()

func _handle_restart() -> void:
	print("[EndingUI] Restart requested by player.")
	restart_requested.emit()
	# Reset story state and reload current scene if in tree
	StoryStateController.reset_story_state()
	if is_inside_tree() and get_tree().current_scene:
		get_tree().reload_current_scene()

## Returns true if the ending overlay is currently visible.
func is_ending_active() -> bool:
	return is_active
