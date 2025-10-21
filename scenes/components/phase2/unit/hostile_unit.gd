extends Unit
class_name Hostile_Unit

var current_vision:Dictionary[Vector2i, bool]
var sighted_hostiles:Dictionary[Vector2i, Unit]
var remembered_sightings:Dictionary[Vector2i, Flag]
var audio_cues:Dictionary[Vector2i, int]


var vision_range:int = 20
var relative_range:int = 5
var ideal_melee_dpt:float = 0.0
var ideal_ranged_dpt:float = 0.0
var turn_breakout_counter:int = 0

var current_alert_level:int = alert_level.GREEN_ALERT
enum alert_level {
	BLUE_ALERT, # Recover
	GREEN_ALERT, # Situation normal
	YELLOW_ALERT, # Heard something suspiscious
	ORANGE_ALERT, # Recently saw a hostile
	RED_ALERT # Hostile in view
}
var time_since_alert_update:int = 0
	
func get_friendly_factions() -> Array[String]:
	var faction_name_ref:String = get_parent().faction_name
	if faction_name_ref == "Friendly" or faction_name_ref == "Player Unit":
		return ["Friendly", "Player Unit"]
	elif faction_name_ref == "Traps":
		return ["Traps"]
	elif faction_name_ref == "Enemy":
		return ["Enemy"]
	return ["Enemy"]

func get_enemy_unit_factions() -> Array[String]:	
	var faction_name_ref:String = get_parent().faction_name
	if faction_name_ref == "Friendly" or faction_name_ref == "Player Unit":
		return ["Enemy"]
	elif faction_name_ref == "Traps":
		return ["Friendly", "Player Unit", "Enemy"]
	elif faction_name_ref == "Enemy":
		return ["Player Unit", "Friendly"]
	return ["Friendly", "Player Unit"]
	
func calculate_relative_strength_norm() -> float:
	return health * 2.0 + max(ideal_melee_dpt, ideal_ranged_dpt)

func calculate_relative_strength_target(target:Vector2i) -> float:
	var dist_to_coord = cur_pos.distance_to(target)
	var calculated_strength = health * 2.0 
	if move_max >= dist_to_coord:
		calculated_strength += ideal_melee_dpt
	elif dist_to_coord <= relative_range * 2.0:
		calculated_strength += ideal_ranged_dpt
	else:
		calculated_strength += max(ideal_melee_dpt, ideal_ranged_dpt)	
	return calculated_strength
	
func calculate_heading(target:Vector2i) -> Vector2i:
	return (target - cur_pos)	
	
func ideal_attack(target_unit:Unit) -> Attackaction:
	print("ACTIONS: ", action_array)
	var atk_actions:Array[Attackaction] = []
	for action in action_array:
		if action.is_class("Attackaction"):
			atk_actions.append(action)
	if len(atk_actions) < 1:
		return null
	return atk_actions[get_parent().get_random_generator().randi_range(0, len(atk_actions)-1)]
func ideal_recovery() -> Healaction:
	var heal_actions:Array[Healaction] = get_restorative_actions()
	if len(heal_actions) < 1 or health >= base_health:
		return null
	return heal_actions[get_parent().get_random_generator().randi_range(0, len(heal_actions)-1)]
	
	
func execute_turn() -> void:
	print("RUNNING NPC TURN")
	print(get_enemy_unit_factions())
	move_count = move_max
	action_count = action_max	
	examine_surroundings()
	var in_progress:bool = true
	var prior_pos = cur_pos
	turn_breakout_counter = 0
	while in_progress and turn_breakout_counter < 4:
		in_progress = threat_analysis()
		if prior_pos != cur_pos:
			examine_surroundings()			
		alert_lvl_update(true)
	alert_lvl_update(false)
	
