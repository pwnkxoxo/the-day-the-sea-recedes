class_name OceanShiftTest
extends Node2D

@onready var village: Village = $Village
@onready var player: Player = $Player
@onready var state_label: Label = $DebugUI/Panel/VBoxContainer/StateLabel
@onready var access_label: Label = $DebugUI/Panel/VBoxContainer/AccessLabel
@onready var instruction_label: Label = $DebugUI/Panel/VBoxContainer/InstructionLabel

func _ready() -> void:
	if village and player:
		if SceneTransitionTrigger.target_spawn_id == "ladder" and village.ladder_spawn:
			player.global_position = village.ladder_spawn.global_position
		elif village.player_spawn:
			player.global_position = village.player_spawn.global_position
		
		SceneTransitionTrigger.target_spawn_id = ""
		village.setup_camera(player)
	
	# Connect to OceanState changes to update debug HUD
	if OceanStateController.instance:
		OceanStateController.instance.state_changed.connect(_on_ocean_state_changed)
	
	_update_debug_hud(OceanStateController.get_current_state())

func _on_ocean_state_changed(new_state: OceanStateController.State) -> void:
	_update_debug_hud(new_state)

func _update_debug_hud(current_state: OceanStateController.State) -> void:
	if not state_label or not access_label:
		return
	
	if current_state == OceanStateController.State.OCEAN_RETREATED:
		state_label.text = "Ocean State: RETREATED"
		state_label.modulate = Color(1.0, 0.85, 0.3)
		access_label.text = "Seabed Access: OPEN (Ladder Accessible)"
		access_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		state_label.text = "Ocean State: NORMAL"
		state_label.modulate = Color(0.4, 0.8, 1.0)
		access_label.text = "Seabed Access: BLOCKED (Ocean at Cliff Base)"
		access_label.modulate = Color(1.0, 0.4, 0.4)
