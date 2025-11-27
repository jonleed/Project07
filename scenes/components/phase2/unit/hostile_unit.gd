extends Unit
class_name Hostile_Unit

@export var enemy_res:AIResource = load("res://resources/AI/balls.tres")
@onready var select_ui := $"Hostile Unit UI"
@onready var dmg_label: Label = $"Hostile Unit UI/DMGLabel"
@onready var hp_label: Label = $"Hostile Unit UI/HPLabel"

var turn_log = ""


func _ready() -> void:
	if u_res:
		print("URES")
	if u_res and u_res.ai_res:
		enemy_res = u_res.ai_res
		print("EXCHANGE")
	
#func set_enemy_res.when_to_retreat(provided_behaviour:int) -> void:
	#if provided_behaviour in when_to_retreat:
		#enemy_res.when_to_retreat = provided_behaviour
		#
#func set_retreat_location(provided_behaviour:int) -> void:
	#if provided_behaviour in where_to_retreat_to:
		#enemy_res.where_to_retreat_to = provided_behaviour
#
#func set_enemy_res.who_to_attack(provided_behaviour:int) -> void:
	#if provided_behaviour in who_to_attack:
		#enemy_res.who_to_attack = provided_behaviour
		

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
	turn_log = "["+str(self) + "] Begining"
	idle_state()
	# print(turn_log)
	
	
var action_failed:bool = false
var movement_failed:bool = false
var enemy_that_we_care_about:Entity = null
var friend_that_we_care_about:Entity = null
var last_unit_to_damage_me:Entity = null

func determine_enemy_we_care_about() -> void:
	if enemy_res.who_to_attack == 0: #LAST TO DAMAGE
		turn_log += "\n\t\tSet to focus on LAST-TO-DMAGE"
		if last_unit_to_damage_me != null:
			turn_log += "\n\t\tLAST-TO-DMAGE is ["+str(last_unit_to_damage_me)+"]"
			enemy_that_we_care_about = last_unit_to_damage_me
		else:
			turn_log += "\n\t\tLAST-TO-DMAGE is null; Defaulting to Minimal"
			enemy_that_we_care_about = get_minimal_enemy()
	else:
		enemy_that_we_care_about = get_minimal_enemy()
	

func get_minimal_enemy(check_closest_override:bool=false) -> Entity:
	var minimal_value = INF
	var minimal_unit:Entity = null
	for enemy_faction_name in get_enemy_unit_factions():
		turn_log += "\n\t\tConsidering faction: ["+enemy_faction_name+"]"
		# Skip our own faction, just in case it somehow ended up in enemy factions
		if enemy_faction_name == cached_parent.faction_name:
			turn_log += "\n\t\t\t\tSkipping own Faction"			
			continue

		# Fetch all units belonging to this enemy faction	
		var unit_array:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
		for enemy_unit:Entity in unit_array:
			turn_log += "\n\t\t\tConsidering unit: ["+str(enemy_unit)+"]"
			if enemy_unit.health <= 0:
				turn_log += "\n\t\t\t\tSkipping as health is below 0"
				continue
			
			var enemy_unit_pos:Vector2i = enemy_unit.cur_pos
			var dist_to_enemy:float = enemy_unit_pos.distance_to(cur_pos)
			var used_value:float = dist_to_enemy
			if (not check_closest_override and enemy_res.who_to_attack == 1):#Lowest Health
				turn_log += "\n\t\t\t\tUsing Health as minimal value."
				used_value = enemy_unit.health
			else:
				turn_log += "\n\t\t\t\tUsing Distance as minimal value."
			turn_log += "\n\t\t\t\tMust meet minimum of ["+str(minimal_value)+"], have a value of ["+str(used_value)+"]"
			if used_value < minimal_value:
				turn_log += "\n\t\t\t\tMinimum Met."
				minimal_value = used_value
				minimal_unit = enemy_unit
	return minimal_unit

