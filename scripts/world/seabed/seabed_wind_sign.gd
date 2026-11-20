class_name SeabedWindSign
extends EnvironmentalSign

@onready var particles: CPUParticles2D = get_node_or_null("WindParticles")

func _update_sign_state(retreated: bool, animate: bool = false) -> void:
	super._update_sign_state(retreated, animate)
	visible = retreated
	if particles:
		particles.emitting = retreated

## Called when the player inspects or experiences the seabed wind/mist draft.
func observe_wind() -> void:
	if not is_active:
		return
	AtmosphericMessageUI.display("A chilling, unnatural draft rises from the dry oceanic trench.")
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("wind_sign_seen", true)
	else:
		StoryStateController.set_story_flag("wind_sign_seen", true)
