extends Unit
class_name Hostile_Unit

var current_vision:Dictionary[Vector2i, bool]
var sighted_hostiles:Dictionary[Vector2i, Entity]
var remembered_sightings:Dictionary[Vector2i, Flag]
var audio_cues:Dictionary[Vector2i, int]


var vision_range:int = 20
var relative_range:int = 5
var ideal_melee_dpt:float = 0.0
var ideal_ranged_dpt:float = 0.0
var turn_breakout_counter:int = 0
var current_turn_debug_print:String = ""


var current_alert_level:int = alert_level.PATROL_AREA
enum alert_level {
	AREA_SECURE, # Recover
	PATROL_AREA, # Situation normal
	INVESTIGATE_AUDIO_CUE, # Heard something suspiscious
	REMEMBERED_HOSTILE, # Recently saw a hostile
	HOSTILE_IN_SIGHT # Hostile in view
}
var time_since_alert_update:int = 0


### ------------------------------------------------------------
### STRENGTH CALCULATIONS
	
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
	
### STRENGTH CALCULATIONS
### ------------------------------------------------------------

	

### ------------------------------------------------------------
### IDEAL ACTION SELECTOR

func ideal_attack(target_unit:Unit) -> Attackaction:
	var atk_actions:Array[Attackaction] = get_attack_actions()
	var pos_atks:Array[Attackaction] = []
	for atk_action in atk_actions:
		#var atk_tiles = atk_action.range_pattern.calculate_affected_tiles_from_center(cur_pos)
		#print(target_unit.cur_pos, " ", cur_pos)
		#print(atk_action.range_pattern.affected_tiles)
		#print(atk_tiles)
		#
		#if cached_parent.debugging_allowed:
		#	print(target_unit.cur_pos, " ", atk_tiles)
		#if target_unit.cur_pos in atk_tiles:
		pos_atks.append(atk_action)
	if len(pos_atks) < 1:
		return null
	return pos_atks[cached_parent.get_random_generator().randi_range(0, len(pos_atks)-1)]
	
func ideal_recovery() -> Healaction:
	var heal_actions:Array[Healaction] = get_restorative_actions()
	if len(heal_actions) < 1 or health >= base_health:
		return null
	return heal_actions[cached_parent.get_random_generator().randi_range(0, len(heal_actions)-1)]
	

### IDEAL ACTION SELECTOR
### ------------------------------------------------------------



### ------------------------------------------------------------
### VISIBILITY UPDATES

## Visibility Updater that:
## [br] - Uses BFS to get all tiles within 'vision_range'
## [br] - Assigns all tiles in vision_range from cur_pos to a Dictionary for easy O(1) lookups
## [br] - Updates current_vision to now use that Dictionary
func update_visible_tiles() -> void:
	var currently_visible_tiles:Dictionary[Vector2i, bool] = {}
	var tiles_in_vision:Array = Globals.get_bfs_tiles(cur_pos, vision_range, cached_parent.map_manager)

	# We place the coordinates into a dictionary instead of just using the Array so that way we can do O(1) dictionary lookups for if we can see a tile, instead of O(n) lookups to see if it's in the Array
	for coordinate in tiles_in_vision:
		currently_visible_tiles[coordinate] = true
	current_vision = currently_visible_tiles

