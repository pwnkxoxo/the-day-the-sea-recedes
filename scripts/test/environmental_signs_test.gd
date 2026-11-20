class_name EnvironmentalSignsTest
extends Node2D

@onready var village: Village = $Village
@onready var player: Player = $Player
@onready var state_label: Label = $DebugHUD/Panel/VBoxContainer/StateLabel
@onready var signs_label: Label = $DebugHUD/Panel/VBoxContainer/SignsLabel
@onready var last_sign_label: Label = $DebugHUD/Panel/VBoxContainer/LastSignLabel
@onready var message_ui: AtmosphericMessageUI = $AtmosphericMessageUI

func _ready() -> void:
	if village and player:
		if SceneTransitionTrigger.target_spawn_id == "ladder" and village.ladder_spawn:
			player.global_position = village.ladder_spawn.global_position
		elif village.player_spawn:
			player.global_position = village.player_spawn.global_position
		
		SceneTransitionTrigger.target_spawn_id = ""
		village.setup_camera(player)
	
	if OceanStateController.instance:
		OceanStateController.instance.state_changed.connect(_on_ocean_state_changed)
	
	if message_ui:
		message_ui.message_displayed.connect(_on_message_displayed)
	
	_update_debug_hud(OceanStateController.get_current_state())

func _on_ocean_state_changed(new_state: OceanStateController.State) -> void:
	_update_debug_hud(new_state)

func _on_message_displayed(text: String) -> void:
	if last_sign_label:
		var preview = text if text.length() <= 32 else text.substr(0, 30) + "..."
		last_sign_label.text = "Examined: \"%s\"" % preview

func _update_debug_hud(current_state: OceanStateController.State) -> void:
	if not state_label or not signs_label:
		return
	
	if current_state == OceanStateController.State.OCEAN_RETREATED:
		state_label.text = "Ocean State: RETREATED"
		state_label.modulate = Color(1.0, 0.85, 0.3)
		signs_label.text = "Strange Signs: ACTIVE (Birds inland, shells hum, pools dry)"
		signs_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		state_label.text = "Ocean State: NORMAL"
		state_label.modulate = Color(0.4, 0.8, 1.0)
		signs_label.text = "Strange Signs: INACTIVE (Birds coastal, shells inert)"
		signs_label.modulate = Color(0.7, 0.7, 0.7)
