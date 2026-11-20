class_name Seabed
extends Node2D

## World dimensions in pixels for camera clamping and boundary verification.
@export var world_width: int = 1280
@export var world_height: int = 720

@onready var player_spawn: Marker2D = $PlayerSpawn

var _wind_stream: AudioStream = preload("res://audio/wind_ambient.wav")
var _wind_player: AudioStreamPlayer = null

func _ready() -> void:
	_wind_player = AudioStreamPlayer.new()
	_wind_player.stream = _wind_stream
	_wind_player.volume_db = -14.0
	add_child(_wind_player)
	_wind_player.play()

## Configures camera limits for a player entering the seabed area.
func setup_camera(player: Player) -> void:
	if player:
		player.set_camera_limits(0, 0, world_width, world_height)
