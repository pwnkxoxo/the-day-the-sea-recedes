class_name NPCTest
extends Node2D

@onready var npc: NPCBase = $NPCBase
@onready var player: Player = get_node_or_null("Player")

func _ready() -> void:
	if npc:
		# Configure waypoint patrol route around the test plaza
		npc.waypoints = [
			Vector2(80, 60),
			Vector2(240, 60),
			Vector2(240, 120),
			Vector2(80, 120)
		]
		npc.loop_waypoints = true
		npc.waypoint_wait_time = 1.0
		npc.set_state(NPCBase.State.WALKING)
