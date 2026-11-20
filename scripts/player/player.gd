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

## List of interactables currently within the interaction detection area.
var nearby_interactables: Array[Interactable] = []

@onready var camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player")
	if sprite and texture_down:
		sprite.texture = texture_down
	if interaction_area:
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)

func _physics_process(_delta: float) -> void:
	if is_movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing_direction = direction
		_update_sprite_direction(direction)
	velocity = direction * speed
	move_and_slide()
	
	if Input.is_action_just_pressed("interact"):
		try_interact()

func _update_sprite_direction(dir: Vector2) -> void:
	if not sprite:
		return
	if abs(dir.x) > abs(dir.y):
		if dir.x < 0 and texture_left:
			sprite.texture = texture_left
		elif dir.x > 0 and texture_right:
			sprite.texture = texture_right
	else:
		if dir.y < 0 and texture_up:
			sprite.texture = texture_up
		elif dir.y > 0 and texture_down:
			sprite.texture = texture_down

## Locks player movement and interaction, resetting velocity to zero.
func lock_movement() -> void:
	is_movement_locked = true
	velocity = Vector2.ZERO

## Restores player movement and interaction.
func unlock_movement() -> void:
	is_movement_locked = false

## Configures camera limits to match the active map/world bounds.
func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	if camera:
		camera.limit_left = left
		camera.limit_top = top
		camera.limit_right = right
		camera.limit_bottom = bottom

## Attempts to interact with the closest valid interactable in range.
## Returns true if an interaction occurred, false otherwise.
func try_interact() -> bool:
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
