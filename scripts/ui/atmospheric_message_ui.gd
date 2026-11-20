class_name AtmosphericMessageUI
extends CanvasLayer

signal message_displayed(text: String)
signal message_hidden

static var instance: AtmosphericMessageUI = null

@onready var panel: PanelContainer = $PanelContainer
@onready var message_label: Label = $PanelContainer/MarginContainer/MessageLabel

var _fade_tween: Tween = null

func _enter_tree() -> void:
	if instance == null:
		instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	if panel:
		panel.modulate.a = 0.0
		panel.visible = false

## Displays a short atmospheric message toast.
func show_message(text: String, duration: float = 3.5) -> void:
	print("[Atmospheric Sign] %s" % text)
	message_displayed.emit(text)
	
	if not panel or not message_label:
		return
	
	message_label.text = text
	panel.visible = true
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	_fade_tween.tween_interval(duration)
	_fade_tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	_fade_tween.finished.connect(func():
		panel.visible = false
		message_hidden.emit()
	)

## Static helper to show message from any script.
static func display(text: String, duration: float = 3.5) -> void:
	if instance:
		instance.show_message(text, duration)
	else:
		print("[Atmospheric Sign] %s" % text)
