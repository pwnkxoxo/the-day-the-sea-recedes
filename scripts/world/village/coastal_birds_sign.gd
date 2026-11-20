class_name CoastalBirdsSign
extends EnvironmentalSign

## Tracks whether the birds have migrated inland.
var is_inland: bool = false

@onready var bird_1: Node2D = $Bird1
@onready var bird_2: Node2D = $Bird2
@onready var bird_3: Node2D = $Bird3

# Normal cliff perching positions (near sea)
const CLIFF_POS_1 := Vector2(450, 375)
const CLIFF_POS_2 := Vector2(510, 376)
const CLIFF_POS_3 := Vector2(480, 365)

# Inland retreat positions (village rooftops)
const INLAND_POS_1 := Vector2(470, 70)
const INLAND_POS_2 := Vector2(170, 90)
const INLAND_POS_3 := Vector2(770, 90)

func _update_sign_state(retreated: bool, animate: bool = false) -> void:
	super._update_sign_state(retreated, animate)
	is_inland = retreated
	
	if retreated:
		if animate and is_inside_tree():
			_animate_flight_inland()
		else:
			_apply_positions_immediate(INLAND_POS_1, INLAND_POS_2, INLAND_POS_3)
	else:
		_apply_positions_immediate(CLIFF_POS_1, CLIFF_POS_2, CLIFF_POS_3)

func _apply_positions_immediate(p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	if bird_1: bird_1.position = p1
	if bird_2: bird_2.position = p2
	if bird_3: bird_3.position = p3

func _animate_flight_inland() -> void:
	var tween = create_tween().set_parallel(true)
	if bird_1:
		tween.tween_property(bird_1, "position", INLAND_POS_1, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if bird_2:
		tween.tween_property(bird_2, "position", INLAND_POS_2, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if bird_3:
		tween.tween_property(bird_3, "position", INLAND_POS_3, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Called when the player inspects or observes the inland roosting birds.
func observe_birds() -> void:
	if not is_inland:
		return
	AtmosphericMessageUI.display("The coastal seabirds have fled inland to the village rooftops.")
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("birds_sign_seen", true)
	else:
		StoryStateController.set_story_flag("birds_sign_seen", true)
