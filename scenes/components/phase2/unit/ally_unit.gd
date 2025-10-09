extends Unit
class_name PlayerUnit

func _ready() -> void:
	ready_entity()
	add_to_group("Unit")
	add_to_group("Player Unit")