## Enemy Unit Visibility Updater that:
## [br] - Increments through all enemy factions
## [br] - - (Skips our faction)
## [br] - - Increment through all units of that faction
## [br] - - - Check if that unit is in vision
## [br] - - - - Adds that unit to a Dictionary[Entity, Vector2i] and a Dictionary[Vector2i, Entity]
## [br] - Returns a Dictionary[Vector2i, Entity] whilst updating the Dictionary[Entity, Vector2i] fed as a parameter
func update_visible_hostiles(cache_for_enemy_units:Dictionary[Entity, Vector2i]) -> Dictionary[Vector2i, Entity]:
	var enemies_in_sight:Dictionary[Vector2i, Entity] = {}
	
	# Check each enemy faction
	for enemy_faction_name in get_enemy_unit_factions():
		# Skip our own faction, just in case it somehow ended up in enemy factions
		if enemy_faction_name == cached_parent.faction_name:
			continue

		# Fetch all units belonging to this enemy faction	
		var unit_arr:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
		for enemy_unit in unit_arr:
			# We can see this enemy unit, record its posistion
			if enemy_unit.cur_pos in current_vision:
				enemies_in_sight[enemy_unit.cur_pos] = enemy_unit
				cache_for_enemy_units[enemy_unit] = enemy_unit.cur_pos

	return enemies_in_sight

## Memory Flag Placer Fucnction that:
## [br] - Checks last known coordinates of all previously visible hostiles
## [br] - (Skips if the unit no longer exists)
## [br] - And plants a memory flag if the unit at that coordinate cannot currently be seen (it moved out of vision)
func place_memory_flags_for_lost_targets(enemies_currently_visible: Dictionary[Entity, Vector2i]) -> void:
	for last_known_position_coordinate in sighted_hostiles:
		var enemy_unit:Entity = sighted_hostiles.get(last_known_position_coordinate)

		# Skip if the enemy unit perished (such as if we no longer see it because we took it out this turn)
		if enemy_unit == null:
			continue

		# We know the enemy still exists but we can't see it, so plant a flag on its last known location
		if enemy_unit not in enemies_currently_visible:
			remembered_sightings[last_known_position_coordinate] = Flag.new(enemy_unit, -1) # We set the counter to -1 as it'll be incremented immediantly after by update_memory_flags to 0

## Visibility Helper function used solely by update_memory_flags()
## [br] - Returns a true/false regarding if the given Entity is visible
func is_enemy_unit_visible(provided_unit: Entity) -> bool:
	return provided_unit.cur_pos in current_vision

## Memory Flag Management Function that:
## [br] - Culls memory flags if a unit no longer exists, or is visible
## [br] - Plants a new memory flag if we see the enemy's last known coordinate, but not the enemy
## [br] - Cull memory flags if they've been active for more than a few turns
func update_memory_flags() -> void:
	var flags_to_remove:Array[Vector2i] = []
	var flags_to_add:Array[Flag] = []

	for coordinate in remembered_sightings:
		var memory_flag:Flag = remembered_sightings.get(coordinate)
		var tracked_enemy:Entity = memory_flag.get_tracking_unit()

		# CASE 1: Unit no longer exists, or we can see it
		if tracked_enemy == null or is_enemy_unit_visible(tracked_enemy):
			# Either the unit no longer exists, or we can see it, meaning we don't need a flag
			flags_to_remove.append(coordinate)
			memory_flag.destroy_flag()
			continue

		# CASE 2: We can see the tile the unit was last seen on, and don't see it.
		if coordinate in current_vision:
			var is_second_time_out_of_sight:bool = memory_flag.get_mode()
			# This is the first-time we've seen the tile it was meant to be on, and it wasn't there; Plant a flag nearby
			if not is_second_time_out_of_sight:	
				# Assume the enemy unit is trying to gain as much distance as possible, and plant a flag in that direction
				var estimated_coordinate:Vector2i = coordinate + calculate_heading(coordinate)
				flags_to_add.append(Flag.new(tracked_enemy, memory_flag.get_counter(), true, estimated_coordinate))
			# Delete all references to the original flag
			flags_to_remove.append(coordinate)
			memory_flag.destroy_flag()
			continue

		# CASE 3: Remove the flag if the flag_obj tells us to (via increment_counter which returns true if the counter exceeds 3 turns)
		var flag_expired:bool = memory_flag.increment_counter()
		if flag_expired:
			flags_to_remove.append(coordinate)
			memory_flag.destroy_flag()

	# Erase all flags slated for removal
	for coordinate in flags_to_remove:
		remembered_sightings.erase(coordinate)

	# Add new flags
	for memory_flag in flags_to_add:
		remembered_sightings[memory_flag.get_last_known_pos()] = memory_flag

