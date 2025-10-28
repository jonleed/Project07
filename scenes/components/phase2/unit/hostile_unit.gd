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

const FALL_BACK_TO_REGROUP_THRESHOLD:float = 0.6
const RETREAT_THRESHOLD:float = 0.4
const INVALID_COORDINATE:Vector2i = Vector2i(-1234, -1234)


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
	
## DESCRIPTION: Makes a basic approximation of a unit's 'Strength'
## [br] Basic Strength Formula is composed as: 2.0 * Health + MaximumDamagePerTurn
## [br]
## [br] RETURNS: float
func calculate_relative_strength_norm() -> float:
	return health * 2.0 + max(ideal_melee_dpt, ideal_ranged_dpt)

## DESCRIPTION: Makes an approximation of a unit's 'Strength', and tries to select an action for MaximumDamagePerTurn via distance to the provided coordinate 
## [br] Pick DamagePerTurn: 
## [br] - If Distance > move_count, use ideal_ranged_dpt (Maximum damage from all 'ranged' pattern (exceeding a 3x3 grid)) 
## [br] - If Distance > move_count / 2, use whichever is greater (ideal_ranged_dpt or ideal_melee_dpt)
## [br] - Else, use ideal_melee_dpt
## [br] Strength is Health * 2.0 + DamagePerTurn
## [br]
## [br] PARAMETERS:
## [br] - target:Vector2i -> the coordinate being queried
## [br]
## [br] RETURNS: float
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
	
## Calculates the percieved strength of allied units nearby based off of the health and distance of nearby ally units to the designated tile
## [br] Iterate through all friendly factions
## [br] - Iterate through all units in that faction
## [br] - - Exclude ourself
## [br] - - Calculate this units distance to the provided coordinate
## [br] - - Modify total friendly support positively by the unit's strength, and negatively by distance (with distance raised to a slight power to make greater distances more punishing to support)
## [br] Return the total amount of 'support' at that time
## [br]
## [br] PARAMETERS:
## [br] - target:Vector2i -> The coordinate being queried
## [br] - influence_cap:float, DEFAULT is -10 -> The 'cap' placed on how much a unit's distance from the location can negatively impact support. (This prevents a unit across the map cratering support, unbounding it to -Infinity effectively divides the map between locations with NUMERICAL Superiority, not QUALITATIVE Superiority)
## [br]
## [br] RETURN:
## [br] - float -> Floating-Point number resembling the approximated strength of allied units at the given coordinate 
func get_friendly_support_at_location(target:Vector2i, influence_cap:float=-10) -> float:
	# current_turn_debug_print += "\n------------------------------------"
	# current_turn_debug_print += "\nFriendly Support:"
	var friendly_support:float = 0.0

	# Iterate through all friendly factions
	for faction_name_ref in get_friendly_factions():

		# Iterate through all units in the friendly faction
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):

			# Exclude ourself
			if friendly_unit == self:
				continue

			# Calculate the distance this friendly unit is from the queried coordinate
			var friendly_unit_pos:Vector2i = friendly_unit.cur_pos
			var dist_to_friendly:float = friendly_unit_pos.distance_to(target)

			# Approximate the unit's strength at the queried coordinate
			var calculated_strength:float = friendly_unit.calculate_relative_strength_target(target)

			# Modify approximate strength negatively by distance as high strength means nothing if they can't get there in time to avenge/support you
			# We cap the friendly_support and hostile_threat addition at -10.0 via influence_cap as leaving it uncapped means we effectively split the map between the two locations with the greatest (localised) concentration of friendly vs hostile units on the entire map (as in you're 'support' could be heavily penalized by a units all the way on the other side of the map, even if you really should be 'safe' in a particular area
			# (We'll use this for determining rally points (running from the greatest known cluster of enemies))
			var modified_strength:float = max(calculated_strength - pow(dist_to_friendly, 1.1), influence_cap)
			friendly_support += modified_strength
			
			# current_turn_debug_print += "\n- Unit at " + str(friendly_unit.cur_pos) + " is " + str(dist_to_friendly) + " away with strength " + str(calculated_strength) + "; Adjusted Strength is: " + str(modified_strength)
			

	# Return the sum total of friendly support for a tile
	# current_turn_debug_print += "\nTotal Friendly Support for " + str(target) + " is " + str(friendly_support)
	return friendly_support

