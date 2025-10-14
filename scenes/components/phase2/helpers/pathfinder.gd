class_name Pathfinder
extends AStar2D

var tile_map_ref:MapManager
var surface_map:Dictionary
@export var identifier_map:Dictionary[Vector2i, int]
@export var inverted_identifier_map:Dictionary[int, Vector2i]

func _init(tile_map:MapManager):
	tile_map_ref = tile_map
	surface_map = tile_map_ref.map_dict_v2

func _ready():
	pass
	
func surrounding_vectors(provided_coordinate:Vector2i) -> Array[Vector2i]:
	var return_arr:Array[Vector2i] = []
	for row in range(provided_coordinate.y-1, provided_coordinate.y+2): # +2 because the upper bound of range is exclusive
		for column in range(provided_coordinate.x-1, provided_coordinate.x+2):
			if row != provided_coordinate.y and column != provided_coordinate.x:
				return_arr.append(Vector2i(column, row))
	return return_arr
	
func _rebuild_connections():
	clear()
	identifier_map = {}
	var counter = 0
	for coordinate in surface_map:
		var conv_coord = Vector2i(coordinate.x, coordinate.y)
		identifier_map[conv_coord] = counter
		add_point(counter, conv_coord, 1.0)
		counter += 1
	for coordinate in identifier_map:
		var coord_id = identifier_map.get(coordinate)
		var vector_grab = surrounding_vectors(coordinate)
		for vector in vector_grab:
			if vector in identifier_map:
				connect_points(coord_id, identifier_map.get(vector))
	
func parse_point(provided_point:int) -> Vector2i:
	if not has_point(provided_point):
		return Vector2i(-1234, -1234)
	else:
		return Vector2i(get_point_position(provided_point))
	
func _return_path(provided_coordinate:Vector2i, provided_target:Vector2i):
	var point_id:int = -1
	var target_id:int = -1
	if provided_coordinate in identifier_map:
		point_id = identifier_map.get(provided_coordinate)
	else:
		point_id = get_closest_point(Vector2(provided_coordinate.x, provided_coordinate.y))
	if provided_target in identifier_map:
		target_id = identifier_map.get(provided_target)
	else:
		target_id = get_closest_point(Vector2(provided_target.x, provided_target.y))
	return get_point_path(point_id, target_id)
	
func calculate_path_cost(provided_path:PackedVector2Array):
	var total_cost:float = 0.0
	for coordinate in provided_path:
		var cround:Vector2i = Vector2i(coordinate)
		if cround in identifier_map:
			total_cost += get_point_weight_scale(identifier_map.get(cround))
		else:
			total_cost += get_point_weight_scale(get_closest_point(cround))
	return total_cost
		
