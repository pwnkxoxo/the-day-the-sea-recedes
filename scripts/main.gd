class_name Main
extends Node2D

@onready var title_screen: CanvasLayer = get_node_or_null("TitleScreen")
@onready var prompt_label: Label = get_node_or_null("TitleScreen/Background/PromptLabel")
@onready var fade_rect: ColorRect = get_node_or_null("TitleScreen/FadeRect")

var _is_starting: bool = false

func _ready() -> void:
	if fade_rect:
		fade_rect.modulate.a = 0.0

func _process(_delta: float) -> void:
	if prompt_label and not _is_starting:
		prompt_label.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 250.0)

func _unhandled_input(event: InputEvent) -> void:
	if _is_starting:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		get_viewport().set_input_as_handled()
		start_game()

func start_game() -> void:
	if _is_starting:
		return
	_is_starting = true
	if is_inside_tree():
		var tween := create_tween()
		if fade_rect:
			tween.tween_property(fade_rect, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
		tween.finished.connect(func():
			get_tree().change_scene_to_file("res://scenes/test/village_test.tscn")
		)
