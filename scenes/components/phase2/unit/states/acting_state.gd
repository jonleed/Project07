extends NPC_State
class_name Acting_State

func _ready() -> void:
	state_name = "Acting_State"

func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	if cached_unit.attack_behaviour == Hostile_Unit.who_to_attack.LAST_TO_DAMAGE:
		target_unit = choose_last_enemy_to_damage_me()
	else:
		target_unit = enemy_iterator(cached_unit.attack_behaviour)
	
	if target_unit != null:
		return [State_Machine.states.RUSHING_STATE, plan_pos, target_unit]
	else:
		return [State_Machine.states.DONE_STATE, plan_pos, null]

func select_attack_action() -> Attackaction:
	var unit_atk_actions = cached_unit.get_attack_actions()
	return unit_atk_actions[0]


func choose_last_enemy_to_damage_me() -> Entity:
	if cached_unit.last_unit_to_damage_me != null:
		return cached_unit.last_unit_to_damage_me
	else:
		return enemy_iterator(Hostile_Unit.who_to_attack.CLOSEST)
	
func enemy_iterator(attack_behaviour:int) -> Entity:
	var minimal_unit:Entity = null
	var minimal_value:float = INF
	for enemy_faction_name in cached_unit.get_enemy_unit_factions():
		# Skip our own faction, just in case it somehow ended up in enemy factions
		if enemy_faction_name == cached_unit.cached_parent.faction_name:
			continue

		# Fetch all units belonging to this enemy faction	
		var unit_array:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
		for enemy_unit in unit_array:
			var enemy_unit_value:float = enemy_unit.health
			if attack_behaviour == Hostile_Unit.who_to_attack.CLOSEST:
				enemy_unit_value = enemy_unit.cur_pos.distamce_to(cached_unit.cur_pos)
			if enemy_unit_value < minimal_value:
				minimal_unit = enemy_unit
				minimal_value = enemy_unit_value
	return minimal_unit
