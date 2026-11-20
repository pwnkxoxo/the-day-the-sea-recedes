class_name SceneTransitionTrigger
extends Area2D

## Static variable tracking destination spawn across scene transitions.
static var target_spawn_id: String = ""

## Static variable remembering the originating scene path for return trips.
static var return_scene_path: String = ""

## Path to the target scene to transition to.
@export_file("*.tscn") var target_scene_path: String = ""

## Spawn identifier to pass to the destination scene (e.g. "ladder", "seabed_entry").
@export var target_spawn_id_to_set: String = ""

var _has_triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _has_triggered:
		return
	if body is Player:
		# Access control check: seabed entry is only permitted when the ocean has retreated
		if target_spawn_id_to_set == "seabed_entry":
			if not OceanStateController.is_ocean_retreated():
				return
		
		_has_triggered = true
		target_spawn_id = target_spawn_id_to_set
		
		# Resolve destination scene
		var destination: String = target_scene_path
		if target_spawn_id_to_set == "ladder" and not return_scene_path.is_empty():
			destination = return_scene_path
		
		# If transitioning to seabed, record current scene for seamless return
		if target_spawn_id_to_set == "seabed_entry" and get_tree().current_scene:
			return_scene_path = get_tree().current_scene.scene_file_path
		
		if not destination.is_empty():
			get_tree().call_deferred("change_scene_to_file", destination)
