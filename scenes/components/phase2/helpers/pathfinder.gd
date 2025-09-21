class_name Pathfinder
extends AStar3D

var tile_map_ref:TerrainTileMap
var surface_map:Dictionary[Vector2i, int]
@export var identifier_map:Dictionary[Vector3, int]

func _init(tile_map:TerrainTileMap):
	tile_map_ref = tile_map
	surface_map = tile_map_ref._provide_surface_map()

func _ready():
	pass
	
func surrounding_vectors(provided_coordinate:Vector3, height_l=-1, height_u=1) -> Array[Vector3]:
	var return_arr = []
	for height in range(provided_coordinate.z + height_l, provided_coordinate.z + height_u + 1):
		for row in range(provided_coordinate.y-1, provided_coordinate.y+2): # +2 because the upper bound of range is exclusive
			for column in range(provided_coordinate.x-1, provided_coordinate.x+2):
				if row != provided_coordinate.y and column != provided_coordinate.x and height != provided_coordinate.z:
					return_arr.append(Vector3(column, row, height))
	return return_arr
	
func _rebuild_connections():
	clear()
	surface_map = tile_map_ref._provide_surface_map()
	identifier_map = {}
	var counter = 0
	for coordinate in surface_map:
		var conv_coord = Vector3(coordinate.x, coordinate.y, surface_map.get(coordinate))
		identifier_map[conv_coord] = counter
		add_point(counter, conv_coord, 1.0)
		counter += 1
	for coordinate in identifier_map:
		var coord_id = identifier_map.get(coordinate)
		var vector_grab = surrounding_vectors(coordinate)
		for vector in vector_grab:
			if vector in identifier_map:
				connect_points(coord_id, identifier_map.get(vector))
		var lower_vectors = surrounding_vectors(coordinate, -2, -2)
		for vector in lower_vectors:
			if vector in identifier_map:
				connect_points(coord_id, identifier_map.get(vector), false)
	
func _return_path(provided_coordinate:Vector3i, provided_target:Vector3i):
	var vec_3 = Vector3(provided_coordinate.x, provided_coordinate.y, provided_coordinate.z)
	var point_id = identifier_map.get(vec_3)
	if vec_3 not in identifier_map:
		point_id = get_closest_point(vec_3)
	vec_3 = Vector3(provided_target.x, provided_target.y, provided_target.z)
	var target_id = identifier_map.get(vec_3)
	if vec_3 not in identifier_map:
		target_id = get_closest_point(vec_3)
	return get_point_path(point_id, target_id)
