class_name StoryStateController
extends Node

## Emitted whenever any story flag changes.
signal flag_changed(flag_name: String, new_value: bool)

## Emitted when the investigation phase begins (threshold of strange signs reached).
signal investigation_started

## Emitted when the major truth about the receding ocean is discovered.
signal truth_discovered

## Emitted when the town warning sequence is completed and town is alerted.
signal town_warned

## Emitted when the evacuation sequence begins.
signal evacuation_started

## Emitted when player reaches the designated high ground cliff safety area.
signal high_ground_reached

## Emitted when the approaching wave event begins.
signal wave_event_started

## Emitted when the catastrophic wave reaches the village/seabed area.
signal wave_arrived

## Emitted when the player has survived the wave safely on high ground.
signal wave_survived

## Emitted when the post-wave aftermath sequence begins.
signal aftermath_started

## Emitted when the final story ending sequence has completed.
signal ending_completed

## Emitted when the opening story sequence has completed.
signal opening_sequence_completed

## Emitted when the sea change (ocean retreat) event is triggered.
signal sea_change_triggered

## Threshold of environmental signs required to trigger the investigation phase.
## Out of 5 signs (Shell, Tide Pools, Birds, Tremor, Wind), observing 3 represents
## the narrative turning point from curiosity/unease into active investigation.
const INVESTIGATION_THRESHOLD: int = 3

## The set of environmental signs contributing to the investigation threshold.
const ENVIRONMENTAL_SIGNS: Array[String] = [
	"shell_sign_seen",
	"tide_pool_sign_seen",
	"birds_sign_seen",
	"tremor_sign_seen",
	"wind_sign_seen",
]

## Baseline default state for all known story flags.
const DEFAULT_FLAGS: Dictionary = {
	"opening_sequence_completed": false,
	"sea_change_triggered": false,
	"ocean_retreat_seen": false,
	"shell_sign_seen": false,
	"tide_pool_sign_seen": false,
	"birds_sign_seen": false,
	"tremor_sign_seen": false,
	"wind_sign_seen": false,
	"investigation_started": false,
	"shipwreck_clue_found": false,
	"major_truth_discovered": false,
	"town_warned": false,
	"evacuation_started": false,
	"evacuation_reached_high_ground": false,
	"wave_event_started": false,
	"wave_arrived": false,
	"survived_wave": false,
	"aftermath_started": false,
	"ending_completed": false,
}

## Static reference to the active controller instance.
static var instance: StoryStateController = null

## Static dictionary persisting story flags across scene transitions and test runs.
static var _persisted_flags: Dictionary = {
	"opening_sequence_completed": false,
	"sea_change_triggered": false,
	"ocean_retreat_seen": false,
	"shell_sign_seen": false,
	"tide_pool_sign_seen": false,
	"birds_sign_seen": false,
	"tremor_sign_seen": false,
	"wind_sign_seen": false,
	"investigation_started": false,
	"shipwreck_clue_found": false,
	"major_truth_discovered": false,
	"town_warned": false,
	"evacuation_started": false,
	"evacuation_reached_high_ground": false,
	"wave_event_started": false,
	"wave_arrived": false,
	"survived_wave": false,
	"aftermath_started": false,
	"ending_completed": false,
}

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect to OceanState to track retreat observation if OceanState exists
	if OceanStateController.instance:
		OceanStateController.instance.retreat_completed.connect(_on_ocean_retreat_completed)
	
	if OceanStateController.is_ocean_retreated():
		set_flag("ocean_retreat_seen", true)

func _on_ocean_retreat_completed() -> void:
	set_flag("ocean_retreat_seen", true)

## Returns true if the specified flag is currently true.
func has_flag(flag_name: String) -> bool:
	return _persisted_flags.get(flag_name, false)

## Sets a story flag to the given value (default true). Idempotent.
func set_flag(flag_name: String, value: bool = true) -> void:
	var current_val: bool = _persisted_flags.get(flag_name, false)
	if current_val == value:
		return
	
	_persisted_flags[flag_name] = value
	flag_changed.emit(flag_name, value)
	
	# Check for automatic investigation threshold trigger
	if value and flag_name in ENVIRONMENTAL_SIGNS:
		_check_investigation_threshold()
	elif flag_name == "investigation_started" and value:
		investigation_started.emit()
	elif flag_name == "major_truth_discovered" and value:
		truth_discovered.emit()
	elif flag_name == "town_warned" and value:
		town_warned.emit()
	elif flag_name == "evacuation_started" and value:
		evacuation_started.emit()
	elif flag_name == "evacuation_reached_high_ground" and value:
		high_ground_reached.emit()
	elif flag_name == "wave_event_started" and value:
		wave_event_started.emit()
	elif flag_name == "wave_arrived" and value:
		wave_arrived.emit()
	elif flag_name == "survived_wave" and value:
		wave_survived.emit()
	elif flag_name == "aftermath_started" and value:
		aftermath_started.emit()
	elif flag_name == "ending_completed" and value:
		ending_completed.emit()
	elif flag_name == "opening_sequence_completed" and value:
		opening_sequence_completed.emit()
	elif flag_name == "sea_change_triggered" and value:
		sea_change_triggered.emit()

