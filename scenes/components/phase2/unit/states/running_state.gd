extends NPC_State
class_name Running_State

func _ready() -> void:
	state_name = "Running_State"

func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	var position_to_reach:Vector2i = Vector2i(-1234, -1234)
	match cached_unit.retreat_location_behaviour:
		Hostile_Unit.where_to_retreat_to.TO_CLOSEST_FRIEND:
			position_to_reach = retreat_to_friend(plan_pos)
		Hostile_Unit.where_to_retreat_to.TO_FURTHEST_POINT_FROM_CLOSEST_ENEMY:
			position_to_reach = retreat_to_furthest_point_from_closest_enemy(plan_pos)
	if position_to_reach != Vector2i(-1234, -1234):
		var pathfinder:Pathfinder = cached_parent.get_pathfinder()
		var path_to_take:PackedVector2Array = pathfinder._return_path(plan_pos, position_to_reach)
		cached_parent.get_plan().add_item_to_plan(cached_unit.get_move_actions()[0], path_to_take, null)
		return [State_Machine.states.IDLE_STATE, position_to_reach]
	else:
		return [State_Machine.states.DONE_STATE, plan_pos]
	
func retreat_to_friend(plan_pos:Vector2i) -> Vector2i:
	var closest_unit:Entity = null
	var closest_distance:float = INF
	for faction_name_ref in cached_unit.get_friendly_factions():
		# Iterate through all units in the friendly faction
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):
			# Exclude ourself
			if friendly_unit == self:
				continue
			# Calculate the distance this friendly unit is from the queried coordinate
			var friendly_unit_pos:Vector2i = friendly_unit.cur_pos
			var dist_to_friendly:float = friendly_unit_pos.distance_to(plan_pos)
			if dist_to_friendly < closest_distance:
				closest_unit = friendly_unit
				closest_distance = dist_to_friendly
	if closest_unit == null:
		return retreat_to_furthest_point_from_closest_enemy(plan_pos)
	else:
		var empty_tiles_around_friendly_unit:Array[Vector2i] = Globals.get_bfs_empty_tiles(plan_pos, 2, cached_unit.cached_parent.map_manager) 
		var closest_tile:Vector2i = Vector2i(-1234, -1234)
		closest_distance = INF
		for adjacent_tile in empty_tiles_around_friendly_unit:
			var dist_to_tile:float = plan_pos.distance_to(adjacent_tile)
			if dist_to_tile < closest_distance:
				closest_tile = adjacent_tile
				closest_distance = dist_to_tile
		if closest_tile != Vector2i(-1234, -1234):
			return closest_tile
		else:
			return retreat_to_furthest_point_from_closest_enemy(plan_pos)
	
func get_closest_enemy_coordinate(plan_pos:Vector2i) -> Vector2i:
	var closest_distance = INF
	var vector_to_closest_enemy = Vector2i(-1234, -1234)
	for enemy_faction_name in cached_unit.get_enemy_unit_factions():
		# Skip our own faction, just in case it somehow ended up in enemy factions
		if enemy_faction_name == cached_parent.faction_name:
			continue

		# Fetch all units belonging to this enemy faction	
		var unit_array:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
		for enemy_unit:Entity in unit_array:
			var enemy_unit_pos:Vector2i = enemy_unit.cur_pos
			var dist_to_enemy:float = enemy_unit_pos.distance_to(plan_pos)
			if dist_to_enemy < closest_distance:
				closest_distance = dist_to_enemy
				vector_to_closest_enemy = enemy_unit.cur_pos
	return vector_to_closest_enemy
	
func calculate_heading(plan_pos:Vector2i, provided_coordinate:Vector2i) -> Vector2i:
	return provided_coordinate - plan_pos
	
func convert_to_unit_vector(provided_coordinate:Vector2i) -> Vector2i:
	var vector_length = provided_coordinate.length()
	return provided_coordinate / vector_length
	
func retreat_to_furthest_point_from_closest_enemy(plan_pos:Vector2i) -> Vector2i:
	var closest_enemy_coordinate:Vector2i = get_closest_enemy_coordinate(plan_pos)
	if closest_enemy_coordinate != Vector2i(-1234, -1234):
		var direction_to_enemy:Vector2i = calculate_heading(plan_pos, closest_enemy_coordinate)
		var unit_vector:Vector2i = convert_to_unit_vector(direction_to_enemy)
		return (-unit_vector * cached_unit.move_count) + plan_pos
	return Vector2i(-1234, -1234)
