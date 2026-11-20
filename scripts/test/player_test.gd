class_name PlayerTest
extends Node2D

## World width in pixels. Used for camera limits and test arena boundaries.
@export var world_width: int = 640

## World height in pixels. Used for camera limits and test arena boundaries.
@export var world_height: int = 360

@onready var player: Player = $Player

func _ready() -> void:
	if player:
		player.set_camera_limits(0, 0, world_width, world_height)