## Main vision-processing function that:
## [br] - Updates visible tiles
## [br] - Updates dictionary of visible enemy units
## [br] - Plants memory flags on last known coordinates of no longer visible hostile units
## [br] - Increment all memory flags
func examine_surroundings() -> void:
	# STEP 1: Update current_vision for the tiles we can see this turn
	update_visible_tiles()
	
	# STEP 2: Update the Dictionary of enemy units we can see this turn
	var enemies_visible_this_turn_Vec_Unit:Dictionary[Vector2i, Entity] = {}
	var enemies_visible_this_turn_Unit_Vec:Dictionary[Entity, Vector2i] = {}
	enemies_visible_this_turn_Vec_Unit = update_visible_hostiles(enemies_visible_this_turn_Unit_Vec)
	if cached_parent.debugging_allowed:
		current_turn_debug_print += "\nDEBUG/SIGHTED: " + str(enemies_visible_this_turn_Vec_Unit)
	sighted_hostiles = enemies_visible_this_turn_Vec_Unit
	
	# STEP 3: Plant Memory Flags on the last known coordinates of enemy units we can no longer see
	place_memory_flags_for_lost_targets(enemies_visible_this_turn_Unit_Vec)
	
	# STEP 4: Increment all Memory Flags, cull Memory Flags that have been active for several turns
	update_memory_flags()

### VISIBILITY UPDATES
### ------------------------------------------------------------



### ------------------------------------------------------------
### DESTINATION HELPERS

func calculate_heading(target:Vector2i) -> Vector2i:
	return (target - cur_pos)	

##Returns [valid:bool, path_cost:int, point_path:Array[ int ]]
func coordinate_validated(coordinate:Vector2i) -> Array:
	var pathfinder:Pathfinder = cached_parent.get_pathfinder()
	var returned_path:PackedVector2Array = pathfinder._return_path(cur_pos, coordinate)
	# if cached_parent.debugging_allowed:
		# print("DEBUG/PATH: (", coordinate, ") ", returned_path)
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

##Returns [max_coord:Vector2i, max_strength:float, max_ratio:float, stored_path:Array[ int ]]
func get_best_supported_tile(provided_target:Vector2i, provided_attack_action:Attackaction, provided_range:int=1) -> Array:
	var max_strength:float = -INF
	var max_coord:Vector2i = Vector2i(-1234, -1234)
	var max_ratio:float = 1.0
	var max_path:PackedVector2Array = []
	var path_cost:float = 0.0		
	var move_pattern:Pattern2D = provided_attack_action.range_pattern
	var coord_arr:Array[Vector2i] = []
	for coordinate_y in range(-move_pattern.grid_size.y, move_pattern.grid_size.y + 1):
		for coordinate_x in range(-move_pattern.grid_size.x, move_pattern.grid_size.x + 1):
			var t_coord = move_pattern.calculate_affected_tiles_from_center(provided_target + Vector2i(coordinate_x, coordinate_y))
			if provided_target in t_coord:
				coord_arr.append(Vector2i(coordinate_x, coordinate_y))
	for coordinate in coord_arr:
		var temp_coord:Vector2i = provided_target + Vector2i(coordinate)
		var f_support = get_friendly_support_at_location(temp_coord) + calculate_relative_strength_target(coordinate)
		var e_support = get_hostile_threat_at_location(temp_coord, false)
		var disparity = f_support - e_support
		if disparity > max_strength:
			var validation = coordinate_validated(temp_coord)
			if validation[0]:				
				disparity -= 0.15 * validation[1]
				if validation[1] > move_count: # if we can't move there immediantly, deprioritize
					disparity -= (validation[1]/move_count)
				if disparity > max_strength:
					max_strength = disparity
					max_coord = temp_coord
					max_ratio = f_support / max(e_support, 0.001)
					max_path = validation[2]
					path_cost = validation[1]
	return [max_coord, max_strength, max_ratio, max_path, path_cost]

