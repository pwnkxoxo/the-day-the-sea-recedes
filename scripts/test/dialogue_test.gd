class_name DialogueTestScene
extends Node2D

## Sequential test dialogue data
const TEST_DIALOGUE: Array[Dictionary] = [
	{"speaker": "Test Character", "text": "This is the first dialogue line."},
	{"speaker": "Test Character", "text": "This is the second dialogue line."},
	{"speaker": "Test Character", "text": "Dialogue system working."}
]

@onready var player: Player = $Player
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var test_npc: Interactable = $TestNPC

var dialogue_trigger_count: int = 0

func _ready() -> void:
	if player:
		# Bounded test arena: 480x270
		player.set_camera_limits(0, 0, 480, 270)
	
	if test_npc:
		test_npc.interacted.connect(_on_npc_interacted)

func _on_npc_interacted(interactor: Player) -> void:
	dialogue_trigger_count += 1
	print("[DialogueTest] Test NPC interacted (Trigger #%d)" % dialogue_trigger_count)
	if dialogue_ui:
		dialogue_ui.start_dialogue(TEST_DIALOGUE, interactor)
	else:
		DialogueUI.start(TEST_DIALOGUE, interactor)
