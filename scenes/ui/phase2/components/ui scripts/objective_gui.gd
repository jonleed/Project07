extends Control

@onready var round_initalizer: RoundInitializer = get_parent().round_initalizer
@onready var content_label: Label = $PanelContainer/VBoxContainer/Label2

func _ready():
	round_initalizer.objective_update.connect(update_objective_count)
	update_objective_count(round_initalizer.kill_count, round_initalizer.kills_to_win)
	

func update_objective_count(count: int, total: int):
	content_label.text = "Defeat " + str(count) +"/" + str(total) + " Enemies"