### DESTINATION HELPERS
### ------------------------------------------------------------



### ------------------------------------------------------------
### SELECT DESTINATION

##Determines via randomized weights which last-known-enemy the unit should investigate
func select_memory_location() -> Array:
	var weighted_coord = []
	var weights = []
	var path_arr = []
	for coordinate in remembered_sightings:
		var valid_arr:Array = coordinate_validated(coordinate)
		if valid_arr[0]:
			var flag_obj:Flag = remembered_sightings.get(coordinate)
			# High Friendly Support is a 'PRO' for investigating an area
			# High (known) Hostile Threat, distance, time since that region was in sight, and general uncertainty are 'CONs'
			weights.append(get_friendly_support_at_location(coordinate) + (flag_obj.get_counter() * 3.0 +  min(coordinate.distance_to(cur_pos), 30.0) + get_hostile_threat_at_location(coordinate, true)) * -1.0)
			weighted_coord.append(coordinate)
			path_arr.append(valid_arr[2])		
	if len(weighted_coord) < 1:
		return [Vector2i(-1234, -1234), []]
	else:
		var index = cached_parent.get_parent().get_random_generator().rand_weighted(weights)
		var selected_coordinate = weighted_coord[index]
		return [selected_coordinate, path_arr[index]]
	
func select_investigation_location() -> Array:
	# Not implemented yet
	for coordinate in audio_cues:
		pass
	return [Vector2i(-1234, -1234), []]
		
var cached_patrol_location_data:Array = [Vector2i(-1234, -1234), []]
func select_patrol_point() -> void:
	# Just select a random coordinate that's x2 movement range right now
	var random_gen:RandomNumberGenerator = cached_parent.get_parent().get_random_generator()
	var attempts:int = 0
	while attempts < 10:
		var ran_x = random_gen.randi_range(-10, 10)
		var ran_y = random_gen.randi_range(-10, 10)
		var assembled_vector:Vector2i = Vector2i(ran_x, ran_y)
		if assembled_vector != Vector2i(0, 0):
			assembled_vector +=  cur_pos
			if assembled_vector in cached_parent.map_manager.map_dict_v2:
				var validation_arr = coordinate_validated(assembled_vector)
				if validation_arr[0]: 
					cached_patrol_location_data = [assembled_vector, validation_arr[2]]
					print("Assigned: ",cached_patrol_location_data)
					return
			else:
				OS.crash("ERROR? " + str(assembled_vector) + " not in cached_parent.map_manager.map_dict_v2\nDict: " + str(cached_parent.map_manager.map_dict_v2))
		attempts += 1
	return
	
##Calculates the 'optimal' rally-point (Vector2i) for a NPC unit to fall back to (greatest localised concentration of friendly units)
##; Returns [ designated_point:Vector2i, point_path:PackedVector2Array]
func find_rally_point() -> Array:
	var weighted_coords:Dictionary[Vector2i, Array] = {}
	var weights = []
	for faction_name_ref in get_friendly_factions():
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):
			if friendly_unit == self:
				continue
			var adjacent_tiles = Globals.get_bfs_empty_tiles(friendly_unit.cur_pos, 2, cached_parent.map_manager)
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
	var index = cached_parent.get_parent().get_random_generator().rand_weighted(weights)
	var weight_keys = weighted_coords.keys()
	var weight_values = weighted_coords.values()
	return [weight_keys[index], weight_values.get(index)[1]] 


