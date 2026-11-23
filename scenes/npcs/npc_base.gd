class_name NPCBase
extends CharacterBody2D

## Lightweight NPC state machine states.
enum State {
	IDLE,
	WALKING,
	PAUSED,
}

## Canonical cardinal animation states matching project standard.
const ANIM_STATES: Array[String] = [
	"idle_up", "idle_down", "idle_left", "idle_right",
	"walk_up", "walk_down", "walk_left", "walk_right",
]

## Emitted when the NPC state machine changes state.
signal state_changed(new_state: State)

## Emitted when the NPC reaches an active waypoint.
signal waypoint_reached(index: int, pos: Vector2)

## Emitted when a player interacts with this NPC.
signal interacted(player: Player)

## Display name of this NPC.
@export var npc_name: String = "Villager"

## Walking movement speed in pixels per second.
@export var speed: float = 40.0

## Active state machine state.
@export var current_state: State = State.IDLE

## Whether movement is externally locked (e.g. during dialogue or cutscenes).
@export var is_movement_locked: bool = false

## Whether this NPC accepts interactions.
@export var is_interactable: bool = true

## Prompt message displayed when the player approaches.
@export var prompt_message: String = "Talk to Villager"

## List of target waypoints in global coordinates.
@export var waypoints: Array[Vector2] = []

## Whether to loop waypoints continuously or stop at the final waypoint.
@export var loop_waypoints: bool = true

## Wait duration at each reached waypoint before proceeding to the next.
@export var waypoint_wait_time: float = 1.0

## Distance threshold in pixels to consider a waypoint reached.
@export var arrival_threshold: float = 2.0

## Seed for deterministic pseudo-random ambient decisions.
@export var rng_seed: int = 12345

## Directional textures.
@export var texture_down: Texture2D = preload("res://art/npcs/villager.png")
@export var texture_up: Texture2D = null
@export var texture_left: Texture2D = null
@export var texture_right: Texture2D = null

## Tracks the last non-zero facing direction (defaults to Vector2.DOWN).
var facing_direction: Vector2 = Vector2.DOWN

## Current active animation state string.
var current_animation_state: String = "idle_down"

## Index of the current target waypoint.
var current_waypoint_index: int = 0

## Direction used when directly commanded to walk without waypoints.
var manual_move_dir: Vector2 = Vector2.ZERO

## Deterministic RNG instance.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Internal timer tracking idle/pause delays.
var _wait_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: NPCInteractionArea = get_node_or_null("InteractionArea")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
	if not interaction_area:
		interaction_area = get_node_or_null("InteractionArea")
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	
	rng.seed = rng_seed
	_setup_animation_player()
	
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if texture_down:
			sprite.texture = texture_down
	
	if interaction_area:
		interaction_area.prompt_message = prompt_message
		interaction_area.is_interactable = is_interactable
	
	_update_animation_state(Vector2.ZERO)

func _setup_animation_player() -> void:
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	if not animation_player:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
	
	var anim_lib := AnimationLibrary.new()
	for state_name in ANIM_STATES:
		var anim := Animation.new()
		var is_walk: bool = state_name.begins_with("walk_")
		anim.length = 0.4 if is_walk else 0.1
		anim.loop_mode = Animation.LOOP_LINEAR if is_walk else Animation.LOOP_NONE
		
		# Track 0: Texture
		var track_tex := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_tex, NodePath("Sprite2D:texture"))
		var tex: Texture2D = _resolve_directional_texture(state_name)
		anim.track_insert_key(track_tex, 0.0, tex)
		
		# Track 1: Subtle GBA walk bobbing for walking states
		if is_walk:
			var track_pos := anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(track_pos, NodePath("Sprite2D:position"))
			anim.track_insert_key(track_pos, 0.0, Vector2(0, -5))
			anim.track_insert_key(track_pos, 0.1, Vector2(0, -6))
			anim.track_insert_key(track_pos, 0.2, Vector2(0, -5))
			anim.track_insert_key(track_pos, 0.3, Vector2(0, -4))
		
		anim_lib.add_animation(state_name, anim)
	
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")
	animation_player.add_animation_library("", anim_lib)

