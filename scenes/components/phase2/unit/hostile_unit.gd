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

enum who_to_support {
	LOWEST_HEALTH,
	CLOSEST
}

enum type_of_unit {
	ATTACKER,
	SUPPORTER
}


var retreat_location_behaviour:int = where_to_retreat_to.TO_CLOSEST_FRIEND
var retreat_behaviour:int = when_to_retreat.LOW_HEALTH
var attack_behaviour:int = who_to_attack.CLOSEST
var support_behaviour:int = who_to_support.CLOSEST
var unit_type_behaviour:int = type_of_unit.ATTACKER
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
		

func execute_turn() -> void:
	cached_parent = get_parent()
	action_failed = false
	movement_failed = false
	cached_attack_action = null
	cached_support_action = null
	enemy_that_we_care_about = null
	friend_that_we_care_about = null
	move_count = move_max
	action_count = action_max
	idle_state()
	
	
var action_failed:bool = false
var movement_failed:bool = false
var enemy_that_we_care_about:Entity = null
var friend_that_we_care_about:Entity = null

func determine_enemy_we_care_about() -> void:
	if attack_behaviour == Hostile_Unit.who_to_attack.LAST_TO_DAMAGE:
		if last_unit_to_damage_me != null:
			enemy_that_we_care_about = last_unit_to_damage_me
		else:
			enemy_that_we_care_about = get_minimal_enemy()
	else:
		enemy_that_we_care_about = get_minimal_enemy()
	

func get_minimal_enemy(check_closest_override:bool=false) -> Entity:
	var minimal_value = INF
	var minimal_unit:Entity = null
	for enemy_faction_name in get_enemy_unit_factions():
		# Skip our own faction, just in case it somehow ended up in enemy factions
		if enemy_faction_name == cached_parent.faction_name:
			continue

		# Fetch all units belonging to this enemy faction	
		var unit_array:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
		for enemy_unit:Entity in unit_array:
			var enemy_unit_pos:Vector2i = enemy_unit.cur_pos
			var dist_to_enemy:float = enemy_unit_pos.distance_to(cur_pos)
			var used_value:float = dist_to_enemy
			if (not check_closest_override and attack_behaviour == Hostile_Unit.who_to_attack.LOWEST_HEALTH):
				used_value = enemy_unit.health
			if used_value < minimal_value:
				minimal_value = used_value
				minimal_unit = enemy_unit
	return minimal_unit

func determine_friend_we_care_about() -> void:
	friend_that_we_care_about = get_minimal_enemy()
	
func get_minimal_friendly(plan_pos:Vector2i, check_closest_override:bool=false) -> Entity:
	var minimal_value = INF
	var minimal_unit:Entity = null
	for friendly_faction_name in get_friendly_factions():
		var unit_array:Array = get_tree().get_nodes_in_group(friendly_faction_name)		
		for friendly_unit:Entity in unit_array:
			if friendly_unit == self:
				continue
			
			var friendly_unit_pos:Vector2i = friendly_unit.cur_pos
			var dist_to_friendly:float = friendly_unit_pos.distance_to(plan_pos)
			var used_value:float = dist_to_friendly
			if (not check_closest_override and support_behaviour == Hostile_Unit.who_to_support.LOWEST_HEALTH):
				used_value = friendly_unit.health
			if used_value < minimal_value:
				minimal_value = used_value
				minimal_unit = friendly_unit
	return minimal_unit
	


func idle_state() -> void:
	while not action_failed and not movement_failed:
		determine_friend_we_care_about()
		determine_enemy_we_care_about()
		moving_state()
		determine_friend_we_care_about()
		determine_enemy_we_care_about()
		acting_state()
	done_state()
	
func done_state() -> void:
	# Make sure these are zero so we get flagged as having ended our turn
	action_count = 0
	move_count = 0
	
func acting_state() -> void:
	if action_count <= 0:
		action_failed = true
		return
		
	if unit_type_behaviour == type_of_unit.ATTACKER:
		attacking_state()
	elif unit_type_behaviour == type_of_unit.SUPPORTER:
		supporting_state()
		
	if action_failed:
		if unit_type_behaviour == type_of_unit.ATTACKER:
			supporting_state()
		elif unit_type_behaviour == type_of_unit.SUPPORTER:
			attacking_state()
	
	return
	