##Updates the alert_level of the unit based upon any hostiles it can see, followed by last-known hostiles, then investigating uncertain audio cues, then patrolling, then restorative actions if 'safe'
func alert_lvl_update(dont_increment:bool=false) -> void:
	if len(sighted_hostiles) > 0:
		current_alert_level = alert_level.RED_ALERT
		time_since_alert_update = 0
	elif len(remembered_sightings) > 0:
		current_alert_level = alert_level.ORANGE_ALERT
		time_since_alert_update = 0
	elif len(audio_cues) > 0:
		current_alert_level = alert_level.YELLOW_ALERT
		time_since_alert_update = 0
	elif time_since_alert_update > 3 and health < base_health:
		current_alert_level = alert_level.BLUE_ALERT
		time_since_alert_update = 0
	elif current_alert_level == alert_level.BLUE_ALERT and health >= base_health:
		time_since_alert_update = 0
		current_alert_level = alert_level.GREEN_ALERT
	else:
		if not dont_increment:
			time_since_alert_update += 1
		
##Uses BFS and vision_range from cur_pos to determine what tiles are visible to this unit
func update_visible_tiles() -> void:
	var new_vision:Dictionary[Vector2i, bool] = {}
	var vision_arr:Array = Globals.get_bfs_tiles(cur_pos, vision_range, get_parent().map_manager)
	for coordinate in vision_arr:
		new_vision[coordinate] = true
	current_vision = new_vision
	
##Updates current_vision, sighted_hostiles, and remembered_sightings
func examine_surroundings() -> void:
	update_visible_tiles()
	var new_sighted_hostiles:Dictionary[Vector2i, Unit] = {}
	var cached_entity_ids:Dictionary[Unit, Vector2i] = {}
	for faction_name_ref in get_enemy_unit_factions():
		if faction_name_ref != get_parent().faction_name:
			var unit_arr:Array = get_tree().get_nodes_in_group(faction_name_ref)		
			if len(unit_arr) > 0:
				for other_unit in unit_arr:
					if other_unit.cur_pos in current_vision:
						new_sighted_hostiles[other_unit.cur_pos] = other_unit
						cached_entity_ids[other_unit] = other_unit.cur_pos
	print(new_sighted_hostiles)

	for coordinate in sighted_hostiles:
		var entry_unit:Unit = sighted_hostiles.get(coordinate)
		if entry_unit not in cached_entity_ids: # Which means not in current_vision as well
			remembered_sightings[coordinate] = Flag.new(entry_unit, -1) # Set counter to one here as they'll be incremented in the next loop
	sighted_hostiles = new_sighted_hostiles
	
	var deletion_coords:Array[Vector2i] = []
	var added_Flags:Array[Flag] = []	
	for coordinate in remembered_sightings:
		var flag_obj:Flag = remembered_sightings.get(coordinate)
		var tracking_unit:Unit = flag_obj.get_tracking_unit()
		if tracking_unit == null or tracking_unit in cached_entity_ids:
			# Either the unit no longer exists, or we can see it, meaning we don't need a flag
			deletion_coords.append(coordinate)
			flag_obj.destroy_flag()
		elif coordinate in current_vision:
			# We can see the tile the unit was last seen on, and don't see it.
			var flag_mode:bool = flag_obj.get_mode()
			if not flag_mode:	
				# This is the first-time we've seen the tile it was meant to be on, and it wasn't there; Plant a flag nearby
				added_Flags.append(Flag.new(tracking_unit, flag_obj.get_counter(), true, coordinate + calculate_heading(coordinate)))
			# Delete all references to the original flag
			deletion_coords.append(coordinate)
			flag_obj.destroy_flag()
		else:
			var ret_deletion_flag:bool = flag_obj.increment_counter()
			# Remove the flag if the flag_obj tells us to (via increment_counter which returns true if the counter exceeds 3 turns)
			if ret_deletion_flag:
				deletion_coords.append(coordinate)
				flag_obj.destroy_flag()					
	for coordinate in deletion_coords:
		remembered_sightings.erase(coordinate)
	for flag_obj in added_Flags:
		remembered_sightings[flag_obj.get_last_known_pos()] = flag_obj