func _resolve_directional_texture(state_name: String) -> Texture2D:
	if "up" in state_name and texture_up:
		return texture_up
	elif "left" in state_name and texture_left:
		return texture_left
	elif "right" in state_name and texture_right:
		return texture_right
	return texture_down

func _physics_process(delta: float) -> void:
	if is_movement_locked or current_state == State.PAUSED:
		velocity = Vector2.ZERO
		if is_inside_tree():
			move_and_slide()
		_update_animation_state(Vector2.ZERO)
		return
	
	if current_state == State.IDLE:
		velocity = Vector2.ZERO
		if is_inside_tree():
			move_and_slide()
		_update_animation_state(Vector2.ZERO)
		
		# If waiting at a waypoint, countdown and advance
		if not waypoints.is_empty() and _wait_timer > 0.0:
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				_advance_waypoint()
		return
	
	if current_state == State.WALKING:
		if waypoints.is_empty():
			if manual_move_dir != Vector2.ZERO:
				facing_direction = manual_move_dir
				velocity = manual_move_dir * speed
				if velocity.x != 0.0 and velocity.y != 0.0:
					velocity.y = 0.0 # Enforce strict cardinal velocity
				_update_animation_state(velocity)
				if is_inside_tree():
					move_and_slide()
			else:
				velocity = Vector2.ZERO
				set_state(State.IDLE)
		else:
			_process_waypoint_movement(delta)

## Executes strict cardinal movement towards the current waypoint.
func _process_waypoint_movement(_delta: float) -> void:
	if current_waypoint_index < 0 or current_waypoint_index >= waypoints.size():
		velocity = Vector2.ZERO
		set_state(State.IDLE)
		return
	
	var target: Vector2 = waypoints[current_waypoint_index]
	var diff: Vector2 = target - global_position
	
	if diff.length() <= arrival_threshold:
		_handle_waypoint_arrival(target)
		return
	
	var move_dir := Vector2.ZERO
	
	# Sequential cardinal movement: resolve dominant axis first
	if abs(diff.x) > arrival_threshold:
		move_dir = Vector2(signf(diff.x), 0.0)
	elif abs(diff.y) > arrival_threshold:
		move_dir = Vector2(0.0, signf(diff.y))
	else:
		_handle_waypoint_arrival(target)
		return
	
	facing_direction = move_dir
	velocity = move_dir * speed
	
	# Strict cardinal enforcement: velocity must NEVER be diagonal
	if velocity.x != 0.0 and velocity.y != 0.0:
		velocity.y = 0.0
	
	_update_animation_state(velocity)
	if is_inside_tree():
		move_and_slide()

func _handle_waypoint_arrival(target: Vector2) -> void:
	global_position = target
	velocity = Vector2.ZERO
	_update_animation_state(Vector2.ZERO)
	var idx := current_waypoint_index
	waypoint_reached.emit(idx, target)
	set_state(State.IDLE)
	_wait_timer = waypoint_wait_time

func _advance_waypoint() -> void:
	if waypoints.is_empty():
		return
	
	var next_idx := current_waypoint_index + 1
	if next_idx >= waypoints.size():
		if loop_waypoints:
			current_waypoint_index = 0
			set_state(State.WALKING)
		else:
			current_waypoint_index = waypoints.size() - 1
			set_state(State.IDLE)
	else:
		current_waypoint_index = next_idx
		set_state(State.WALKING)

# --- State & Control Methods ---

## Changes state and emits state_changed signal.
func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)

func get_state() -> State:
	return current_state

func get_state_name() -> String:
	match current_state:
		State.IDLE: return "IDLE"
		State.WALKING: return "WALKING"
		State.PAUSED: return "PAUSED"
	return "UNKNOWN"

## Turns NPC to face an explicit cardinal direction vector.
func face_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	if abs(dir.x) >= abs(dir.y):
		facing_direction = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		facing_direction = Vector2.DOWN if dir.y > 0 else Vector2.UP
	_update_animation_state(Vector2.ZERO)