func determine_friend_we_care_about() -> void:
	friend_that_we_care_about = get_minimal_friendly(cur_pos, false, true)
	
func get_minimal_friendly(plan_pos:Vector2i, override_consider_closest:bool=false, exclude_max_health:bool=false) -> Entity:
	var minimal_value = INF
	var minimal_unit:Entity = null
	for friendly_faction_name in get_friendly_factions():
		turn_log += "\n\t\tConsidering faction: ["+friendly_faction_name+"]"
		var unit_array:Array = get_tree().get_nodes_in_group(friendly_faction_name)		
		for friendly_unit:Entity in unit_array:
			turn_log += "\n\t\t\tConsidering unit: ["+str(friendly_unit)+"]"
			if friendly_unit == self:	
				turn_log += "\n\t\t\t\tSkipping Self"			
				continue
			if friendly_unit.health <= 0:
				turn_log += "\n\t\t\t\tSkipping as health is below 0"
				continue
				
			if exclude_max_health:
				if friendly_unit.health >= friendly_unit.base_health:
					turn_log += "\n\t\t\t\tExcluding unit at maximum health"
					continue
			
			var friendly_unit_pos:Vector2i = friendly_unit.cur_pos
			var dist_to_friendly:float = friendly_unit_pos.distance_to(plan_pos)
			var used_value:float = dist_to_friendly
			if (not override_consider_closest and enemy_res.who_to_support == 0):#Lowest Health
				turn_log += "\n\t\t\t\tUsing Health as minimal value."
				used_value = friendly_unit.health
			else:
				turn_log += "\n\t\t\t\tUsing Distance as minimal value."
			turn_log += "\n\t\t\t\tMust meet minimum of ["+str(minimal_value)+"], have a value of ["+str(used_value)+"]"
			if used_value < minimal_value:
				turn_log += "\n\t\t\t\tMinimum Met."
				minimal_value = used_value
				minimal_unit = friendly_unit
	return minimal_unit
	


func idle_state() -> void:
	var debug_loop_iteration = 1
	while not action_failed and not movement_failed:
		turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: ActionFail ["+str(action_failed)+"]; MovementFail: ["+str(movement_failed)+"]"
		turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: DETERMINING FRIEND WE CARE ABOUT"
		determine_friend_we_care_about()
		turn_log += "\n\t\tFRIEND WE CARE ABOUT IS: ["+str(friend_that_we_care_about)+"]"
		turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: DETERMINING ENEMY WE CARE ABOUT"
		determine_enemy_we_care_about()
		turn_log += "\n\t\tENEMY WE CARE ABOUT IS: ["+str(enemy_that_we_care_about)+"]"
		turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: ENTERING MOVING STATE"
		moving_state()
		turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: DETERMINING FRIEND WE CARE ABOUT (AGAIN)"
		determine_friend_we_care_about()
		turn_log += "\n\t\tFRIEND WE CARE ABOUT IS: ["+str(friend_that_we_care_about)+"]"
		turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: DETERMINING ENEMY WE CARE ABOUT (AGAIN)"
		determine_enemy_we_care_about()
		turn_log += "\n\t\tENEMY WE CARE ABOUT IS: ["+str(enemy_that_we_care_about)+"]"
		turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: ENTERING ACTING STATE"
		acting_state()
	turn_log += "\n\t[LOOP "+str(debug_loop_iteration)+"]: Ending unit's turn with ["+str(move_count)+"] Movement and ["+str(action_count)+"] Actions left."
	done_state()
	
func done_state() -> void:
	# Make sure these are zero so we get flagged as having ended our turn
	action_count = 0
	move_count = 0
	
