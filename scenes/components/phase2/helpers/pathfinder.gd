class_name Pathfinder
extends AStar3D

var tile_map_ref:TerrainTileMap
var surface_map:Dictionary[Vector2i, int] = {}
var identifier_map:Dictionary[Vector3, int] = {}
var inverted_identifier_map:Dictionary[int, Vector3] = {}
func _init(tile_map:TerrainTileMap):
	tile_map_ref = tile_map
	_rebuild_connections()
	
func _ready():
	pass
	
func surrounding_vectors(provided_coordinate:Vector3, height_l=-1, height_u=1) -> Array[Vector3]:
	var return_arr = []
	for height in range(provided_coordinate.z + height_l, provided_coordinate.z + height_u + 1):
		for row in range(provided_coordinate.y-1, provided_coordinate.y+2): # +2 because the upper bound of range is exclusive
			for column in range(provided_coordinate.x-1, provided_coordinate.x+2):
				if row != provided_coordinate.y and column != provided_coordinate.x and height != provided_coordinate.z:
					if Vector2i(provided_coordinate.x, provided_coordinate.y) in surface_map:
						return_arr.append(Vector3(column, row, height))
	return return_arr
	
func _get_point_id(unit_pos:Vector2i)->int:
	if unit_pos in surface_map:
		var conv_coord:Vector3 = Vector3(unit_pos.x, unit_pos.y, surface_map.get(unit_pos))
		if conv_coord in identifier_map:
			return identifier_map.get(conv_coord)
		else:
			print("[ WARN]: When fetching point using unit posistion [" + str(unit_pos.x) + "][" + str(unit_pos.y) + "], point was not in [identifier_map]. Resorting to closest_point.")
			var tmp:int =  get_closest_point(conv_coord)
			identifier_map[conv_coord] = tmp
			return tmp 
	else:
		print("[ERROR]: Unit provided posistion [" + str(unit_pos.x) + "][" + str(unit_pos.y) + "] is not in surface_map")
		return -1

func _rebuild_point_with_id(point_id:int):
	var old_coord = inverted_identifier_map.get(point_id)
	if old_coord == null:
		if has_point(point_id):
			print("[ WARN]: When rebuilding point [" + str(point_id) + "], point exists but is not stored in [inverted_identifier_map]. Fixing.")
			inverted_identifier_map[point_id] = get_point_position(point_id)
			old_coord = inverted_identifier_map.get(point_id)
		else:
			print("[ERROR]: When rebuilding point [" + str(point_id) + "], point does NOT exist")
			return
	remove_point(point_id)
	surface_map = tile_map_ref._provide_surface_map()
	var conv_coord = Vector3(old_coord.x, old_coord.y, surface_map.get(old_coord.x, old_coord.y))
	identifier_map.erase(old_coord)
	add_point(point_id, conv_coord, 1.0)
	identifier_map[conv_coord] = point_id
	inverted_identifier_map[point_id] = conv_coord
	var coord_id = identifier_map.get(conv_coord)
	var vector_grab = surrounding_vectors(conv_coord)
	for vector in vector_grab:
		if vector in identifier_map:
			connect_points(coord_id, identifier_map.get(vector))
	var lower_vectors = surrounding_vectors(conv_coord, -2, -2)
	for vector in lower_vectors:
		if vector in identifier_map:
			connect_points(coord_id, identifier_map.get(vector), false)

func _localised_rebuild_point(center_point_id:int, radius=1):
	surface_map = tile_map_ref._provide_surface_map()
	var old_coord_arr = surrounding_vectors(inverted_identifier_map.get(center_point_id), -radius, radius)
	old_coord_arr.append(center_point_id)
	var tmp_coord_arr = []
	for coord in old_coord_arr:
		if coord in identifier_map:
			tmp_coord_arr.append([coord, identifier_map.get(coord)])
			remove_point(coord)
	var new_coord_arr = []
	for entry in tmp_coord_arr: 
		var new_coord = Vector3(entry[0].x, entry[0].y, surface_map.get(entry[0].x, entry[0].y))
		new_coord_arr.append(new_coord)
		identifier_map.erase(entry[0])
		identifier_map[new_coord] = entry[1]
		inverted_identifier_map[entry[1]] = new_coord
		add_point(entry[1], new_coord, 1.0)
	for coordinate in new_coord_arr:
		var coord_id = identifier_map.get(coordinate)
		var vector_grab = surrounding_vectors(coordinate)
		for vector in vector_grab:
			if vector in identifier_map:
				connect_points(coord_id, identifier_map.get(vector))
		var lower_vectors = surrounding_vectors(coordinate, -2, -2)
		for vector in lower_vectors:
			if vector in identifier_map:
				connect_points(coord_id, identifier_map.get(vector), false)
	
func _rebuild_connections():
	clear()
	surface_map = tile_map_ref._provide_surface_map()
	identifier_map = {}
	inverted_identifier_map = {}
	var counter = 0
	for coordinate in surface_map:
		var conv_coord = Vector3(coordinate.x, coordinate.y, surface_map.get(coordinate))
		identifier_map[conv_coord] = counter
		inverted_identifier_map[counter] = conv_coord
		add_point(counter, conv_coord, 1.0)
		counter += 1
	for coordinate in identifier_map:
		var coord_id = identifier_map.get(coordinate)
		var vector_grab = surrounding_vectors(coordinate)
		for vector in vector_grab:
			# Don't need a saftey check for if it's in identifier_map cause identifier_map = surface_map and surrounding_vectors only return ones that are 'within' bounds of surface_map
			connect_points(coord_id, identifier_map.get(vector))
		var lower_vectors = surrounding_vectors(coordinate, -2, -2)
		for vector in lower_vectors:
			# Don't need a saftey check for if it's in identifier_map cause identifier_map = surface_map and surrounding_vectors only return ones that are 'within' bounds of surface_map
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
	
func _provide_inverted_identifier_map()->Dictionary[int, Vector3]:
	return inverted_identifier_map
func _provide_identifier_map()->Dictionary[Vector3, int]:
	return identifier_map
