extends Node
class_name Entity

var pathfinder:Pathfinder
var coordinate:Vector3i
var clean_coordinate:Vector2i
var icon_sprite:Sprite2D
var map_sprite:Sprite2D

func _init(pathfinder_ref:Pathfinder, spawn_pos:Vector2i) -> void:
	pathfinder = pathfinder_ref
	var tmp_ref = pathfinder._provide_tile_map_ref()
	var tmp_surf_map = tmp_ref._provide_surface_map()
	if spawn_pos in tmp_surf_map:
		coordinate = Vector3i(spawn_pos.x, spawn_pos.y, tmp_surf_map.get(spawn_pos))
		clean_coordinate = spawn_pos
	else:
		var tmp_arr = tmp_surf_map.keys()
		coordinate = Vector3i(tmp_arr[0].x, tmp_arr[0].y, tmp_surf_map.get(tmp_arr[0]))
		clean_coordinate = Vector2i(tmp_arr[0].x, tmp_arr[0].y)

func _ready() -> void:
	pass


func convert_position(coord) -> int:
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

func assign_sprite(sprite:Sprite2D, selection:int, same_sprite:bool=false) -> void:
	if selection == 0 or same_sprite:
		icon_sprite = sprite
	if selection == 1 or same_sprite:
		map_sprite = sprite