##Determines via randomized weights which last-known-enemy the unit should investigate
func select_memory_location() -> Vector2i:
	var weighted_coord = []
	var weights = []
	for coordinate in remembered_sightings:
		var flag_obj:Flag = remembered_sightings.get(coordinate)
		# High Friendly Support is a 'PRO' for investigating an area
		# High (known) Hostile Threat, distance, time since that region was in sight, and general uncertainty are 'CONs'
		weights.append(get_friendly_support_at_location(coordinate) + (flag_obj.get_counter() * 3.0 +  min(coordinate.distance_to(cur_pos), 30.0) + get_hostile_threat_at_location(coordinate, true)) * -1.0)
		weighted_coord.append(coordinate)
	var index = get_parent().get_parent().get_random_generator().rand_weighted(weights)
	var selected_coordinate = weighted_coord[index]
	return selected_coordinate
	
func select_investigation_location() -> Vector2i:
	# Not implemented yet
	for coordinate in audio_cues:
		pass
	return Vector2i(-1234, -1234)
		
func select_patrol_point() -> Vector2i:
	# Not implemented yet
	
	return Vector2i(-1234, -1234)
		
# We cap the friendly_support and hostile_threat addition at -10.0 as leaving it uncapped means we effectively split the map between the two locations with the greatest (localised) concentration of friendly vs hostile units on the entire map (as in you're 'support' could be heavily penalized by a units all the way on the other side of the map, even if you really should be 'safe' in a particular area
# (We'll use this for determining rally points (running from the greatest known cluster of enemies))
##Calculates the percieved strength of allied units nearby based off of the health and distance of nearby ally units to the designated tile
func get_friendly_support_at_location(target:Vector2i, influence_cap:float=-10) -> float:
	var friendly_support:float = 0.0
	for faction_name_ref in get_friendly_factions():
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):
			if friendly_unit == self:
				continue
			var friendly_unit_pos:Vector2i = friendly_unit.cur_pos
			var dist_to_friendly:float = friendly_unit_pos.distance_to(target)
			var calculated_strength:float = friendly_unit.calculate_relative_strength_target(target)
			friendly_support += max(calculated_strength - pow(dist_to_friendly, 1.1), influence_cap)
	return friendly_support

##Calculates the percieved threat of a tile based off of the health and distance of nearby enemy units to the designated tile
func get_hostile_threat_at_location(target:Vector2i, uncertain:bool=false, influence_cap:float=-10) -> float:
	var hostile_threat:float = 0.0
	for hostile_coordinate:Vector2i in sighted_hostiles:
		var hostile_unit:Unit = sighted_hostiles.get(hostile_coordinate)
		var dist_to_hostile:float = hostile_coordinate.distance_to(target)
		var calculated_strength:float = hostile_unit.calculate_relative_strength_target(target)
		hostile_threat += max(calculated_strength - pow(dist_to_hostile, 1.1), influence_cap)
	if uncertain:
		hostile_threat += base_health * 2.0 # Assume peer-level threat on tile
	return hostile_threat
	

##Returns [valid:bool, path_cost:int, point_path:Array[ int ]]
func coordinate_validated(coordinate:Vector2i) -> Array:
	var pathfinder:Pathfinder = get_parent().get_pathfinder()
	var returned_path:PackedVector2Array = pathfinder._return_path(cur_pos, coordinate)
	if len(returned_path) == 0:
		# We got either got just cur_pos or an empty path- not sure what the 'failure' state for get_point_path() is.
		return [true, 0, []]
	else:
		var parsed:Vector2i = returned_path[-1]
		# We don't know what the point returned is
		if parsed == Vector2i(-1234, -1234):
			return [false, INF]
		# We couldn't get to the tile in question (we came short)
		elif parsed != coordinate:
			var path_cost = pathfinder.calculate_path_cost(returned_path)
			if parsed.distance_to(coordinate) <= relative_range:
				return [false, path_cost, returned_path]
			else:
				return [false, INF, returned_path]
		else:
			var path_cost = pathfinder.calculate_path_cost(returned_path)
			return [true, path_cost, returned_path]
	
