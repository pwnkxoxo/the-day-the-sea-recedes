class_name Player
extends CharacterBody2D

## Configurable movement speed in pixels per second.
@export var speed: float = 80.0

## Whether player movement and interaction are locked (e.g. during dialogue or cutscenes).
@export var is_movement_locked: bool = false

## Tracks the last non-zero movement direction (defaults to Vector2.DOWN).
var facing_direction: Vector2 = Vector2.DOWN

## Directional textures
@export var texture_down: Texture2D = preload("res://art/sens/sens_down.png")
@export var texture_up: Texture2D = preload("res://art/sens/sens_up.png")
@export var texture_left: Texture2D = preload("res://art/sens/sens_left.png")
@export var texture_right: Texture2D = preload("res://art/sens/sens_right.png")

## Canonical cardinal animation states for pixel-art characters.
const ANIM_STATES: Array[String] = [
	"idle_up", "idle_down", "idle_left", "idle_right",
	"walk_up", "walk_down", "walk_left", "walk_right"
]

## Current animation / movement state string.
## Valid states: idle_up, idle_down, idle_left, idle_right, walk_up, walk_down, walk_left, walk_right.
var current_animation_state: String = "idle_down"

## List of interactables currently within the interaction detection area.
var nearby_interactables: Array[Interactable] = []

## Stack of currently active pressed movement directions in order of activation (last is active).
var _input_stack: Array[String] = []

## Tracks previous pressed state of each cardinal direction for change detection.
var _action_pressed_states: Dictionary = {
	"up": false,
	"down": false,
	"left": false,
	"right": false,
}

@onready var camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not camera:
		camera = get_node_or_null("Camera2D")
	if not interaction_area:
		interaction_area = get_node_or_null("InteractionArea")
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	
	_setup_animation_player()
	
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if texture_down:
			sprite.texture = texture_down
	if interaction_area:
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)
	
	_update_animation_state(Vector2.ZERO)

func _setup_animation_player() -> void:
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	if not animation_player:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
	
	var anim_lib := AnimationLibrary.new()
	var states: Array[String] = [
		"idle_up", "idle_down", "idle_left", "idle_right",
		"walk_up", "walk_down", "walk_left", "walk_right"
	]
	
	for state_name in states:
		var anim := Animation.new()
		var is_walk: bool = state_name.begins_with("walk_")
		anim.length = 0.4 if is_walk else 0.1
		anim.loop_mode = Animation.LOOP_LINEAR if is_walk else Animation.LOOP_NONE
		
		# Track 0: Texture
		var track_tex := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_tex, NodePath("Sprite2D:texture"))
		var tex: Texture2D = texture_down
		if "up" in state_name:
			tex = texture_up
		elif "left" in state_name:
			tex = texture_left
		elif "right" in state_name:
			tex = texture_right
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

func _unhandled_input(event: InputEvent) -> void:
	if is_movement_locked:
		return
	
	for dir_name in ["up", "down", "left", "right"]:
		var action_name := _dir_name_to_action(dir_name)
		if event.is_action_pressed(action_name) and not event.is_echo():
			_input_stack.erase(dir_name)
			_input_stack.append(dir_name)
			_action_pressed_states[dir_name] = true
		elif event.is_action_released(action_name):
			_input_stack.erase(dir_name)
			_action_pressed_states[dir_name] = false

func _physics_process(_delta: float) -> void:
	if is_movement_locked:
		velocity = Vector2.ZERO
		if is_inside_tree():
			move_and_slide()
		_update_animation_state(Vector2.ZERO)
		return

	_sync_input_stack()
	var direction := get_4way_direction()
	
	if direction != Vector2.ZERO:
		facing_direction = direction
	
	velocity = direction * speed
	
	# Strict cardinal enforcement: velocity must NEVER be diagonal
	if velocity.x != 0.0 and velocity.y != 0.0:
		if abs(velocity.x) >= abs(velocity.y):
			velocity.y = 0.0
		else:
			velocity.x = 0.0
	
	_update_animation_state(direction)
	if is_inside_tree():
		move_and_slide()
	
	if Input.is_action_just_pressed("interact"):
		try_interact()

## Synchronizes input stack with actual action states from Input singleton.
func _sync_input_stack() -> void:
	for dir_name in ["up", "down", "left", "right"]:
		var is_pressed: bool = _is_direction_action_pressed(dir_name)
		var was_pressed: bool = _action_pressed_states.get(dir_name, false)
		
		if is_pressed and not was_pressed:
			_input_stack.erase(dir_name)
			_input_stack.append(dir_name)
		elif not is_pressed and was_pressed:
			_input_stack.erase(dir_name)
		
		_action_pressed_states[dir_name] = is_pressed
	
	# Prune any released actions from stack
	var active: Array[String] = []
	for d in _input_stack:
		if _is_direction_action_pressed(d):
			active.append(d)
	_input_stack = active

func _is_direction_action_pressed(dir_name: String) -> bool:
	match dir_name:
		"up": return Input.is_action_pressed("move_up")
		"down": return Input.is_action_pressed("move_down")
		"left": return Input.is_action_pressed("move_left")
		"right": return Input.is_action_pressed("move_right")
	return false

