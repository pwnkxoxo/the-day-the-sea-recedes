class_name ApproachingWave
extends Node2D

## Emitted when the approaching wave event begins.
signal wave_started

## Emitted during the distant wave approach phase.
signal wave_approaching

## Emitted when the wave impacts and reaches the village/seabed.
signal wave_impacted

## Emitted when the wave sequence completes and player has survived.
signal wave_completed

## Emitted on trigger attempts; [param was_gated] is true if blocked by prerequisites.
signal wave_attempted(was_gated: bool)

## State machine for the deterministic wave sequence.
enum WaveState {
	IDLE,
	APPROACHING,
	ARRIVING,
	COMPLETE
}

## Current state of the wave sequence.
var current_state: WaveState = WaveState.IDLE

## Whether to automatically start the wave event when reaching high ground.
@export var auto_start_on_high_ground: bool = true

## Duration in seconds for the wave wall to travel from horizon to the village.
@export var wave_travel_duration: float = 3.0

## Duration of screen shake during wave arrival.
@export var shake_duration: float = 0.8

## Magnitude of screen shake in pixels.
@export var shake_magnitude: float = 4.0

# Node references
@onready var wave_container: Node2D = get_node_or_null("WaveContainer")
@onready var surge_wall: ColorRect = get_node_or_null("WaveContainer/SurgeWall")
@onready var wave_foam: ColorRect = get_node_or_null("WaveContainer/WaveFoam")
@onready var flooded_overlay: ColorRect = get_node_or_null("FloodedOverlay")
@onready var flash_overlay: ColorRect = get_node_or_null("FlashOverlay")

var _active_tween: Tween = null
var _bound_player: Player = null
var _bound_camera: Camera2D = null
var _original_camera_offset: Vector2 = Vector2.ZERO

var _surge_stream: AudioStream = preload("res://audio/wave_surge.wav")
var _surge_player: AudioStreamPlayer = null

func _ready() -> void:
	_surge_player = AudioStreamPlayer.new()
	_surge_player.stream = _surge_stream
	_surge_player.volume_db = -4.0
	add_child(_surge_player)
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_story_flag_changed)
	
	_setup_visuals()
	
	# If already completed in persisted state, reflect it immediately
	if StoryStateController.has_player_survived():
		current_state = WaveState.COMPLETE
		_apply_post_wave_environment()
	elif StoryStateController.is_wave_hit():
		current_state = WaveState.ARRIVING
		_apply_post_wave_environment()

func _on_story_flag_changed(flag_name: String, value: bool) -> void:
	if flag_name == "evacuation_reached_high_ground" and value:
		if auto_start_on_high_ground and current_state == WaveState.IDLE:
			call_deferred("start_wave_event")

## Initializes visual components to their baseline state.
func _setup_visuals() -> void:
	if wave_container:
		wave_container.visible = false
	if flooded_overlay:
		flooded_overlay.visible = false
	if flash_overlay:
		flash_overlay.visible = false
		flash_overlay.modulate.a = 0.0

## Returns the current wave state machine state.
func get_state() -> WaveState:
	return current_state

## Returns the state name as a human-readable string.
func get_state_string() -> String:
	match current_state:
		WaveState.IDLE:
			return "IDLE"
		WaveState.APPROACHING:
			return "APPROACHING"
		WaveState.ARRIVING:
			return "ARRIVING"
		WaveState.COMPLETE:
			return "COMPLETE"
	return "UNKNOWN"

## Primary entry point to initiate the wave event.
func start_wave_event(player: Player = null, camera: Camera2D = null) -> bool:
	var can_trigger: bool = StoryStateController.can_trigger_wave_event()
	if not can_trigger:
		wave_attempted.emit(true)
		print("[ApproachingWave] Wave event gated: evacuation_reached_high_ground is false.")
		return false
	
	if current_state != WaveState.IDLE or StoryStateController.has_player_survived():
		wave_attempted.emit(false)
		return false
	
	wave_attempted.emit(false)
	_bound_player = player if player else _find_player()
	_bound_camera = camera if camera else _find_camera()
	
	current_state = WaveState.APPROACHING
	StoryStateController.set_story_flag("wave_event_started", true)
	wave_started.emit()
	print("[ApproachingWave] Wave event started: wave_event_started = true")
	
	_run_sequence()
	return true

## Direct alias for triggering wave event programmatically or in test scripts.
func trigger_wave() -> bool:
	return start_wave_event()

## Runs the deterministic sequence phases.
func _run_sequence() -> void:
	# PHASE 1 — SILENCE
	AtmosphericMessageUI.display("The sea has gone completely still.")
	
	if not is_inside_tree():
		_execute_arrival_instant()
		_execute_completion_instant()
		return
	
	var seq_tween := create_tween()
	# Brief silence interval before distant movement
	seq_tween.tween_interval(1.5)
	
	# PHASE 2 — DISTANT MOVEMENT
	seq_tween.tween_callback(func():
		AtmosphericMessageUI.display("The horizon is moving.")
		wave_approaching.emit()
		_show_distant_wave()
	)
	
	# PHASE 3 — WAVE RISES & APPROACHES
	seq_tween.tween_interval(0.8)
	seq_tween.tween_callback(func():
		_animate_wave_advance()
	)
	
	# Wait for wave advance tween to reach village
	seq_tween.tween_interval(wave_travel_duration)
	
	# PHASE 4 — WAVE ARRIVAL (IMPACT)
	seq_tween.tween_callback(func():
		_execute_wave_arrival()
	)
	
	# Pause during impact before survival message
	seq_tween.tween_interval(1.5)
	
	# PHASE 5 — SURVIVAL
	seq_tween.tween_callback(func():
		_execute_wave_survival()
	)

