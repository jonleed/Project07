extends Control

@onready var player_unit_manager: Unit_Manager = get_parent().player_unit_manager
@onready var movement_label: Label = $HBoxContainer/MovementLabel

func _ready():
	visible = false
	player_unit_manager.connect("unit_selected", Callable(self, "update_movement_label"))

func update_movement_label(unit):
	if unit.move_count < 0:
		visible = false
	else: 
		visible = true
		movement_label.text = str(unit.move_count)
