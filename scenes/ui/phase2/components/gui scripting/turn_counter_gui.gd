extends Control

@onready var player_unit_manager: Unit_Manager = get_parent().get_parent().player_unit_manager

var current_turn := 1

func _ready():
	player_unit_manager.connect("faction_turn_complete", Callable(self, "_on_turn_complete"))
	_update_label()

func _on_turn_complete():
	current_turn += 1
	_update_label()

func _update_label():
	$TurnCounterContainer/TurnCounterLabel.text = str(current_turn)