##Functions similarly to rally point, but only tiles within movement distance of the current unit are viable candidates instead of units adjacent to allies
func find_retreat_point() -> Array:
	var max_score:float = -INF
	var max_coord:Vector2i = Vector2i(-1234, -1234)
	var max_path:PackedVector2Array = []
	var possible_move_tiles = Globals.get_bfs_empty_tiles(cur_pos, move_count, cached_parent.map_manager)
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
var cached_attack_action:Attackaction = null
func find_exposed_hostile() -> Array:
	var max_strength:float = -INF
	var max_ratio:float = 1.0
	var max_coord:Vector2i = Vector2i(-1234, -1234)
	var max_path:PackedVector2Array = []
	var path_cost:float = 0.0
	var only_ranged:bool = false
	for coordinate in sighted_hostiles:
		var adj_tiles = Globals.get_bfs_empty_tiles(coordinate, 1, cached_parent.map_manager)
		var num_empty_adj = len(adj_tiles)
		if num_empty_adj <= 0 and relative_range <= 1:
			# print("No empty tiles adjacent to ", coordinate)
			continue
		
		# Fetch best attack specific to this enemy:
		cached_attack_action = ideal_attack(sighted_hostiles.get(coordinate))
		var support_arr:Array = get_best_supported_tile(coordinate, cached_attack_action)
		if support_arr[0] != Vector2i(-1234, -1234):
			# Only consider enemies wherein we have a Friendly to Enemy Ratio of 0.5; Then check to see if we've got better support here than the 'best' enemy to attack
			if support_arr[2] > 0.5:
				if support_arr[1] > max_strength:
					max_coord = coordinate
					max_strength = support_arr[1]
					max_ratio = support_arr[2]
					max_path = support_arr[3]
					if num_empty_adj <= 0:
						only_ranged = true
					else:
						only_ranged = false
					path_cost = support_arr[4]
				# else:
				# 	print("There are better options than hitting "+str(coordinate)+" ("+str(max_coord)+")")
			# else:
			# 	print("Enemy Threat level "+support_arr[2]+" is too high at this supporting tile")
		# else:
		#	print("There's no way for us to target ", coordinate)
	return [max_coord, max_strength, max_ratio, max_path, only_ranged, path_cost]

var cached_support_action:Healaction = null
func find_unit_in_need() -> Array:
	var max_strength:float = -INF
	var max_ratio:float = 1.0
	var max_coord:Vector2i = Vector2i(-1234, -1234)
	var max_path:PackedVector2Array = []
	var path_cost:float = 0.0
	var only_ranged:bool = false
	var selected_unit:Entity = null
	for faction_name_ref in get_friendly_factions():
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):
			cached_support_action = ideal_recovery()
			selected_unit = friendly_unit
	return [max_coord, max_strength, max_ratio, max_path, only_ranged, path_cost, selected_unit]

### SELECT DESTINATION
### ------------------------------------------------------------



### ------------------------------------------------------------
### STATE MACHINE HELPERS

enum state_machine {
	IDLE,
	DONE,
	ACTING,
	ATTACKING,
	SUPPORTING,
	MOVING,
	RUSHING,
	RUNNING
}
var current_state:int = state_machine.IDLE

func execute_turn() -> void:
	cached_parent = get_parent()
	examine_surroundings()
	alert_lvl_update()
	move_count = move_max
	action_count = action_max	
	current_turn_debug_print = ""
	current_state = state_machine.IDLE
	var mandatory_stop:int = 20
	var incrementer:int = 0
	while (current_state != state_machine.DONE and incrementer < mandatory_stop):
		var prior_pos:Vector2i = cur_pos
		process_active_state()
		incrementer += 1
		if prior_pos != cur_pos:
			examine_surroundings()
			alert_lvl_update(false)
	if cached_parent.debugging_allowed:
		print(current_turn_debug_print)
		

func process_active_state() -> void:
	current_turn_debug_print += "\nDEBUG/ST-M: Processing State (" + get_string_name_of_state(current_state) + ")"
	match current_state:
		state_machine.IDLE:
			state_machine_idle()
		state_machine.DONE:
			state_machine_done()
		state_machine.ACTING:
			state_machine_acting()
		state_machine.ATTACKING:
			state_machine_attacking()
		state_machine.SUPPORTING:
			state_machine_supporting()
		state_machine.MOVING:
			state_machine_moving()
		state_machine.RUSHING:
			state_machine_rushing()
		state_machine.RUNNING:
			state_machine_running()