func acting_state() -> void:
	if action_count <= 0:
		action_failed = true
		return
		
	turn_log += "\n\t\tFirst Action Attempt;"
	if enemy_res.type_of_unit == 0:#Attacker
		turn_log += "\n\t\tAttempting Attack!"
		attacking_state()
	elif enemy_res.type_of_unit == 1:#Supporter
		turn_log += "\n\t\tAttempting Support!"
		supporting_state()
		
	if action_failed:
		turn_log += "\n\t\tAction failed; Attempting Alternates;"
		if enemy_res.type_of_unit == 0:#Attacker
			turn_log += "\n\t\t\tAttempting Support!"
			supporting_state()
		elif enemy_res.type_of_unit == 1:#Supporter
			turn_log += "\n\t\t\tAttempting Attack!"
			attacking_state()
	
	return
	
# Gets the tiles affectable by an action
func range_pattern_or_flow_pattern(provided_action:Action) -> Array[Vector2i]:
	if provided_action.range_type == 0:
		# Range pattern
		return provided_action.range_pattern.calculate_affected_tiles_from_center(cur_pos)
	else: 
		# Flow
		if provided_action.is_vision_based:
			return Globals.get_bfs_tiles(cur_pos, provided_action.range_dist, cached_parent.map_manager)
		else:
			return Globals.get_bfs_empty_tiles(cur_pos, provided_action.range_dist, cached_parent.map_manager)
	
func attacking_state() -> void:
	if cached_attack_action == null:
		turn_log += "\n\t\t\tWe don't have a valid attack action!"
		action_failed = true
		return
	
	if enemy_that_we_care_about.cur_pos not in range_pattern_or_flow_pattern(cached_attack_action):
		turn_log += "\n\t\t\tThe enemy we care about isn't in range!"
		action_failed = true
		return
	
	turn_log += "\n\t\t\tUsing Attackaction ["+str(cached_attack_action)+"]"
	use_action(cached_attack_action, enemy_that_we_care_about)
	action_failed = false
	return
	
func supporting_state() -> void:
	if cached_support_action == null:
		action_failed = true
		return
		
	if friend_that_we_care_about.cur_pos not in range_pattern_or_flow_pattern(cached_support_action):
		action_failed = true
		return
	
	use_action(cached_support_action, friend_that_we_care_about)
	action_failed = false
	return
	
func moving_state() -> void:
	turn_log += "\n\t\tMove Pts available: ["+str(move_count)+"]"
	if move_count <= 0:
		turn_log += "\n\t\tInsufficient Movement Points, movement failed."
		movement_failed = true
		return
	
	turn_log += "\n\t\tShould we retreat?"
	if should_we_should_retreat():
		turn_log += "\n\t\tRETREAT!!!"
		running_state()
	else:
		turn_log += "\n\t\tNAH-- CHARGE!!!"
		rushing_state()
		
	return
	
func should_we_should_retreat() -> bool:
	match enemy_res.when_to_retreat:
		3:#NEVER
			turn_log += "\n\t\t\tNever"
			return false
		2:#LOW Health
			turn_log += "\n\t\t\tIf we have less than low_health -> ["+str(base_health*enemy_res.LOW_HEALTH_THRESHOLD)+"]; We have ["+str(health)+"]"
			if health <= int(base_health*enemy_res.LOW_HEALTH_THRESHOLD):
				turn_log += "\n\t\t\tHealth below threshold"
				return true
		1:#MED Health
			turn_log += "\n\t\t\tIf we have less than mid_health -> ["+str(base_health*enemy_res.MID_HEALTH_THRESHOLD)+"]; We have ["+str(health)+"]"
			if health <= int(base_health*enemy_res.MID_HEALTH_THRESHOLD):
				turn_log += "\n\t\t\tHealth below threshold"
				return true
		0:#THREATENED
			turn_log += "\n\t\t\tIf we are threatened"
			for enemy_faction_name in get_enemy_unit_factions():
				turn_log += "\n\t\t\t\tConsidering faction: ["+str(enemy_faction_name)+"]"
				# Skip our own faction, just in case it somehow ended up in enemy factions
				if enemy_faction_name == cached_parent.faction_name:
					turn_log += "\n\t\t\t\t\tSkipping own Faction"
					continue

				# Fetch all units belonging to this enemy faction	
				var unit_array:Array = get_tree().get_nodes_in_group(enemy_faction_name)		
				for enemy_unit in unit_array:
					turn_log += "\n\t\t\t\t\tConsidering unit: ["+str(enemy_unit)+"]"
					if enemy_unit.health <= 0:
						turn_log += "\n\t\t\t\t\tSkipping as health is below 0"
					
					var dist_from_us = enemy_unit.cur_pos.distance_to(cur_pos)
					turn_log += "\n\t\t\t\t\tDistance must be < ["+str(enemy_res.THREATENING_DISTANCE)+"] to retreat; Distance is ["+str(dist_from_us)+"]"
					if dist_from_us <= enemy_res.THREATENING_DISTANCE:
						turn_log += "\n\t\t\t\t\tThreatening Distance met."
						return true
	return false
	
