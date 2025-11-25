extends Unit
class_name PlayerUnit

@onready var target := $Target

func _ready() -> void:
	ready_entity()
	load_unit_res(u_res)
	add_to_group("Unit")
	add_to_group("Player Unit")