func get_string_name_of_state(provided_state:int) -> String:
	match provided_state:
		state_machine.IDLE:
			return "IDLE"
		state_machine.DONE:
			return "DONE"
		state_machine.ACTING:
			return "ACTING"
		state_machine.ATTACKING:
			return "ATTACKING"
		state_machine.SUPPORTING:
			return "SUPPORTING"
		state_machine.MOVING:
			return "MOVING"
		state_machine.RUSHING:
			return "RUSHING"
		state_machine.RUNNING:
			return "RUNNING"
	
	# if you reach here, that means it's an invalid state.
	return "INVALID-STATE-OF-("+ str(provided_state) + ")-PROVIDED"
	
func get_string_name_of_alert(provided_alert:int) -> String:
	match provided_alert:
		alert_level.HOSTILE_IN_SIGHT:
			return "HOSTILE_IN_SIGHT"
		alert_level.REMEMBERED_HOSTILE:
			return "REMEMBERED_HOSTILE"
		alert_level.INVESTIGATE_AUDIO_CUE:
			return "INVESTIGATE_AUDTIO_CUE"
		alert_level.PATROL_AREA:
			return "PATROL_AREA"
		alert_level.AREA_SECURE:
			return "AREA_SECURE"
	
	# if you reach here, that means it's an invalid alert.
	return "INVALID-ALERT-OF-("+ str(provided_alert) + ")-PROVIDED"

func change_state(new_state:int) -> void:
	current_turn_debug_print += "\nDEBUG/ST-M: Transistioning from "+get_string_name_of_state(current_state)+" to "+get_string_name_of_state(new_state)
	current_state = new_state

### STATE MACHINE HELPERS
### ------------------------------------------------------------



### ------------------------------------------------------------
### STATE MACHINE

func state_machine_idle() -> void:
	current_turn_debug_print += "\nDEBUG/IDLE: with MOVE: "+str(move_count)+ ", ACTIONS: " +str(action_count) +", ALERT: " + get_string_name_of_alert(current_alert_level) + ", on COORD: " + str(cur_pos)
	
	# PRIORITY 1 -> ENGAGE HOSTILES
	if len(sighted_hostiles) > 0:
		current_alert_level = alert_level.HOSTILE_IN_SIGHT
		var threat_diff = (calculate_relative_strength_target(cur_pos) + get_friendly_support_at_location(cur_pos)) / max(get_hostile_threat_at_location(cur_pos, false), 0.001)
		current_turn_debug_print += "\nDEBUG/IDLE/THREAT: " + str(threat_diff)
		# Odds are in our favour
		if threat_diff > 0.6 and action_count > 0:
			change_state(state_machine.ACTING)
			return
		# Not great odds, we should regroup with nearby allies
		elif threat_diff > 0.4 and move_count > 0:
			change_state(state_machine.RUSHING)
			return
		# Run, run run away the enemy is insurmountable
		elif move_count > 0:
			change_state(state_machine.RUNNING)
			return
		
	# PRIORITY 2 -> SEARCH FOR HOSTILES
	if len(remembered_sightings) > 0 and move_count > 0:
		current_alert_level = alert_level.REMEMBERED_HOSTILE
		change_state(state_machine.MOVING)
		return
	
	# PRIORITY 3 -> INVESTIGATE AUDIO CUES
	if len(audio_cues) > 0 and move_count > 0:
		current_alert_level = alert_level.INVESTIGATE_AUDIO_CUE
		change_state(state_machine.MOVING)
		return
		
	# PRIORITY 4 -> RECOVERY ACTIONS
	if action_count > 0:
		current_alert_level = alert_level.AREA_SECURE
		var ideal_recovery_action:Healaction =  ideal_recovery()
		if ideal_recovery_action != null:
			change_state(state_machine.ACTING)
			return
	
	# PRIORITY 5 -> PATROLLING
	if move_count > 0:
		current_alert_level = alert_level.PATROL_AREA
		change_state(state_machine.MOVING)
		return
	
	change_state(state_machine.DONE)
	return
	
