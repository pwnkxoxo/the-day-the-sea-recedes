class_name HighGroundZone
extends Area2D

## Emitted when player successfully reaches the high-ground safety zone during evacuation.
signal high_ground_reached

## Emitted on entry attempts; [param was_gated] is true if blocked because town has not been warned yet.
signal high_ground_attempted(was_gated: bool)

## Whether this trigger is currently active.
@export var is_active: bool = true

## Primary atmospheric confirmation message.
@export var primary_message: String = "High ground."

## Followup atmospheric realization message.
@export var followup_message: String = "The village lies below. The sea is coming."

## Delay in seconds between primary and followup atmospheric messages.
@export var followup_delay: float = 2.0

## Tracks if high ground has been activated on this instance.
var has_triggered: bool = false

## Visual indicator reference if present.
@onready var visual_marker: Node2D = get_node_or_null("VisualMarker")
@onready var prompt_label: Label = get_node_or_null("PromptLabel")

func _ready() -> void:
	# Ensure collision layer and mask detect Player character body (layer 1) and interaction area (layer 2)
	collision_layer = 2
	collision_mask = 1 | 2
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# If StoryState already recorded reaching high ground in a previous scene, reflect it
	if StoryStateController.has_story_flag("evacuation_reached_high_ground"):
		has_triggered = true
		_update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body is Player or body.is_in_group("player") or body.name == "Player":
		_handle_player_entry(body)

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	var candidate: Node = area.owner if area.owner else area.get_parent()
	if candidate is Player or candidate.is_in_group("player"):
		_handle_player_entry(candidate)

## Main entry handler for player reaching the high-ground zone.
func _handle_player_entry(player: Node) -> void:
	var is_warned: bool = StoryStateController.is_village_warned() if StoryStateController.instance == null else StoryStateController.instance.is_town_warned()
	
	# Gate check: town must be warned before evacuation to high ground becomes valid
	if not is_warned:
		high_ground_attempted.emit(true)
		return
	
	# Idempotent check: prevent repeated activation
	if has_triggered or StoryStateController.has_story_flag("evacuation_reached_high_ground"):
		high_ground_attempted.emit(false)
		return
	
	has_triggered = true
	high_ground_attempted.emit(false)
	
	# Set StoryState flag
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("evacuation_reached_high_ground", true)
	else:
		StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
	
	high_ground_reached.emit()
	_update_visuals()
	
	# Atmospheric toasts: "High ground." then "The village lies below. The sea is coming."
	AtmosphericMessageUI.display(primary_message)
	
	if is_inside_tree() and followup_delay > 0.0:
		var tree_ref := get_tree()
		if tree_ref:
			var timer := tree_ref.create_timer(followup_delay)
			timer.timeout.connect(func():
				AtmosphericMessageUI.display(followup_message)
			)
	elif followup_delay <= 0.0:
		AtmosphericMessageUI.display(followup_message)
	
	print("[HighGroundZone] Player reached high ground. evacuation_reached_high_ground = true")

## Direct helper to trigger high-ground entry programmatically or in test scripts.
func trigger_entry(player: Node = null) -> bool:
	if not is_active:
		return false
	_handle_player_entry(player)
	return has_triggered

## Updates visual props associated with this zone.
func _update_visuals() -> void:
	if visual_marker:
		visual_marker.modulate = Color(0.6, 0.9, 1.0, 1.0)
	if prompt_label:
		prompt_label.text = "High Ground [Safe]"
		prompt_label.modulate = Color(0.6, 0.9, 1.0, 1.0)