func _dir_name_to_action(dir_name: String) -> String:
	match dir_name:
		"up": return "move_up"
		"down": return "move_down"
		"left": return "move_left"
		"right": return "move_right"
	return ""

func _dir_name_to_vector(dir_name: String) -> Vector2:
	match dir_name:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.ZERO

## Returns the active cardinal movement direction vector based on the input stack.
func get_4way_direction() -> Vector2:
	if _input_stack.is_empty():
		return Vector2.ZERO
	return _dir_name_to_vector(_input_stack[-1])

## Returns the current facing direction name as a string ("up", "down", "left", "right").
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

## Returns current animation state string.
func get_animation_state() -> String:
	return current_animation_state

## Returns a copy of the canonical 8 animation state names.
static func get_animation_states() -> Array[String]:
	return ANIM_STATES.duplicate()

## Returns true if the given animation state name is valid.
static func has_animation_state(state_name: String) -> bool:
	return ANIM_STATES.has(state_name)

## Returns directional texture by cardinal direction name ("up", "down", "left", "right").
func get_directional_texture(dir_name: String) -> Texture2D:
	match dir_name:
		"up": return texture_up
		"down": return texture_down
		"left": return texture_left
		"right": return texture_right
	return null

## Sets directional texture by cardinal direction name.
func set_directional_texture(dir_name: String, tex: Texture2D) -> void:
	match dir_name:
		"up": texture_up = tex
		"down": texture_down = tex
		"left": texture_left = tex
		"right": texture_right = tex
	_update_sprite_direction()
	_setup_animation_player()

## Updates animation state and directional sprite textures.
func _update_animation_state(dir: Vector2) -> void:
	var dir_name := get_facing_direction_name()
	if dir != Vector2.ZERO:
		current_animation_state = "walk_" + dir_name
	else:
		current_animation_state = "idle_" + dir_name
	
	_update_sprite_direction(dir)
	
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	if animation_player and animation_player.has_animation(current_animation_state):
		if animation_player.current_animation != current_animation_state:
			animation_player.play(current_animation_state)

## Backward-compatible sprite direction update method.
func _update_sprite_direction(_dir: Vector2 = Vector2.ZERO) -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
	match get_facing_direction_name():
		"up":
			if texture_up: sprite.texture = texture_up
		"down":
			if texture_down: sprite.texture = texture_down
		"left":
			if texture_left: sprite.texture = texture_left
		"right":
			if texture_right: sprite.texture = texture_right

## Locks player movement and interaction, resetting velocity to zero.
func lock_movement() -> void:
	is_movement_locked = true
	velocity = Vector2.ZERO
	_input_stack.clear()
	_update_animation_state(Vector2.ZERO)

## Restores player movement and interaction.
func unlock_movement() -> void:
	is_movement_locked = false

## Configures camera limits to match the active map/world bounds.
func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	if not camera:
		camera = get_node_or_null("Camera2D")
	if camera:
		camera.limit_left = left
		camera.limit_top = top
		camera.limit_right = right
		camera.limit_bottom = bottom

## Attempts to interact with the closest valid interactable in range.
## Returns true if an interaction occurred, false otherwise.
func try_interact() -> bool:
	if is_movement_locked:
		return false
	var target := get_best_interactable()
	if target:
		target.interact(self)
		return true
	return false

## Returns the closest available interactable within range.
func get_best_interactable() -> Interactable:
	var best: Interactable = null
	var best_distance_sq := INF
	for item in nearby_interactables:
		if not is_instance_valid(item) or not item.is_interactable:
			continue
		var dist_sq := global_position.distance_squared_to(item.global_position)
		if dist_sq < best_distance_sq:
			best_distance_sq = dist_sq
			best = item
	return best

func _on_interaction_area_entered(area: Area2D) -> void:
	if area is Interactable and not nearby_interactables.has(area):
		nearby_interactables.append(area)

func _on_interaction_area_exited(area: Area2D) -> void:
	if area is Interactable:
		nearby_interactables.erase(area)

# --- Public helpers for deterministic testing and simulation ---

## Simulates pressing a direction (for testing or scripted sequences).
func simulate_press(dir_name: String) -> void:
	var action := _dir_name_to_action(dir_name)
	if not action.is_empty():
		Input.action_press(action)
	if dir_name in ["up", "down", "left", "right"]:
		_input_stack.erase(dir_name)
		_input_stack.append(dir_name)
		_action_pressed_states[dir_name] = true

## Simulates releasing a direction (for testing or scripted sequences).
func simulate_release(dir_name: String) -> void:
	var action := _dir_name_to_action(dir_name)
	if not action.is_empty():
		Input.action_release(action)
	if dir_name in ["up", "down", "left", "right"]:
		_input_stack.erase(dir_name)
		_action_pressed_states[dir_name] = false

## Clears all simulated inputs and active stack.
func clear_simulated_inputs() -> void:
	for d in ["up", "down", "left", "right"]:
		simulate_release(d)
	_input_stack.clear()

## Computes deterministic direction for an arbitrary stack of direction names.
static func compute_direction_from_stack(stack: Array[String]) -> Vector2:
	if stack.is_empty():
		return Vector2.ZERO
	match stack[-1]:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.ZERO
