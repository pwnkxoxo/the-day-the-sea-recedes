class_name Village
extends Node2D

## World width in pixels. Used for camera limits and boundary sizing.
@export var world_width: int = 960

## World height in pixels. Used for camera limits and boundary sizing.
@export var world_height: int = 540

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var ladder_spawn: Marker2D = $LadderSpawn
@onready var ocean_water: Node2D = $Shore/OceanWater
@onready var access_barrier: StaticBody2D = $Boundaries/SeabedAccessBarrier
@onready var seabed_transition: Area2D = $SeabedAccess/SeabedTransition
@onready var town_hall_door: ColorRect = get_node_or_null("Buildings/TownHall/Door")
@onready var sens_house_door: ColorRect = get_node_or_null("Buildings/SensHouse/Door")
@onready var evacuation_props: Node2D = get_node_or_null("EvacuationProps")
@onready var high_ground_zone: HighGroundZone = get_node_or_null("HighGroundZone")
@onready var coastal_birds: Node2D = get_node_or_null("CoastalBirds")
@onready var approaching_wave: ApproachingWave = get_node_or_null("ApproachingWave")
@onready var final_overlook: FinalOverlook = get_node_or_null("FinalOverlook")
@onready var survivors_group: Node2D = get_node_or_null("Survivors")
@onready var npcs_group: Node2D = get_node_or_null("NPCs")
@onready var sea_change_event: SeaChangeEvent = get_node_or_null("SeaChangeEvent")

## Returns all active NPCBase children residing in the village.
func get_npcs() -> Array[NPCBase]:
	var result: Array[NPCBase] = []
	if npcs_group:
		for child in npcs_group.get_children():
			if child is NPCBase:
				result.append(child)
	return result

## Returns an NPCBase child matching the given node name or npc_name, or null.
func get_npc_by_name(p_name: String) -> NPCBase:
	if npcs_group:
		for child in npcs_group.get_children():
			if child is NPCBase:
				if child.name == p_name or child.npc_name == p_name:
					return child
	return null

## Scripted dialogue initiating the evacuation when returning to warned village.
const EVACUATION_INTRO_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Sens",
		"text": "People are abandoning the lower village... everyone is heading uphill!"
	},
	{
		"speaker": "Sens",
		"text": "The wind is turning cold. I need to reach the high ground cliff lookout before the water strikes!"
	}
]

var _is_animating: bool = false
var _is_evacuation_transitioning: bool = false

var _ambient_stream: AudioStream = preload("res://audio/ocean_ambient.wav")
var _ambient_player: AudioStreamPlayer = null

func _ready() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.stream = _ambient_stream
	_ambient_player.volume_db = -12.0
	add_child(_ambient_player)
	_ambient_player.play()
	
	# Connect to OceanState changes
	if OceanStateController.instance:
		OceanStateController.instance.state_changed.connect(_on_ocean_state_changed)
	
	# Connect to StoryState changes
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_story_flag_changed)
	
	# Initialize access and visuals based on current ocean state
	if StoryStateController.has_player_survived():
		apply_normal_state()
	elif OceanStateController.is_ocean_retreated():
		apply_retreated_state(false)
	else:
		apply_normal_state()
	
	_update_town_state()
	call_deferred("_check_evacuation_start")
	call_deferred("_check_aftermath_start")

## Configures camera limits for a player entering this village area.
func setup_camera(player: Player) -> void:
	if player:
		player.set_camera_limits(0, 0, world_width, world_height)
		_check_evacuation_start(player)

func _on_ocean_state_changed(new_state: OceanStateController.State) -> void:
	if new_state == OceanStateController.State.OCEAN_RETREATED:
		if _ambient_player:
			_ambient_player.volume_db = -20.0
		apply_retreated_state(true)
	else:
		if _ambient_player:
			_ambient_player.volume_db = -12.0
			_ambient_player.pitch_scale = 1.0
		apply_normal_state()

## Applies the normal high-water state: ocean is present, seabed access is blocked.
func apply_normal_state() -> void:
	if ocean_water:
		ocean_water.position.y = 0.0
	if access_barrier and access_barrier.has_node("CollisionShape2D"):
		access_barrier.get_node("CollisionShape2D").set_deferred("disabled", false)
	if seabed_transition:
		if seabed_transition.has_node("CollisionShape2D"):
			seabed_transition.get_node("CollisionShape2D").set_deferred("disabled", true)
		seabed_transition.set_deferred("monitoring", false)

## Applies the retreated state: ocean moves away, exposing the seabed and opening access.
func apply_retreated_state(animate: bool) -> void:
	if animate and is_inside_tree():
		_play_retreat_animation()
	else:
		_set_retreated_immediate()

func _set_retreated_immediate() -> void:
	if ocean_water:
		ocean_water.position.y = 140.0
	if access_barrier and access_barrier.has_node("CollisionShape2D"):
		access_barrier.get_node("CollisionShape2D").set_deferred("disabled", true)
	if seabed_transition:
		if seabed_transition.has_node("CollisionShape2D"):
			seabed_transition.get_node("CollisionShape2D").set_deferred("disabled", false)
		seabed_transition.set_deferred("monitoring", true)