## Clears (sets to false) the specified flag.
func clear_flag(flag_name: String) -> void:
	set_flag(flag_name, false)

## Records an environmental or clue discovery explicitly.
func record_discovery(flag_name: String) -> void:
	set_flag(flag_name, true)

## Evaluates whether enough environmental signs have been seen to trigger investigation.
func _check_investigation_threshold() -> void:
	if has_flag("investigation_started"):
		return
	if get_discovered_sign_count() >= INVESTIGATION_THRESHOLD:
		set_flag("investigation_started", true)

## Returns the number of distinct environmental signs the player has observed.
func get_discovered_sign_count() -> int:
	var count: int = 0
	for sign_name in ENVIRONMENTAL_SIGNS:
		if _persisted_flags.get(sign_name, false):
			count += 1
	return count

## Returns true if the player has begun investigating the strange signs.
func is_investigation_started() -> bool:
	return has_flag("investigation_started")

## Returns true if prerequisites are met to discover the major truth (for Milestone 11).
func can_discover_truth() -> bool:
	return is_investigation_started() and has_flag("shipwreck_clue_found")

## Returns true if the major truth has been uncovered.
func is_truth_discovered() -> bool:
	return has_flag("major_truth_discovered")

## Returns true if prerequisites are met to warn the town (for Milestone 13).
func can_warn_town() -> bool:
	return is_truth_discovered()

## Returns true if the town has been successfully warned.
func is_town_warned() -> bool:
	return has_flag("town_warned")

## Returns true if prerequisites are met to start village evacuation (Milestone 14).
func can_start_evacuation() -> bool:
	return is_town_warned()

## Returns true if village evacuation has begun.
func is_evacuation_started() -> bool:
	return has_flag("evacuation_started")

## Returns true if player has reached the high-ground safety area.
func has_reached_high_ground() -> bool:
	return has_flag("evacuation_reached_high_ground")

## Returns true if prerequisites are met to start the approaching wave event (Milestone 15).
func can_start_wave_event() -> bool:
	return has_reached_high_ground()

## Returns true if the approaching wave event has started.
func is_wave_event_started() -> bool:
	return has_flag("wave_event_started")

## Returns true if the wave has reached the village/seabed area.
func is_wave_arrived() -> bool:
	return has_flag("wave_arrived")

## Returns true if the player has survived the wave event.
func has_survived_wave() -> bool:
	return has_flag("survived_wave")

## Returns true if prerequisites are met to start the aftermath sequence (Milestone 16).
func can_start_aftermath() -> bool:
	return has_survived_wave()

## Returns true if the aftermath sequence has begun.
func is_aftermath_started() -> bool:
	return has_flag("aftermath_started")

## Returns true if prerequisites are met to complete the final story ending.
func can_complete_ending() -> bool:
	return has_survived_wave()

## Returns true if the final story ending sequence has completed.
func is_ending_completed() -> bool:
	return has_flag("ending_completed")

## Returns true if the opening story sequence has completed.
func is_opening_sequence_completed() -> bool:
	return has_flag("opening_sequence_completed")

## Returns true if the sea-change event has been triggered.
func is_sea_change_triggered() -> bool:
	return has_flag("sea_change_triggered")

## Returns normalized story progress between 0.0 and 1.0.
func get_progress() -> float:
	var progress: float = 0.0
	
	if has_flag("ocean_retreat_seen"):
		progress += 0.15
	
	# Environmental signs contribute up to 0.45 (0.15 per sign up to threshold of 3)
	var sign_count: int = mini(get_discovered_sign_count(), INVESTIGATION_THRESHOLD)
	progress += sign_count * 0.15
	
	if has_flag("investigation_started"):
		progress += 0.10
	
	if has_flag("shipwreck_clue_found"):
		progress += 0.15
	
	if has_flag("major_truth_discovered"):
		progress += 0.15
	
	if has_flag("town_warned"):
		progress += 0.15
	
	if has_flag("evacuation_started"):
		progress += 0.05
	
	if has_flag("evacuation_reached_high_ground"):
		progress += 0.05
	
	if has_flag("wave_event_started"):
		progress += 0.05
	
	if has_flag("wave_arrived"):
		progress += 0.05
	
	if has_flag("survived_wave"):
		progress += 0.05
	
	if has_flag("aftermath_started"):
		progress += 0.05
	
	if has_flag("ending_completed"):
		progress += 0.05
	
	return clampf(progress, 0.0, 1.0)

