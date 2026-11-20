class_name SeabedTremorSign
extends EnvironmentalSign

signal tremor_triggered

## Number of tremors triggered.
var tremor_count: int = 0

## Interval between ambient micro-tremors in seconds.
@export var tremor_interval: float = 20.0

var _timer: float = 0.0
var _is_tremoring: bool = false

func _process(delta: float) -> void:
	if not is_active:
		return
	
	_timer += delta
	if _timer >= tremor_interval:
		_timer = 0.0
		trigger_subtle_tremor()

## Triggers an extremely subtle, brief camera micro-tremor.
func trigger_subtle_tremor(player: Player = null) -> void:
	if _is_tremoring:
		return
	
	_is_tremoring = true
	tremor_count += 1
	tremor_triggered.emit()
	print("[Environmental Sign] A faint tremor vibrates through the seabed floor...")
	
	# Record tremor observation in StoryState
	if StoryStateController.instance:
		StoryStateController.instance.set_flag("tremor_sign_seen", true)
	else:
		StoryStateController.set_story_flag("tremor_sign_seen", true)
	
	# Find player/camera if not provided
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Player:
			player = players[0] as Player
	
	if player and player.camera:
		var cam: Camera2D = player.camera
		var tween = create_tween()
		tween.tween_property(cam, "offset", Vector2(0.75, -0.5), 0.08)
		tween.tween_property(cam, "offset", Vector2(-0.5, 0.6), 0.08)
		tween.tween_property(cam, "offset", Vector2.ZERO, 0.08)
		tween.finished.connect(func():
			cam.offset = Vector2.ZERO
			_is_tremoring = false
		)
	else:
		_is_tremoring = false
