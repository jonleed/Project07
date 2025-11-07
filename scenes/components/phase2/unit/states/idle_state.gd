extends NPC_State
class_name Idle_State

func _ready() -> void:
	state_name = "Idle_State"

func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	# First check if we should retreat
	if should_we_should_retreat():
		return [State_Machine.states.RUNNING_STATE, plan_pos, target_unit, target_action]
	
	
	return [State_Machine.states.DONE_STATE, plan_pos, target_unit, target_action]
	
	
func should_we_should_retreat() -> bool:
	match cached_unit.retreat_behaviour:
		Hostile_Unit.when_to_retreat.NEVER:
			return false
		Hostile_Unit.when_to_retreat.LOW_HEALTH:
			if cached_unit.health <= Globals.LOW_HEALTH_THRESHOLD:
				return true
		Hostile_Unit.when_to_retreat.MID_HEALTH:
			if cached_unit.health <= Globals.MID_HEALTH_THRESHOLD:
				return true
		Hostile_Unit.when_to_retreat.WHEN_THREATENED:
			for enemy_faction_name in cached_unit.get_enemy_unit_factions():
				# Skip our own faction, just in case it somehow ended up in enemy factions
				if enemy_faction_name == cached_unit.cached_parent.faction_name:
					continue

				# Fetch all units belonging to this enemy faction	
				var unit_array:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
				for enemy_unit in unit_array:
					if enemy_unit.cur_pos.distance_to(cached_unit.cur_pos) <= Globals.THREATENING_DISTANCE:
						return true
	return false