func attacking_state() -> void:
	if cached_attack_action == null:
		action_failed = true
		return
	
	if enemy_that_we_care_about.cur_pos not in cached_attack_action.range_pattern.calculate_affected_tiles_from_center(cur_pos):
		action_failed = true
		return
	
	use_action(cached_attack_action, enemy_that_we_care_about)
	action_failed = false
	return
	
func supporting_state() -> void:
	if cached_support_action == null:
		action_failed = true
		return
		
	if friend_that_we_care_about.cur_pos not in cached_support_action.range_pattern.calculate_affected_tiles_from_center(cur_pos):
		action_failed = true
		return
	
	use_action(cached_support_action, friend_that_we_care_about)
	action_failed = false
	return
	
func moving_state() -> void:
	if move_count <= 0:
		movement_failed = true
		return
	
	if should_we_should_retreat():
		running_state()
	else:
		rushing_state()
		
	return
	
func should_we_should_retreat() -> bool:
	match retreat_behaviour:
		Hostile_Unit.when_to_retreat.NEVER:
			return false
		Hostile_Unit.when_to_retreat.LOW_HEALTH:
			if health <= Globals.LOW_HEALTH_THRESHOLD:
				return true
		Hostile_Unit.when_to_retreat.MID_HEALTH:
			if health <= Globals.MID_HEALTH_THRESHOLD:
				return true
		Hostile_Unit.when_to_retreat.WHEN_THREATENED:
			for enemy_faction_name in get_enemy_unit_factions():
				# Skip our own faction, just in case it somehow ended up in enemy factions
				if enemy_faction_name == cached_parent.faction_name:
					continue

				# Fetch all units belonging to this enemy faction	
				var unit_array:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
				for enemy_unit in unit_array:
					if enemy_unit.cur_pos.distance_to(cur_pos) <= Globals.THREATENING_DISTANCE:
						return true
	return false
	
func calculate_heading(unit_coordinate:Vector2i, provided_coordinate:Vector2i) -> Vector2i:
	return provided_coordinate - unit_coordinate
	
func convert_to_unit_vector(provided_coordinate:Vector2i) -> Vector2i:
	var vector_length = provided_coordinate.length()
	return provided_coordinate / vector_length
	
func retreat_to_furthest_point_from_closest_enemy() -> Vector2i:
	var closest_enemy:Entity = null
	if enemy_that_we_care_about != null and attack_behaviour == Hostile_Unit.who_to_attack.CLOSEST:
		closest_enemy = enemy_that_we_care_about
	else:
		closest_enemy = get_minimal_enemy(true)
	
	var closest_enemy_coordinate:Vector2i = closest_enemy.cur_pos
	if closest_enemy_coordinate != Vector2i(-INF, -INF):
		var direction_to_enemy:Vector2i = calculate_heading(cur_pos, closest_enemy_coordinate)
		var unit_vector:Vector2i = convert_to_unit_vector(direction_to_enemy)
		return (-unit_vector * (move_count + 1)) + cur_pos
	return Vector2i(-INF, -INF)
	
func retreat_to_friend() -> Vector2i:
	var closest_unit:Entity = null
	var closest_distance:float = INF
	for faction_name_ref in get_friendly_factions():
		# Iterate through all units in the friendly faction
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):
			# Exclude ourself
			if friendly_unit == self:
				continue
			# Calculate the distance this friendly unit is from the queried coordinate
			var friendly_unit_pos:Vector2i = friendly_unit.cur_pos
			var dist_to_friendly:float = friendly_unit_pos.distance_to(cur_pos)
			if dist_to_friendly < closest_distance:
				closest_unit = friendly_unit
				closest_distance = dist_to_friendly
	if closest_unit == null:
		return retreat_to_furthest_point_from_closest_enemy()
	else:
		var empty_tiles_around_friendly_unit:Array[Vector2i] = Globals.get_bfs_empty_tiles(cur_pos, 2, cached_parent.map_manager) 
		var closest_tile:Vector2i = Vector2i(-INF, -INF)
		closest_distance = INF
		for adjacent_tile in empty_tiles_around_friendly_unit:
			if adjacent_tile not in cached_parent.map_manager.map_dict_v2:
				continue
				
			var dist_to_tile:float = cur_pos.distance_to(adjacent_tile)
			if dist_to_tile < closest_distance:
				closest_tile = adjacent_tile
				closest_distance = dist_to_tile
		if closest_tile != Vector2i(-INF, -INF):
			return closest_tile
		else:
			return retreat_to_furthest_point_from_closest_enemy()
	
