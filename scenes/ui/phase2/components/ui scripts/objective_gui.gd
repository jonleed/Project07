extends Control

@onready var round_initalizer: RoundInitializer = get_parent().round_initalizer
@onready var content_label: Label = $PanelContainer/VBoxContainer/Label2

func _ready():
	round_initalizer.objective_update.connect(update_objective_count)
	var win_con = round_initalizer.win_condition
	match win_con:
		0:
			update_objective_count(round_initalizer.round_count, round_initalizer.turns_to_survive, win_con)
		1:
			update_objective_count(round_initalizer.kill_count, round_initalizer.kills_to_win, win_con)
		2:
			update_objective_count(0, 1, win_con)
	

func update_objective_count(count: int, total: int, win_condition:int):
	match win_condition:
		0: # Survive
			content_label.text = "Survive " + str(count) +"/" + str(total) + " Rounds"
		1: # Elimination
			content_label.text = "Defeat " + str(count) +"/" + str(total) + " Enemies"
		2: # Escape
			content_label.text = "Escape (Step on a red-brick)"
	
