class_name AftermathEndingTestScene
extends Node2D

@onready var player: Player = $Player
@onready var elder_cael: SurvivorInteractable = $Survivors/ElderCael
@onready var villager: SurvivorInteractable = $Survivors/Villager
@onready var final_overlook: FinalOverlook = $FinalOverlook
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var message_ui: AtmosphericMessageUI = $AtmosphericMessageUI
@onready var ending_ui: EndingUI = $EndingUI

# Visual environment references
@onready var flooded_village: ColorRect = $FloodedVillage
@onready var returned_ocean: ColorRect = $ReturnedOcean
@onready var high_ground_plateau: ColorRect = $HighGroundPlateau

# Debug HUD labels
@onready var town_warned_label: Label = $DebugHUD/Panel/VBoxContainer/TownWarnedLabel
@onready var evac_started_label: Label = $DebugHUD/Panel/VBoxContainer/EvacStartedLabel
@onready var high_ground_label: Label = $DebugHUD/Panel/VBoxContainer/HighGroundLabel
@onready var wave_started_label: Label = $DebugHUD/Panel/VBoxContainer/WaveStartedLabel
@onready var wave_arrived_label: Label = $DebugHUD/Panel/VBoxContainer/WaveArrivedLabel
@onready var survived_label: Label = $DebugHUD/Panel/VBoxContainer/SurvivedLabel
@onready var aftermath_label: Label = $DebugHUD/Panel/VBoxContainer/AftermathLabel
@onready var ending_label: Label = $DebugHUD/Panel/VBoxContainer/EndingLabel
@onready var ending_state_label: Label = $DebugHUD/Panel/VBoxContainer/EndingStateLabel
@onready var progress_label: Label = $DebugHUD/Panel/VBoxContainer/ProgressLabel

func _ready() -> void:
	if player:
		# Bounded arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	if StoryStateController.instance:
		StoryStateController.instance.flag_changed.connect(_on_flag_changed)
	
	if final_overlook:
		final_overlook.overlook_attempted.connect(_on_overlook_attempted)
		final_overlook.resolution_started.connect(_on_resolution_started)
		final_overlook.resolution_ended.connect(_on_resolution_ended)
		final_overlook.ending_triggered.connect(_on_ending_triggered)
	
	_update_environment()
	_update_hud()
	
	# If booting directly with survived_wave, check aftermath sequence
	call_deferred("_check_aftermath_start")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			var current: bool = StoryStateController.has_player_survived()
			var new_val: bool = not current
			if new_val:
				# Set upstream story flags to fulfill prerequisites
				StoryStateController.set_story_flag("ocean_retreat_seen", true)
				StoryStateController.set_story_flag("investigation_started", true)
				StoryStateController.set_story_flag("shipwreck_clue_found", true)
				StoryStateController.set_story_flag("major_truth_discovered", true)
				StoryStateController.set_story_flag("town_warned", true)
				StoryStateController.set_story_flag("evacuation_started", true)
				StoryStateController.set_story_flag("evacuation_reached_high_ground", true)
				StoryStateController.set_story_flag("wave_event_started", true)
				StoryStateController.set_story_flag("wave_arrived", true)
			StoryStateController.set_story_flag("survived_wave", new_val)
			_update_environment()
			_update_hud()
			if new_val:
				_check_aftermath_start()
			AtmosphericMessageUI.display("Toggled survived_wave: %s" % str(new_val))
		elif event.physical_keycode == KEY_F:
			print("[AftermathEndingTest] Manual Final Overlook trigger (F pressed). Checking gate...")
			if final_overlook:
				if final_overlook.can_trigger_overlook():
					final_overlook.interact(player)
				else:
					final_overlook.interact(player)
					AtmosphericMessageUI.display("Final Overlook gated: Wave must be survived first! (Press T)")
			_update_hud()
		elif event.physical_keycode == KEY_R:
			StoryStateController.reset_story_state()
			if final_overlook:
				final_overlook.has_completed = false
				final_overlook.is_resolution_active = false
			if ending_ui:
				ending_ui.is_active = false
				ending_ui.can_restart = false
				if ending_ui.background:
					ending_ui.background.visible = false
					ending_ui.background.modulate.a = 0.0
			_update_environment()
			_update_hud()
			AtmosphericMessageUI.display("StoryState and ending sequence reset to baseline.")