## Calculates the percieved threat of a tile based off of the health and distance of nearby enemy units to the designated tile
## [br] VIRTUALLY IDENTICAL TO get_friendly_support_at_location()
## [br] Iterate through each coordinate flagged with a hostile unit
## [br] - Calculate distance of hostile unit to queried coordinate
## [br] - Approximate strength of the hostile unit; 'Downplay' the threat of a hostile unit the further away it is
## [br] If we recently lost vision of an enemy on this tile, assume a peer-level threat and add to the total threat level on the tile
## [br] Return the total threat level for the tile
## [br] 
## [br]
## [br] PARAMETERS:
## [br] - target:Vector2i -> The coordinate being queried
## [br] - influence_cap:float, DEFAULT is -10 -> The 'cap' placed on how much a unit's distance from the location can negatively impact support. (This prevents a unit across the map cratering support, unbounding it to -Infinity effectively divides the map between locations with NUMERICAL Superiority, not QUALITATIVE Superiority)
## [br]
## [br] RETURN:
## [br] - float -> Floating-Point number resembling the approximated strength of enemy units at the given coordinate 
func get_hostile_threat_at_location(target:Vector2i, uncertain:bool=false, influence_cap:float=-10) -> float:
	# current_turn_debug_print += "\n------------------------------------"
	# current_turn_debug_print += "\nEnemy Threat:"
	var hostile_threat:float = 0.0

	# Iterate through coordinates flagged with a hostile unit
	for hostile_coordinate:Vector2i in sighted_hostiles:

		# Fetch the unit object at that coordinate
		var hostile_unit:Unit = sighted_hostiles.get(hostile_coordinate)

		# Calculate the distance between the hostile unit and the queried coordinate
		var dist_to_hostile:float = hostile_coordinate.distance_to(target)

		# Approximate the unit's strength at the queried coordinate
		var calculated_strength:float = hostile_unit.calculate_relative_strength_target(target)

		# Modify approximate strength negatively by distance as enemies further away or less threatening than those closer (we have more time to react/get away/get help)
		var modified_strength:float = max(calculated_strength - pow(dist_to_hostile, 1.1), influence_cap)
		# current_turn_debug_print += "\n- Unit at " + str(hostile_coordinate) + " is " + str(dist_to_hostile) + " away with strength " + str(calculated_strength) + "; Adjusted Strength is: " + str(modified_strength)
		hostile_threat += modified_strength

	# Used specifically for select_memory_location, when we remember an enemy used to be there-- but we don't have sight and thus, don't know what their actual strength is
	if uncertain:
		hostile_threat += 1.25 * (base_health * 2.0 + max(ideal_melee_dpt, ideal_ranged_dpt)) # Assume peer-level threat on tile
		# current_turn_debug_print += "\n- Adding Peer Threat of " + str(1.25 * (base_health * 2.0 + max(ideal_melee_dpt, ideal_ranged_dpt)))
	
	# Return the sum total of friendly support for a tile
	# current_turn_debug_print += "\nTotal Enemy Threat for " + str(target) + " is " + str(hostile_threat)
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

## Destination Helper function used solely by update_memory_flags()
## [br] DESCRIPTION:
## [br] - Simply finds the slope/difference between the provided coordinate and cur_pos (which can then be added to the provided_coordinate to get the 'worse-case' scenario coordinate (the coordinate/direction the tracked unit would go in to gain as much distance as possible)
## [br] - - WARNING: This approach is flawed, and it assumes there are no walls and that all tiles have the same cost to traverse 
## [br] 
## [br] PARAMETERS:
## [br] - target:Vector2i
## [br]
## [br] RETURNS:
## [br] - Vector2i
func calculate_heading(target:Vector2i) -> Vector2i:
	return (target - cur_pos)	

## Used extensively for determining if a location is reachable, and if so, the path and movement cost to get there.
## [br]
## [br] PARAMETERS:
## [br] - coordinate:Vector2i
## [br]
## [br] RETURNS: Array[bool, int, PackedVector2Array]
## [br] - If not output[0]: path or location doesn't exist
## [br] - If output[0] and output[1] == 0: already at location
## [br] - If output[0] and output[1] != 0: not there yet, but we can get there
func coordinate_validated(coordinate:Vector2i) -> Array:
	# First, make sure we aren't already at our destination
	#if cur_pos == coordinate:
	#	return [false, 0, [cur_pos, cur_pos]]

	# Secondly, make sure the coordinate EXISTS on the map, that it's in bounds
	if coordinate not in cached_parent.map_manager.map_dict_v2:
		return [false, INF, [INVALID_COORDINATE, INVALID_COORDINATE]]

	var pathfinder:Pathfinder = cached_parent.get_pathfinder()
	var returned_path:PackedVector2Array = pathfinder._return_path(cur_pos, coordinate)
	
	# Thirdly, make sure a path even exists to the desired coordinate
	if len(returned_path) == 0 or coordinate == INVALID_COORDINATE:
		return [false, INF, [INVALID_COORDINATE, INVALID_COORDINATE]]
	
	var path_cost = pathfinder.calculate_path_cost(returned_path)

	# Returns -> Yes we can move directly there, the cost in movement to get there, and the Vector2 path to that location
	return [true, path_cost, returned_path]


enum function_mode {
	RETREAT, 
	RALLY,
	SEARCH,
	SUPPORT	
}

