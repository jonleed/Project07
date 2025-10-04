extends Unit
class_name Player_Unit

func provide_entity_type()->int:
	return entity_types.PLAYER_UNIT

func set_entity_type()->void:
	entity_type = Entity.entity_types.PLAYER_UNIT

func execute_turn()->void:
	pass
