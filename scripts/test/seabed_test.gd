class_name SeabedTest
extends Node2D

@onready var seabed: Seabed = $Seabed
@onready var player: Player = $Player

func _ready() -> void:
	if seabed and player:
		if seabed.player_spawn:
			player.global_position = seabed.player_spawn.global_position
		seabed.setup_camera(player)