##Calculates the 'optimal' rally-point (Vector2i) for a NPC unit to fall back to (greatest localised concentration of friendly units)
##; Returns [ designated_point:Vector2i, point_path:Array[ int ] ]
func find_rally_point() -> Array:
	var weighted_coords:Dictionary[Vector2i, Array] = {}
	var weights = []
	for faction_name_ref in get_friendly_factions():
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):
			if friendly_unit == self:
				continue
			var adjacent_tiles = Globals.get_bfs_empty_tiles(friendly_unit.cur_pos, 2, get_parent().map_manager)
			for tile in adjacent_tiles:
				if tile not in weighted_coords:
					var validation_distance = coordinate_validated(tile)
					if validation_distance[0]: # We want to get directly there
						var my_dist = validation_distance[1]
						var weight = get_friendly_support_at_location(tile, -500) - get_hostile_threat_at_location(tile, true, -500) - min(my_dist, 30.0)
						weighted_coords[tile] = [weight, validation_distance[2]] # Save the path taken
						weights.append(weight)
	if len(weights) < 1:
		return [Vector2i(-1234, -1234), PackedVector2Array([Vector2i(-1234, -1234)])]
	var index = get_parent().get_parent().get_random_generator().rand_weighted(weights)
	var weight_keys = weighted_coords.keys()
	var weight_values = weighted_coords.values()
	return [weight_keys[index], weight_values[index][1]] 


##Functions similarly to rally point, but only tiles within movement distance of the current unit are viable candidates instead of units adjacent to allies
func find_retreat_point() -> Array:
	var max_score:float = -INF
	var max_coord:Vector2i = Vector2i(-1234, -1234)
	var max_path:PackedVector2Array = []
	var possible_move_tiles = Globals.get_bfs_empty_tiles(cur_pos, move_count, get_parent().map_manager)
	for coordinate in possible_move_tiles:
		var validation_distance = coordinate_validated(coordinate)
		if validation_distance[0]: # Check if the tile is reachable
			var f_support = get_friendly_support_at_location(coordinate) + calculate_relative_strength_target(coordinate)
			var e_support = get_hostile_threat_at_location(coordinate, false)
			var disparity = f_support - e_support
			if disparity > max_score:
				max_score = disparity
				max_coord = coordinate
				max_path = validation_distance[2]
	return [max_coord, max_path]

##Returns [max_coord:Vector2i, max_strength:float, max_ratio:float, max_path:Array[ int ], only_ranged:bool, path_cost:float]
func find_exposed_hostile() -> Array:
	var max_strength:float = -INF
	var max_ratio:float = 1.0
	var max_coord:Vector2i = Vector2i(-1234, -1234)
	var max_path:PackedVector2Array = []
	var path_cost:float = 0.0
	var only_ranged:bool = false
	for coordinate in sighted_hostiles:
		var adj_tiles = Globals.get_bfs_empty_tiles(coordinate, 1, get_parent().map_manager)
		var num_empty_adj = len(adj_tiles)
		if num_empty_adj <= 0 and relative_range <= 1:
			# print("No empty tiles adjacent to ", coordinate)
			continue
		var f_support = get_friendly_support_at_location(coordinate) + calculate_relative_strength_target(coordinate)
		var e_support = get_hostile_threat_at_location(coordinate, false)
		var disparity = f_support - e_support
		if disparity > max_strength:
			var validation = coordinate_validated(coordinate)
			if validation[1] != INF:
				max_strength = disparity
				max_coord = coordinate
				max_ratio = f_support / max(e_support, 0.001)
				max_path = validation[2]
				only_ranged = not validation[0]
				path_cost = validation[1]
	return [max_coord, max_strength, max_ratio, max_path, only_ranged, path_cost]
	
##Returns [max_coord:Vector2i, max_strength:float, max_ratio:float, stored_path:Array[ int ]]
func get_best_supported_tile(provided_target:Vector2i, provided_range:int=1) -> Array:
	var max_strength:float = -INF
	var max_coord:Vector2i = Vector2i(-1234, -1234)
	var max_ratio:float = 1.0
	var max_path:PackedVector2Array = []
	var path_cost:float = 0.0
	var adj_tiles = Globals.get_bfs_empty_tiles(provided_target, provided_range, get_parent().map_manager)
	for coordinate in adj_tiles:
		var f_support = get_friendly_support_at_location(coordinate) + calculate_relative_strength_target(coordinate)
		var e_support = get_hostile_threat_at_location(coordinate, false)
		var disparity = f_support - e_support
		if disparity > max_strength:
			var validation = coordinate_validated(coordinate)
			if validation[0]:				
				if validation[1] > move_count: # if we can't move there immediantly, deprioritize
					disparity -= (validation[1]/move_count)
				if disparity > max_strength:
					max_strength = disparity
					max_coord = coordinate
					max_ratio = f_support / max(e_support, 0.001)
					max_path = validation[2]
					path_cost = validation[1]
	print("DEBUG/Support: ", max_coord, max_strength, max_ratio, max_path, path_cost)		
	return [max_coord, max_strength, max_ratio, max_path, path_cost]
		