## Turns NPC to face towards a world position (e.g. approaching player).
func face_towards(target_pos: Vector2) -> void:
	var diff := target_pos - global_position
	face_direction(diff)

## Direct command to walk in a single cardinal direction.
func walk_in_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		stop_moving()
		return
	if abs(dir.x) >= abs(dir.y):
		manual_move_dir = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		manual_move_dir = Vector2.DOWN if dir.y > 0 else Vector2.UP
	facing_direction = manual_move_dir
	set_state(State.WALKING)

## Stops movement and returns to IDLE.
func stop_moving() -> void:
	manual_move_dir = Vector2.ZERO
	velocity = Vector2.ZERO
	set_state(State.IDLE)

## Pauses movement temporarily without losing waypoint progress.
func pause_movement() -> void:
	velocity = Vector2.ZERO
	set_state(State.PAUSED)

## Resumes movement.
func resume_movement() -> void:
	set_state(State.WALKING)

## Sets the waypoint list and starts walking towards the first waypoint.
func set_waypoints(new_waypoints: Array) -> void:
	waypoints.clear()
	for wp in new_waypoints:
		if wp is Vector2:
			waypoints.append(wp)
	current_waypoint_index = 0
	_wait_timer = 0.0
	if not waypoints.is_empty():
		set_state(State.WALKING)

func add_waypoint(wp: Vector2) -> void:
	waypoints.append(wp)
	if current_state == State.IDLE and waypoints.size() == 1:
		set_state(State.WALKING)

func clear_waypoints() -> void:
	waypoints.clear()
	current_waypoint_index = 0
	stop_moving()

# --- Movement Locking ---

func lock_movement() -> void:
	is_movement_locked = true
	velocity = Vector2.ZERO
	_update_animation_state(Vector2.ZERO)

func unlock_movement() -> void:
	is_movement_locked = false

# --- Interaction Support ---

## Primary interaction entry point.
func interact(player: Player) -> void:
	if not is_interactable:
		return
	if player:
		face_towards(player.global_position)
	interacted.emit(player)

# --- Animation & Facing Helpers ---

func get_facing_direction() -> Vector2:
	return facing_direction

func get_facing_direction_name() -> String:
	if facing_direction == Vector2.UP:
		return "up"
	elif facing_direction == Vector2.DOWN:
		return "down"
	elif facing_direction == Vector2.LEFT:
		return "left"
	elif facing_direction == Vector2.RIGHT:
		return "right"
	return "down"

func get_animation_state() -> String:
	return current_animation_state

func _update_animation_state(dir: Vector2) -> void:
	var dir_name := get_facing_direction_name()
	if dir != Vector2.ZERO:
		current_animation_state = "walk_" + dir_name
	else:
		current_animation_state = "idle_" + dir_name
	
	_update_sprite_direction()
	
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	if animation_player and animation_player.has_animation(current_animation_state):
		if animation_player.current_animation != current_animation_state:
			animation_player.play(current_animation_state)

func _update_sprite_direction() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
	var tex := _resolve_directional_texture(current_animation_state)
	if tex:
		sprite.texture = tex

# --- Randomness Helpers ---

func set_rng_seed(seed_val: int) -> void:
	rng_seed = seed_val
	rng.seed = seed_val

func get_random_float(min_val: float, max_val: float) -> float:
	return rng.randf_range(min_val, max_val)

func get_random_int(min_val: int, max_val: int) -> int:
	return rng.randi_range(min_val, max_val)

func get_random_idle_duration(min_time: float = 1.0, max_time: float = 3.0) -> float:
	return rng.randf_range(min_time, max_time)

func get_random_pause_duration(min_time: float = 0.5, max_time: float = 2.0) -> float:
	return rng.randf_range(min_time, max_time)

func get_random_waypoint_index() -> int:
	if waypoints.is_empty():
		return 0
	return rng.randi_range(0, waypoints.size() - 1)