## Resets all story flags back to initial default values.
func reset_state() -> void:
	_persisted_flags = DEFAULT_FLAGS.duplicate()

# --- Static helper methods for convenient querying & control across scenes & tests ---

static func has_story_flag(flag_name: String) -> bool:
	return _persisted_flags.get(flag_name, false)

static func set_story_flag(flag_name: String, value: bool = true) -> void:
	if instance:
		instance.set_flag(flag_name, value)
	else:
		var current_val: bool = _persisted_flags.get(flag_name, false)
		if current_val != value:
			_persisted_flags[flag_name] = value
			if value and flag_name in ENVIRONMENTAL_SIGNS:
				var count: int = 0
				for s in ENVIRONMENTAL_SIGNS:
					if _persisted_flags.get(s, false): count += 1
				if count >= INVESTIGATION_THRESHOLD:
					_persisted_flags["investigation_started"] = true

static func record_story_discovery(flag_name: String) -> void:
	set_story_flag(flag_name, true)

static func get_sign_count() -> int:
	var count: int = 0
	for s in ENVIRONMENTAL_SIGNS:
		if _persisted_flags.get(s, false): count += 1
	return count

static func is_investigating() -> bool:
	return _persisted_flags.get("investigation_started", false)

static func can_reveal_truth() -> bool:
	return is_investigating() and _persisted_flags.get("shipwreck_clue_found", false)

static func is_truth_known() -> bool:
	return _persisted_flags.get("major_truth_discovered", false)

static func can_trigger_town_warning() -> bool:
	return is_truth_known()

static func is_village_warned() -> bool:
	return _persisted_flags.get("town_warned", false)

static func can_begin_evacuation() -> bool:
	return is_village_warned()

static func is_evacuating() -> bool:
	return _persisted_flags.get("evacuation_started", false)

static func is_high_ground_reached() -> bool:
	return _persisted_flags.get("evacuation_reached_high_ground", false)

static func can_trigger_wave_event() -> bool:
	return is_high_ground_reached()

static func is_wave_approaching() -> bool:
	return _persisted_flags.get("wave_event_started", false)

static func is_wave_hit() -> bool:
	return _persisted_flags.get("wave_arrived", false)

static func has_player_survived() -> bool:
	return _persisted_flags.get("survived_wave", false)

static func can_trigger_aftermath() -> bool:
	return has_player_survived()

static func is_aftermath_active() -> bool:
	return _persisted_flags.get("aftermath_started", false)

static func can_trigger_ending() -> bool:
	return has_player_survived()

static func is_game_ended() -> bool:
	return _persisted_flags.get("ending_completed", false)

static func is_opening_completed() -> bool:
	return _persisted_flags.get("opening_sequence_completed", false)

static func set_opening_completed(val: bool = true) -> void:
	set_story_flag("opening_sequence_completed", val)

static func is_sea_change_active() -> bool:
	return _persisted_flags.get("sea_change_triggered", false)

static func set_sea_change_triggered(val: bool = true) -> void:
	set_story_flag("sea_change_triggered", val)

static func get_story_progress() -> float:
	if instance:
		return instance.get_progress()
	var p: float = 0.0
	if _persisted_flags.get("ocean_retreat_seen", false): p += 0.15
	var sc: int = mini(get_sign_count(), INVESTIGATION_THRESHOLD)
	p += sc * 0.15
	if _persisted_flags.get("investigation_started", false): p += 0.10
	if _persisted_flags.get("shipwreck_clue_found", false): p += 0.15
	if _persisted_flags.get("major_truth_discovered", false): p += 0.15
	if _persisted_flags.get("town_warned", false): p += 0.15
	if _persisted_flags.get("evacuation_started", false): p += 0.05
	if _persisted_flags.get("evacuation_reached_high_ground", false): p += 0.05
	if _persisted_flags.get("wave_event_started", false): p += 0.05
	if _persisted_flags.get("wave_arrived", false): p += 0.05
	if _persisted_flags.get("survived_wave", false): p += 0.05
	if _persisted_flags.get("aftermath_started", false): p += 0.05
	if _persisted_flags.get("ending_completed", false): p += 0.05
	return clampf(p, 0.0, 1.0)

static func reset_story_state() -> void:
	if instance:
		instance.reset_state()
	else:
		_persisted_flags = DEFAULT_FLAGS.duplicate()
