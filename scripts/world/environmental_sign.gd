class_name EnvironmentalSign
extends Node2D

## Whether this environmental sign is currently in its active, retreated state.
var is_active: bool = false

func _ready() -> void:
	# Connect to OceanState changes
	if OceanStateController.instance:
		OceanStateController.instance.state_changed.connect(_on_ocean_state_changed)
	
	# Apply current state immediately
	_update_sign_state(OceanStateController.is_ocean_retreated(), false)

func _on_ocean_state_changed(new_state: OceanStateController.State) -> void:
	_update_sign_state(new_state == OceanStateController.State.OCEAN_RETREATED, true)

## Virtual method to be overridden by specific environmental signs.
## [param retreated]: true if ocean has retreated; false if ocean is normal.
## [param animate]: true if triggered via runtime state shift, false if initializing on scene load.
func _update_sign_state(retreated: bool, animate: bool = false) -> void:
	is_active = retreated