## DESCRIPTION: Examines a provided coordinate (and information regarding the 'best' coordinate checked thus far), and determines if the provided coordinate's calculated score is higher than the 'best', updating the 'best' if it is.
## [br] Make sure we can pathfind to the coordinate
## [br] - Calculate Strength Disparity
## [br] - If RALLY -> return if Disparity Ratio is below RETREAT_THRESHOLD; Otherwise, modify disparity negatively by distance to the coordinate
## [br] - IF SEARCH -> return if DISPARITY Ratio is below FALL_BACK_TO_REGROUP_THRESHOLD; Otherwise, modify disparity by both distance and the time left on the flag (prioritizing flags more recently placed)
## [br] - IF SUPPORT (get_best_supported_tile, not as in a supporting-action) -> modify disparity negatively by 0.15 * movementcost; Further modify by number of turns the tile is from the unit
## [br] - Add the tile to the unpredictable array data holders
## [br] - Update provided parameters and return information if coordinate score is greater than the best coordinate score
## [br] Return
## [br] 
## [br] PARAMETERS:
## [br] - coordinate:Vector2i -> The coordinate being checked
## [br] - best_coordinate_score:float -> The highest coordinate score recorded thus far
## [br] - best_strength_disparity_ratio:float -> The highest strength disparity score recorded thus far
## [br] - path_cost_for_best_disparity_coordinate:float -> The movement cost to get to the coordinate with the highest coordinate score
## [br] - best_coordinate_package_array:Array[Vector2i, PackedVector2Array], PASS BY REFERENCE -> [BestCoordinate, PathToBestCoordinate]
## [br] - mode:int -> Identifier for which function is calling the function
## [br] - unpredictable:bool, DEFAULT is false -> Determines if the function is deterministic or randomized
## [br] - unpredictable_potential_coordinates:Array[Vector2i], DEFAULT is [], PASS BY REFERENCE -> Stores an array of Coordinates
## [br] - unpredictable_coordinate_weights:Array[float], DEFAULT is [], PASS BY REFERENCE -> Stores an array of coordinate scores
## [br] - unpredictable_stored_paths:Array[PackedVector2Array], DEFAULT is [], PASS BY REFERENCE -> Stores an array of Paths to Coordinates
## [br]
## [br] RETURNS: Array[float, float, float]
## [br] - [BestCoordinateScore, BestCoordinateDisparityRatio, BestCoordinateMovementCost]
func coordinate_scorer(coordinate:Vector2i, best_coordinate_score:float, best_strength_disparity_ratio:float, path_cost_for_best_disparity_coordinate:float, best_coordinate_package_array:Array, mode:int, unpredictable:bool=false, unpredictable_potential_coordinates:Array=[], unpredictable_coordinate_weights:Array=[], unpredictable_stored_paths:Array=[]) -> Array: 
	# Call upon coordinate_validated to ensure it's actually possible to reach that location; Don't consider coordinates we can't reach 
	var validation = coordinate_validated(coordinate)

	# Deconstruct the data returned by coordinate_validated for legibility
	var can_reach_location:bool = validation[0]
	var movement_cost_to_coordinate:float = validation[1]
	var path_to_coordinate:PackedVector2Array = validation[2]

	# Make sure we can actually pathfind to this location
	if can_reach_location:
		# Calculate the disparity in strength between us and the enemy
		var friendly_support = get_friendly_support_at_location(coordinate) + calculate_relative_strength_target(coordinate)
		var uncertain_flag:bool = false if mode != function_mode.SEARCH else true
		
		var enemy_threat = get_hostile_threat_at_location(coordinate, uncertain_flag)
		var strength_disparity = friendly_support - enemy_threat
		var strength_disparity_ratio:float = friendly_support / max(enemy_threat, 0.001)
		var coordinate_score = strength_disparity
		
		if mode == function_mode.RALLY:
			if strength_disparity_ratio <= RETREAT_THRESHOLD and not unpredictable:
				return [best_coordinate_score, best_strength_disparity_ratio, path_cost_for_best_disparity_coordinate]
			# Inflate 'enemy threat' artificially by movement cost because we need help NOW, deprioritizing further away rally points
			coordinate_score -= min(movement_cost_to_coordinate, 30.0)
		
		if mode == function_mode.SEARCH:
			if strength_disparity_ratio <= FALL_BACK_TO_REGROUP_THRESHOLD and not unpredictable:
				return [best_coordinate_score, best_strength_disparity_ratio, path_cost_for_best_disparity_coordinate]
			var memory_flag:Flag = remembered_sightings.get(coordinate)
			# Inflate 'enemy threat' artificially by movement cost and by the time left on the flag (prioritizing locations we most recently had eyes on, that are closer)
			coordinate_score -= (memory_flag.get_counter() * 3.0 + min(movement_cost_to_coordinate, 30.0))
		

		if mode == function_mode.SUPPORT:
			# Weight disparity slightly negatively by the movement cost to get there
			coordinate_score -= 0.15 * movement_cost_to_coordinate

			# If we can't get to the desired tile immediantly this turn, deprioritize it by the amount of turns it takes to get there
			if movement_cost_to_coordinate > move_count:
				# Since we're dividing, using max to prevent divide-by-zero errors
				coordinate_score -= (movement_cost_to_coordinate/max(move_count, 0.001))

		if unpredictable:
			unpredictable_potential_coordinates.append(coordinate)
			unpredictable_coordinate_weights.append(best_coordinate_score)
			unpredictable_stored_paths.append(path_to_coordinate)

		# Now, if the finalized disparity is higher than the current maximum, update the storage variables with the new information
		if coordinate_score > best_coordinate_score:
			best_coordinate_score = coordinate_score
			best_strength_disparity_ratio = strength_disparity_ratio
			# Since we're dividing, using max to prevent divide-by-zero errors
			best_coordinate_package_array[0] = coordinate
			best_coordinate_package_array[1] = path_to_coordinate
			path_cost_for_best_disparity_coordinate = movement_cost_to_coordinate

	# We need to return all Non-Arrays (as those are references so are alreayd modified)
	return [best_coordinate_score, best_strength_disparity_ratio, path_cost_for_best_disparity_coordinate]

