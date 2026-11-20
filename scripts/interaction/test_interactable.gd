class_name TestInteractable
extends Interactable

## Number of times this object has been interacted with.
var interaction_count: int = 0

## Current visual toggle state.
var is_active: bool = false

@onready var visual: ColorRect = $ColorRect

func _ready() -> void:
	_update_visual()

func interact(player: Player) -> void:
	super.interact(player)
	interaction_count += 1
	is_active = !is_active
	_update_visual()
	print("[%s] Interacted! Total count: %d, Active: %s" % [name, interaction_count, is_active])

func _update_visual() -> void:
	if visual:
		# Amber / gold when inactive, teal / green when active
		visual.color = Color(0.243, 0.722, 0.51) if is_active else Color(0.831, 0.639, 0.294)
