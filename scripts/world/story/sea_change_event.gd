class_name SeaChangeEvent
extends Node2D

## Emitted when exploration threshold is satisfied and sea change becomes eligible.
signal eligibility_reached

## Emitted when the atmospheric buildup for the sea change starts.
signal buildup_started

## Emitted when the ocean retreat transition is actively triggered.
signal retreat_initiated

## Emitted when the sea change event, buildup, and NPC reactions complete.
signal event_completed

## Emitted whenever the player completes an exploration activity.
signal exploration_progress_changed(current: int, target: int)

## Static singleton reference for global scene access.
static var instance: SeaChangeEvent = null

## Target village node. If null, auto-discovered in parent or tree.
@export var target_village: Village = null

## Number of distinct exploration actions required to trigger the event.
@export var required_exploration_count: int = 2

## If true, automatically monitors NPCs, NoticeBoard, and Shoreline for exploration.
@export var auto_monitor: bool = true

## If true, accelerates buildup and retreat timers (used for unit tests and fast execution).
@export var fast_mode: bool = false

## Current count of completed exploration actions.
var exploration_count: int = 0

## List of unique exploration action keys recorded.
var _completed_actions: Dictionary = {}

## State flags
var is_eligible: bool = false
var is_buildup_active: bool = false
var is_event_completed: bool = false

var _shoreline_area: Area2D = null
var _buildup_timer: SceneTreeTimer = null

func _enter_tree() -> void:
	if instance == null:
		instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	_find_dependencies()
	_setup_shoreline_trigger()
	
	if auto_monitor:
		call_deferred("_connect_exploration_listeners")
	
	# If ocean is already retreated or event already occurred, finalize state
	if OceanStateController.is_ocean_retreated() or StoryStateController.has_story_flag("sea_change_triggered"):
		is_event_completed = true

func _find_dependencies() -> void:
	if not target_village and is_inside_tree():
		if get_parent() is Village:
			target_village = get_parent() as Village
		elif get_parent():
			target_village = get_parent().get_node_or_null("Village") as Village
		if not target_village:
			var v_nodes := get_tree().get_nodes_in_group("village")
			if not v_nodes.is_empty():
				target_village = v_nodes[0] as Village

## Prepares an Area2D trigger along the southern shore cliff overlook.
func _setup_shoreline_trigger() -> void:
	_shoreline_area = get_node_or_null("ShorelineTrigger") as Area2D
	if not _shoreline_area:
		_shoreline_area = Area2D.new()
		_shoreline_area.name = "ShorelineTrigger"
		_shoreline_area.collision_layer = 0
		_shoreline_area.collision_mask = 1 # Detect Player (layer 1)
		_shoreline_area.position = Vector2(480, 360)
		
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 45.0
		col.shape = shape
		_shoreline_area.add_child(col)
		add_child(_shoreline_area)
	
	if not _shoreline_area.body_entered.is_connected(_on_shoreline_body_entered):
		_shoreline_area.body_entered.connect(_on_shoreline_body_entered)

## Wires up exploration listeners across town NPCs and notice board.
func _connect_exploration_listeners() -> void:
	if not target_village:
		_find_dependencies()
	if not target_village:
		return
	
	# 1. Connect to village NPCs
	for npc in target_village.get_npcs():
		if npc and not npc.interacted.is_connected(_on_npc_interacted):
			npc.interacted.connect(func(player: Player):
				_on_npc_interacted(npc, player)
			)
	
	# 2. Connect to NoticeBoard
	var notice_board: NoticeBoard = target_village.get_node_or_null("Interactables/NoticeBoard") as NoticeBoard
	if notice_board and not notice_board.interacted.is_connected(_on_notice_board_interacted):
		notice_board.interacted.connect(_on_notice_board_interacted)

func _on_npc_interacted(npc: NPCBase, _player: Player) -> void:
	var key: String = "npc_" + (npc.name if npc else "unknown")
	register_exploration_action(key)

func _on_notice_board_interacted(_player: Player) -> void:
	register_exploration_action("notice_board")

func _on_shoreline_body_entered(body: Node2D) -> void:
	if body is Player:
		register_exploration_action("shoreline_overlook")

## Registers a distinct exploration action and evaluates eligibility for sea change.
func register_exploration_action(action_id: String) -> void:
	if is_event_completed or is_buildup_active or OceanStateController.is_ocean_retreated():
		return
	
	if not _completed_actions.has(action_id):
		_completed_actions[action_id] = true
		exploration_count += 1
		print("[SeaChangeEvent] Exploration registered: %s (Total: %d/%d)" % [action_id, exploration_count, required_exploration_count])
		exploration_progress_changed.emit(exploration_count, required_exploration_count)
	
	_evaluate_eligibility(action_id)

