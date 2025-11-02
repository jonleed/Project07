extends Control

@onready var player_unit_manager: Unit_Manager = get_parent().player_unit_manager
@onready var turn_counter: Label = $TurnCounter
@onready var end_turn_btn: Button = $HBoxContainer/EndTurnBTN
@onready var undo_btn: Button = $HBoxContainer/UndoBTN
@onready var reset_btn: Button = $HBoxContainer/ResetBTN

var current_turn := 1

func _ready():
	player_unit_manager.connect("faction_turn_complete", Callable(self, "_on_turn_complete"))
	end_turn_btn.pressed.connect(_on_end_turn)
	undo_btn.pressed.connect(_on_undo)
	reset_btn.pressed.connect(_on_reset)

func _on_turn_complete():
	current_turn += 1
	_update_counter()

func _update_counter():
	turn_counter.text = str(current_turn)


# Currently: Ends Player Turn
# ToDo: Only end selected Unit's Turn
func _on_end_turn():
	#player_unit_manager.end_selected_unit_turn()
	player_unit_manager.end_turn()

# Call to Stack in Player Manager and Pop top to reverse last move
func _on_undo():
	return

# Call to stack and pop all to reverse entire player turn
func _on_reset():
	return