func calculate_heading(unit_coordinate:Vector2, provided_coordinate:Vector2) -> Vector2:
	return provided_coordinate - unit_coordinate
	
func convert_to_unit_vector(provided_coordinate:Vector2) -> Vector2:
	var vector_length = provided_coordinate.length()
	return provided_coordinate / vector_length
	
func retreat_to_furthest_point_from_closest_enemy() -> Vector2i:
	var closest_enemy:Entity = null
	if enemy_that_we_care_about != null and enemy_res.who_to_attack == 2:#CLOSEST
		turn_log += "\n\t\t\t\tRetreating from ["+str(enemy_that_we_care_about)+"] due to cache"
		closest_enemy = enemy_that_we_care_about
	else:
		turn_log += "\n\t\t\t\tFetching closest enemy"
		closest_enemy = get_minimal_enemy(true)
	
	turn_log += "\n\t\t\t\tCloset Enemy is: ["+str(closest_enemy)+"] at "+str(closest_enemy.cur_pos)
	var closest_enemy_coordinate:Vector2 = Vector2(closest_enemy.cur_pos)
	if closest_enemy_coordinate != Vector2(-INF, -INF):
		var direction_to_enemy:Vector2 = calculate_heading(cur_pos, closest_enemy_coordinate)
		turn_log += "\n\t\t\t\tDirection to Enemy is: ["+str(direction_to_enemy)+"]"
		var unit_vector:Vector2 = convert_to_unit_vector(direction_to_enemy)
		turn_log += "\n\t\t\t\tNormalized Direction is: ["+str(unit_vector)+"]"
		var retreat_location = Vector2(cur_pos)
		var last_non_wall_tile = retreat_location
		var breaking_condition = false
		var movement_accounted_for = 0
		while movement_accounted_for < move_count and not breaking_condition:
			movement_accounted_for += 1
			var incremented_retreat_location:Vector2 = retreat_location - unit_vector
			var rounded_location:Vector2i = Vector2i(round(incremented_retreat_location.x), round(incremented_retreat_location.y))
			turn_log += "\n\t\t\t\t\t"+str(movement_accounted_for)+"\\"+str(move_count)+"; Incremented Tile from "+str(retreat_location)+" is: " + str(incremented_retreat_location) + "("+str(Vector2i(incremented_retreat_location))+")"
			if cached_parent.map_manager.get_surface_tile(rounded_location) != 5:
				# turn_log += "\n\t\t\t\t\t"+str(movement_accounted_for)+"\\"+str(move_count)+"; Tile: " + str(incremented_retreat_location) + "is NOT Air"
				retreat_location = incremented_retreat_location
				if rounded_location in cached_parent.map_manager.map_dict_all_non_wall_tiles:
					# turn_log += "\n\t\t\t\t\t\t"+str(movement_accounted_for)+"\\"+str(move_count)+"; Tile: " + str(incremented_retreat_location) + "is NOT a Wall"
					last_non_wall_tile = rounded_location
				else:
					turn_log += "\n\t\t\t\t\t"+str(movement_accounted_for)+"\\"+str(move_count)+"; Tile: " + str(incremented_retreat_location) + "is occupied!"
			else:
				turn_log += "\n\t\t\t\t\t"+str(movement_accounted_for)+"\\"+str(move_count)+" BREAKING; Tile: " + str(incremented_retreat_location) + "is Air"
				breaking_condition = true
		retreat_location = Vector2i(last_non_wall_tile)
		turn_log += "\n\t\t\t\tRetreat Location is: ["+str(retreat_location)+"]"
		return retreat_location
	turn_log += "\n\t\t\t\tClosest enemy is off the map?"
	return Vector2i(-INF, -INF)
	
