class_name Pathfinder
extends AStar3D

var tile_map_ref:TerrainTileMap
var surface_map:Dictionary[Vector2i, int]
@export var identifier_map:Dictionary[Vector3, int]
@export var inverted_identifier_map:Dictionary[int, Vector3]


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
	
func _return_path(provided_coordinate:Vector3i, provided_target:Vector3i)->Array[int]:
	var point_id = get_closest_point(Vector3(provided_coordinate.x, provided_coordinate.y, provided_coordinate.z))
	var target_id = get_closest_point(Vector3(provided_target.x, provided_target.y, provided_target.z))
	return get_point_path(point_id, target_id)
	
func _provide_tile_map_ref()->TerrainTileMap:
	return tile_map_ref

func _provide_identifier_map()->Dictionary[Vector3, int]:
	return identifier_map
	
func _provide_inverted_identifier_map()->Dictionary[int, Vector3]:
	return inverted_identifier_map
	
func downgrade_vector(provided_vector:Vector3)->Vector2:
	return Vector2(provided_vector.x, provided_vector.y)
	
func get_line_of_sight(origin:Vector3i, target:Vector3i) -> bool:
	var interpolation_precision = 2
	var interpolation_steps:float = interpolation_precision * max(max(abs(origin.x-target.x), abs(origin.y-target.y)), abs(origin.z-target.z))
	if interpolation_steps == 0: return true
	for step in range(1, int(interpolation_steps) + 1):
		var line_percent:float = float(step) / interpolation_steps 
		
	
	
	return true