func running_state() -> void:
	var retreat_coordinate:Vector2i = Vector2i(-INF, -INF)
	if retreat_location_behaviour == Hostile_Unit.where_to_retreat_to.TO_FURTHEST_POINT_FROM_CLOSEST_ENEMY:
		retreat_coordinate = retreat_to_furthest_point_from_closest_enemy()
	else:
		retreat_coordinate = retreat_to_friend()
	
	if retreat_coordinate == Vector2i(-INF, -INF):
		movement_failed = true
		return
	
	var pathfinder:Pathfinder = cached_parent.get_pathfinder()
	var path_to_take:PackedVector2Array = pathfinder._return_path(cur_pos, retreat_coordinate)
	if path_to_take[0] == Vector2(-INF, -INF):
		movement_failed = true
	else:
		cached_parent.move_unit_via_path(self, path_to_take)
	return
	
	
func get_tiles_that_can_act_on_given_tile(target_unit:Entity, provided_action:Action) -> Array[Vector2i]:
	var used_pattern:Pattern2D = provided_action.range_pattern
	var possible_coordinates:Array[Vector2i] = []

	# First, simulate being at a location wherein provided_coordinate falls within the pattern's grid 
	
	for coordinate_y in range(-used_pattern.grid_size.y, used_pattern.grid_size.y + 1):
		for coordinate_x in range(-used_pattern.grid_size.x, used_pattern.grid_size.x + 1):
			# Converts the pattern offsets in the pattern to an actual map coordinate
			var offset_mapped_to_coordinate = target_unit.cur_pos + Vector2i(coordinate_x, coordinate_y)

			# Secondly, see if the provided_coordinate is within the list of tiles affected from that location
			var coordinates_affected_by_pattern = used_pattern.calculate_affected_tiles_from_center(offset_mapped_to_coordinate)
			if target_unit.cur_pos in coordinates_affected_by_pattern:
				# Thirdly, compile all pattern offsets wherein we can hit provided_coordinate with the pattern
				possible_coordinates.append(offset_mapped_to_coordinate)
	return possible_coordinates


var cached_attack_action:Attackaction = null
var cached_support_action:Healaction = null
func get_point_to_act_from(is_attacking_target:bool, target_unit:Entity) -> Array:
	var closest_point:Vector2i = Vector2i(-INF, -INF)
	var closest_action:Action = null
	var closest_distance:float = INF
	var potential_actions:Array = get_attack_actions()
	if not is_attacking_target:
		potential_actions = get_restorative_actions()
	
	for action in potential_actions:
		var points_that_can_hit_target:Array[Vector2i] = get_tiles_that_can_act_on_given_tile(target_unit, action)
		for point in points_that_can_hit_target:
			if point not in cached_parent.map_manager.map_dict_v2:
				continue
			
			
			var distance_to_point:float = point.distance_to(cur_pos)
			if distance_to_point < closest_distance :
				closest_point = point
				closest_action = action
				closest_distance = distance_to_point
	return [closest_point, closest_action]
	
func rushing_state() -> void:
	var acting_point = Vector2i(-INF, -INF)
	cached_attack_action = null
	cached_support_action = null
	if unit_type_behaviour == type_of_unit.ATTACKER:
		if enemy_that_we_care_about != null:
			var returned_data:Array = get_point_to_act_from(true, enemy_that_we_care_about)
			acting_point = returned_data[0]
			cached_attack_action = returned_data[1]
		elif friend_that_we_care_about != null:
			var returned_data:Array = get_point_to_act_from(false, friend_that_we_care_about)
			acting_point = returned_data[0]
			cached_support_action = returned_data[1]
	elif unit_type_behaviour == type_of_unit.SUPPORTER:
		if friend_that_we_care_about != null:
			var returned_data:Array = get_point_to_act_from(false, friend_that_we_care_about)
			acting_point = returned_data[0]
			cached_support_action = returned_data[1]
		elif enemy_that_we_care_about != null:
			var returned_data:Array = get_point_to_act_from(true, enemy_that_we_care_about)
			acting_point = returned_data[0]
			cached_attack_action = returned_data[1]
	
	if acting_point == Vector2i(-INF, -INF) or (cached_attack_action == null and cached_support_action == null):
		movement_failed = true
	else:
		var pathfinder:Pathfinder = cached_parent.get_pathfinder()
		var path_to_take:PackedVector2Array = pathfinder._return_path(cur_pos, acting_point)
		if path_to_take[0] == Vector2(-INF, -INF):
			movement_failed = true
		else:
			cached_parent.move_unit_via_path(self, path_to_take)
	return
