extends Control

# Todo: Combat Log / Entity Viewer; Other two buttons

@onready var player_unit_manager: Unit_Manager = get_parent().get_parent().player_unit_manager
@onready var end_turn_btn = $LogPanelHeader/SplitContainer/HBoxContainer/EndTurnBTN
@onready var undo_btn = $LogPanelHeader/SplitContainer/HBoxContainer/UndoBTN
@onready var reset_btn = $LogPanelHeader/SplitContainer/HBoxContainer/ResetBTN

func _ready():
	end_turn_btn.pressed.connect(_on_end_turn)
	undo_btn.pressed.connect(_on_undo)
	reset_btn.pressed.connect(_on_reset)

func _on_end_turn():
	player_unit_manager.end_selected_unit_turn()

func _on_undo():
	return

func _on_reset():
	return