func retreat_to_friend() -> Vector2i:
	var closest_unit:Entity = get_minimal_friendly(cur_pos, true)	
	turn_log += "\n\t\t\tClosest Friendly Unit is: ["+str(closest_unit)+"]"
	if closest_unit == null:
		return retreat_to_furthest_point_from_closest_enemy()
	else:
		var empty_tiles_around_friendly_unit:Array[Vector2i] = Globals.get_bfs_empty_tiles(closest_unit.cur_pos, 1, cached_parent.map_manager) 
		turn_log += "\n\t\t\tPossible Tiles: ["+str(empty_tiles_around_friendly_unit)+"]"
		var closest_tile:Vector2i = Vector2i(-INF, -INF)
		var closest_distance = INF
		for adjacent_tile in empty_tiles_around_friendly_unit:
			turn_log += "\n\t\t\t\tConsidering Tile: ["+str(adjacent_tile)+"]"
			if adjacent_tile in cached_parent.map_manager.map_dict:
				turn_log += "\n\t\t\t\tDiscarding solid tile"
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
	if enemy_res.where_to_retreat_to == 1:#FURTHEST POINT FROM CLOSEST ENEMY
		turn_log += "\n\t\t\tAway from the nearest enemy!"
		retreat_coordinate = retreat_to_furthest_point_from_closest_enemy()
	else:
		turn_log += "\n\t\t\tTo our friends!"
		retreat_coordinate = retreat_to_friend()
	turn_log += "\n\t\t\tRetreat to ["+str(retreat_coordinate)+"]!"
	
	if retreat_coordinate == Vector2i(-INF, -INF):
		turn_log += "\n\t\t\tThere's no where to run to!"
		movement_failed = true
		return
	
	#var pathfinder:Pathfinder = cached_parent.get_pathfinder()
	#var path_to_take:PackedVector2Array = pathfinder._return_path(cur_pos, retreat_coordinate)
	var path_to_take = cached_parent.map_manager.get_star_path(cur_pos, retreat_coordinate)
	if path_to_take.is_empty() or path_to_take[0] == Vector2i(-INF, -INF):
		turn_log += "\n\t\t\tWe have an invalid path!!! -> "+str(path_to_take)
		movement_failed = true
	else:
		move_down_path(path_to_take, true)
	return
	
	