func choose_unpredictable_location(best_coordinate_package_array:Array, unpredictable:bool=false, unpredictable_potential_coordinates:Array=[], unpredictable_coordinate_weights:Array=[], unpredictable_stored_paths:Array=[]) -> Array:
	if unpredictable:
		if len(unpredictable_potential_coordinates) < 1:
			# This is guaranteed to be [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
			return best_coordinate_package_array
			
		# Use the coordinate_score for that coordinate as a random weight, with higher coordinate_scores being more likely to be selected
		var index = cached_parent.get_parent().get_random_generator().rand_weighted(unpredictable_coordinate_weights)
		var selected_coordinate = unpredictable_potential_coordinates[index]
		return [selected_coordinate, unpredictable_stored_paths[index]]
	return best_coordinate_package_array

## DESCRIPTION: Used extensively to determine the optimal tile to move to
## [br] - Given a provided action, increment through all tiles that could hypothetically affect the provided_coordinate
## [br] - - Use 'calculate_affected_tiles_from_center' to put together map coordinates the pattern can affect at that location
## [br] - - See if provided_coordinate falls within that list of affected coordinates, if so, add it to the list of potential coordinates to consider
## [br] - Iterate through all potential coordinates
## [br] - - Calculate the strenght disparity at that coordinate, modified by movement cost to get there, and also by if we can get there this turn or not
## [br] - - If this has the best strength disparity, update the storage variables to use that coordinate
## [br] - Return the storage variables in an array: [DesiredCoordinate:Vector2i, StrengthDisparity:Float, StrengthDisparityRatio:Float, PathToCoordinate:PackedVector2Array, MovementCost:Float]
## [br]
## [br] PARAMETERS:
## [br] - provided_coordinate:Vector2i
## [br] - provided_action:Action
## [br]
## [br] RETURNS: Array[Vector2i, float, PackedVector2Array]
## [br] - [Coordinate, StrengthDisparityRatio, PathToCoordinate]
## [br] - - If output[0] == INVALID_COORDINATE or output[1] == -INF -> No valid support tile
func get_best_supported_tile(provided_coordinate:Vector2i, provided_action:Action) -> Array:
	# Variable initialization	
	var best_strength_disparity:float = -INF
	var best_coordinate_package_array:Array = [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
	var best_disparity_coordinate:Vector2i = INVALID_COORDINATE
	var best_strength_disparity_ratio:float = -INF
	var path_to_best_disparity_coordinate:PackedVector2Array = [INVALID_COORDINATE, INVALID_COORDINATE]
	var path_cost_for_best_disparity_coordinate:float = INF		
	var used_pattern:Pattern2D = provided_action.range_pattern
	var possible_coordinates:Array[Vector2i] = []

	# First, simulate being at a location wherein provided_coordinate falls within the pattern's grid 
	for coordinate_y in range(-used_pattern.grid_size.y, used_pattern.grid_size.y + 1):
		for coordinate_x in range(-used_pattern.grid_size.x, used_pattern.grid_size.x + 1):
			# Converts the pattern offsets in the pattern to an actual map coordinate
			var converted_coordinate = provided_coordinate + Vector2i(coordinate_x, coordinate_y)

			# Secondly, see if the provided_coordinate is within the list of tiles affected from that location
			var coordinates_affected_by_pattern = used_pattern.calculate_affected_tiles_from_center(converted_coordinate)
			if provided_coordinate in coordinates_affected_by_pattern:
				# Thirdly, compile all pattern offsets wherein we can hit provided_coordinate with the pattern
				possible_coordinates.append(converted_coordinate)

	# Iterate through all coordinates wherein it is possible to affect provided_coordinate
	for coordinate in possible_coordinates:
		var returned_array:Array = coordinate_scorer(coordinate, best_strength_disparity, best_strength_disparity_ratio, path_cost_for_best_disparity_coordinate, best_coordinate_package_array, function_mode.SUPPORT)
		
		best_strength_disparity = returned_array[0]
		best_strength_disparity_ratio = returned_array[1]
		path_cost_for_best_disparity_coordinate = returned_array[2]
		best_disparity_coordinate = best_coordinate_package_array[0]
		path_to_best_disparity_coordinate = best_coordinate_package_array[1]
					
	return [best_disparity_coordinate, best_strength_disparity_ratio, path_to_best_disparity_coordinate]

### DESTINATION HELPERS
### ------------------------------------------------------------



### ------------------------------------------------------------
### SELECT DESTINATION

## Iterates through each coordinate a Memory Flag has been planted at (where a hostile unit was last seen at):
## [br] - Make sure we can pathfind to that coordinate
## [br] - - Make sure the tile isn't one we were retreating from
## [br] - - - Calculate the tile's "score" (+Friendly Strength, -Enemy Threat, -Time Elapsed, -Distance)
## [br] - - - Use the coordinate with the greatest tile 'score' 
## [br] - - - ORRRRR- if called with true, use the scores as a random weight to select the tile to 'Search'
## [br]
## [br] PARAMETERS:
## [br] - unpredictable:bool, DEFAULT: false
## [br]
## [br] RETURNS: Array[Vector2i, PackedVector2Array]
## [br] - On Fail: [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
## [br] - On Success: [MemoryFlagCoordinate, PathToCoordinate]
func select_memory_location(unpredictable:bool=false) -> Array:
	var best_coordinate_score:float = -INF
	var best_coordinate_package_array:Array = [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
	var unpredictable_potential_coordinates = []
	var unpredictable_coordinate_weights = []
	var unpredictable_stored_paths:Array[PackedVector2Array] = []

	# Iterate through each coordinate we've planted a Memory Flag on (where we remember seeing enemies) 
	for coordinate in remembered_sightings:
		var returned_array:Array = coordinate_scorer(coordinate, best_coordinate_score, -INF, INF, best_coordinate_package_array, function_mode.SEARCH, unpredictable, unpredictable_potential_coordinates, unpredictable_coordinate_weights, unpredictable_stored_paths)
		best_coordinate_score = returned_array[0]

	# Only run the random weight logic if the unpredictable parameter was passed as true
	return choose_unpredictable_location(best_coordinate_package_array, unpredictable, unpredictable_potential_coordinates, unpredictable_coordinate_weights, unpredictable_stored_paths)

func select_investigation_location() -> Array:
	# Not implemented yet
	for coordinate in audio_cues:
		pass
	return [INVALID_COORDINATE, []]

##DESCRIPTION: Calculates the 'optimal' rally-point (Vector2i) for a NPC unit to fall back to (greatest localised concentration of friendly units)
## [br] Iterate through each friendly faction
## [br] - Iterate through each friendly unit
## [br] - - Abort if that friendly unit is us
## [br] - - Iterate through each tile within 2 tiles of that friendly unit
## [br] - - - Abort if we've checked this tile already
## [br] - - - Make sure we can pathfind to this location
## [br] - - - - Calculate Ally to Enemy Strength Ratio
## [br] - - - - Update best_coordinate_package_array according to highest recorded Strength Ratio
## [br] If we are unpredictable -> Randomly select a rally-point via using the Strength Ratios as random weights
## [br] Otherwise, return best_coordinate_package_array
## [br] 
## [br] PARAMETERS:
## [br]  - unpredictable:bool, DEFAULT: false
## [br]
## [br] RETURNS: Array[Vector2i, PackedVector2Array]
## [br] - On Fail: [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
## [br] - On Success: [RallyCoordinate, PathToCoordinate]
func find_rally_point(unpredictable:bool=false) -> Array:
	var best_coordinate_score:float = -INF
	var best_coordinate_package_array:Array = [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
	var quick_coordinate_lookup_dictionary:Dictionary[Vector2i, bool] = {}
	var unpredictable_potential_coordinates = []
	var unpredictable_coordinate_weights = []
	var unpredictable_stored_paths:Array[PackedVector2Array] = []
	
	# Iterate through each faction marked as friendly
	for friendly_faction_name in get_friendly_factions():

		# Iterate through each of that faction's units
		for friendly_unit:Unit in get_tree().get_nodes_in_group(friendly_faction_name):

			# Make sure we aren't checking ourselves
			if friendly_unit == self:
				continue

			# Get all tiles in a radius of 2 from the friendly unit in question
			var adjacent_tiles:Array[Vector2i] = Globals.get_bfs_empty_tiles(friendly_unit.cur_pos, 2, cached_parent.map_manager)

			# Iterate through each tile near the friendly unit in question
			for coordinate in adjacent_tiles:

				# Make sure we haven't already considered this tile (as friendly units may be next to each other)
				if coordinate not in quick_coordinate_lookup_dictionary:
					quick_coordinate_lookup_dictionary[coordinate] = true

					# best_coordinate_package_array is updated to hold the best reported coordinate / coordinate path (prior or this one, dependent on maximum of coordinate score between prior and this coordinate)
					# Adds this cooridnate to unpredictable_potential_coordinates, its coordinate score to unpredictable_coordinate_weights, and the path to the coordinate in unpredictable_stored_paths
					# Rally Point doesn't care about the Disparity Ratio or Movement Cost of prior Best-Scoring tiles (because we don't need to return those)
					var returned_array = coordinate_scorer(coordinate, best_coordinate_score, -INF, INF, best_coordinate_package_array, function_mode.RALLY, unpredictable, unpredictable_potential_coordinates, unpredictable_coordinate_weights, unpredictable_stored_paths)

					# Updates best_coordinate_score to be the Coordinate with the best score (as determined by coordinate_scorer)
					best_coordinate_score = returned_array[0]

	# Unless unpredictable is true, this will return best_coordinate_package_array (Being deterministic), but if unpredictable IS true, then it'll pick a location based off the coordinate scores (higher scores meaning higher chance to get picked)
	return choose_unpredictable_location(best_coordinate_package_array, unpredictable, unpredictable_potential_coordinates, unpredictable_coordinate_weights, unpredictable_stored_paths)

##DESCRIPTION: Calculates the 'optimal' retreat-point (the coordinate furthest from harm / enemy threat within movement range)
## [br] Iterate through all unoccupied tiles within movement range
## [br] -> Done via coordinate_scorer:
## [br] - - Make sure we can pathfind to this location
## [br] - - Calculate Ally to Enemy Strength Ratio
## [br] - - Update best_coordinate_package_array according to highest recorded Strength Ratio
## [br] If we are unpredictable -> Randomly select a rally-point via using the Strength Ratios as random weights
## [br] Otherwise, return best_coordinate_package_array
## [br] 
## [br] PARAMETERS:
## [br]  - unpredictable:bool, DEFAULT: false
## [br]
## [br] RETURNS: Array[Vector2i, PackedVector2Array]
## [br] - On Fail: [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
## [br] - On Success: [RallyCoordinate, PathToCoordinate]
func find_retreat_point(unpredictable:bool=false) -> Array:
	# Intialise Variables
	var best_coordinate_score:float = -INF
	var movement_cost_to_best_coordinate:float = INF
	var best_coordinate_package_array:Array = [INVALID_COORDINATE, [INVALID_COORDINATE, INVALID_COORDINATE]]
	var unpredictable_potential_coordinates = []
	var unpredictable_coordinate_weights = []
	var unpredictable_stored_paths:Array[PackedVector2Array] = []

	# Get candidate coordinates for places we can retreat to (within our movement range and unoccupied)
	var possible_move_tiles = Globals.get_bfs_empty_tiles(cur_pos, move_count, cached_parent.map_manager)

	# Iterate through each coordinate we could retreat to
	for coordinate in possible_move_tiles:
		# best_coordinate_package_array is updated to hold the best reported coordinate / coordinate path (prior or this one, dependent on maximum of coordinate score between prior and this coordinate)
		# Adds this cooridnate to unpredictable_potential_coordinates, its coordinate score to unpredictable_coordinate_weights, and the path to the coordinate in unpredictable_stored_paths
		# -INF because we don't need to worry about returned_array[1] (disparity ratio) for this function
		var returned_array:Array = coordinate_scorer(coordinate, best_coordinate_score, -INF, movement_cost_to_best_coordinate, best_coordinate_package_array, function_mode.RETREAT, unpredictable, unpredictable_potential_coordinates, unpredictable_coordinate_weights, unpredictable_stored_paths)

		# Updates best_coordinate_score to be the Coordinate with the best score (as determined by coordinate_scorer)
		best_coordinate_score = returned_array[0]

		# Updates movement_cost_to_best_coordinate to store the cost to move to the tile with the best coordinate score (as determined by coordinate_scorer)
		movement_cost_to_best_coordinate = returned_array[2]

	# Unless unpredictable is true, this will return best_coordinate_package_array (Being deterministic), but if unpredictable IS true, then it'll pick a location based off the coordinate scores (higher scores meaning higher chance to get picked)
	return choose_unpredictable_location(best_coordinate_package_array, unpredictable, unpredictable_potential_coordinates, unpredictable_coordinate_weights, unpredictable_stored_paths)

var cached_patrol_location_data:Array = [INVALID_COORDINATE, []]
##DESCRIPTION: Pick a random location near this unit to patrol to
## [br] - Randomly generate a Vector2i Offset two turns-worth of movement of from the unit 
## [br] - - Make sure the patrol point isn't our current coordinate
## [br] - - - Make sure the patrol point isn't a wall
## [br] - - - - Make sure we can reach the patrol point
## [br] - - - - - Assign the patorl point
## [br] - Repeat up to 10 times until a valid patrol point is selected before failing
## [br]
## [br] RETURNS: VOID (updates cached_patrol_location_data)
func select_patrol_point() -> void:
	var random_gen:RandomNumberGenerator = cached_parent.get_parent().get_random_generator()
	var attempts:int = 0

	# Plant patrol points 2 turns worth of movement away from the unit
	var double_move_max:int = move_max * 2

	# Abort attempts to set patrol location if it fails to select a valid location within 10 attempts
	while attempts < 10:
		# Randomly pick a vector offset within movement * 2 of the unit
		var random_x_offset = random_gen.randi_range(-double_move_max, double_move_max)
		var random_y_offset = random_gen.randi_range(-double_move_max, double_move_max)
		var assembled_vector:Vector2i = Vector2i(random_x_offset, random_y_offset)

		# Make sure we aren't trying to set our patrol point to ourself
		if assembled_vector != Vector2i(0, 0):

			# Add the vector offset to get a coordinate tile
			assembled_vector +=  cur_pos

			# Make sure we aren't telling ourself to walk into a wall or a tile another Entity is on
			if assembled_vector not in cached_parent.map_manager.map_dict:
				var validation = coordinate_validated(assembled_vector)
				var can_reach_location:bool = validation[0]
				var path_to_coordinate:PackedVector2Array = validation[2]

				# Make sure the tile is reachable (and exists)
				if can_reach_location: 

					# Assign the coordinate to a variable that carries between turns
					cached_patrol_location_data = [assembled_vector, path_to_coordinate]
					current_turn_debug_print += "DEBUG/PATROL: Assigned " + str(assembled_vector) + " with path " + str(path_to_coordinate)
					return
		attempts += 1
	return

var cached_attack_action:Attackaction = null
## Searches for the most undefended /  vulnerable enemy unit to attack
## - Iterate through all coordinates flagged with an enemy unit
## - - Skip if we only have 3x3 range patterns AND there are no empty adjacent tiles
## - - Store the ideal attack for this
##
## RETURN: Array[Vector2i, float, PackedVector2Array]
##  - [CoordinateToAttackExposedHostileFrom, StrengthDisparityRatio, PathToAttackCoordinate] 
func find_exposed_hostile() -> Array:
	var best_strength_disparity:float = -INF
	var exposed_enemy_coord:Vector2i = INVALID_COORDINATE
	var path_to_attack_location:PackedVector2Array = [INVALID_COORDINATE, INVALID_COORDINATE]
	for coordinate in sighted_hostiles:
		# Get all tiles surrounding the enemy unit
		var adjacent_tiles = Globals.get_bfs_empty_tiles(coordinate, 1, cached_parent.map_manager)

		# If there are no empty tiles directly surrounding AND we only have 3x3 attack patterns (ie, we're melee only with no ranged options), then skip this unit
		var num_empty_adjacent_tiles = len(adjacent_tiles)
		if num_empty_adjacent_tiles <= 0 and relative_range <= 1:
			# print("No empty tiles adjacent to ", coordinate)
			continue

		# Fetch best attack specific to this enemy
		var temporary_attack_action_cache:Attackaction = ideal_attack(sighted_hostiles.get(coordinate))

		# Find the best tile to attack this enemy from using this attack's pattern
		var support_arr:Array = get_best_supported_tile(coordinate, temporary_attack_action_cache)
		# current_turn_debug_print += "\nDEBUG/ACTING/EXPO: SupportArr for Enemy at Coord " + str(coordinate) + " is " + str(support_arr)
		# Check to make sure the tile is reachable (and that there were no other errors)
		if support_arr[0] != INVALID_COORDINATE:
			# Only consider enemies we'd be willing to attack when in the ACTING State
			if support_arr[1] > FALL_BACK_TO_REGROUP_THRESHOLD:
				# Update the information for 'most-exposed' enemy if we have a better strength disparity ratio for this unit
				if support_arr[1] > best_strength_disparity:
					exposed_enemy_coord = coordinate
					best_strength_disparity = support_arr[1]
					path_to_attack_location = support_arr[2]
					cached_attack_action = temporary_attack_action_cache
				# else:
				# 	current_turn_debug_print += "\nDEBUG/ACTING/EXPO: We've already found a better enemy to attack than the one at " + str(coordinate)
			# else:
			# 	current_turn_debug_print += "\nDEBUG/ACTING/EXPO: We aren't brave enough to fight the enemy at " + str(coordinate)
		# else:
		# 	current_turn_debug_print += "\nDEBUG/ACTING/EXPO: INVALID COORDINATE for " + str(coordinate)

	# IMPORTANT: exposed_enemy_coord is NOT the tile to attack from, that's the tile the enemy unit is on
	return [exposed_enemy_coord, best_strength_disparity, path_to_attack_location]

var cached_support_action:Healaction = null
## Searches for Allied Units in need of aid (buffing / healing)
## [br] - Iterate through all friendly factions
## [br] - - Iterate through all units in that faction
## [br] - - - DO NOT Skip us (because how else will we heal ourselves?)
## [br] - - - 
## [br] - - Store the ideal attack for this
## [br]
## [br] RETURN: Array[Vector2i, float, PackedVector2Array]
## [br]  - [CoordinateToAttackExposedHostileFrom, StrengthDisparityRatio, PathToAttackCoordinate] 
func find_unit_in_need() -> Array:
	var best_strength_disparity:float = -INF
	var ally_in_need_coord:Vector2i = INVALID_COORDINATE
	var path_to_recovery_location:PackedVector2Array = []
	var selected_unit:Entity = null
	for faction_name_ref in get_friendly_factions():
		for friendly_unit:Unit in get_tree().get_nodes_in_group(faction_name_ref):
			var coordinate:Vector2i = friendly_unit.cur_pos

			# Get all tiles surrounding the allied unit
			var adjacent_tiles = Globals.get_bfs_empty_tiles(coordinate, 1, cached_parent.map_manager)

			# If there are no empty tiles directly surrounding AND we only have 3x3 action patterns (ie, we're touch-only with no ranged options), then skip this allied unit -- we can't help reach them to help them
			var num_empty_adjacent_tiles = len(adjacent_tiles)
			if num_empty_adjacent_tiles <= 0 and relative_range <= 1:
				continue

			# Fetch best recovery action specific to this allied unit
			var temporary_recovery_action_cache:Healaction = ideal_recovery()
			var support_arr = get_best_supported_tile(coordinate, cached_support_action)
			if support_arr[0] != INVALID_COORDINATE:
				# Only consider allies wherein we have a Friendly to Enemy Ratio of 0.5; Then check to see if we've got better support here than the 'best' enemy to attack
				if support_arr[1] > RETREAT_THRESHOLD:
					if support_arr[1] > best_strength_disparity:
						ally_in_need_coord = coordinate
						best_strength_disparity = support_arr[1]
						path_to_recovery_location = support_arr[2]
						cached_support_action = temporary_recovery_action_cache
	
	# Unlike find_exposed_hostile, we need to store the unit we'll be 'focusing' on, AND we still need to have a 'set' coordinate vector that we can compare with INVALID_COORDINATE
	return [ally_in_need_coord, best_strength_disparity, path_to_recovery_location, selected_unit]

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
		if threat_diff > FALL_BACK_TO_REGROUP_THRESHOLD and action_count > 0:
			change_state(state_machine.ACTING)
			return
		# Not great odds, we should regroup with nearby allies
		elif threat_diff > RETREAT_THRESHOLD and move_count > 0:
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
		var data_arr = [INVALID_COORDINATE, -INF, [INVALID_COORDINATE, INVALID_COORDINATE]]
		if current_alert_level == alert_level.HOSTILE_IN_SIGHT:
			data_arr = find_exposed_hostile()
		else:
			data_arr = find_unit_in_need()
		current_turn_debug_print += "\nDEBUG/ACTING/DATA_ARR: " + str(data_arr)
		if data_arr[0] != INVALID_COORDINATE:
			if current_alert_level == alert_level.HOSTILE_IN_SIGHT:
				current_turn_debug_print += "\nDEBUG/ACTING/EXPOSED_HOSTILE: " + str(data_arr[0])
				current_turn_debug_print += "\nDEBUG/ACTING/SELECTED_ATTACK: " + str(cached_attack_action)
				cached_focus_unit = sighted_hostiles.get(data_arr[0])
			else:
				current_turn_debug_print += "\nDEBUG/ACTING/UNIT_IN_AID: " + str(data_arr[0])
				current_turn_debug_print += "\nDEBUG/ACTING/SELECTED_ACTION: " + str(cached_support_action)
				cached_focus_unit = data_arr[3]
			cached_movement_path = data_arr[2]
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
		# var bypass_location_check:bool = false
		#if len(cached_movement_path) == 0:
		#	current_turn_debug_print += "\nDEBUG/MOVING: Already at desired location of " + str(cur_pos)
		#	bypass_location_check = true
		#else:
		if len(cached_movement_path) == 0:
			print("PRINTING DEBUG EARLY:")
			print(current_turn_debug_print)
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
		if selection[0] != INVALID_COORDINATE:
			cached_parent.move_unit_via_path(self, selection[1], true)
	elif current_alert_level == alert_level.INVESTIGATE_AUDIO_CUE:
		var selection:Array = select_investigation_location()
		if selection[0] != INVALID_COORDINATE:
			cached_parent.move_unit_via_path(self, selection[1], true)
	elif current_alert_level == alert_level.PATROL_AREA:
		if cached_patrol_location_data[0] == INVALID_COORDINATE or cur_pos == cached_patrol_location_data[0]:
			select_patrol_point()
			
		if cached_patrol_location_data[0] != INVALID_COORDINATE:
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
	if data_arr[0] != INVALID_COORDINATE:
		cached_parent.move_unit_via_path(self, data_arr[1], true)
		change_state(state_machine.IDLE)
		return	
	
	# Only way to get <-1234, -1234> is if we can't get to allies, so do the next best thing and gain distance from enemies; Can't default to IDLE as nothing has changed, so we'd get stuck in a loop
	change_state(state_machine.RUNNING)
	
func state_machine_running() -> void:
	var data_arr:Array = find_retreat_point()
	if data_arr[0] != INVALID_COORDINATE:
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