func threat_analysis() -> bool:
	var course_select:bool = false
	var rerun_allowed:bool = false
	if alert_level.RED_ALERT:
		print("Entering -> Red Alert")
		var threat_diff = (calculate_relative_strength_target(cur_pos) + get_friendly_support_at_location(cur_pos)) / max(get_hostile_threat_at_location(cur_pos, false), 0.001)
		print(threat_diff)
		if threat_diff > 2: # Charge - We can take em- 
			var returned_arr:Array = find_exposed_hostile()
			if returned_arr[0] != Vector2i(-1234, -1234):
				print("Found an exposed hostile!")
				var support_arr = get_best_supported_tile(sighted_hostiles.get(returned_arr[0]).cur_pos)
				if support_arr[0] != Vector2i(-1234, -1234) and support_arr[2] > 0.5:
					get_parent().move_unit_via_path(self, support_arr[3], true)	
					var selected_attack:Attackaction = ideal_attack(sighted_hostiles.get(returned_arr[0]))
					if selected_attack != null and action_count > 0:
						# So the attack is valid, we can target the selected unit
						course_select = true
						action_count -= 1
						selected_attack.executeAttack(self, sighted_hostiles.get(returned_arr[0]))									
			else:
				print("No exposed hostiles!")
		# Cannot do elif chains as we need a fallback if a prior option didn't work
		if (not course_select and move_count > 0 and threat_diff > 0.4):
			print("-> -> Entering Rally")
			var returned_arr:Array = find_rally_point()
			if returned_arr[0] != Vector2i(-1234, -1234):
				course_select = true
				get_parent().move_unit_via_path(self, returned_arr[1], true)
				rerun_allowed = true
		if not course_select and move_count > 0:
			print("-> -> Entering Retreat")
			var returned_arr:Array = find_retreat_point()
			if returned_arr[0] != Vector2i(-1234, -1234):
				course_select = true
				get_parent().move_unit_via_path(self, returned_arr[1], true)
				rerun_allowed = true
	if not course_select and current_alert_level >= alert_level.ORANGE_ALERT and move_count > 0:
		print("Entering -> Orange Alert")
		if len(remembered_sightings) > 0:
			var selected_sighting:Vector2i = select_memory_location()
			if selected_sighting != Vector2i(-1234, -1234):
				course_select = true
				get_parent().move_unit_via_path(self, get_parent().get_parent()._return_path(cur_pos, selected_sighting), false)
				rerun_allowed = true
	if not course_select and current_alert_level >= alert_level.YELLOW_ALERT and move_count > 0:
		print("Entering -> Yellow Alert")
		if len(audio_cues) > 0:
			var selected_sighting:Vector2i = select_investigation_location()
			if selected_sighting != Vector2i(-1234, -1234):
				course_select = true
				get_parent().move_unit_via_path(self, get_parent().get_parent()._return_path(cur_pos, selected_sighting), false)
				rerun_allowed = true
	if not course_select and current_alert_level >= alert_level.GREEN_ALERT and move_count > 0:
		print("Entering -> Green Alert")
		pass
	if not course_select and current_alert_level >= alert_level.BLUE_ALERT and action_count > 0:
		print("Entering -> Blue Alert")
		var ideal_recovery_action:Healaction = ideal_recovery()
		if ideal_recovery_action != null and action_count > 0:
			course_select = true
			ideal_recovery_action.execute()
	
			rerun_allowed = true
	if not course_select:
		action_count = 0
		move_count = 0
		rerun_allowed = false
		# Because if it's false by this point, then no action has been chosen (because they may be invalid), so end turn.
	turn_breakout_counter += 1
	return rerun_allowed