## Shows initial distant wave visual on the horizon.
func _show_distant_wave() -> void:
	if wave_container:
		wave_container.visible = true
		wave_container.scale = Vector2(0.2, 0.2)
		wave_container.modulate.a = 0.5
		# Position far out towards seabed/sea (typically south or horizon)
		wave_container.position.y = 380.0

## Animates wave swelling and rushing toward lower village.
func _animate_wave_advance() -> void:
	if not wave_container:
		return
	if _surge_player:
		_surge_player.play()
	var advance_tween := create_tween().set_parallel(true)
	advance_tween.tween_property(wave_container, "scale", Vector2(1.0, 1.0), wave_travel_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	advance_tween.tween_property(wave_container, "position:y", 180.0, wave_travel_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	advance_tween.tween_property(wave_container, "modulate:a", 1.0, 1.0)

## Executes Phase 4: wave arrival impact.
func _execute_wave_arrival() -> void:
	current_state = WaveState.ARRIVING
	StoryStateController.set_story_flag("wave_arrived", true)
	wave_impacted.emit()
	print("[ApproachingWave] Wave arrived at village: wave_arrived = true")
	
	# Briefly lock player movement to preserve high-ground position
	if _bound_player and is_instance_valid(_bound_player):
		_bound_player.lock_movement()
		_bound_player.velocity = Vector2.ZERO
	
	_trigger_screen_shake()
	_trigger_impact_flash()
	_apply_post_wave_environment()

## Executes Phase 5: wave survival and completion.
func _execute_wave_survival() -> void:
	current_state = WaveState.COMPLETE
	StoryStateController.set_story_flag("survived_wave", true)
	wave_completed.emit()
	print("[ApproachingWave] Player survived wave on high ground: survived_wave = true")
	
	# Cleanly restore player control
	if _bound_player and is_instance_valid(_bound_player):
		_bound_player.unlock_movement()
	
	# Atmospheric survival messages
	AtmosphericMessageUI.display("The wave has passed.")
	if is_inside_tree():
		var tree_ref := get_tree()
		if tree_ref:
			var timer := tree_ref.create_timer(2.2)
			timer.timeout.connect(func():
				AtmosphericMessageUI.display("The village is still standing above the water.")
			)
	
	# Hide surging wave wall; flooded overlay persists
	if wave_container:
		var fade_tween := create_tween()
		fade_tween.tween_property(wave_container, "modulate:a", 0.0, 1.0)
		fade_tween.finished.connect(func():
			if wave_container: wave_container.visible = false
		)

## Instant arrival execution for headless or instantaneous tests.
func _execute_arrival_instant() -> void:
	current_state = WaveState.ARRIVING
	StoryStateController.set_story_flag("wave_arrived", true)
	wave_impacted.emit()
	_apply_post_wave_environment()

## Instant completion execution for headless or instantaneous tests.
func _execute_completion_instant() -> void:
	current_state = WaveState.COMPLETE
	StoryStateController.set_story_flag("survived_wave", true)
	wave_completed.emit()
	AtmosphericMessageUI.display("The wave has passed.")

## Screen shake during wave impact.
func _trigger_screen_shake() -> void:
	if not _bound_camera or not is_inside_tree():
		return
	_original_camera_offset = _bound_camera.offset
	var shake_tween := create_tween()
	var step_count: int = int(shake_duration / 0.05)
	for i in range(step_count):
		var rand_offset := Vector2(
			randf_range(-shake_magnitude, shake_magnitude),
			randf_range(-shake_magnitude, shake_magnitude)
		)
		shake_tween.tween_property(_bound_camera, "offset", _original_camera_offset + rand_offset, 0.05)
	shake_tween.tween_property(_bound_camera, "offset", _original_camera_offset, 0.05)

## Impact flash overlay effect.
func _trigger_impact_flash() -> void:
	if not flash_overlay or not is_inside_tree():
		return
	flash_overlay.visible = true
	flash_overlay.modulate.a = 0.8
	var flash_tween := create_tween()
	flash_tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.6)
	flash_tween.finished.connect(func():
		if flash_overlay: flash_overlay.visible = false
	)

## Applies post-wave environmental changes: flooded lower village and returned sea.
func _apply_post_wave_environment() -> void:
	if flooded_overlay:
		flooded_overlay.visible = true
		flooded_overlay.modulate.a = 0.85

func _find_player() -> Player:
	if is_inside_tree():
		return get_tree().get_first_node_in_group("player") as Player
	return null

func _find_camera() -> Camera2D:
	if _bound_player and _bound_player.camera:
		return _bound_player.camera
	if is_inside_tree():
		var p := _find_player()
		if p and p.camera:
			return p.camera
	return null
