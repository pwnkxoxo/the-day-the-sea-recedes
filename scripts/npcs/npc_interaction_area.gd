class_name NPCInteractionArea
extends Interactable

## Reference to the parent NPCBase node.
var npc: CharacterBody2D = null

func _ready() -> void:
	# Inherit Interactable collision settings
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("interactable")
	
	if get_parent() is CharacterBody2D:
		npc = get_parent() as CharacterBody2D
		if "prompt_message" in npc:
			prompt_message = npc.prompt_message

func interact(player: Player) -> void:
	if not is_interactable:
		return
	super.interact(player)
	if npc and is_instance_valid(npc) and npc.has_method("interact"):
		npc.interact(player)
