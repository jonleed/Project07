extends Unit
class_name Hostile_Unit

enum when_to_retreat {
	WHEN_THREATENED, # Ie, an enemy unit is within X distance
	MID_HEALTH, # Retreat at a higher health threshold
	LOW_HEALTH, # Retreat at the 'standard' health threshold
	NEVER # Never Retreat
}

enum where_to_retreat_to {
	TO_CLOSEST_FRIEND,
	TO_FURTHEST_POINT_FROM_CLOSEST_ENEMY
}

enum who_to_attack {
	LAST_TO_DAMAGE, # Target the unit to last attack you; Otherwise, go for the closest
	LOWEST_HEALTH, # Go for the unit with the least health
	CLOSEST
}

enum who_to_heal {
	LAST_TO_TAKE_DAMAGE,
	LOWEST_HEALTH,
	CLOSEST
}

enum type_of_unit {
	ATTACK,
	SUPPORTER
}


var retreat_location_behaviour:int = where_to_retreat_to.TO_CLOSEST_FRIEND
var retreat_behaviour:int = when_to_retreat.LOW_HEALTH
var attack_behaviour:int = who_to_attack.CLOSEST
var unit_acting_behaviour:int = type_of_unit.ATTACK
var cached_movement_path:PackedVector2Array = []
var last_unit_to_damage_me:Entity = null

func _ready() -> void:
	pass
	
func set_retreat_behaviour(provided_behaviour:int) -> void:
	if provided_behaviour in when_to_retreat:
		retreat_behaviour = provided_behaviour
		
func set_retreat_location(provided_behaviour:int) -> void:
	if provided_behaviour in where_to_retreat_to:
		retreat_location_behaviour = provided_behaviour

func set_attack_behaviour(provided_behaviour:int) -> void:
	if provided_behaviour in who_to_attack:
		attack_behaviour = provided_behaviour
		

func _execute_turn() -> void:
	var created_plan:Plan = $State_Machine.make_plan()
	var plan_data:Dictionary[int, Dictionary] = created_plan.get_plan()
	
	var last_action_succeeded:bool = true
	for index in range(0, created_plan.get_num_planned_actions()):
		var plan_increment_data:Dictionary[String, Variant] = plan_data[index]
		var planned_action:Action = plan_increment_data.get("Action")
		if planned_action is Moveaction:
			var planned_movement_path:PackedVector2Array = plan_increment_data.get("Path")
			cached_parent.move_unit_via_path(self, planned_movement_path, true)
			if cur_pos != Vector2i(planned_movement_path[-1]):
				last_action_succeeded = false
				break
		elif planned_action is Attackaction or planned_action is Healaction:
			var affected_unit:Entity = plan_increment_data.get("Targetted Unit")
			if affected_unit.cur_pos not in planned_action.range_pattern.calculate_affected_tiles_from_center(cur_pos):
				last_action_succeeded = false
				break
			else:
				use_action(planned_action, affected_unit)
	
	# Set all to 0 to ensure the unit is flagged as having completed their turn
	move_count = 0
	action_count = 0
