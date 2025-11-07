extends NPC_State
class_name Rushing_State

func _ready() -> void:
	state_name = "Rushing_State"

func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	var attack_point_data = get_point_to_attack_from(plan_pos, target_unit)
	var attack_point:Vector2i = attack_point_data[0]
	var chosen_attack:Attackaction = attack_point_data[1]
	if attack_point != Vector2i(-1234, -1234):
		var pathfinder:Pathfinder = cached_parent.get_pathfinder()
		var path_to_take:PackedVector2Array = pathfinder._return_path(plan_pos, attack_point)
		cached_parent.get_plan().add_item_to_plan(cached_unit.get_move_actions()[0], path_to_take, null)
		plan_pos = attack_point
		return [State_Machine.states.ATTACKING_STATE, plan_pos, target_unit, chosen_attack]
	return [State_Machine.states.DONE_STATE, plan_pos, target_unit]


func get_tiles_that_can_attack_given_tile(target_unit:Entity, provided_attack_action:Attackaction) -> Array[Vector2i]:
	var used_pattern:Pattern2D = provided_attack_action.range_pattern
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



func get_point_to_attack_from(plan_pos:Vector2i, target_unit:Entity) -> Array:
	var closest_point:Vector2i = Vector2i(-1234, -1234)
	var closest_action:Attackaction = null
	var closest_distance:float = INF
	for attack_action in cached_unit.get_attack_actions():
		var points_that_can_hit_target:Array[Vector2i] = get_tiles_that_can_attack_given_tile(target_unit, attack_action)
		for point in points_that_can_hit_target:
			var distance_to_point:float = point.distance_to(plan_pos)
			if distance_to_point < closest_distance :
				closest_point = point
				closest_action = attack_action
				closest_distance = distance_to_point
	return [closest_point, closest_action]
