class_name VillageTest
extends Node2D

@onready var village: Village = $Village
@onready var player: Player = $Player
@onready var opening_sequence: OpeningSequence = get_node_or_null("OpeningSequence")

func _ready() -> void:
	if village and player:
		if SceneTransitionTrigger.target_spawn_id == "ladder" and village.has_node("LadderSpawn"):
			player.global_position = village.get_node("LadderSpawn").global_position
		elif village.player_spawn:
			player.global_position = village.player_spawn.global_position
		
		SceneTransitionTrigger.target_spawn_id = ""
		village.setup_camera(player)
		
		if opening_sequence and not StoryStateController.has_story_flag("opening_sequence_completed"):
			opening_sequence.initialize(village, player)
