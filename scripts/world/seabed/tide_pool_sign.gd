class_name TidePoolSign
extends EnvironmentalSign

## Tracks whether the tide pools have completed draining.
var is_drained: bool = false

@onready var water_1: ColorRect = $PoolRim1/PoolWater1
@onready var water_2: ColorRect = $PoolRim2/PoolWater2
@onready var water_3: ColorRect = $PoolRim3/PoolWater3

# Full healthy water sizes and offsets
const FULL_WATER_1 := {"left": 6.0, "top": 6.0, "right": 94.0, "bottom": 64.0, "color": Color(0.18, 0.38, 0.46)}
const FULL_WATER_2 := {"left": 4.0, "top": 4.0, "right": 66.0, "bottom": 56.0, "color": Color(0.16, 0.36, 0.44)}
const FULL_WATER_3 := {"left": 4.0, "top": 4.0, "right": 66.0, "bottom": 56.0, "color": Color(0.18, 0.38, 0.46)}

# Drained murky puddle sizes and offsets
const DRAINED_WATER_1 := {"left": 30.0, "top": 24.0, "right": 70.0, "bottom": 48.0, "color": Color(0.11, 0.22, 0.25)}
const DRAINED_WATER_2 := {"left": 20.0, "top": 18.0, "right": 50.0, "bottom": 42.0, "color": Color(0.10, 0.20, 0.23)}
const DRAINED_WATER_3 := {"left": 22.0, "top": 20.0, "right": 52.0, "bottom": 44.0, "color": Color(0.11, 0.22, 0.25)}

func _update_sign_state(retreated: bool, animate: bool = false) -> void:
	super._update_sign_state(retreated, animate)
	is_drained = retreated
	
	if retreated:
		if animate and is_inside_tree():
			_animate_drain()
		else:
			_apply_drained_immediate()
	else:
		_apply_full_immediate()

func _apply_full_immediate() -> void:
	_set_water_rect(water_1, FULL_WATER_1)
	_set_water_rect(water_2, FULL_WATER_2)
	_set_water_rect(water_3, FULL_WATER_3)

func _apply_drained_immediate() -> void:
	_set_water_rect(water_1, DRAINED_WATER_1)
	_set_water_rect(water_2, DRAINED_WATER_2)
	_set_water_rect(water_3, DRAINED_WATER_3)

func _set_water_rect(rect: ColorRect, data: Dictionary) -> void:
	if not rect:
		return
	rect.offset_left = data.left
	rect.offset_top = data.top
	rect.offset_right = data.right
	rect.offset_bottom = data.bottom
	rect.color = data.color

func _animate_drain() -> void:
	var tween = create_tween().set_parallel(true)
	_tween_water(tween, water_1, DRAINED_WATER_1, 1.5)
	_tween_water(tween, water_2, DRAINED_WATER_2, 1.5)
	_tween_water(tween, water_3, DRAINED_WATER_3, 1.5)

func _tween_water(tween: Tween, rect: ColorRect, data: Dictionary, duration: float) -> void:
	if not rect:
		return
	tween.tween_property(rect, "offset_left", data.left, duration)
	tween.tween_property(rect, "offset_top", data.top, duration)
	tween.tween_property(rect, "offset_right", data.right, duration)
	tween.tween_property(rect, "offset_bottom", data.bottom, duration)
	tween.tween_property(rect, "color", data.color, duration)

## Called when the player inspects or examines the drained tide pools.
func observe_tide_pools() -> void:
	if not is_drained:
		return
	AtmosphericMessageUI.display("The tide pools have drained away, leaving only murky silt.")
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("tide_pool_sign_seen", true)
	else:
		StoryStateController.set_story_flag("tide_pool_sign_seen", true)
