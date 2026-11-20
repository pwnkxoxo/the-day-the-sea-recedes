class_name OceanStateController
extends Node

## Enumeration of possible ocean states.
enum State {
	NORMAL_OCEAN,
	OCEAN_RETREATED,
}

## Emitted whenever the ocean state changes.
signal state_changed(new_state: State)

## Emitted when the ocean retreat begins.
signal retreat_started

## Emitted when the ocean retreat completes.
signal retreat_completed

## Static reference to the active controller instance.
static var instance: OceanStateController = null

## Static persistence variable so state survives scene reloads and tests.
static var _persisted_state: State = State.NORMAL_OCEAN

## Current state property backed by static persistence.
@export var current_state: State = State.NORMAL_OCEAN:
	set(value):
		set_state(value)
	get:
		return _persisted_state

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	# Temporary development / debug trigger using key 'T'
	if event.is_action_pressed("debug_retreat") or (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_T or event.keycode == KEY_T)):
		if is_normal():
			trigger_retreat()

## Returns true if the ocean is in its normal high-water state.
func is_normal() -> bool:
	return _persisted_state == State.NORMAL_OCEAN

## Returns true if the ocean has retreated, exposing the seabed.
func is_retreated() -> bool:
	return _persisted_state == State.OCEAN_RETREATED

## Returns current ocean state.
func get_state() -> State:
	return _persisted_state

## Triggers the ocean retreat transition.
func trigger_retreat() -> void:
	if _persisted_state == State.OCEAN_RETREATED:
		return
	retreat_started.emit()
	_persisted_state = State.OCEAN_RETREATED
	state_changed.emit(_persisted_state)
	retreat_completed.emit()

## Sets the ocean state directly (useful for testing or initialization).
func set_state(new_state: State) -> void:
	if _persisted_state == new_state:
		return
	_persisted_state = new_state
	state_changed.emit(_persisted_state)

## Resets ocean state back to NORMAL_OCEAN.
func reset_state() -> void:
	set_state(State.NORMAL_OCEAN)

# --- Static helper methods for convenient querying & control ---

static func is_ocean_normal() -> bool:
	return _persisted_state == State.NORMAL_OCEAN

static func is_ocean_retreated() -> bool:
	return _persisted_state == State.OCEAN_RETREATED

static func get_current_state() -> State:
	return _persisted_state

static func trigger_ocean_retreat() -> void:
	if instance:
		instance.trigger_retreat()
	else:
		_persisted_state = State.OCEAN_RETREATED

static func set_ocean_state(new_state: State) -> void:
	if instance:
		instance.set_state(new_state)
	else:
		_persisted_state = new_state

static func reset_ocean_state() -> void:
	set_ocean_state(State.NORMAL_OCEAN)
