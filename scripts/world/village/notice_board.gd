class_name NoticeBoard
extends Interactable

## Tracks interaction count for verification and testing.
var interaction_count: int = 0

## Visual state flag.
var is_active: bool = false

@onready var visual: ColorRect = $ColorRect

func _ready() -> void:
	prompt_message = "Read Notice Board"
	_update_visual()

func interact(player: Player) -> void:
	super.interact(player)
	interaction_count += 1
	is_active = !is_active
	_update_visual()
	print("[NoticeBoard] Interacted! 'The Great Receding takes place today. Respect the ocean.' (Count: %d)" % interaction_count)

func _update_visual() -> void:
	if visual:
		# Warm wood/parchment tone when default, sea-green highlight when interacted
		visual.color = Color(0.24, 0.72, 0.51) if is_active else Color(0.72, 0.56, 0.35)