func _play_retreat_animation() -> void:
	if _is_animating:
		return
	_is_animating = true
	var tween = create_tween()
	if ocean_water:
		tween.tween_property(ocean_water, "position:y", 140.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		_is_animating = false
		_set_retreated_immediate()
	)

func _on_story_flag_changed(flag_name: String, new_val: bool) -> void:
	if flag_name == "town_warned":
		_update_town_state()
		_check_evacuation_start()
	elif flag_name == "evacuation_started" or flag_name == "evacuation_reached_high_ground":
		_update_town_state()
	elif flag_name == "wave_arrived":
		_update_town_state()
	elif flag_name == "survived_wave" and new_val:
		_update_town_state()
		_check_aftermath_start()
	elif flag_name == "aftermath_started":
		_update_town_state()

## Checks whether the aftermath start sequence should trigger.
func _check_aftermath_start() -> void:
	var survived: bool = StoryStateController.has_player_survived() if StoryStateController.instance == null else StoryStateController.instance.has_survived_wave()
	if not survived:
		return
	if StoryStateController.has_story_flag("aftermath_started"):
		return
	
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("aftermath_started", true)
	else:
		StoryStateController.set_story_flag("aftermath_started", true)
	
	_update_town_state()
	
	AtmosphericMessageUI.display("The water has stopped.")
	if is_inside_tree():
		var tree_ref := get_tree()
		if tree_ref:
			var timer1 := tree_ref.create_timer(2.0)
			timer1.timeout.connect(func():
				AtmosphericMessageUI.display("Only the sound of the sea remains.")
			)
			var timer2 := tree_ref.create_timer(4.0)
			timer2.timeout.connect(func():
				AtmosphericMessageUI.display("The village below is still standing.")
			)

## Checks whether the evacuation start sequence should trigger.
func _check_evacuation_start(player: Player = null) -> void:
	var is_warned: bool = StoryStateController.is_village_warned() if StoryStateController.instance == null else StoryStateController.instance.is_town_warned()
	if not is_warned:
		return
	if StoryStateController.has_story_flag("evacuation_started"):
		return
	if _is_evacuation_transitioning:
		return
	_is_evacuation_transitioning = true
	
	var active_player: Player = player
	if active_player == null and is_inside_tree():
		active_player = get_tree().get_first_node_in_group("player") as Player
	
	_start_evacuation_sequence(active_player)

## Launches the short evacuation introduction dialogue and toast.
func _start_evacuation_sequence(player: Player = null) -> void:
	AtmosphericMessageUI.display("People are leaving the lower village. Head for high ground.")
	
	if DialogueUI.instance:
		if not DialogueUI.instance.dialogue_ended.is_connected(_on_evacuation_dialogue_ended):
			DialogueUI.instance.dialogue_ended.connect(_on_evacuation_dialogue_ended, CONNECT_ONE_SHOT)
		DialogueUI.display_dialogue(EVACUATION_INTRO_DIALOGUE, player)
	else:
		# Fallback if DialogueUI is not instantiated in test scene
		_finalize_evacuation_start()

func _on_evacuation_dialogue_ended() -> void:
	_finalize_evacuation_start()

## Finalizes the evacuation start by updating StoryState and village visuals.
func _finalize_evacuation_start() -> void:
	_is_evacuation_transitioning = false
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("evacuation_started", true)
	else:
		StoryStateController.set_story_flag("evacuation_started", true)
	_update_town_state()
	print("[Village] Evacuation started: evacuation_started = true")

## Updates village visual state when town is warned, evacuated, or in aftermath.
func _update_town_state() -> void:
	var is_warned: bool = StoryStateController.is_village_warned() if StoryStateController.instance == null else StoryStateController.instance.is_town_warned()
	var has_survived: bool = StoryStateController.has_player_survived() if StoryStateController.instance == null else StoryStateController.instance.has_survived_wave()
	
	if town_hall_door:
		if is_warned:
			# Open doorway into dark council hall
			town_hall_door.color = Color(0.08, 0.05, 0.04, 1)
		else:
			# Closed wooden door
			town_hall_door.color = Color(0.25, 0.18, 0.12, 1)
	if sens_house_door:
		if is_warned:
			sens_house_door.color = Color(0.08, 0.05, 0.04, 1)
		else:
			sens_house_door.color = Color(0.25, 0.18, 0.12, 1)
	if evacuation_props:
		evacuation_props.visible = is_warned
	if coastal_birds:
		# Birds scatter inland away from the shore
		coastal_birds.visible = not is_warned
	
	# Aftermath specific visuals
	if has_survived:
		apply_normal_state()
		if approaching_wave and approaching_wave.flooded_overlay:
			approaching_wave.flooded_overlay.visible = true
		if survivors_group:
			survivors_group.visible = true
		if final_overlook:
			final_overlook.visible = true
	else:
		if survivors_group:
			survivors_group.visible = false
		if final_overlook:
			final_overlook.visible = false