func state_machine_done() -> void:
	pass
	
var cached_movement_path:PackedVector2Array = []
var cached_focus_unit:Entity = null
func state_machine_acting() -> void:
	# Gets triggered by Desire to Heal and Desire to Attack
	current_turn_debug_print += "\nDEBUG/ACTING/ALERT_LEVEL: " + str(current_alert_level)
	if current_alert_level == alert_level.HOSTILE_IN_SIGHT or current_alert_level == alert_level.AREA_SECURE:
		var data_arr = []
		if current_alert_level == alert_level.HOSTILE_IN_SIGHT:
			data_arr = find_exposed_hostile()
		else:
			data_arr = find_unit_in_need()
		if data_arr[0] != Vector2i(-1234, -1234):
			if current_alert_level == alert_level.HOSTILE_IN_SIGHT:
				current_turn_debug_print += "\nDEBUG/ACTING/EXPOSED_HOSTILE: " + str(data_arr[0])
				current_turn_debug_print += "\nDEBUG/ACTING/SELECTED_ATTACK: " + str(cached_attack_action)
				cached_focus_unit = sighted_hostiles.get(data_arr[0])
			else:
				current_turn_debug_print += "\nDEBUG/ACTING/UNIT_IN_AID: " + str(data_arr[0])
				current_turn_debug_print += "\nDEBUG/ACTING/SELECTED_ACTION: " + str(cached_support_action)
				cached_focus_unit = data_arr[6]
			cached_movement_path = data_arr[3]
			change_state(state_machine.MOVING)
			return
		#else:
			# A Vector2i of <-1234, -1234> can only be attained if:
			# - There are no adjacent tiles to the enemy, AND we only have melee attacks (Patterns with a grid size of 3x3)
			# - The location does not exist
		
	change_state(state_machine.IDLE)
	return
	

func state_machine_attacking() -> void:
	use_action(cached_attack_action, cached_focus_unit, true)
	change_state(state_machine.IDLE)
	return
	
func state_machine_supporting() -> void:
	use_action(cached_support_action, cached_focus_unit, true)
	change_state(state_machine.IDLE)
	return
	