func get_tiles_that_can_act_on_given_tile(target_unit:Entity, provided_action:Action) -> Array[Vector2i]:
	var possible_coordinates:Array[Vector2i] = []
	if provided_action.range_type == 0:
		var used_pattern:Pattern2D = provided_action.range_pattern

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
	else:
		for coordinate_y in range(-provided_action.range_dist, provided_action.range_dist + 1):
			for coordinate_x in range(-provided_action.range_dist, provided_action.range_dist + 1):
				# Converts the pattern offsets in the pattern to an actual map coordinate
				var offset_mapped_to_coordinate = target_unit.cur_pos + Vector2i(coordinate_x, coordinate_y)
				
				# Secondly, see if the provided_coordinate is within the list of tiles affected from that location
				var coordinates_affected_by_pattern = range_pattern_or_flow_pattern(provided_action)
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
		turn_log += "\n\t\t\tConsidering Action: ["+str(action.action_name)+"]"
		var points_that_can_hit_target:Array[Vector2i] = get_tiles_that_can_act_on_given_tile(target_unit, action)
		for point in points_that_can_hit_target:
			turn_log += "\n\t\t\t\tConsidering Tile: ["+str(point)+"]"
			# Make sure it's a valid tile (in the map), and that there isn't an entity on that tile
			if point not in cached_parent.map_manager.map_dict_all_non_wall_tiles or point in cached_parent.map_manager.map_dict:
				turn_log += "\n\t\t\t\t\tDiscarding invalid tile"
				continue
			
			var distance_to_point:float = point.distance_to(cur_pos)
			turn_log += "\n\t\t\t\t\tMust meet minimum of ["+str(closest_distance)+"], have a value of ["+str(distance_to_point)+"]"
			if distance_to_point < closest_distance :
				turn_log += "\n\t\t\t\t\tMinimum Met."
				closest_point = point
				closest_action = action
				closest_distance = distance_to_point
	if closest_action != null:
		turn_log += "\n\t\t\tDecided upon Action ["+str(closest_action.action_name)+"] at tile ["+str(closest_point)+"]"
	else:
		turn_log += "\n\t\t\tDecided upon Action [NULL] at tile ["+str(closest_point)+"]"
	return [closest_point, closest_action]
	
func rushing_state() -> void:
	var acting_point = Vector2i(-INF, -INF)
	cached_attack_action = null
	cached_support_action = null
	if enemy_res.type_of_unit == 0:#ATTACKER
		turn_log += "\n\t\tWe are an ATTACKER"
		if enemy_that_we_care_about != null:
			turn_log += "\n\t\tWe care about: ["+str(enemy_that_we_care_about)+"]"
			var returned_data:Array = get_point_to_act_from(true, enemy_that_we_care_about)
			acting_point = returned_data[0]
			cached_attack_action = returned_data[1]
		elif friend_that_we_care_about != null:
			turn_log += "\n\t\tWe care about: ["+str(friend_that_we_care_about)+"]"
			var returned_data:Array = get_point_to_act_from(false, friend_that_we_care_about)
			acting_point = returned_data[0]
			cached_support_action = returned_data[1]
		else:
			turn_log += "\n\t\tWe don't care about ANYONE"
	elif enemy_res.type_of_unit == 1:#SUPPORTER
		turn_log += "\n\t\tWe are a SUPPORTER"
		if friend_that_we_care_about != null:
			turn_log += "\n\t\tWe care about: ["+str(friend_that_we_care_about)+"]"
			var returned_data:Array = get_point_to_act_from(false, friend_that_we_care_about)
			acting_point = returned_data[0]
			cached_support_action = returned_data[1]
		elif enemy_that_we_care_about != null:
			turn_log += "\n\t\tWe care about: ["+str(enemy_that_we_care_about)+"]"
			var returned_data:Array = get_point_to_act_from(true, enemy_that_we_care_about)
			acting_point = returned_data[0]
			cached_attack_action = returned_data[1]
		else:
			turn_log += "\n\t\tWe don't care about ANYONE"
	
	if acting_point == Vector2i(-INF, -INF) or (cached_attack_action == null and cached_support_action == null):
		turn_log += "\n\t\tWe couldn't figure out how to act on our target."
		movement_failed = true
	else:
		#var pathfinder:Pathfinder = cached_parent.get_pathfinder()
		#var path_to_take:PackedVector2Array = pathfinder._return_path(cur_pos, acting_point)
		var path_to_take = cached_parent.map_manager.get_star_path(cur_pos, acting_point)
		if path_to_take.is_empty() or path_to_take[0] == Vector2i(-INF, -INF):
			movement_failed = true
		else:
			move_down_path(path_to_take, true)
	return
