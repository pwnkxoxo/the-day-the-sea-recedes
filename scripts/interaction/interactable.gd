class_name Interactable
extends Area2D

## Emitted when a player successfully interacts with this object.
signal interacted(player: Player)

## Whether this object is currently available for interaction.
@export var is_interactable: bool = true

## Optional descriptive name or prompt text for future UI or prompt labels.
@export var prompt_message: String = "Interact"

func _init() -> void:
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true

## Base interaction method. Triggers the interacted signal.
## Can be overridden by subclasses or connected via the 'interacted' signal.
func interact(player: Player) -> void:
	if not is_interactable:
		return
	interacted.emit(player)