func state_machine_moving() -> void:
	if move_count <= 0:
		change_state(state_machine.DONE)
		return
	
	if current_alert_level == alert_level.HOSTILE_IN_SIGHT or current_alert_level == alert_level.AREA_SECURE:
		current_turn_debug_print += "\nDEBUG/MOVING: " +str(cur_pos) + " -> " + str(cached_movement_path[-1]) + " using path: " + str(cached_movement_path)
		cached_parent.move_unit_via_path(self, cached_movement_path, true)
		current_turn_debug_print += "\nDEBUG/MOVING: Reached " + str(cur_pos) + " with " + str(move_count) + " moves left"
		if cur_pos == Vector2i(cached_movement_path[-1]):		
			current_turn_debug_print += "\nDEBUG/MOVING: At Action Location"
			if current_alert_level == alert_level.HOSTILE_IN_SIGHT:
				change_state(state_machine.ATTACKING)
				return
			if current_alert_level == alert_level.AREA_SECURE:
				change_state(state_machine.SUPPORTING)
				return
		else:
			change_state(state_machine.DONE)
			return
	elif current_alert_level == alert_level.REMEMBERED_HOSTILE:
		var selection:Array = select_memory_location()
		if selection[0] != Vector2i(-1234, -1234):
			cached_parent.move_unit_via_path(self, selection[1], true)
	elif current_alert_level == alert_level.INVESTIGATE_AUDIO_CUE:
		var selection:Array = select_investigation_location()
		if selection[0] != Vector2i(-1234, -1234):
			cached_parent.move_unit_via_path(self, selection[1], true)
	elif current_alert_level == alert_level.PATROL_AREA:
		if cached_patrol_location_data[0] == Vector2i(-1234, -1234) or cur_pos == cached_patrol_location_data[0]:
			select_patrol_point()
			
		if cached_patrol_location_data[0] != Vector2i(-1234, -1234):
			cached_parent.move_unit_via_path(self, cached_patrol_location_data[1], true)
			
			# Cull the tiles we've gone through from the path (as move_unit_via_path needs a path from cur_pos to destination (cur_pos, tile3, destination), not (tile1, tile2, cur_pos, tile3, destination) etc.
			var ignore_index = -1
			for index in range(len(cached_patrol_location_data[1])):
				if Vector2i(cached_patrol_location_data[1][index]) == cur_pos:
					ignore_index = index
					break
			var new_path = []
			for index in range(len(cached_patrol_location_data[1])):
				if index >= ignore_index:
					new_path.append(cached_patrol_location_data[1][index])
			cached_patrol_location_data[1] = new_path
		else:
			# Nothing will have changed, so going back to IDLE would just get us in loop
			change_state(state_machine.DONE)
			return
		
	change_state(state_machine.IDLE)
	return	

func state_machine_rushing() -> void:
	var data_arr:Array = find_rally_point()
	if data_arr[0] != Vector2i(-1234, -1234):
		cached_parent.move_unit_via_path(self, data_arr[1], true)
		change_state(state_machine.IDLE)
		return	
	
	# Only way to get <-1234, -1234> is if we can't get to allies, so do the next best thing and gain distance from enemies; Can't default to IDLE as nothing has changed, so we'd get stuck in a loop
	change_state(state_machine.RUNNING)
	
func state_machine_running() -> void:
	var data_arr:Array = find_retreat_point()
	if data_arr[0] != Vector2i(-1234, -1234):
		cached_parent.move_unit_via_path(self, data_arr[1], true)
		change_state(state_machine.IDLE)
		return	
		
	# Only way to get <-1234, -1234> is if it's impossible to move (out of movement or all tiles nearby are blocked)
	# Hypothetically, we could switch to ACTING as the only way to get to RUNNING is from HOSTILE_IN_SIGHT (which would trigger ACTING in IDLE unless overwhelming odds), but find_exposed_hostiles purposefully excludes low-odd hostiles, so we would be stuck in a loop unless exceptions are added.
	change_state(state_machine.DONE)
		
### STATE MACHINE
### ------------------------------------------------------------



### ------------------------------------------------------------
### DECISION TREE
	
##Updates the alert_level of the unit based upon any hostiles it can see, followed by last-known hostiles, then investigating uncertain audio cues, then patrolling, then restorative actions if 'safe'
func alert_lvl_update(dont_increment:bool=false) -> void:
	if len(sighted_hostiles) > 0:
		current_alert_level = alert_level.HOSTILE_IN_SIGHT
		time_since_alert_update = 0
		return
		
	if len(remembered_sightings) > 0:
		current_alert_level = alert_level.REMEMBERED_HOSTILE
		time_since_alert_update = 0
		return
		
	if len(audio_cues) > 0:
		current_alert_level = alert_level.INVESTIGATE_AUDIO_CUE
		time_since_alert_update = 0
		return
		
	if not dont_increment:
		time_since_alert_update += 1
		
	if time_since_alert_update > 4 and health < base_health:
		current_alert_level = alert_level.AREA_SECURE
		time_since_alert_update = 0
		return 

	if current_alert_level != alert_level.PATROL_AREA:
		current_alert_level = alert_level.PATROL_AREA
		time_since_alert_update = 0
		return
	
	
### DECISION TREE
### ------------------------------------------------------------
