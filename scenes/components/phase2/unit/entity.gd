extends Node
class_name Entity

var pathfinder:Pathfinder
var coordinate:Vector3i
var clean_coordinate:Vector2i
var icon_sprite:Sprite2D
var map_sprite:Sprite2D
var x_coord:int
var y_coord:int
var entity_name:String
var entity_id:int

func _init(pathfinder_ref:Pathfinder, spawn_pos:Vector2i, provided_info:Dictionary) -> void:
	pathfinder = pathfinder_ref
	entity_name = provided_info.get("name")
	entity_id = provided_info.get("id")
	var tmp_ref = pathfinder._provide_tile_map_ref()
	var tmp_surf_map = tmp_ref._provide_surface_map()
	if spawn_pos in tmp_surf_map:
		coordinate = Vector3i(spawn_pos.x, spawn_pos.y, tmp_surf_map.get(spawn_pos))
	else:
		var tmp_arr = tmp_surf_map.keys()
		coordinate = Vector3i(tmp_arr[0].x, tmp_arr[0].y, tmp_surf_map.get(tmp_arr[0]))
	clean_coordinate = Vector2i(coordinate.x, coordinate.y)
	set_xy()

func _ready() -> void:
	pass

func set_xy() -> void:
	x_coord = clean_coordinate.x
	y_coord = clean_coordinate.y
	
func convert_position(coord:Vector2i) -> int:
	return pathfinder._get_point_id(Vector2i(coord.x, coord.y))

func arbitrary_move(target:Vector2i):
	var point_id = convert_position(target)
	if point_id != -1:
		var tmp_map = pathfinder._provide_inverted_identifier_map()
		if point_id in tmp_map:
			coordinate = tmp_map.get(point_id)
		else:
			coordinate = pathfinder.get_point_position(point_id)
		clean_coordinate = Vector2i(coordinate.x, coordinate.y)
		set_xy()

func assign_sprite(sprite:Sprite2D, selection:int, same_sprite:bool=false) -> void:
	if selection == 0 or same_sprite:
		icon_sprite = sprite
	if selection == 1 or same_sprite:
		map_sprite = sprite

func provide_coordinate()->Vector3i:
	return coordinate

func provide_x_coord()->int:
	return x_coord
	
func provide_y_coord()->int:
	return y_coord
	
func provide_entity_id()->int:
	return entity_id