## Checks whether conditions are met to trigger the sea change naturally.
func _evaluate_eligibility(last_action: String = "") -> void:
	if is_eligible or is_buildup_active or OceanStateController.is_ocean_retreated():
		return
	
	# Must not trigger before opening sequence completes
	var opening_done: bool = StoryStateController.has_story_flag("opening_sequence_completed")
	if not opening_done:
		return
	
	# Criteria:
	# A) Completed required distinct exploration actions (default 2), OR
	# B) Completed at least 1 action and visited the shoreline overlook
	var count_satisfied: bool = (exploration_count >= required_exploration_count)
	var shore_after_exploration: bool = (exploration_count >= 1 and last_action == "shoreline_overlook")
	
	if count_satisfied or shore_after_exploration:
		is_eligible = true
		eligibility_reached.emit()
		print("[SeaChangeEvent] Sea-change eligibility reached! Starting atmospheric buildup.")
		start_sea_change()

## Begins the atmospheric buildup and initiates ocean retreat.
func start_sea_change() -> void:
	if is_buildup_active or is_event_completed:
		return
	if StoryStateController.has_story_flag("sea_change_triggered") or OceanStateController.is_ocean_retreated():
		return
	
	is_buildup_active = true
	StoryStateController.set_story_flag("sea_change_triggered", true)
	buildup_started.emit()
	
	# 1. Atmospheric audio & narration
	AtmosphericMessageUI.display("The sound of the surf suddenly alters. A deep, hollow vibration echoes across the shore.")
	if target_village and target_village._ambient_player:
		target_village._ambient_player.pitch_scale = 0.85
	
	# 2. NPC reaction: NPCs pause and face south toward the sea
	_trigger_npc_reactions()
	
	# 3. Buildup delay before water recedes
	var delay: float = 0.05 if fast_mode else 1.8
	if is_inside_tree():
		_buildup_timer = get_tree().create_timer(delay)
		_buildup_timer.timeout.connect(_on_buildup_completed)
	else:
		_on_buildup_completed()

func _trigger_npc_reactions() -> void:
	if not target_village:
		_find_dependencies()
	if not target_village:
		return
	
	for npc in target_village.get_npcs():
		if npc and is_instance_valid(npc):
			npc.pause_movement()
			npc.face_direction(Vector2.DOWN)
	
	# Short NPC reaction dialogue
	AtmosphericMessageUI.display("Elder Cael: Look at the water... where is the tide going?!")

func _on_buildup_completed() -> void:
	retreat_initiated.emit()
	
	# Activate the existing OceanState retreat transition
	OceanStateController.trigger_ocean_retreat()
	
	# Allow retreat animation to proceed, then restore NPCs and finalize
	var retreat_wait: float = 0.05 if fast_mode else 1.5
	if is_inside_tree():
		var timer := get_tree().create_timer(retreat_wait)
		timer.timeout.connect(_finalize_sea_change)
	else:
		_finalize_sea_change()

func _finalize_sea_change() -> void:
	# NPCs resume their normal routines
	if target_village:
		for npc in target_village.get_npcs():
			if npc and is_instance_valid(npc):
				npc.resume_movement()
	
	AtmosphericMessageUI.display("The ocean has receded into the deep trench. The seabed lies exposed.")
	
	is_buildup_active = false
	is_event_completed = true
	event_completed.emit()
	print("[SeaChangeEvent] Event completed: Seabed is exposed and accessible.")

# --- Public helper methods for deterministic gameplay, testing & debug ---

## Triggers the event organically by simulating required exploration and running buildup.
func trigger_organically() -> void:
	if is_buildup_active or is_event_completed or OceanStateController.is_ocean_retreated():
		return
	StoryStateController.set_story_flag("opening_sequence_completed", true)
	register_exploration_action("test_action_1")
	register_exploration_action("test_action_2")

## Triggers the retreat transition immediately via debug pathway (identical to T key).
func trigger_debug() -> void:
	OceanStateController.trigger_ocean_retreat()

func is_ready_for_retreat() -> bool:
	return is_eligible

func get_exploration_count() -> int:
	return exploration_count

func get_tracked_actions() -> Array:
	return _completed_actions.keys()