func _check_aftermath_start() -> void:
	if not StoryStateController.has_player_survived():
		return
	if StoryStateController.has_story_flag("aftermath_started"):
		return
	
	StoryStateController.set_story_flag("aftermath_started", true)
	AtmosphericMessageUI.display("The water has stopped.")
	if is_inside_tree():
		var tree_ref := get_tree()
		if tree_ref:
			var timer1 := tree_ref.create_timer(1.8)
			timer1.timeout.connect(func():
				AtmosphericMessageUI.display("Only the sound of the sea remains.")
			)
			var timer2 := tree_ref.create_timer(3.6)
			timer2.timeout.connect(func():
				AtmosphericMessageUI.display("The village below is still standing.")
			)

func _on_flag_changed(_flag_name: String, _new_val: bool) -> void:
	_update_environment()
	_update_hud()

func _on_overlook_attempted(was_gated: bool) -> void:
	print("[AftermathEndingTest] Overlook interaction attempted: was_gated=%s" % str(was_gated))
	_update_hud()

func _on_resolution_started() -> void:
	print("[AftermathEndingTest] Final story resolution started.")
	_update_hud()

func _on_resolution_ended() -> void:
	print("[AftermathEndingTest] Final story resolution dialogue ended.")
	_update_hud()

func _on_ending_triggered() -> void:
	print("[AftermathEndingTest] Ending overlay triggered.")
	_update_hud()

func _update_environment() -> void:
	var survived: bool = StoryStateController.has_player_survived()
	if flooded_village:
		flooded_village.visible = survived
	if returned_ocean:
		returned_ocean.visible = survived
	if elder_cael:
		elder_cael.visible = survived
	if villager:
		villager.visible = survived
	if final_overlook:
		final_overlook.visible = survived

func _update_hud() -> void:
	if not town_warned_label:
		return
	
	var warned: bool = StoryStateController.is_village_warned()
	var evac: bool = StoryStateController.has_story_flag("evacuation_started")
	var hg: bool = StoryStateController.is_high_ground_reached()
	var w_started: bool = StoryStateController.is_wave_approaching()
	var w_arrived: bool = StoryStateController.is_wave_hit()
	var survived: bool = StoryStateController.has_player_survived()
	var aftermath: bool = StoryStateController.is_aftermath_active()
	var ended: bool = StoryStateController.is_game_ended()
	var progress: float = StoryStateController.get_story_progress()
	
	var state_desc: String = "BEFORE_SURVIVAL"
	if ended:
		state_desc = "ENDING_COMPLETED"
	elif aftermath:
		state_desc = "AFTERMATH_ACTIVE"
	elif survived:
		state_desc = "SURVIVED_WAVE"
	
	town_warned_label.text = "town_warned: %s" % str(warned).to_upper()
	town_warned_label.modulate = Color(0.4, 1.0, 0.4) if warned else Color(0.8, 0.8, 0.8)
	
	evac_started_label.text = "evacuation_started: %s" % str(evac).to_upper()
	evac_started_label.modulate = Color(0.4, 1.0, 0.4) if evac else Color(0.8, 0.8, 0.8)
	
	high_ground_label.text = "evacuation_reached_high_ground: %s" % str(hg).to_upper()
	high_ground_label.modulate = Color(0.4, 1.0, 0.4) if hg else Color(0.8, 0.8, 0.8)
	
	wave_started_label.text = "wave_event_started: %s" % str(w_started).to_upper()
	wave_started_label.modulate = Color(0.4, 1.0, 0.4) if w_started else Color(0.8, 0.8, 0.8)
	
	wave_arrived_label.text = "wave_arrived: %s" % str(w_arrived).to_upper()
	wave_arrived_label.modulate = Color(0.4, 1.0, 0.4) if w_arrived else Color(0.8, 0.8, 0.8)
	
	survived_label.text = "survived_wave: %s [T to toggle]" % str(survived).to_upper()
	survived_label.modulate = Color(0.3, 1.0, 0.9) if survived else Color(1.0, 0.6, 0.4)
	
	aftermath_label.text = "aftermath_started: %s" % str(aftermath).to_upper()
	aftermath_label.modulate = Color(0.4, 1.0, 0.4) if aftermath else Color(0.8, 0.8, 0.8)
	
	ending_label.text = "ending_completed: %s" % str(ended).to_upper()
	ending_label.modulate = Color(1.0, 0.85, 0.3) if ended else Color(0.8, 0.8, 0.8)
	
	ending_state_label.text = "Ending State: %s (Press F to trigger)" % state_desc
	progress_label.text = "Story Progress: %d%%" % int(progress * 100)
